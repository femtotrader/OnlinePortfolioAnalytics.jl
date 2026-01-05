# Internals

This page provides detailed technical documentation for contributors and users who want to understand the internal design of OnlinePortfolioAnalytics.jl.

## Type Hierarchy

All analytics in OnlinePortfolioAnalytics inherit from the `OnlineStat{T}` interface provided by OnlineStatsBase.jl:

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
    PortfolioAnalyticsSingleOutput <|-- UpCapture
    PortfolioAnalyticsSingleOutput <|-- M2
    PortfolioAnalyticsSingleOutput <|-- UlcerIndex

    PortfolioAnalyticsMultiOutput <|-- AssetReturnMoments
```

### Type Categories

- **PortfolioAnalyticsSingleOutput{T}**: Metrics that return a single scalar value (e.g., Sharpe ratio returns a `Float64`)
- **PortfolioAnalyticsMultiOutput{T}**: Metrics that return a NamedTuple with multiple values (e.g., AssetReturnMoments returns `(mean, std, skewness, kurtosis)`)

## Composition Pattern

Complex metrics are built by composing simpler online statistics. This enables code reuse and ensures numerical stability:

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

    class Rolling {
        +OnlineStat stat
        +CircBuff buffer
        +Int window
    }

    Sharpe --> Mean
    Sharpe --> StdDev
    Calmar --> AnnualizedReturn
    Calmar --> MaxDrawDown
    MaxDrawDown --> DrawDowns
    MaxDrawDown --> Extrema
    DrawDowns --> Prod
    DrawDowns --> Extrema
    Rolling --> OnlineStat
    Rolling --> CircBuff
```

### Key Composition Examples

- **Sharpe** composes `Mean` and `StdDev` to compute risk-adjusted returns
- **Calmar** composes `AnnualizedReturn` and `MaxDrawDown` to compute the Calmar ratio
- **MaxDrawDown** composes `DrawDowns` and `Extrema` to track the worst drawdown
- **Rolling** wraps any `OnlineStat` with a `CircBuff` (circular buffer) for rolling window calculations

## Data Flow

### Single Observation Processing

When you call `fit!` with a new observation, here's what happens:

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

### Rolling Window Processing

Rolling window metrics maintain a buffer of recent observations:

```mermaid
sequenceDiagram
    participant User
    participant Rolling as Rolling Wrapper
    participant Buffer as CircBuff
    participant Stat as Wrapped Stat

    User->>Rolling: fit!(rolling, observation)
    Rolling->>Buffer: Add observation to buffer
    Buffer-->>Rolling: Buffer updated (oldest dropped if full)
    Rolling->>Stat: empty!(stat)
    loop For each buffered observation
        Rolling->>Stat: fit!(stat, obs)
    end
    User->>Rolling: value(rolling)
    Rolling->>Stat: value(stat)
    Stat-->>Rolling: Current window value
    Rolling-->>User: Rolling metric value
```

## OnlineStatsBase Interface

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

## Adding New Metrics

To add a new metric, follow this pattern:

1. Create a new file in `src/` (e.g., `src/my_metric.jl`)
2. Define a struct extending `PortfolioAnalyticsSingleOutput{T}` or `PortfolioAnalyticsMultiOutput{T}`
3. Implement required functions:
   - `OnlineStatsBase._fit!(stat, data)` - Update logic
   - `OnlineStatsBase.value(stat)` - Return current value
   - `Base.empty!(stat)` - Reset state
   - (Optional) `OnlineStatsBase._merge!(stat1, stat2)` - Parallel support
4. Add export in `OnlinePortfolioAnalytics.jl`
5. Include file in `OnlinePortfolioAnalytics.jl`
6. Create test file in `test/`

See the API page for the full list of available metrics.
