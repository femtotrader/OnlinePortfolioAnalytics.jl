# PainIndex - Mean absolute drawdown

@doc """
$(TYPEDEF)

    PainIndex{T}()

Calculate the Pain Index from a stream of returns.

The Pain Index measures the average depth of drawdowns by computing the mean of
absolute drawdown values. It provides a linear measure of "pain" compared to the
quadratic penalty of the Ulcer Index.

# Mathematical Definition

``\\text{PainIndex} = \\frac{1}{n} \\sum_{i=1}^{n} |D_i|``

Where:
- ``D_i`` = drawdown at time i (from DrawDowns tracker, always ≤ 0)
- ``|D_i|`` = absolute value of drawdown

# Edge Cases

- Returns `0.0` when no observations
- Returns `0.0` when no drawdown (always at peak)

# Interpretation

- Lower values indicate smoother returns with shallower drawdowns
- Higher values indicate more volatile returns with deeper drawdowns
- Always non-negative

# Fields

$(FIELDS)

# Example

```julia
stat = PainIndex()
fit!(stat, 0.10)   # +10% gain - new peak
fit!(stat, -0.05)  # -5% loss - in drawdown
fit!(stat, -0.03)  # -3% loss - deeper drawdown
value(stat)        # Mean of absolute drawdown values
```

See also: [`UlcerIndex`](@ref), [`PainRatio`](@ref), [`DrawDowns`](@ref)
"""
mutable struct PainIndex{T} <: PortfolioAnalyticsSingleOutput{T}
    "Current Pain Index value"
    value::T
    "Number of observations"
    n::Int
    "Internal drawdown tracker"
    drawdowns::DrawDowns{T}
    "Sum of absolute drawdowns"
    sum_abs_dd::T

    function PainIndex{T}() where {T}
        new{T}(zero(T), 0, DrawDowns{T}(), zero(T))
    end
end

# Convenience constructor (default Float64)
PainIndex(; T::Type = Float64) = PainIndex{T}()

function OnlineStatsBase._fit!(stat::PainIndex{T}, ret) where {T}
    # Update drawdown tracker
    fit!(stat.drawdowns, ret)
    stat.n += 1

    # Get current drawdown (always ≤ 0)
    current_dd = value(stat.drawdowns)

    # Accumulate absolute drawdown
    stat.sum_abs_dd += abs(current_dd)

    # Calculate Pain Index = mean(|DD|)
    if stat.n > 0
        stat.value = stat.sum_abs_dd / stat.n
    end
end

function OnlineStatsBase.value(stat::PainIndex)
    return stat.value
end

function Base.empty!(stat::PainIndex{T}) where {T}
    stat.value = zero(T)
    stat.n = 0
    empty!(stat.drawdowns)
    stat.sum_abs_dd = zero(T)
end
