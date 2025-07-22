# MyLibs for MetaTrader 5

**MetaTrader 5 (MT5)** is a multi-asset trading platform widely used for developing and executing automated trading strategies. [Learn more](https://www.metatrader5.com/en)

This is a modular MQL5 codebase containing reusable classes and utilities designed to accelerate EA development, backtesting, and live deployment for MetaTrader 5. It includes complete solutions for trade management, risk control, signal generation, time-based utilities, and more.

> **Note**: To use this framework, the `MyLibs` folder must be placed inside your MetaTrader 5 **`Include/`** directory:
>
> ```
> MQL5/Include/MyLibs/
> ```

## Folder Structure
```
MyLibs/
├── BacktestUtils/
│   ├── CustomMax.mqh              # Defines custom optimization criteria for backtesting
│   └── TestDataSplit.mqh          # Supports splitting historical data into training/testing segments
│
├── Indicators/
│   ├── AtrBands.mqh               # Calculates and visualizes ATR-based dynamic bands
│   └── TrendlineAnalyser.mqh      # Detects trendline breaks and trend direction changes
│
├── Orders/
│   ├── AdjustPosition.mqh         # Manages stop loss adjustments, trailing stops, and breakevens
│   ├── CalculatePositionData.mqh  # Computes lot sizing and position metrics
│   ├── EntryOrders.mqh            # Handles logic for opening buy/sell orders
│   ├── ExitOrders.mqh             # Handles logic for closing trades under various conditions
│   ├── OrderTracker.mqh           # Tracks open orders and their metadata
│   └── StopLogic.mqh              # Provides rule-based SL/TP value resolution
│
├── RiskManagement/
│   └── DrawdownControl.mqh        # Implements drawdown-based risk controls
│
├── Strategy/
│   └── RangeCalculator.mqh        # Measures recent market range to inform signal logic
│
├── Utils/
│   ├── AtrHandleManager.mqh            # Efficiently manages and caches ATR indicator handles
│   ├── ChartUtils.mqh                  # Utilities for drawing and annotating charts
│   ├── DealingWithTime.mqh             # Time conversion and formatting helpers
│   ├── Enums.mqh                       # Enum declarations for inputs and logic flow
│   ├── MarketDataUtils.mqh             # Simplifies access to indicator buffers and price info
│   ├── MultiSymbolSignalTracker.mqh    # Tracks per-symbol signal state in multi-asset EAs
│   ├── ResourceManager.mqh             # Central manager for indicator handle cleanup
│   ├── SignalStateTracker.mqh          # Tracks signal timing (e.g., how many bars ago a trigger occurred)
│   ├── TimeZones.mqh                   # Handles timezone conversion and time window logic
│   └── TradeWindow.mqh                 # Defines and manages tradable time sessions
```

## Included EA Example

This repository also includes a full EA (`trend_following_ea.mq5`) that demonstrates how to use the MyLibs framework.

### Features of the EA

- Multi-symbol trading (`AUDNZD`, `EURGBP`, etc.)
- Custom indicators and buffer signal handling
- Virtual TP runner trades
- ATR trailing stops and breakeven logic
- Risk split between take-profit and runner entries
- Support for data splitting during backtesting
- Modular entry and exit strategies
- Time-based filtering and session control

### EA Strategy Logic Overview

Signal generation is broken into modular components:

- **Trigger** (e.g., RSI cross)
- **Trendline** (direction, breakout, pullback)
- **Confirmation** (e.g., CCI alignment)
- **Volume** (OBV trend confirmation)
- **ATR Band Positioning** (via `AtrBands`)
- **Exit Logic** (Stochastic crossover, trendline break)

### EA Dependencies

The EA uses standard MQL5 built-in indicators, but can be easily modified to use custom indicators if desired:

- `iMA` – Moving Average (used for trendline estimation)
- `iRSI` – Relative Strength Index (used as a trigger)
- `iCCI` – Commodity Channel Index (used for confirmation)
- `iOBV` – On-Balance Volume (used for volume filtering)
- `iStochastic` – Stochastic Oscillator (used for exit signals)

**Note:** These indicators were selected for simplicity and demonstration purposes only. They are **not optimized** for trading performance and should be replaced or tuned during real development and testing. The architecture is fully modular and allows for plugging in better-suited or proprietary indicators.

All indicator handles are dynamically created and released via the `ResourceManager` class, ensuring clean memory handling during runtime and backtests.

---

## Installation & Usage

1. Clone or download this repository.
2. Copy the `MyLibs/` directory into your MT5 `Include/` folder:
3. Place the example EA file into the `MQL5/Experts/` directory.
4. Open **MetaEditor** and compile the EA.

