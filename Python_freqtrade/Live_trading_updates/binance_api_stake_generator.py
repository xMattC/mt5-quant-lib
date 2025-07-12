#!/usr/bin/env python3
import os
import logging
from datetime import datetime, timedelta
from time import sleep
import pandas as pd
from binance import Client
from forex_python.converter import CurrencyRates
import telegram
import schedule

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s - %(levelname)s - %(message)s",
)

# Environment variables for sensitive information
API_KEY = os.getenv("BINANCE_API_KEY")
API_SECRET = os.getenv("BINANCE_API_SECRET")
BOT_TOKEN = os.getenv("TELEGRAM_BOT_TOKEN")
BOT_CHAT_ID = os.getenv("TELEGRAM_CHAT_ID")

# Constants
MAX_TRADES = 5
RESET_STAKE_AMOUNT = 10  # minutes
DATA_DIR = "data"

# Ensure data directory exists
os.makedirs(DATA_DIR, exist_ok=True)


def telegram_send_message(bot_token, bot_chat_id, message):
    """
    Send a message via Telegram bot.
    """
    try:
        bot = telegram.Bot(token=bot_token)
        bot.send_message(chat_id=bot_chat_id, text=message)
    except Exception as e:
        logging.error(f"Failed to send Telegram message: {e}")


def update_df(gbp, usd, btc, exchange_rate):
    """
    Update the HDF5 file with new balance data.
    """
    try:
        file_path = os.path.join(DATA_DIR, "balances.h5")
        time_now = pd.to_datetime(datetime.now().replace(microsecond=0))
        new_data = pd.DataFrame({
            "date_time": [time_now],
            "£": [gbp],
            "$": [usd],
            "BTC": [btc],
            "Ex-rate": [exchange_rate],
        })

        with pd.HDFStore(file_path) as store:
            if "df" in store:
                df = store["df"]
                df = pd.concat([df, new_data]).drop_duplicates(subset="date_time", keep="first")
            else:
                df = new_data.set_index("date_time")
            store["df"] = df

        logging.info("Updated DataFrame successfully.")

    except Exception as e:
        logging.error(f"Could not update DataFrame: {e}")
        telegram_send_message(BOT_TOKEN, BOT_CHAT_ID, "Could not update DataFrame.")


def trim_df():
    """
    Trim the DataFrame to the last 24 hours.
    """
    try:
        file_path = os.path.join(DATA_DIR, "balances.h5")
        cut_before = datetime.now() - timedelta(hours=25)

        with pd.HDFStore(file_path) as store:
            if "df" in store:
                df = store["df"]
                df = df[df.index >= cut_before]
                store["df"] = df

        logging.info("Trimmed DataFrame to the last 24 hours.")
    except Exception as e:
        logging.error(f"Could not trim DataFrame: {e}")
        telegram_send_message(BOT_TOKEN, BOT_CHAT_ID, "Could not trim DataFrame.")


def update_exchange_rate():
    """
    Fetch the latest USD to GBP exchange rate and store it.
    """
    cr = CurrencyRates()
    file_path = os.path.join(DATA_DIR, "USDGBP_exchange_rate.txt")

    try:
        exchange_rate = cr.get_rate("USD", "GBP")
        with open(file_path, "w") as f:
            f.write(str(exchange_rate))
        logging.info("Updated USD to GBP exchange rate.")
    except Exception as e:
        logging.error(f"Could not update exchange rate: {e}")
        telegram_send_message(BOT_TOKEN, BOT_CHAT_ID, "Could not update exchange rate.")


def convert_usd_to_gbp(usd):
    """
    Convert USD to GBP using the stored exchange rate.
    """
    file_path = os.path.join(DATA_DIR, "USDGBP_exchange_rate.txt")

    try:
        with open(file_path, "r") as f:
            exchange_rate = float(f.read())
        gbp = usd * exchange_rate
        return gbp, exchange_rate
    except Exception as e:
        logging.error(f"Could not convert USD to GBP: {e}")
        return usd, 1.0  # Fallback to 1:1 conversion


def get_balance():
    """
    Retrieve account balances from Binance and update the stake amount.
    """
    try:
        client = Client(API_KEY, API_SECRET)
        account_info = client.get_account()
        balances = account_info["balances"]

        usdt = 0.0
        for balance in balances:
            asset = balance["asset"]
            free = float(balance["free"])
            locked = float(balance["locked"])
            total = free + locked

            if total > 0:
                if asset == "USDT":
                    usdt += total
                else:
                    try:
                        price = float(client.get_symbol_ticker(symbol=f"{asset}USDT")["price"])
                        usdt += total * price
                    except Exception:
                        pass

        btc_price = float(client.get_symbol_ticker(symbol="BTCUSDT")["price"])
        btc = usdt / btc_price
        gbp, exchange_rate = convert_usd_to_gbp(usdt)
        stake_amount = round(usdt / MAX_TRADES)

        with open(os.path.join(DATA_DIR, "stake_amount.txt"), "w") as f:
            f.write(str(stake_amount))

        update_df(gbp, usdt, btc, exchange_rate)
    except Exception as e:
        logging.error(f"Could not fetch balances: {e}")
        telegram_send_message(BOT_TOKEN, BOT_CHAT_ID, "Could not fetch Binance balances.")


def run_code():
    """
    Main function to schedule tasks and run the bot.
    """
    update_exchange_rate()
    get_balance()
    schedule.every(RESET_STAKE_AMOUNT).minutes.do(get_balance)
    schedule.every().day.at("11:45").do(update_exchange_rate)
    schedule.every(4).hours.do(trim_df)

    while True:
        schedule.run_pending()
        sleep(1)


if __name__ == "__main__":
    run_code()
