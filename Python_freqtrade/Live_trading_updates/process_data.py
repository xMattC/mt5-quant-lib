#!/usr/bin/env python3
import os
import time
import shutil
import warnings
import pandas as pd
import matplotlib.pyplot as plt  # pip install matplotlib
import matplotlib.dates as mdates
from datetime import datetime, timedelta, date
import telegram
import schedule  # pip install schedule

warnings.simplefilter(action='ignore', category=FutureWarning)

# Constants
LONG_PLOT_DAYS = -1  # 60 # -1 all days in df
LONG_PLOT_CURRENCY = '£'
PLOT_CURRENCY = '$'

# Environment variables for sensitive information
API_KEY = os.getenv("BINANCE_API_KEY")
API_SECRET = os.getenv("BINANCE_API_SECRET")
BOT_TOKEN = os.getenv("TELEGRAM_BOT_TOKEN")
BOT_CHAT_ID = os.getenv("TELEGRAM_CHAT_ID")


date_today = date.today()
TODAY = date_today.strftime("%Y_%m_%d")


def telegram_send_image(bot_token, bot_chat_id, image_path):
    """Send an image to the specified Telegram chat."""
    bot = telegram.Bot(token=bot_token)
    with open(image_path, 'rb') as photo:
        bot.send_photo(chat_id=bot_chat_id, photo=photo)
    return ()


def telegram_send_message(bot_token, bot_chat_id, message):
    """Send a message to the specified Telegram chat."""
    bot = telegram.Bot(token=bot_token)
    bot.send_message(chat_id=bot_chat_id, text=message)
    return ()


def plot_and_send_image(df, currency, plot_title, file_name):
    """Generate plot and send it as an image to Telegram."""
    plt.rcParams.update({'font.size': 14, 'font.family': 'STIXGeneral', 'mathtext.fontset': 'stix'})
    fig, axs = plt.subplots(figsize=(7, 4))
    axs.xaxis.set_major_formatter(mdates.DateFormatter("%d %b"))
    df[currency].plot.line(ax=axs, color="darkgreen", linewidth=1.50)
    delta_y = int(df[currency].max()) - int(df[currency].min())
    y_min = int(df[currency].min()) - (delta_y * 0.05)
    y_max = int(df[currency].max()) + (delta_y * 0.05)
    x_max = datetime.now()
    x_min = datetime.now() - timedelta(days=len(df))
    axs.set_title(plot_title)
    axs.set_ylim(y_min, y_max)
    axs.set_xlim(x_min, x_max)
    axs.set_ylabel("")
    axs.set_xlabel("")
    axs.grid(color='grey', alpha=0.5, linestyle='dashed', linewidth=0.5)
    axs.yaxis.set_major_formatter(f"{currency} {{x:1.0f}}")

    plt.savefig(file_name)
    plt.cla()
    plt.close(fig)

    # Send image to Telegram
    telegram_send_image(BOT_TOKEN, BOT_CHAT_ID, file_name)
    return ()


def plot_long(period=LONG_PLOT_DAYS, currency=LONG_PLOT_CURRENCY):
    """Plot long-term data."""
    try:
        if os.path.exists('balances_24h.h5'):
            balances_24h = pd.HDFStore('balances_24h.h5')
            df = balances_24h['df_24h'].iloc[1:, :]
            balances_24h.close()
            if period == -1:
                no_of_days = len(df)
            else:
                no_of_days = period
            df = df.tail(no_of_days)
            plot_and_send_image(df, currency, f"{no_of_days} days plot", "plot_long.png")
        else:
            message = "No balances_24h.h5 file"
            telegram_send_message(BOT_TOKEN, BOT_CHAT_ID, message)
    except Exception:
        message = "Could not generate long plot"
        telegram_send_message(BOT_TOKEN, BOT_CHAT_ID, message)
    return ()


def plot_30days(currency=PLOT_CURRENCY):
    """Plot 30 days data."""
    try:
        if os.path.exists('balances_4h.h5'):
            balances_4h = pd.HDFStore('balances_4h.h5')
            df = balances_4h['df_4h'].iloc[1:, :]
            balances_4h.close()
            df = df.tail(180)
            plot_and_send_image(df, currency, "30 Day Balances", "30_days.png")
        else:
            message = "No balances_4h.h5 file"
            telegram_send_message(BOT_TOKEN, BOT_CHAT_ID, message)
    except Exception:
        message = "Could not generate 30 day plot"
        telegram_send_message(BOT_TOKEN, BOT_CHAT_ID, message)
    return ()


def plot_7days(currency=PLOT_CURRENCY):
    """Plot 7 days data."""
    try:
        if os.path.exists('balances_1h.h5'):
            balances_1h = pd.HDFStore('balances_1h.h5')
            df = balances_1h['df_1h']
            end_date = datetime.now().replace(microsecond=0)
            cut_before_date = end_date - timedelta(days=7)
            df = df.loc[df.index >= cut_before_date]
            plot_and_send_image(df, currency, "7 Day Balances", "7_days.png")
        else:
            message = "No balances_1h.h5 file"
            telegram_send_message(BOT_TOKEN, BOT_CHAT_ID, message)
    except Exception:
        message = "Could not generate 7 day plot"
        telegram_send_message(BOT_TOKEN, BOT_CHAT_ID, message)
    return ()


def plot_24h(currency=PLOT_CURRENCY):
    """Plot 24 hours data."""
    try:
        if os.path.exists('balances.h5'):
            balances = pd.HDFStore('balances.h5')
            df = balances['df'].iloc[1:, :]
            df['date_time'] = pd.to_datetime(df['date_time'])
            balances.close()
            df = df.set_index('date_time')
            plot_and_send_image(df, currency, TODAY, "24_hour.png")
        else:
            message = "No balances.h5 file"
            telegram_send_message(BOT_TOKEN, BOT_CHAT_ID, message)
    except Exception:
        message = "Could not generate 24h plot"
        telegram_send_message(BOT_TOKEN, BOT_CHAT_ID, message)
    return ()


def send_plots():
    """Send all generated plots to Telegram."""
    try:
        balances = pd.HDFStore('balances.h5')
        df = balances['df']
        balances.close()
        GBP = df['£'].iloc[-1]
        USDT = df['$'].iloc[-1]
        BTC = df['BTC'].iloc[-1]

        message = f"Balance:\n   GBP  £ {round(GBP, 2)}\n   USD  $ {round(USDT, 2)}\n   BTC   {round(BTC, 6)}"
        telegram_send_message(BOT_TOKEN, BOT_CHAT_ID, message)

        # Send all plots
        for file_name in ["plot_long.png", "30_days.png", "7_days.png", "24_hour.png"]:
            if os.path.exists(file_name):
                telegram_send_image(BOT_TOKEN, BOT_CHAT_ID, file_name)
            else:
                telegram_send_message(BOT_TOKEN, BOT_CHAT_ID, f"Could not find {file_name}")

        print(f"{datetime.now().replace(microsecond=0)} - Sent plots to Telegram.")
    except Exception:
        message = "Could not send plots."
        telegram_send_message(BOT_TOKEN, BOT_CHAT_ID, message)
    return ()


def resample_data():
    """Resample data to 1h, 4h, and 24h."""
    try:
        if not os.path.exists("balances_1h.h5"):
            balances = pd.HDFStore('balances.h5')
            df = balances['df']
            df['date_time'] = pd.to_datetime(df['date_time'])
            df = df.set_index('date_time')
            balances.close()

            # Resample to 1h
            data_1h = df.resample("H").mean()
            balances_1h = pd.HDFStore('balances_1h.h5')
            balances_1h['df_1h'] = data_1h
            balances_1h.close()

        if not os.path.exists("balances_4h.h5"):
            balances_1h = pd.HDFStore('balances_1h.h5')
            df_1h = balances_1h['df_1h']
            balances_1h.close()

            # Resample to 4h
            data_4h = df_1h.resample("4H").mean()
            balances_4h = pd.HDFStore('balances_4h.h5')
            balances_4h['df_4h'] = data_4h
            balances_4h.close()

        if not os.path.exists("balances_24h.h5"):
            balances_4h = pd.HDFStore('balances_4h.h5')
            df_4h = balances_4h['df_4h']
            balances_4h.close()

            # Resample to 24h
            data_24h = df_4h.resample("24H").mean()
            balances_24h = pd.HDFStore('balances_24h.h5')
            balances_24h['df_24h'] = data_24h
            balances_24h.close()

    except Exception:
        message = "Error in resampling data"
        telegram_send_message(BOT_TOKEN, BOT_CHAT_ID, message)
    return ()


def delete_old_files():
    """Delete old files in the directory."""
    try:
        directory = "path_to_your_directory"
        for file_name in os.listdir(directory):
            file_path = os.path.join(directory, file_name)
            if os.path.getmtime(file_path) < time.time() - 7 * 86400:
                os.remove(file_path)
    except Exception:
        message = "Error in deleting old files"
        telegram_send_message(BOT_TOKEN, BOT_CHAT_ID, message)
    return ()


def archive_data():
    """Archive old data to a zip file."""
    try:
        archive_name = f"archive_data_{TODAY}.zip"
        if not os.path.exists('archive_data'):
            os.makedirs('archive_data')
        shutil.make_archive(f'archive_data/{archive_name}', 'zip', 'path_to_your_directory')
    except Exception:
        message = "Error in archiving data"
        telegram_send_message(BOT_TOKEN, BOT_CHAT_ID, message)
    return ()


# Scheduling tasks
schedule.every().day.at("00:00").do(archive_data)
schedule.every().day.at("01:00").do(delete_old_files)
schedule.every().day.at("02:00").do(resample_data)
schedule.every().day.at("02:30").do(plot_long)
schedule.every().day.at("03:00").do(plot_30days)
schedule.every().day.at("03:30").do(plot_7days)
schedule.every().day.at("04:00").do(plot_24h)
schedule.every().day.at("05:00").do(send_plots)

# Main loop
while True:
    schedule.run_pending()
    time.sleep(1)
