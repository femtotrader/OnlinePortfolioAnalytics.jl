# ActivePremium - Difference between annualized portfolio and benchmark returns

const ACTIVE_PREMIUM_PERIOD = 252  # Daily trading days

@doc """
$(TYPEDEF)

    ActivePremium{T}(; period=252)

Calculate the Active Premium (annualized portfolio return minus annualized benchmark return)
from a stream of paired portfolio and benchmark returns.

Active Premium measures the raw excess return of the portfolio over the benchmark
on an annualized basis, without adjusting for risk.

# Mathematical Definition

``\\text{Active Premium} = \\text{AnnualizedReturn}_{port} - \\text{AnnualizedReturn}_{bench}``

Where AnnualizedReturn is the CAGR (Compound Annual Growth Rate):
``\\text{AnnualizedReturn} = (\\prod_{i=1}^{n}(1 + r_i))^{period/n} - 1``

# Interpretation

- Positive value: Portfolio outperforms benchmark
- Negative value: Portfolio underperforms benchmark
- Zero: Portfolio matches benchmark exactly

# Parameters

- `period`: Annualization factor (default 252 for daily returns)
  - Daily: 252 (trading days per year)
  - Weekly: 52
  - Monthly: 12

# Fields

$(FIELDS)

# Example

```julia
stat = ActivePremium(period=252)
fit!(stat, AssetBenchmarkReturn(0.01, 0.008))  # Daily returns
fit!(stat, AssetBenchmarkReturn(0.02, 0.015))
value(stat)  # Annualized excess return
```

See also: [`AnnualizedReturn`](@ref), [`InformationRatio`](@ref), [`MSquaredExcess`](@ref)
"""
mutable struct ActivePremium{T} <: PortfolioAnalyticsSingleOutput{AssetBenchmarkReturn{T}}
    "Current Active Premium value"
    value::T
    "Number of observations"
    n::Int
    "Portfolio annualized return tracker"
    port_ann_return::AnnualizedReturn{T}
    "Benchmark annualized return tracker"
    bench_ann_return::AnnualizedReturn{T}
    "Annualization period"
    period::Int

    function ActivePremium{T}(; period::Int = ACTIVE_PREMIUM_PERIOD) where {T}
        new{T}(zero(T), 0, AnnualizedReturn{T}(period = period), AnnualizedReturn{T}(period = period), period)
    end
end

# Convenience constructor (default Float64)
ActivePremium(; T::Type = Float64, period::Int = ACTIVE_PREMIUM_PERIOD) =
    ActivePremium{T}(period = period)

function OnlineStatsBase._fit!(stat::ActivePremium{T}, obs::AssetBenchmarkReturn) where {T}
    fit!(stat.port_ann_return, obs.asset)
    fit!(stat.bench_ann_return, obs.benchmark)
    stat.n += 1

    # ActivePremium = AnnualizedReturn(portfolio) - AnnualizedReturn(benchmark)
    stat.value = value(stat.port_ann_return) - value(stat.bench_ann_return)
end

function OnlineStatsBase.value(stat::ActivePremium)
    return stat.value
end

function Base.empty!(stat::ActivePremium{T}) where {T}
    stat.value = zero(T)
    stat.n = 0
    empty!(stat.port_ann_return)
    empty!(stat.bench_ann_return)
end
