# UlcerIndex - Root-mean-square of drawdowns

@doc """
$(TYPEDEF)

    UlcerIndex{T}()

Calculate the Ulcer Index from a stream of returns.

The Ulcer Index measures the depth and duration of drawdowns by computing the
root-mean-square (RMS) of all drawdown values. It penalizes both the magnitude
and frequency of drawdowns, capturing the "pain" of holding an investment through
volatile periods.

# Mathematical Definition

``\\text{UlcerIndex} = \\sqrt{\\frac{1}{n} \\sum_{i=1}^{n} D_i^2}``

Where:
- ``D_i`` = drawdown at time i (from DrawDowns tracker, always ≤ 0)

# Edge Cases

- Returns `0.0` when no observations
- Returns `0.0` when no drawdown (always at peak)

# Interpretation

- Lower values indicate smoother returns with shallower drawdowns
- Higher values indicate more volatile returns with deeper/longer drawdowns
- Always non-negative (RMS of non-positive values)

# Fields

$(FIELDS)

# Example

```julia
stat = UlcerIndex()
fit!(stat, 0.10)   # +10% gain - new peak
fit!(stat, -0.05)  # -5% loss - in drawdown
fit!(stat, -0.03)  # -3% loss - deeper drawdown
value(stat)        # RMS of drawdown values
```

See also: [`PainIndex`](@ref), [`DrawDowns`](@ref), [`MaxDrawDown`](@ref)
"""
mutable struct UlcerIndex{T} <: PortfolioAnalyticsSingleOutput{T}
    "Current Ulcer Index value"
    value::T
    "Number of observations"
    n::Int
    "Internal drawdown tracker"
    drawdowns::DrawDowns{T}
    "Sum of squared drawdowns"
    sum_dd_squared::T

    function UlcerIndex{T}() where {T}
        new{T}(zero(T), 0, DrawDowns{T}(), zero(T))
    end
end

# Convenience constructor (default Float64)
UlcerIndex(; T::Type = Float64) = UlcerIndex{T}()

function OnlineStatsBase._fit!(stat::UlcerIndex{T}, ret) where {T}
    # Update drawdown tracker
    fit!(stat.drawdowns, ret)
    stat.n += 1

    # Get current drawdown (always ≤ 0)
    current_dd = value(stat.drawdowns)

    # Accumulate squared drawdown
    stat.sum_dd_squared += current_dd^2

    # Calculate Ulcer Index = sqrt(mean(DD^2))
    if stat.n > 0
        stat.value = sqrt(stat.sum_dd_squared / stat.n)
    end
end

function OnlineStatsBase.value(stat::UlcerIndex)
    return stat.value
end

function Base.empty!(stat::UlcerIndex{T}) where {T}
    stat.value = zero(T)
    stat.n = 0
    empty!(stat.drawdowns)
    stat.sum_dd_squared = zero(T)
end
