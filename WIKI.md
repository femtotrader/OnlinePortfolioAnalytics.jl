# OnlinePortfolioAnalytics.jl - Technical Documentation

> Streaming portfolio analytics using online algorithms for Julia

## Table of Contents

- [Project Overview](#project-overview)
- [Architecture](#architecture)
- [Project Structure](#project-structure)
- [Core Components](#core-components)
- [Data Flow](#data-flow)
- [Type Hierarchy](#type-hierarchy)
- [API Reference](#api-reference)
- [Configuration](#configuration)
- [Getting Started](#getting-started)
- [Development Guide](#development-guide)

---

## Project Overview

**OnlinePortfolioAnalytics.jl** is a Julia package (v0.2.0) that provides streaming portfolio analytics using [online algorithms](https://en.wikipedia.org/wiki/Online_algorithm). Online algorithms process data incrementally, one observation at a time, without storing the full history in memory.

### Tech Stack

| Component | Technology | Purpose |
|-----------|------------|---------|
| Language | Julia 1.6+ | Core implementation |
| Online Stats | OnlineStatsBase 1.x | Base types and interface |
| Advanced Stats | OnlineStats 1.x | CovMatrix, Quantile algorithms |
| Statistics | Statistics (stdlib) | Mean, std functions |
| Extended Stats | StatsBase 0.34.3 | Skewness, kurtosis |
| Documentation | DocStringExtensions 0.9.3 | TYPEDEF, LICENSE macros |
| Tables | Tables.jl 1.x | DataFrame integration |

### Key Features

- **Memory Efficient**: Process unlimited data streams with constant memory
- **Real-time Analytics**: Update statistics incrementally as data arrives
- **Composable**: Complex metrics built from simpler online statistics
- **Parallelizable**: Merge operations support distributed computation
- **Tables.jl Integration**: Works seamlessly with DataFrames and TSFrames

### Dependencies

```toml
[deps]
OnlineStatsBase = "925886fa-5bf2-5e8e-b522-a9147a512338"
OnlineStats = "a15396b6-48d5-5d58-9928-6d29437db91e"
Statistics = "10745b16-79ce-11e8-11f9-7d13ad32a3b2"
StatsBase = "2913bbd2-ae8a-5f71-8c99-4fb6c76f3a91"
DocStringExtensions = "ffbed154-4ef7-542d-bbb7-c09d3a79fcae"
Tables = "bd369af6-aec1-5ad0-b16a-f7cc5008161c"
Dates = "ade2ca70-3891-5945-98fb-dc099432e06a"
```

---

## Architecture

### High-Level Architecture

```mermaid
flowchart TB
    subgraph Input["Data Sources"]
        PRICES[Price Stream]
        RETURNS[Return Stream]
        PAIRED[Asset/Benchmark Pairs]
    end

    subgraph Core["OnlinePortfolioAnalytics Core"]
        direction TB
        BASE[PortfolioAnalytics Abstract Type]
        SINGLE[PortfolioAnalyticsSingleOutput]
        MULTI[PortfolioAnalyticsMultiOutput]

        BASE --> SINGLE
        BASE --> MULTI
    end

    subgraph Metrics["Portfolio Metrics"]
        direction LR
        RET[Return Metrics]
        RISK[Risk Metrics]
        CAPM[CAPM Metrics]
        RATIO[Risk-Adjusted Ratios]
    end

    subgraph Integration["Integrations"]
        TABLES[Tables.jl]
        DF[DataFrames]
        TSF[TSFrames]
    end

    Input --> Core
    Core --> Metrics
    Metrics --> Integration

    TABLES --> DF
    TABLES --> TSF
```

### Metric Categories

```mermaid
flowchart LR
    subgraph Returns["Return Calculations"]
        SAR[SimpleAssetReturn]
        LAR[LogAssetReturn]
        CR[CumulativeReturn]
        AR[AnnualizedReturn]
        AMR[ArithmeticMeanReturn]
        GMR[GeometricMeanReturn]
    end

    subgraph Volatility["Volatility Metrics"]
        STD[StdDev]
        DD[DownsideDeviation]
        UD[UpsideDeviation]
    end

    subgraph Drawdown["Drawdown Analysis"]
        DDS[DrawDowns]
        ADD[ArithmeticDrawDowns]
        MDD[MaxDrawDown]
        MADD[MaxArithmeticDrawDown]
    end

    subgraph RiskAdjusted["Risk-Adjusted Returns"]
        SH[Sharpe]
        SO[Sortino]
        CAL[Calmar]
        OM[Omega]
    end

    subgraph CAPMMetrics["CAPM Metrics"]
        BETA[Beta]
        ER[ExpectedReturn]
        TR[Treynor]
        JA[JensenAlpha]
    end

    subgraph Relative["Relative Performance"]
        TE[TrackingError]
        IR[InformationRatio]
    end

    subgraph Risk["Risk Metrics"]
        VAR[VaR]
        ES[ExpectedShortfall]
    end

    subgraph Moments["Statistical Moments"]
        ARM[AssetReturnMoments]
    end
```

---

## Project Structure

```
OnlinePortfolioAnalytics/
├── src/
│   ├── OnlinePortfolioAnalytics.jl  # Main module (exports, includes)
│   ├── integrations/
│   │   └── tables.jl                # Tables.jl integration
│   │
│   ├── # Return Calculations
│   ├── asset_return.jl              # SimpleAssetReturn, LogAssetReturn
│   ├── cumulative_return.jl         # CumulativeReturn
│   ├── annualized_return.jl         # AnnualizedReturn
│   ├── mean_return.jl               # ArithmeticMeanReturn, GeometricMeanReturn
│   │
│   ├── # Volatility
│   ├── std_dev.jl                   # StdDev
│   ├── downside_deviation.jl        # DownsideDeviation
│   ├── upside_deviation.jl          # UpsideDeviation
│   │
│   ├── # Drawdowns
│   ├── drawdowns.jl                 # DrawDowns, ArithmeticDrawDowns
│   ├── max_drawdown.jl              # MaxDrawDown, MaxArithmeticDrawDown
│   │
│   ├── # Risk-Adjusted Ratios
│   ├── sharpe.jl                    # Sharpe ratio
│   ├── sortino.jl                   # Sortino ratio
│   ├── calmar.jl                    # Calmar ratio
│   ├── omega.jl                     # Omega ratio
│   │
│   ├── # CAPM Metrics
│   ├── asset_benchmark_return.jl    # AssetBenchmarkReturn wrapper
│   ├── beta.jl                      # Beta coefficient
│   ├── expected_return.jl           # CAPM Expected Return
│   ├── treynor.jl                   # Treynor ratio
│   ├── jensen_alpha.jl              # Jensen's Alpha
│   │
│   ├── # Relative Performance
│   ├── tracking_error.jl            # Tracking Error
│   ├── information_ratio.jl         # Information Ratio
│   │
│   ├── # Risk Metrics
│   ├── var.jl                       # Value at Risk
│   ├── expected_shortfall.jl        # Expected Shortfall (CVaR)
│   │
│   ├── # Statistical Moments
│   ├── moments.jl                   # AssetReturnMoments
│   │
│   ├── # Utilities
│   ├── prod.jl                      # Product accumulator
│   └── sample_data.jl               # Sample TSLA, NFLX, MSFT data
│
├── test/
│   ├── runtests.jl                  # Test entry point
│   ├── common.jl                    # Common test setup
│   └── test_*.jl                    # Individual test files (27 total)
│
├── Project.toml                     # Dependencies
├── Manifest.toml                    # Lock file
├── README.md                        # Project overview
└── CLAUDE.md                        # Development guidelines
```

---

## Core Components

### OnlineStatsBase Interface

All types implement the standard OnlineStatsBase interface:

```julia
# Core functions
fit!(stat, observation)  # Update statistic with new observation
value(stat)              # Get current value
empty!(stat)             # Reset to initial state
merge!(stat1, stat2)     # Combine statistics (for parallel computation)
```

### Input Types

#### Scalar Returns
Most metrics accept scalar return values directly:

```julia
stat = Sharpe{Float64}()
fit!(stat, 0.05)   # 5% return
fit!(stat, -0.02)  # -2% return
```

#### AssetBenchmarkReturn
For relative/CAPM metrics, use paired observations:

```julia
struct AssetBenchmarkReturn{T<:Real}
    asset::T      # Asset/portfolio return
    benchmark::T  # Benchmark/market return
end

# Usage
stat = Beta{Float64}()
fit!(stat, AssetBenchmarkReturn(0.05, 0.03))  # Asset +5%, Market +3%
```

### Composition Pattern

Complex metrics compose simpler online statistics:

```mermaid
classDiagram
    class Sharpe {
        +Mean mean
        +StdDev stddev
        +Int period
        +T risk_free
    }

    class Calmar {
        +AnnualizedReturn annualized
        +MaxDrawDown max_dd
    }

    class Beta {
        +CovMatrix cov_matrix
    }

    class MaxDrawDown {
        +DrawDowns drawdowns
        +Extrema max_dd_extrema
    }

    class DrawDowns {
        +Prod cumulative
        +Extrema peak
    }

    Sharpe --> Mean
    Sharpe --> StdDev
    Calmar --> AnnualizedReturn
    Calmar --> MaxDrawDown
    MaxDrawDown --> DrawDowns
    MaxDrawDown --> Extrema
    DrawDowns --> Prod
    DrawDowns --> Extrema
```

---

## Data Flow

### Single Observation Processing

```mermaid
sequenceDiagram
    participant User
    participant Metric as Portfolio Metric
    participant Internal as Internal Stats
    participant Value as value()

    User->>Metric: fit!(stat, observation)
    Metric->>Internal: Update internal trackers
    Internal-->>Metric: Updated state
    Metric->>Metric: Compute current value
    User->>Value: value(stat)
    Value-->>User: Current metric value
```

### Tables.jl Integration Flow

```mermaid
sequenceDiagram
    participant DF as DataFrame/TSFrame
    participant Wrapper as PortfolioAnalyticsWrapper
    participant Load as load!()
    participant Process as process_col()
    participant Result as PortfolioAnalyticsResults

    DF->>Wrapper: apply_pa(MetricType, table)
    Wrapper->>Load: load!(table, results, wrapper)
    Load->>Process: For each column
    Process->>Process: fit! for each row
    Process-->>Load: Column results
    Load-->>Result: PortfolioAnalyticsResults
    Result-->>DF: typeof(table)(results)
```

### Parallel Merge Flow

```mermaid
sequenceDiagram
    participant P1 as Partition 1
    participant P2 as Partition 2
    participant M as merge!()
    participant Final as Combined Result

    P1->>P1: Process observations 1..n
    P2->>P2: Process observations n+1..m
    P1->>M: stat1
    P2->>M: stat2
    M->>M: Combine internal states
    M-->>Final: Merged statistic
```

---

## Type Hierarchy

```mermaid
classDiagram
    class OnlineStat~T~ {
        <<interface>>
        +fit!(data)
        +value()
        +merge!(other)
    }

    class PortfolioAnalytics~T~ {
        <<abstract>>
    }

    class PortfolioAnalyticsSingleOutput~T~ {
        <<abstract>>
        Returns single value
    }

    class PortfolioAnalyticsMultiOutput~T~ {
        <<abstract>>
        Returns NamedTuple
    }

    OnlineStat <|-- PortfolioAnalytics
    PortfolioAnalytics <|-- PortfolioAnalyticsSingleOutput
    PortfolioAnalytics <|-- PortfolioAnalyticsMultiOutput

    PortfolioAnalyticsSingleOutput <|-- Sharpe
    PortfolioAnalyticsSingleOutput <|-- Sortino
    PortfolioAnalyticsSingleOutput <|-- Beta
    PortfolioAnalyticsSingleOutput <|-- MaxDrawDown
    PortfolioAnalyticsSingleOutput <|-- VaR

    PortfolioAnalyticsMultiOutput <|-- AssetReturnMoments
```

---

## API Reference

### Return Calculations

| Type | Input | Output | Description |
|------|-------|--------|-------------|
| `SimpleAssetReturn{T}` | Prices | `(Pt - Pt-k) / Pt-k` | Arithmetic returns |
| `LogAssetReturn{T}` | Prices | `ln(Pt / Pt-k)` | Log returns |
| `CumulativeReturn{T}` | Returns | `prod(1 + Ri)` | Geometric cumulative |
| `AnnualizedReturn{T}` | Returns | CAGR | Annualized return |
| `ArithmeticMeanReturn{T}` | Returns | `sum(Ri) / n` | Simple average |
| `GeometricMeanReturn{T}` | Returns | `(prod(1+Ri))^(1/n) - 1` | Geometric mean |

### Volatility Metrics

| Type | Input | Output | Description |
|------|-------|--------|-------------|
| `StdDev{T}` | Returns | `sigma` | Standard deviation |
| `DownsideDeviation{T}` | Returns | `sigma_down` | Semi-deviation below threshold |
| `UpsideDeviation{T}` | Returns | `sigma_up` | Semi-deviation above threshold |

### Drawdown Analysis

| Type | Input | Output | Description |
|------|-------|--------|-------------|
| `DrawDowns{T}` | Returns | Current DD | Geometric drawdown |
| `ArithmeticDrawDowns{T}` | Returns | Current DD | Arithmetic drawdown |
| `MaxDrawDown{T}` | Returns | Min DD | Worst geometric drawdown |
| `MaxArithmeticDrawDown{T}` | Returns | Min DD | Worst arithmetic drawdown |

### Risk-Adjusted Ratios

| Type | Formula | Parameters |
|------|---------|------------|
| `Sharpe{T}` | `sqrt(T) * (E[R] - rf) / sigma` | `period=252`, `risk_free=0` |
| `Sortino{T}` | `sqrt(T) * (E[R] - rf) / sigma_down` | `period=252`, `risk_free=0` |
| `Calmar{T}` | `AnnualizedReturn / abs(MaxDD)` | `period=252` |
| `Omega{T}` | Probability ratio above threshold | `threshold=0` |

### CAPM Metrics

| Type | Formula | Input |
|------|---------|-------|
| `Beta{T}` | `Cov(Ra, Rm) / Var(Rm)` | `AssetBenchmarkReturn` |
| `ExpectedReturn{T}` | `rf + beta(E[Rm] - rf)` | `AssetBenchmarkReturn` |
| `Treynor{T}` | `(E[R] - rf) / beta` | `AssetBenchmarkReturn` |
| `JensenAlpha{T}` | `E[R] - (rf + beta(E[Rm] - rf))` | `AssetBenchmarkReturn` |

### Relative Performance

| Type | Formula | Input |
|------|---------|-------|
| `TrackingError{T}` | `sigma(Ra - Rb)` | `AssetBenchmarkReturn` |
| `InformationRatio{T}` | `E[Ra - Rb] / sigma(Ra - Rb)` | `AssetBenchmarkReturn` |

### Risk Metrics

| Type | Description | Parameters |
|------|-------------|------------|
| `VaR{T}` | Value at Risk at confidence level | `alpha=0.05` |
| `ExpectedShortfall{T}` | Expected loss beyond VaR | `alpha=0.05` |

### Statistical Moments

| Type | Output | Description |
|------|--------|-------------|
| `AssetReturnMoments{T}` | `NamedTuple(mean, std, skewness, kurtosis)` | All four moments |

---

## Configuration

### Annualization Periods

Default period is 252 (daily trading days):

| Frequency | Period Value |
|-----------|--------------|
| Daily | 252 |
| Weekly | 52 |
| Monthly | 12 |
| Hourly | 252 x 6.5 = 1638 |

```julia
# Configure for monthly data
sharpe = Sharpe{Float64}(period=12, risk_free=0.001)
```

### Risk-Free Rate

Specify per-period risk-free rate:

```julia
# 2% annual risk-free rate for daily data
rf_daily = 0.02 / 252
sharpe = Sharpe{Float64}(risk_free=rf_daily)
```

---

## Getting Started

### Installation

```julia
using Pkg
Pkg.add("OnlinePortfolioAnalytics")
```

### Basic Usage

```julia
using OnlinePortfolioAnalytics

# Create a Sharpe ratio tracker
sharpe = Sharpe{Float64}(period=252, risk_free=0.0)

# Stream daily returns
returns = [0.01, -0.02, 0.015, 0.005, -0.01]
for r in returns
    fit!(sharpe, r)
    println("Current Sharpe: ", value(sharpe))
end
```

### Using with DataFrames

```julia
using OnlinePortfolioAnalytics
using DataFrames

# Create sample data
df = DataFrame(
    Date = Date(2024,1,1):Day(1):Date(2024,1,10),
    AAPL = rand(10) .* 0.02 .- 0.01,
    MSFT = rand(10) .* 0.02 .- 0.01
)

# Calculate Sharpe ratio for each column
result = Sharpe(df, period=252)
```

### CAPM Analysis

```julia
using OnlinePortfolioAnalytics

# Calculate Beta
beta = Beta{Float64}()

# Stream paired (asset, market) returns
observations = [
    AssetBenchmarkReturn(0.05, 0.03),
    AssetBenchmarkReturn(0.02, 0.01),
    AssetBenchmarkReturn(-0.01, -0.02)
]

for obs in observations
    fit!(beta, obs)
end

println("Beta: ", value(beta))
```

### Parallel Computation

```julia
using OnlinePortfolioAnalytics

# Process partitions in parallel
partition1_returns = [0.01, 0.02, -0.01]
partition2_returns = [-0.02, 0.03, 0.01]

# Create separate stats for each partition
stat1 = MaxDrawDown{Float64}()
stat2 = MaxDrawDown{Float64}()

# Process partitions independently
for r in partition1_returns; fit!(stat1, r); end
for r in partition2_returns; fit!(stat2, r); end

# Merge results
merge!(stat1, stat2)
println("Combined Max Drawdown: ", value(stat1))
```

---

## Development Guide

### Running Tests

```bash
julia --project -e 'using Pkg; Pkg.test()'
```

### Test Structure

Tests use TestItemRunner/TestItems framework:

```julia
@testitem "Sharpe ratio calculation" begin
    @testsnippet CommonTestSetup

    stat = Sharpe{Float64}()
    fit!(stat, 0.02)
    fit!(stat, -0.01)

    @test value(stat) ≈ expected_value atol=0.0001
end
```

### Adding New Metrics

1. Create new file in `src/` (e.g., `src/new_metric.jl`)
2. Define type extending `PortfolioAnalyticsSingleOutput{T}` or `PortfolioAnalyticsMultiOutput{T}`
3. Implement required functions:
   - `OnlineStatsBase._fit!(stat, data)` - Update logic
   - `OnlineStatsBase.value(stat)` - Return current value
   - `Base.empty!(stat)` - Reset state
   - (Optional) `OnlineStatsBase._merge!(stat1, stat2)` - Parallel support
4. Add export in `OnlinePortfolioAnalytics.jl`
5. Include file in `OnlinePortfolioAnalytics.jl`
6. Add Tables.jl wrapper in `integrations/tables.jl`
7. Create test file in `test/`

### Code Style

- Follow standard Julia conventions
- Use comprehensive docstrings with `$(TYPEDEF)` and `$(LICENSE)`
- Document mathematical definitions with LaTeX
- Include edge case handling
- Add cross-references with `See also:`

### Merge Support

For parallelizable metrics, implement `_merge!`:

```julia
function OnlineStatsBase._merge!(stat1::MyMetric, stat2::MyMetric)
    # Combine internal states algebraically
    merge!(stat1.internal_stat, stat2.internal_stat)
    stat1.n += stat2.n

    # Recalculate value from merged state
    stat1.value = compute_value(stat1)

    return stat1
end
```

---

## References

- [OnlineStatsBase.jl](https://github.com/joshday/OnlineStats.jl) - Base types and interface
- [OnlineStats.jl](https://github.com/joshday/OnlineStats.jl) - CovMatrix, Quantile
- [Tables.jl](https://github.com/JuliaData/Tables.jl) - Table interface
- [empyrical](https://github.com/quantopian/empyrical) - Python reference implementation
- [PerformanceAnalytics](https://cran.r-project.org/web/packages/PerformanceAnalytics/) - R reference

---

*Generated for OnlinePortfolioAnalytics.jl v0.2.0*
