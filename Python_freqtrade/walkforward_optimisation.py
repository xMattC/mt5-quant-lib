"""
MattC - 2025
This code is a working prototype and is intended for initial testing and development purposes. Some Python
standards, including but not limited to PEP 8 compliance, error handling, and code optimization, are yet to be fully
implemented. Further refactoring and enhancements are planned to improve readability, maintainability,
and efficiency.
"""

import os
from os import walk
import json
from datetime import datetime, timedelta
import pandas as pd
import shutil
from pathlib import Path
import logging
import matplotlib.pyplot as plt  # pip install matplotlib
import matplotlib.dates as mdates
import warnings
import urllib
from urllib.request import urlopen
import time

warnings.simplefilter(action='ignore', category=FutureWarning)
logger = logging.getLogger(__name__)


# TODO sort out download data
class WalkForward(object):

    def __init__(self, strategy_path, strategy, config, output_dir, wf_start, wf_finish, anchored_start, min_trades,
                 in_sample_days, out_sample_days, loss_function, cpu, epochs, wallet="2500", fee="0.002",
                 pre_live=False, re_opt=False, re_opt_t="5m 1h 1d"):

        self.in_sample_days = in_sample_days
        self.out_sample_days = out_sample_days
        self.loss_function = loss_function
        self.re_opt = re_opt
        self.output_dir = self.create_run_dir(output_dir)
        self.config = self.copy_input_config(config)
        self.strategy_path = strategy_path
        self.strategy_name = strategy
        self.strategy = self.copy_input_strategy(strategy_path, self.strategy_name)
        self.wf_start = wf_start
        self.wf_finish = wf_finish
        self.anchored_start = anchored_start
        self.is_start = self.in_sample_start()
        self.min_trades = min_trades
        self.cpu = cpu
        self.epochs = epochs
        self.wallet = wallet
        self.fee = fee
        self.pre_live = pre_live
        self.re_opt_t = re_opt_t
        self.start_log()

    def run_walk_forward(self):

        stages = self.generate_wf_stages()
        no_stages = len(stages)
        start_wallet = self.wallet

        start_time = datetime.now()
        logger.info(f'Running Walk-forward for {no_stages} stages')

        for count, value in enumerate(stages, 1):
            stage_start_time = datetime.now()
            logger.info(f'{"-" * 79}')
            hyperopt_time = value[0]
            backtest_time = value[1]
            full_time_period = f"{hyperopt_time.split('-')[0]}-{backtest_time.split('-')[1]}"
            logger.info(f'Walk-forward optimization for stage {count} of {no_stages}')
            stage_dir = self.create_stage_dir(self.output_dir, count, full_time_period)

            # Run Hyperopt and process required data
            logger.info(f'Hyperopting for {hyperopt_time}')
            cpu = self.set_cpu(hyperopt_time)
            self.run_hyperopt(hyperopt_time, stage_dir, self.epochs, cpu)
            hy_start = datetime.strptime(hyperopt_time.split('-')[0], "%Y%m%d")
            hy_finish = datetime.strptime(hyperopt_time.split('-')[1], "%Y%m%d")
            hy_delta = hy_start - hy_finish
            hy_days = int(hy_delta.days)
            logger.info(f'Running Hyperopt Backtest for period {hyperopt_time} ({hy_days} days)')
            result_op, bt_file_op = self.run_backtest(hyperopt_time, "op_bt", start_wallet, stage_dir)
            self.save_bt_file_data(stage_dir, bt_file_op, "op_bt")
            df_op = self.update_df(result_op, "op_bt", count, hyperopt_time, start_wallet)

            # Walk forward testing constant starting wallet:
            logger.info(f'Running WF Backtest for period {backtest_time} ({self.out_sample_days} days)')
            result_bt, bt_file_bt = self.run_backtest(backtest_time, "wf_bt", start_wallet, stage_dir)
            self.save_bt_file_data(stage_dir, bt_file_bt, "wf_bt")
            df_wf = self.update_df(result_bt, "wf_bt", count, backtest_time, start_wallet)
            plot_equity_curve(df_wf, self.output_dir, save_fig=True)

            self.combine_data(hyperopt_time, df_op, df_wf)
            stage_run_time = str(datetime.now() - stage_start_time)
            logger.info(f'Stage {count} walk-forward analysis Duration: {stage_run_time.split(".")[0]}')

        if self.pre_live:
            self.pre_live_optimise()

        if self.re_opt:
            self.re_optimise()

        run_time = str(datetime.now() - start_time)
        logger.info(f'Total walk-forward analysis Duration: {run_time.split(".")[0]}')

    def re_optimise(self):
        # Download data
        # time_periods = "5m 15m 1h 4h 12h 1d"
        time_periods = self.re_opt_t
        self.download_data(time_periods)

        end_date = datetime.strptime(self.wf_finish, "%Y%m%d")
        start_date = end_date - timedelta(int(self.in_sample_days))
        t1 = start_date.strftime("%Y%m%d")
        t2 = end_date.strftime("%Y%m%d")
        hyperopt_time = t1 + "-" + t2
        full_time_period = f"{hyperopt_time}"

        stage_dir = self.create_stage_dir(self.output_dir, "re_optimise", full_time_period)
        epochs = f"{int(self.epochs)}"
        self.run_hyperopt(hyperopt_time, stage_dir, epochs, self.cpu)
        logger.info(f'Running Hyperopt Backtest for period {hyperopt_time} ({self.in_sample_days} days)')
        _ = self.run_backtest(hyperopt_time, "re_optimise", self.wallet, stage_dir)

    def save_bt_file_data(self, stage_dir, bt_file_op, file_id):

        with open(f'{stage_dir}/{bt_file_op}') as f:
            data1 = json.load(f)
            df1 = pd.DataFrame.from_dict(data1["strategy"][self.strategy_name]["results_per_pair"])
            csv_filepath = f"{stage_dir}/{file_id}_bt_results.csv"
            df1.to_csv(csv_filepath)

    def update_df(self, result, file_id, wf_stage, time_range, start_wallet):

        h5_string = f"{self.output_dir}/{file_id}.h5"
        if not os.path.exists(h5_string):
            cols = ["profit_mean", "profit_mean_pct", "profit_sum", "profit_sum_pct", "profit_total_abs",
                    "profit_total_pct" "profit_total", "wins", "draws", "losses", "wf-stage", "bt_time_period",
                    "start-balance", "final-balance", "%_profit_pa", "acc-start", "acc-finish"]
            df = pd.DataFrame(columns=cols)
            df.to_hdf(h5_string, 'data')

        df = pd.read_hdf(h5_string, 'data')

        if file_id == "op_bt":
            is_start = datetime.strptime(time_range.split('-')[0], "%Y%m%d")
            is_finish = datetime.strptime(time_range.split('-')[1], "%Y%m%d")
            delta = is_start - is_finish
            sample_days = int(delta.days)
        else:
            sample_days = self.out_sample_days

        data = result[0]
        data.pop('key')
        data["%_profit_pa"] = data["profit_total_pct"] / float(sample_days) * 365  # percent profit year
        data["wf-stage"] = wf_stage
        data["start-balance"] = start_wallet
        data["final-balance"] = float(start_wallet) + float(data["profit_total_abs"])
        data["bt_time_period"] = time_range

        if len(df) == 0:
            data["acc-start"] = float(self.wallet)
        else:
            data["acc-start"] = df["acc-finish"].iloc[-1]

        data["acc-finish"] = (data["acc-start"] * data["profit_total_pct"] / 100) + data["acc-start"]
        df2 = pd.DataFrame(data, index=[0])
        df_new = df.copy()
        df_new = df_new.append([df2], ignore_index=True)

        csv_filepath = f"{self.output_dir}/{file_id}.csv"
        df_new.to_csv(csv_filepath)
        df_new.to_hdf(h5_string, 'data')

        return df_new

    def pre_live_optimise(self):

        end_date = datetime.strptime(self.wf_finish, "%Y%m%d")
        start_date = end_date - timedelta(int(self.in_sample_days))
        t1 = start_date.strftime("%Y%m%d")
        t2 = end_date.strftime("%Y%m%d")
        hyperopt_time = t1 + "-" + t2
        full_time_period = f"{hyperopt_time}"

        stage_dir = self.create_stage_dir(self.output_dir, "pre_live", full_time_period)
        epochs = f"{int(self.epochs) * 2}"
        self.run_hyperopt(hyperopt_time, stage_dir, epochs, self.cpu)
        logger.info(f'Running Hyperopt Backtest for period {hyperopt_time} ({self.in_sample_days} days)')
        result_op = self.run_backtest(hyperopt_time, "pre_live", self.wallet, stage_dir)

    def combine_data(self, hyp_time_range, df_op, df_wf):

        is_start = datetime.strptime(hyp_time_range.split('-')[0], "%Y%m%d")
        is_finish = datetime.strptime(hyp_time_range.split('-')[1], "%Y%m%d")
        delta = is_start - is_finish
        days_in = int(delta.days)

        days_out = int(self.out_sample_days)

        try:
            a = pd.Series(df_op["profit_mean_pct"], name='op_profit_av')
            b = pd.Series(df_wf["profit_mean_pct"], name='wf_profit_av')
            c = pd.Series(df_op["wins"] / df_op["losses"], name='op_wl%')
            d = pd.Series(df_wf["wins"] / df_wf["losses"], name='wf_wl%')
            e = pd.Series(df_op['trades'].apply(lambda x: x / days_in), name='op_trades_per_day')
            f = pd.Series(df_wf['trades'].apply(lambda x: x / days_out), name='wf_trades_per_day')
            g = pd.Series(df_op["profit_total"].apply(lambda x: (x / days_in) * 365), name='op_ppa')
            h = pd.Series(df_wf["profit_total"].apply(lambda x: (x / days_out) * 365), name='wf_ppa')
            i = pd.Series(df_op["%_profit_pa"], name='op_%ppa')
            j = pd.Series(df_wf["%_profit_pa"], name='wf_%ppa')

            df_combined = pd.concat([a, b, c, d, e, f, g, h, i, j], axis=1)
            filepath = f"{self.output_dir}/combined.csv"
            df_combined.to_csv(filepath)

        except:
            pass

        return

    def generate_wf_stages(self):

        is_start = datetime.strptime(self.is_start, "%Y%m%d")
        oos_start = datetime.strptime(self.wf_start, "%Y%m%d")
        end_date = datetime.strptime(self.wf_finish, "%Y%m%d")
        oos_end = oos_start + timedelta(int(self.out_sample_days))
        stages = []
        while True:

            t1 = is_start.strftime("%Y%m%d")
            t2 = oos_start.strftime("%Y%m%d")
            t3 = oos_end.strftime("%Y%m%d")

            # define stage:
            insample_timframe = t1 + "-" + t2
            outsample_timframe = t2 + "-" + t3
            stage = [insample_timframe, outsample_timframe]
            stages.append(stage)

            oos_start = oos_start + timedelta(int(self.out_sample_days))
            oos_end = oos_start + timedelta(int(self.out_sample_days))

            if not self.in_sample_days == "anchored":
                is_start = is_start + timedelta(int(self.out_sample_days))

            if oos_end > end_date:
                break

        return stages

    def run_hyperopt(self, time_range, stage_dir, epochs, cpu):
        """
        :param stage_number:
        :param time_range:
        :param epochs:
        :param loss_function: SortinoHyperOptLoss,
        :param fee:
        :param cpu:
        :return:
        """
        self.wait_for_internet_connection()
        start_time = datetime.now()
        os.system(
            "freqtrade hyperopt" +
            " --min-trades " + self.min_trades +
            " -j " + cpu +
            " -e " + epochs +
            " --spaces buy " +
            " --fee " + self.fee +
            " --logfile " + stage_dir + "/op_log" +
            " --timerange " + time_range +
            " --hyperopt-loss " + self.loss_function +
            " --strategy " + self.strategy +
            " --strategy-path " + self.output_dir +
            " --config " + self.config +
            " --dry-run-wallet " + self.wallet
        )

        self.wait_for_internet_connection()
        os.system(
            "freqtrade hyperopt-list" +
            " --no-details " +
            " --export-csv " + stage_dir + "/op.csv"
        )

        # # Copy the best optimisation results to "stage output directory":
        src = Path(f"{self.output_dir}/{self.strategy}.json")
        dst = f"{stage_dir}/op_result.json"
        shutil.copyfile(str(src), dst)

        run_time = str(datetime.now() - start_time)
        logger.info(f'Hyperopt Duration: {run_time.split(".")[0]}')

        with open(dst) as f:
            data = json.load(f)

        results = data["params"]["buy"]
        for i in results:
            logger.info(f'Hyperopt result: {i}: {results[i]}')

    def run_backtest(self, time_range, file_id, wallet, stage_dir):
        self.wait_for_internet_connection()
        start_time = datetime.now()
        os.system(
            "freqtrade backtesting" +
            " --export trades " +
            " --fee " + self.fee +
            f" --logfile {stage_dir}/{file_id}_log.txt"
            " --timerange " + time_range +
            " --strategy " + self.strategy +
            " --strategy-path " + self.output_dir +
            " --config " + self.config +
            " --dry-run-wallet " + wallet +
            f" --export-filename {stage_dir}/{file_id}_result.json"
        )

        result, bt_file = self.get_backtest_data(stage_dir, file_id)
        run_time = str(datetime.now() - start_time)
        if not file_id == "wf_acc_bt":
            logger.info(f'Backtest Duration: {run_time.split(".")[0]}')

        self.log_bt_results(time_range, result, wallet, file_id)
        self.plot_bt_profit(time_range, stage_dir, bt_file, file_id)

        return result, bt_file

    def download_data(self, time_periods, days="4000"):
        self.wait_for_internet_connection()
        logger.info(f'downloading data')
        os.system(
            "freqtrade download-data" +
            " -t " + time_periods +
            " --exchange binance " +
            " --pairs .*/USDT " +
            " --new-pairs-days " + days +
            " --include-inactive-pairs "
        )
        logger.info(f'finished downloading data')

        return

    @staticmethod
    def wait_for_internet_connection():
        start_time = datetime.now()
        switch = True
        while True:
            try:
                urlopen('https://www.google.com', timeout=1)
                if not switch:
                    offline_time = str(datetime.now() - start_time)
                    logger.warning(f"Disconnected time: {offline_time.split('.')[0]}")
                    logger.warning("#############################")
                return

            except urllib.error.URLError:

                if switch:
                    logger.warning("#############################")
                    logger.warning("NO INTERNET")

                switch = False
                time.sleep(2)

                pass

    def log_bt_results(self, time_range, result, wallet, file_id):

        data = result[0].copy()

        final_balance = float(wallet) + data["profit_total_abs"]
        w_start = round(float(wallet), 2)
        w_finish = round(final_balance, 2)
        percent_prof = round(data["profit_total_pct"], 1)

        if file_id == "op_bt":

            is_start = datetime.strptime(time_range.split('-')[0], "%Y%m%d")
            is_finish = datetime.strptime(time_range.split('-')[1], "%Y%m%d")
            delta = is_start - is_finish
            sample_days = int(delta.days)

        else:
            sample_days = self.out_sample_days

            pppa = round((percent_prof / float(sample_days) * 365), 2)  # percent profit per year
            logger.info(f'Backtest result - Balance £{w_start} --> £{w_finish} ({percent_prof}%): {pppa} %profit pa')

            # Trade stats
            win = data['wins']
            loss = data['losses']
            draw = data['draws']
            trades = data['trades']
            logger.info(f"Backtest result - Wins: {win}, Draws: {draw}, Losses: {loss}, trades: {trades}")

            # Average tade profits:
            mean_p = round(float(data['profit_mean']), 2)
            mp_percent = round(float(data['profit_mean_pct']), 2)
            logger.info(f"Backtest result - mean trade profit £{mean_p}, {mp_percent}%")

            # Account draw-down:
            dd_percent = round((data['max_drawdown_account'] * 100), 2)
            dd_abs = round(float(data['max_drawdown_abs']), 2)
            logger.info(f"Backtest result - Max dd: {dd_percent}%, £{dd_abs}")

    def plot_bt_profit(self, time_range, stage_dir, bt_file, file_id):
        os.system(
            "freqtrade plot-profit "
            " --timeframe 1d "
            " --timerange " + time_range +
            " --strategy " + self.strategy +
            " --strategy-path " + self.output_dir +
            " --config " + self.config +
            f" --export-filename {stage_dir}/{bt_file}"
        )

        # TODO relative path required:
        src = Path(f"/home/matt/freqtrade/user_data/plot/freqtrade-profit-plot.html")
        dst = f"{stage_dir}/{file_id}_profit-plot.html"
        shutil.copyfile(str(src), dst)

    @staticmethod
    def get_backtest_data(stage_dir, file_id):
        f = []
        for (dirpath, dirnames, filenames) in walk(stage_dir):
            f.extend(filenames)
            break

        # Find the backtest file for wf stage
        for file in f:

            # not meta.json:
            if file[-9:-5] != "meta":

                my_file = file_id + "_result"
                if file.split("-")[0] == my_file:
                    # change to while open:
                    f = open(stage_dir + "/" + file)
                    data = json.load(f)
                    result = data["strategy_comparison"]
                    backtest_file = file

        return result, backtest_file

    def create_run_dir(self, path):

        _time = datetime.now().strftime('%Y%m%d_%I:%M%p')
        if self.re_opt:
            directory = f"{path}/{_time}_{self.loss_function}_re-optimise_{self.in_sample_days}"
        else:
            directory = f"{path}/{_time}_{self.loss_function}_in_{self.in_sample_days}_out_{self.out_sample_days}"

        if not os.path.exists(path):
            os.makedirs(path)

        try:
            os.makedirs(directory)

        except:
            pass

        return directory

    @staticmethod
    def create_stage_dir(path, stage, full_time_period):
        dir_string = f"{path}/stage_{stage}_{full_time_period}"
        if not os.path.exists(path):
            os.makedirs(path)

        try:
            os.makedirs(dir_string)

        except Exception as e:
            pass

        return dir_string

    def copy_input_config(self, in_config):
        # Copy config:
        config = f"{in_config}"
        dst_config = f"{self.output_dir}/{config.split('/')[-1]}"
        shutil.copyfile(config, dst_config)
        return dst_config

    def copy_input_strategy(self, in_strategy_path, strategy):
        # Copy Strategy
        src = f"{in_strategy_path}/{strategy}.py"
        dst_strategy = f"{self.output_dir}/{strategy}.py"
        shutil.copyfile(src, dst_strategy)
        return strategy

    def in_sample_start(self):

        oos_start = datetime.strptime(self.wf_start, "%Y%m%d")

        if self.in_sample_days == "anchored":
            is_start = datetime.strptime(self.anchored_start, "%Y%m%d")  # + oos days

        else:
            is_start = oos_start - timedelta(int(self.in_sample_days))

        is_start = is_start.strftime("%Y%m%d")

        return is_start

    def set_cpu(self, hyperopt_time):

        is_start = datetime.strptime(hyperopt_time.split('-')[0], "%Y%m%d")
        is_finish = datetime.strptime(hyperopt_time.split('-')[1], "%Y%m%d")
        delta = is_finish - is_start
        days = int(delta.days)

        if self.in_sample_days == "anchored":
            if days < 50:
                cpu = "-1"
            if days > 50:
                cpu = "-2"
            if days > 100:
                cpu = "-4"
            if days > 150:
                cpu = "-6"
            if days > 200:
                cpu = "-8"
            if days > 250:
                cpu = "-10"
            if days > 300:
                cpu = "-11"
            if days > 350:
                cpu = "-12"
            if days > 400:
                cpu = "-13"
            if days > 450:
                cpu = "-14"
            if days > 500:
                cpu = "-14"
            if days > 550:
                cpu = "-16"
            if days > 600:
                cpu = "-16"
            if days > 650:
                cpu = "-17"
            if days > 700:
                cpu = "-17"
            if days > 750:
                cpu = "-17"
            if days > 800:
                cpu = "-18"
            if days > 850:
                cpu = "-18"
            if days > 900:
                cpu = "-18"
            if days > 950:
                cpu = "-19"
            if days > 1000:
                cpu = "-19"
            if days > 1100:
                cpu = "-20"
        else:
            d1 = datetime.strptime("20220601", "%Y%m%d")
            d2 = datetime.strptime("20210101", "%Y%m%d")
            d3 = datetime.strptime("20200101", "%Y%m%d")
            d4 = datetime.strptime("20190101", "%Y%m%d")
            d5 = datetime.strptime("20180101", "%Y%m%d")

            if is_finish > d1:
                cpu = self.cpu

            if d2 < is_finish < d1:
                cpu = int(self.cpu) + 1

            if d3 < is_finish < d2:
                cpu = int(self.cpu) + 2

            if d4 < is_finish < d3:
                cpu = int(self.cpu) + 3

            if d5 < is_finish < d4:
                cpu = int(self.cpu) + 4

            if is_finish < d5:
                cpu = int(self.cpu) + 5

        return str(cpu)

    def start_log(self):
        # Set format and level:
        logger.setLevel(logging.INFO)
        formatter = logging.Formatter('%(asctime)s - WF - %(levelname)s - %(message)s')

        # Remove old handlers:
        while logger.handlers:
            logger.handlers.pop()

        # Define file handler:
        file_handler = logging.FileHandler(f'{self.output_dir}/wf.log')
        file_handler.setFormatter(formatter)
        logger.addHandler(file_handler)

        # Define console handler:
        console_handler = logging.StreamHandler()
        console_handler.setFormatter(formatter)
        logger.addHandler(console_handler)

        # Startup logs:
        _cpu = 20 + int(self.cpu) + 1
        start_date = datetime.strptime(self.is_start, '%Y%m%d').date()
        end_date = datetime.strptime(self.wf_finish, '%Y%m%d').date()
        run_time = str(end_date - start_date).split(",")[0]
        logger.info('Code Initiated')
        logger.info(f'Strategy:{self.strategy_path}/{self.strategy}')
        logger.info(f'Config:{self.config}')
        logger.info(f'Loss Function: {self.loss_function}')
        logger.info(f'Time Frame:{self.is_start}-{self.wf_finish} ({run_time})')
        logger.info(f'IS-days:{self.in_sample_days}, OOS-days:{self.out_sample_days}')
        logger.info(f'CPUs:{_cpu}, Epochs:{self.epochs}, Wallet:{"2500"}, Fee:{"0.002"}, Min-trades:{self.min_trades}')


def plot_equity_curve(df, output_dir, save_fig=False):
    df = df.copy()
    pd.set_option('display.max_columns', None)
    fig, axs = plt.subplots(figsize=(7, 4))
    axs.xaxis.set_major_formatter(mdates.DateFormatter("%d %b"))
    df['dates'] = df["bt_time_period"].apply(lambda i: i.split("-")[1])
    df['dt'] = df['dates'].apply(lambda i: datetime.strptime(i, '%Y%m%d'))
    df.set_index('dt')
    df.plot(ax=axs, x="dt", y="acc-finish")
    dela_y = int(df["acc-finish"].max()) - int(df["acc-finish"].min())
    y_min = int(df["acc-finish"].min()) - (dela_y * 0.05)
    y_max = int(df["acc-finish"].max()) + (dela_y * 0.05)
    axs.set_title('Walk-Forward equity curve')
    axs.set_ylim(y_min, y_max)
    axs.set_ylabel("")
    axs.set_xlabel("")
    axs.grid(color='grey', alpha=0.5, linestyle='dashed', linewidth=0.5)
    axs.yaxis.set_major_formatter("£" + '{x:1.0f}')
    # plt.show()

    if save_fig:
        try:
            plt.savefig(f"{output_dir}/wf_equity_curve.png")
        except:
            pass


def walk_forward(path, strategy, config, output_dir, wf_start, wf_finish, anchored_start, pre_live=False, re_opt=False):
    is_list = ["730"]
    oos_list = ["30"]
    n_trades = ["100"]
    cpu_list = ["-15"]

    ep = "100"
    loss_f = "SharpeHyperOptLoss"

    for count, is_days in enumerate(is_list):
        oos_days = oos_list[count]
        nt = n_trades[count]
        cores = cpu_list[count]

        wf = WalkForward(strategy_path=path, strategy=strategy, config=config, output_dir=output_dir,
                         wf_start=wf_start, wf_finish=wf_finish, anchored_start=anchored_start, epochs=ep,
                         loss_function=loss_f, in_sample_days=is_days, out_sample_days=oos_days, min_trades=nt,
                         cpu=cores, pre_live=pre_live, re_opt=re_opt)

        wf.run_walk_forward()
    return


def re_optimise(path, strategy, config, output_dir, cpu="-19"):
    today = datetime.now().strftime("%Y%m%d")
    loss_f = "SortinoHyperOptLoss"
    in_sample_days = "730"
    n_trades = "100"
    ep = "200"
    download_data_t = "5m  1h 1d"

    wf = WalkForward(strategy_path=path, strategy=strategy, config=config, output_dir=output_dir, wf_start=today,
                     wf_finish=today, anchored_start=today, epochs=ep, loss_function=loss_f,
                     in_sample_days=in_sample_days, out_sample_days="1", min_trades=n_trades, cpu=cpu,
                     pre_live=False, re_opt=True, re_opt_t=download_data_t)

    wf.re_optimise()


if __name__ == "__main__":
    WF_START = "20200101"  # 2023-03-25
    WF_END = "20230910"
    ANCHORED_START = "20200101"  # only used if in_sample_days == "anchored"
    STRATEGY_PATH_THOR = "/home/matt/freqtrade/user_data/strategies/Thor"
    STRATEGY_THOR = "Optimise_Thor_BuySig_RiskReward"
    CONFIG_THOR = "/home/matt/freqtrade/user_data/strategies/Thor/config_Thor_WF.json"
    OUTPUT_DIR_THOR = "/home/matt/freqtrade/user_data/strategies/Thor/walk_forward"

    # -------------------------------------------------------------
    walk_forward(STRATEGY_PATH_THOR, STRATEGY_THOR, CONFIG_THOR, OUTPUT_DIR_THOR, WF_START, WF_END, ANCHORED_START)

    # -------------------------------------------------------------
    re_optimise(STRATEGY_PATH_THOR, STRATEGY_THOR, CONFIG_THOR, OUTPUT_DIR_THOR)
