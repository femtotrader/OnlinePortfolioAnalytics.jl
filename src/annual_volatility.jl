# AnnualVolatility - Annualized standard deviation of returns

const ANNUAL_VOLATILITY_PERIOD = 252  # Daily trading days

@doc """
$(TYPEDEF)

    AnnualVolatility{T}(; period=252)

Calculate annualized volatility from a stream of periodic returns.

Annualized volatility is the standard deviation of returns scaled by the square root
of the annualization period. It represents the expected annual dispersion of returns.

# Mathematical Definition

``\\text{Annual Volatility} = \\sigma \\times \\sqrt{\\text{period}}``

Where:
- ``\\sigma`` = sample standard deviation of periodic returns
- period = annualization factor (252 for daily, 52 for weekly, 12 for monthly)

# Parameters

- `period`: Annualization factor (default 252 for daily returns)
  - Daily: 252 (trading days per year)
  - Weekly: 52
  - Monthly: 12

# Fields

$(FIELDS)

# Example

```julia
stat = AnnualVolatility()
fit!(stat, 0.01)   # 1% daily return
fit!(stat, 0.02)   # 2% daily return
fit!(stat, -0.01)  # -1% daily return
value(stat)        # Annualized volatility
```

See also: [`StdDev`](@ref), [`Sharpe`](@ref)
"""
mutable struct AnnualVolatility{T} <: PortfolioAnalyticsSingleOutput{T}
    "Current annualized volatility value"
    value::T
    "Number of observations"
    n::Int
    "Internal variance tracker"
    variance::Variance
    "Annualization period"
    period::Int

    function AnnualVolatility{T}(; period::Int = ANNUAL_VOLATILITY_PERIOD) where {T}
        new{T}(zero(T), 0, Variance(T), period)
    end
end

# Convenience constructor (default Float64)
AnnualVolatility(; T::Type = Float64, period::Int = ANNUAL_VOLATILITY_PERIOD) =
    AnnualVolatility{T}(period = period)

function OnlineStatsBase._fit!(stat::AnnualVolatility{T}, ret) where {T}
    fit!(stat.variance, ret)
    stat.n += 1

    # AnnualVolatility = sqrt(variance) * sqrt(period)
    var_val = value(stat.variance)
    if var_val > 0
        stat.value = T(sqrt(var_val) * sqrt(stat.period))
    else
        stat.value = zero(T)
    end
end

function OnlineStatsBase.value(stat::AnnualVolatility)
    return stat.value
end

function Base.empty!(stat::AnnualVolatility{T}) where {T}
    stat.value = zero(T)
    stat.n = 0
    stat.variance = Variance(T)
end
