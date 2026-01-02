# SterlingRatio - Annualized return over adjusted maximum drawdown

const STERLING_PERIOD = 252
const STERLING_THRESHOLD = 0.10

@doc """
$(TYPEDEF)

    SterlingRatio{T}(; period=252, threshold=0.10)

Calculate the Sterling Ratio from a stream of returns.

The Sterling Ratio measures risk-adjusted performance by dividing annualized return
by the adjusted maximum drawdown. The threshold (default 10%) accounts for "normal"
expected drawdown, making the ratio more stable for portfolios with small drawdowns.

# Mathematical Definition

``\\text{SterlingRatio} = \\frac{\\text{AnnualizedReturn}}{|\\text{MaxDrawDown}| - \\text{threshold}}``

Where:
- AnnualizedReturn = geometric mean return annualized
- MaxDrawDown = worst peak-to-trough decline (negative value)
- threshold = drawdown adjustment (default 0.10)

# Parameters

- `period`: Annualization factor (default: 252 for daily returns)
- `threshold`: Drawdown adjustment (default: 0.10 = 10%)

# Edge Cases

- Returns `Inf` when |MaxDD| ≤ threshold (adjusted denominator is ≤ 0)
- Returns `0.0` when no observations

# Interpretation

- Higher values indicate better risk-adjusted returns
- Accounts for expected "normal" drawdown via threshold

# Fields

$(FIELDS)

# Example

```julia
stat = SterlingRatio(period=252, threshold=0.10)
for r in returns
    fit!(stat, r)
end
value(stat)  # Annualized return / (|MaxDD| - 10%)
```

See also: [`Calmar`](@ref), [`MaxDrawDown`](@ref), [`AnnualizedReturn`](@ref)
"""
mutable struct SterlingRatio{T} <: PortfolioAnalyticsSingleOutput{T}
    "Current Sterling Ratio value"
    value::T
    "Number of observations"
    n::Int
    "Internal annualized return tracker"
    annualized_return::AnnualizedReturn{T}
    "Internal max drawdown tracker"
    max_drawdown::MaxDrawDown{T}
    "Drawdown threshold adjustment"
    threshold::T
    "Annualization period"
    period::Int

    function SterlingRatio{T}(; period::Int = STERLING_PERIOD, threshold::Real = STERLING_THRESHOLD) where {T}
        new{T}(zero(T), 0, AnnualizedReturn{T}(period=period), MaxDrawDown{T}(), T(threshold), period)
    end
end

# Convenience constructor (default Float64)
SterlingRatio(; T::Type = Float64, period::Int = STERLING_PERIOD, threshold::Real = STERLING_THRESHOLD) =
    SterlingRatio{T}(period=period, threshold=threshold)

function OnlineStatsBase._fit!(stat::SterlingRatio{T}, ret) where {T}
    # Update internal trackers
    fit!(stat.annualized_return, ret)
    fit!(stat.max_drawdown, ret)
    stat.n += 1

    # Calculate Sterling Ratio
    ann_ret = value(stat.annualized_return)
    max_dd = value(stat.max_drawdown)  # This is negative

    # Adjusted denominator = |MaxDD| - threshold
    adjusted_dd = abs(max_dd) - stat.threshold

    if adjusted_dd > 0
        stat.value = ann_ret / adjusted_dd
    else
        stat.value = T(Inf)  # Drawdown less than threshold
    end
end

function OnlineStatsBase.value(stat::SterlingRatio)
    return stat.value
end

function Base.empty!(stat::SterlingRatio{T}) where {T}
    stat.value = zero(T)
    stat.n = 0
    empty!(stat.annualized_return)
    empty!(stat.max_drawdown)
end
