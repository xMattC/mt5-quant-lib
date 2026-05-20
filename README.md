![MQL5](https://img.shields.io/badge/MQL5-MetaTrader_5-blue)
![Library](https://img.shields.io/badge/Type-Custom_Library-success)
![Architecture](https://img.shields.io/badge/Architecture-Modular-success)
![Risk](https://img.shields.io/badge/Risk-Management-orange)
![Trading](https://img.shields.io/badge/Domain-Algorithmic_Trading-green)
![Backtesting](https://img.shields.io/badge/Backtesting-MT5_Strategy_Tester-blueviolet)

# MT5 Quant Lib

A reusable MQL5 library providing infrastructure components and utility classes for MetaTrader 5 development.

The library abstracts common functionality such as trade execution, risk management, indicator handling, signal tracking, and supporting utilities into reusable components.

The primary goal is to reduce duplicated implementation, improve maintainability, and provide a modular foundation for building Expert Advisors and trading systems.

---

## 🔍 Domain Context

MetaTrader 5 (MT5) is a multi-asset trading platform widely used for developing and executing automated trading strategies. [Learn more](https://www.metatrader5.com/en)

---

## 🧰 What the Library Provides

MT5 Quant Lib provides reusable infrastructure for common Expert Advisor development tasks.

The library includes utilities for:

- **Order management** — opening, modifying, and managing trade orders.
- **Position sizing** — calculating trade volume based on account risk, stop loss distance, and symbol properties.
- **Risk management** — applying consistent risk controls across trading systems.
- **Stop-loss management** — setting fixed, breakeven, trailing, and rule-based stop losses.
- **Take-profit handling** — supporting fixed targets and trade management rules.
- **Indicator access** — managing indicator handles and retrieving indicator buffer values.
- **Signal tracking** — maintaining signal state across symbols, bars, and strategy components.
- **Time/session filtering** — restricting logic to specific trading windows or market sessions.
- **Multi-symbol support** — helping Expert Advisors operate consistently across multiple instruments.
- **Backtesting support** — providing reusable utilities for testing and optimisation workflows.

The aim is to centralise common MT5 infrastructure so that strategy-specific code can stay focused on trading logic rather than repeated platform plumbing.

---

## 🎯 Engineering Focus

This project was built to demonstrate:

- Reusable library design
- Object-oriented development
- Modular architecture
- Infrastructure abstraction
- Trade management utilities
- Risk-management systems
- Indicator abstraction layers
- Multi-symbol support
- Shared runtime components
- Separation of concerns

---

## 🛠️ Tech Stack

- **Language:** MQL5
- **Platform:** MetaTrader 5
- **Architecture:** Modular utility library
- **Testing:** MT5 Strategy Tester
- **Domain:** Trading infrastructure and system development

---

## 🔑 Core Library Components

The library provides reusable modules including:

- Trade execution utilities
- Position sizing components
- Risk management systems
- Stop-loss and take-profit management
- Indicator handle management
- Signal state tracking
- Time and session filters
- Multi-symbol support
- Backtesting utilities
- Shared helper functions

---

## 📂 Repository Structure

```text
MT5-Quant-Lib/

├── Indicators/
├── Orders/
├── Utils/
├── BacktestUtils/
├── trend_following_ea.mq5
└── README.md
```

Main modules:

- **Indicators/** — indicator wrappers and helper components
- **Orders/** — order execution and position management
- **Utils/** — shared utility classes and helper functions
- **BacktestUtils/** — optimisation and testing helpers

---

## 🧩 Example Expert Advisor

The repository includes an example Expert Advisor demonstrating practical use of the library components within a complete multi-symbol trading workflow.

The example EA illustrates how independent library modules can be composed into a larger application while keeping infrastructure concerns separated from strategy logic.

The example demonstrates:

- Multi-symbol processing across configurable instrument lists
- Event-driven execution using timer-based updates
- Signal construction using modular indicator components
- Composition of multiple entry conditions and trade rules
- Position sizing based on configurable risk settings
- Trade lifecycle management including entries, exits, and runners
- Trailing stop and breakeven management
- Signal memory and state tracking across bars
- Resource lifecycle management for indicator handles
- Train/test data separation for optimisation workflows
- Custom optimisation metrics through `OnTester()`

The example application intentionally keeps strategy logic modular by separating:

- signal generation
- trade execution
- risk calculations
- position management
- indicator handling
- state tracking

This demonstrates how reusable infrastructure components can support larger systems without tightly coupling implementation details.

[Example Expert Advisor](trend_following_ea.mq5)

---

## ⚠️ Current Limitations

- Designed specifically for MetaTrader 5
- Requires an MT5 environment
- Not intended as a standalone trading system
- Platform-specific dependencies may limit portability
- Automated testing is limited due to MT5 platform constraints

---

## ⚙️ Installation

Clone the repository:

```bash
git clone https://github.com/xMattC/mt5-quant-lib.git
```

Copy the library folder into your MetaTrader 5 `Include` directory:

```text
C:/Users/<YourUser>/AppData/Roaming/MetaQuotes/Terminal/<Terminal_ID>/MQL5/Include/
```

The final structure should look similar to:

```text
MQL5/

└── Include/
    └── MyLibs/
        ├── Indicators/
        ├── Orders/
        ├── Utils/
        ├── BacktestUtils/
        └── ...
```

The `Terminal_ID` directory is generated automatically by MetaTrader 5 and will vary between installations.

After copying the library, modules can be imported into Expert Advisors using:

```cpp
#include <MyLibs/Orders/EntryOrders.mqh>
#include <MyLibs/Orders/AdjustPosition.mqh>

EntryOrders entry_orders;
AdjustPosition adjust_pos;
```

## ⚠ Disclaimer

This project was developed for research and software engineering purposes.

The library provides reusable infrastructure components and does not constitute investment advice or a complete trading system.

