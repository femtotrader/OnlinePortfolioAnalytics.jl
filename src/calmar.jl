# Calmar Ratio - Risk-adjusted return metric

const CALMAR_PERIOD = 252  # Daily trading days

@doc """
$(TYPEDEF)

    Calmar{T}(; period=252)

Calculate the Calmar ratio from a stream of periodic returns.

The Calmar ratio measures risk-adjusted performance by dividing the annualized
return by the absolute value of the maximum drawdown.

# Mathematical Definition

``\\text{Calmar} = \\frac{\\text{AnnualizedReturn}}{|\\text{MaxDrawDown}|}``

Where:
- AnnualizedReturn is the CAGR (Compound Annual Growth Rate)
- MaxDrawDown is the worst peak-to-trough decline (negative value)

# Parameters

- `period`: Annualization factor (default 252 for daily returns)
  - Daily: 252 (trading days per year)
  - Weekly: 52
  - Monthly: 12

# Fields

- `value::T`: Current Calmar ratio
- `n::Int`: Number of observations
- `annualized_return::AnnualizedReturn{T}`: Internal annualized return tracker
- `max_drawdown::MaxDrawDown{T}`: Internal max drawdown tracker
- `period::Int`: Annualization factor

# Edge Cases

- Returns `Inf` when max drawdown is zero (all positive returns)
- Returns `0.0` when no observations have been made

# Example

```julia
stat = Calmar()
fit!(stat, 0.05)   # 5% gain
fit!(stat, -0.03)  # 3% loss
fit!(stat, 0.02)   # 2% gain
value(stat)        # Calmar ratio
```

See also: [`AnnualizedReturn`](@ref), [`MaxDrawDown`](@ref), [`Sharpe`](@ref)
"""
mutable struct Calmar{T} <: PortfolioAnalyticsSingleOutput{T}
    value::T
    n::Int
    annualized_return::AnnualizedReturn{T}
    max_drawdown::MaxDrawDown{T}
    period::Int

    function Calmar{T}(; period::Int = CALMAR_PERIOD) where {T}
        new{T}(zero(T), 0, AnnualizedReturn{T}(period = period), MaxDrawDown{T}(), period)
    end
end

# Convenience constructor (default Float64)
Calmar(; T::Type = Float64, period::Int = CALMAR_PERIOD) = Calmar{T}(period = period)

function OnlineStatsBase._fit!(stat::Calmar, ret)
    # Delegate to internal stats
    fit!(stat.annualized_return, ret)
    fit!(stat.max_drawdown, ret)
    stat.n += 1

    # Calculate Calmar ratio
    ann_return = value(stat.annualized_return)
    max_dd = value(stat.max_drawdown)

    if max_dd == 0.0
        # No drawdown (all positive returns or single observation)
        stat.value = ann_return >= 0 ? convert(typeof(stat.value), Inf) : convert(typeof(stat.value), -Inf)
    else
        # Calmar = annualized_return / |max_drawdown|
        stat.value = ann_return / abs(max_dd)
    end
end

function OnlineStatsBase.value(stat::Calmar)
    return stat.value
end

function Base.empty!(stat::Calmar{T}) where {T}
    stat.value = zero(T)
    stat.n = 0
    empty!(stat.annualized_return)
    empty!(stat.max_drawdown)
end
