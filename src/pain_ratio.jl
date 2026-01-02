# PainRatio - Excess return per unit of Pain Index

const PAIN_RATIO_PERIOD = 252

@doc """
$(TYPEDEF)

    PainRatio{T}(; period=252, risk_free=0)

Calculate the Pain Ratio from a stream of returns.

The Pain Ratio measures risk-adjusted performance by dividing excess return by the
Pain Index (mean absolute drawdown). It provides a linear penalty for drawdowns
compared to the quadratic penalty of the Burke Ratio.

# Mathematical Definition

``\\text{PainRatio} = \\frac{\\text{AnnualizedReturn} - R_f}{\\text{PainIndex}}``

Where:
- AnnualizedReturn = geometric mean return annualized
- ``R_f`` = risk-free rate
- PainIndex = mean of absolute drawdown values

# Parameters

- `period`: Annualization factor (default: 252 for daily returns)
- `risk_free`: Risk-free rate per period (default: 0)

# Edge Cases

- Returns `Inf` when Pain Index is zero (no drawdowns)
- Returns `0.0` when no observations

# Interpretation

- Higher values indicate better risk-adjusted returns
- Uses linear (not quadratic) penalty for drawdowns

# Fields

$(FIELDS)

# Example

```julia
stat = PainRatio(period=252, risk_free=0.0)
for r in returns
    fit!(stat, r)
end
value(stat)  # Excess return / PainIndex
```

See also: [`PainIndex`](@ref), [`BurkeRatio`](@ref), [`SterlingRatio`](@ref)
"""
mutable struct PainRatio{T} <: PortfolioAnalyticsSingleOutput{T}
    "Current Pain Ratio value"
    value::T
    "Number of observations"
    n::Int
    "Internal annualized return tracker"
    annualized_return::AnnualizedReturn{T}
    "Internal Pain Index tracker"
    pain_index::PainIndex{T}
    "Risk-free rate"
    risk_free::T
    "Annualization period"
    period::Int

    function PainRatio{T}(; period::Int = PAIN_RATIO_PERIOD, risk_free::Real = zero(T)) where {T}
        new{T}(zero(T), 0, AnnualizedReturn{T}(period=period), PainIndex{T}(), T(risk_free), period)
    end
end

# Convenience constructor (default Float64)
PainRatio(; T::Type = Float64, period::Int = PAIN_RATIO_PERIOD, risk_free::Real = 0.0) =
    PainRatio{T}(period=period, risk_free=risk_free)

function OnlineStatsBase._fit!(stat::PainRatio{T}, ret) where {T}
    # Update internal trackers
    fit!(stat.annualized_return, ret)
    fit!(stat.pain_index, ret)
    stat.n += 1

    # Calculate Pain Ratio
    ann_ret = value(stat.annualized_return)
    excess_return = ann_ret - stat.risk_free
    pain_idx = value(stat.pain_index)

    if pain_idx > 0
        stat.value = excess_return / pain_idx
    else
        stat.value = T(Inf)  # No drawdowns
    end
end

function OnlineStatsBase.value(stat::PainRatio)
    return stat.value
end

function Base.empty!(stat::PainRatio{T}) where {T}
    stat.value = zero(T)
    stat.n = 0
    empty!(stat.annualized_return)
    empty!(stat.pain_index)
end
