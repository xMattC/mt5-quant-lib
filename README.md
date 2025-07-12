# MT5_Python_Strategy_Framework

This project provides an experimental framework for integrating MetaTrader 5 (MT5) custom indicators and trading logic with Python-based data processing and strategy testing using [Freqtrade](https://www.freqtrade.io/).

## Features

- 🧠 **Custom MT5 Libraries**: Modular `.mqh` files to handle position sizing, drawdown control, order management, and utility functions.
- 🐍 **Python Scripts**:
  - `pre_process.py`: Prepares or cleans data before indicator processing.
  - `process_entry_indicators.py`: Extracts and processes entry signals.
  - `post_process_test.py`: Analyses backtest output or result data.
- 📦 **Freqtrade-Compatible Module**: Python strategies and helpers located in `Python_freqtrade/` for integration with the Freqtrade framework.
- 🛠️ **Project Structure Support**: Includes `.idea/` and `.vscode/` folders for JetBrains and VSCode IDE configurations.

## Project Structure

```
MT5_Python_Strategy_Framework/
├── My_MQL5_Libs/                  # Custom MQL5 include files
├── Python_freqtrade/             # Freqtrade strategy components
├── pre_process.py                # Data pre-processing script
├── process_entry_indicators.py   # Entry signal extraction logic
├── post_process_test.py          # Backtest result post-processing
├── .idea/, .vscode/              # IDE configs (optional)
└── README.md                     # Project documentation
```

## Getting Started

### Requirements

- MetaTrader 5 with access to `terminal64.exe`
- Python 3.8+
- Optional: Freqtrade installed (`pip install freqtrade`)

### Running Scripts

```bash
python pre_process.py
python process_entry_indicators.py
python post_process_test.py
```

### MT5 Library Usage

Place the `.mqh` files from `My_MQL5_Libs/` into your `MQL5/Include` folder to use them in your Expert Advisors or custom indicators.

## Notes

- This project is a scaffold for connecting MQL5 strategies to Python-based optimisation and analysis tools.
- Actual EA logic, data formats, and strategy specifics should be customised to your use case.

## License

This project is provided for educational and prototyping purposes. Please adapt and extend as needed for production environments.
