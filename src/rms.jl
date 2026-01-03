# RMS - Root Mean Square statistic

@doc """
$(TYPEDEF)

    RMS{T}()

Calculate the Root Mean Square (RMS) from a stream of numeric values.

RMS is a fundamental statistical measure that computes the square root of the mean
of squared values. It is commonly used in signal processing, physics, and finance
to measure the magnitude of varying quantities.

# Mathematical Definition

``\\text{RMS} = \\sqrt{\\frac{1}{n} \\sum_{i=1}^{n} x_i^2}``

Where:
- ``x_i`` = observation at time i
- ``n`` = total number of observations

# Edge Cases

- Returns `0.0` when no observations (n=0)
- Handles negative values correctly (squared, so sign doesn't matter)
- RMS of all zeros returns `0.0`

# Fields

$(FIELDS)

# Example

```julia
stat = RMS()
fit!(stat, 3.0)
fit!(stat, 4.0)
value(stat)  # sqrt((9+16)/2) ≈ 3.536
```

# Usage in Portfolio Analytics

RMS is used internally by [`UlcerIndex`](@ref) to compute the root-mean-square
of drawdown values, measuring the "pain" of holding an investment through
volatile periods.

See also: [`UlcerIndex`](@ref), [`DownsideDeviation`](@ref), [`StdDev`](@ref)
"""
mutable struct RMS{T} <: PortfolioAnalyticsSingleOutput{T}
    "Current RMS value"
    value::T
    "Number of observations"
    n::Int
    "Sum of squared values"
    sum_sq::T

    function RMS{T}() where {T}
        new{T}(zero(T), 0, zero(T))
    end
end

# Convenience constructor (default Float64)
RMS(; T::Type = Float64) = RMS{T}()

function OnlineStatsBase._fit!(stat::RMS{T}, x) where {T}
    stat.n += 1
    stat.sum_sq += T(x)^2

    # Calculate RMS = sqrt(mean(x^2))
    stat.value = T(sqrt(stat.sum_sq / stat.n))

    nothing
end

function OnlineStatsBase.value(stat::RMS)
    return stat.n == 0 ? zero(stat.value) : stat.value
end

function Base.empty!(stat::RMS{T}) where {T}
    stat.value = zero(T)
    stat.n = 0
    stat.sum_sq = zero(T)
    nothing
end

function OnlineStatsBase._merge!(stat1::RMS, stat2::RMS)
    stat1.n += stat2.n
    stat1.sum_sq += stat2.sum_sq

    # Recalculate value
    stat1.value = stat1.n > 0 ?
        typeof(stat1.value)(sqrt(stat1.sum_sq / stat1.n)) :
        zero(typeof(stat1.value))

    return stat1
end
