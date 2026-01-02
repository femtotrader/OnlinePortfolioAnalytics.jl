# BurkeRatio - Excess return over root-sum-squared drawdowns

const BURKE_PERIOD = 252

@doc """
$(TYPEDEF)

    BurkeRatio{T}(; period=252, risk_free=0)

Calculate the Burke Ratio from a stream of returns.

The Burke Ratio measures risk-adjusted performance by dividing excess return by the
root-mean-square of drawdown values. Unlike Sterling (which uses only max drawdown),
Burke penalizes both the magnitude and frequency of all drawdowns.

# Mathematical Definition

``\\text{BurkeRatio} = \\frac{\\text{AnnualizedReturn} - R_f}{\\sqrt{\\frac{1}{n}\\sum_{i=1}^{n} D_i^2}}``

Where:
- AnnualizedReturn = geometric mean return annualized
- ``R_f`` = risk-free rate
- ``D_i`` = drawdown at time i

The denominator is equivalent to the Ulcer Index.

# Parameters

- `period`: Annualization factor (default: 252 for daily returns)
- `risk_free`: Risk-free rate per period (default: 0)

# Edge Cases

- Returns `Inf` when sum of squared drawdowns is zero (no drawdowns)
- Returns `0.0` when no observations

# Interpretation

- Higher values indicate better risk-adjusted returns
- Penalizes both depth and frequency of drawdowns

# Fields

$(FIELDS)

# Example

```julia
stat = BurkeRatio(period=252, risk_free=0.0)
for r in returns
    fit!(stat, r)
end
value(stat)  # Excess return / sqrt(mean(DD^2))
```

See also: [`SterlingRatio`](@ref), [`UlcerIndex`](@ref), [`MaxDrawDown`](@ref)
"""
mutable struct BurkeRatio{T} <: PortfolioAnalyticsSingleOutput{T}
    "Current Burke Ratio value"
    value::T
    "Number of observations"
    n::Int
    "Internal annualized return tracker"
    annualized_return::AnnualizedReturn{T}
    "Internal drawdown tracker"
    drawdowns::DrawDowns{T}
    "Sum of squared drawdowns"
    sum_dd_squared::T
    "Risk-free rate"
    risk_free::T
    "Annualization period"
    period::Int

    function BurkeRatio{T}(; period::Int = BURKE_PERIOD, risk_free::Real = zero(T)) where {T}
        new{T}(zero(T), 0, AnnualizedReturn{T}(period=period), DrawDowns{T}(), zero(T), T(risk_free), period)
    end
end

# Convenience constructor (default Float64)
BurkeRatio(; T::Type = Float64, period::Int = BURKE_PERIOD, risk_free::Real = 0.0) =
    BurkeRatio{T}(period=period, risk_free=risk_free)

function OnlineStatsBase._fit!(stat::BurkeRatio{T}, ret) where {T}
    # Update internal trackers
    fit!(stat.annualized_return, ret)
    fit!(stat.drawdowns, ret)
    stat.n += 1

    # Get current drawdown and accumulate squared
    current_dd = value(stat.drawdowns)
    stat.sum_dd_squared += current_dd^2

    # Calculate Burke Ratio
    ann_ret = value(stat.annualized_return)
    excess_return = ann_ret - stat.risk_free

    # Denominator = sqrt(sum(DD^2) / n) = RMS of drawdowns = Ulcer Index
    if stat.sum_dd_squared > 0
        rms_dd = sqrt(stat.sum_dd_squared / stat.n)
        stat.value = excess_return / rms_dd
    else
        stat.value = T(Inf)  # No drawdowns
    end
end

function OnlineStatsBase.value(stat::BurkeRatio)
    return stat.value
end

function Base.empty!(stat::BurkeRatio{T}) where {T}
    stat.value = zero(T)
    stat.n = 0
    empty!(stat.annualized_return)
    empty!(stat.drawdowns)
    stat.sum_dd_squared = zero(T)
end
