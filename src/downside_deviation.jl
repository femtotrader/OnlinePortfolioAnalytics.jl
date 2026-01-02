# DownsideDeviation - Semi-standard deviation below threshold

@doc """
$(TYPEDEF)

    DownsideDeviation{T}(; threshold=0.0)

Calculate Downside Deviation (semi-standard deviation) from a stream of returns.

Downside Deviation measures the volatility of returns below a threshold (typically 0 or MAR).
It captures only negative volatility, providing a more intuitive measure of risk than
symmetric standard deviation.

# Mathematical Definition

``\\text{DD} = \\sqrt{\\frac{1}{n} \\sum_{i=1}^{n} \\min(R_i - \\tau, 0)^2}``

Where:
- ``R_i`` = return for period i
- ``\\tau`` = threshold (Minimum Acceptable Return)
- ``n`` = total number of observations (consistent with Sortino definition)

# Parameters

- `threshold`: Minimum Acceptable Return (default 0.0)

# Input Type

Accepts single return values (Number) via `fit!`.

# Edge Cases

- Returns `0.0` when no observations (n=0)
- Returns `0.0` when all returns are above threshold

# Fields

- `value::T`: Current downside deviation
- `n::Int`: Total observation count
- `n_below::Int`: Count of observations below threshold
- `sum_sq_below::T`: Sum of squared deviations below threshold
- `threshold::T`: MAR threshold

# Example

```julia
stat = DownsideDeviation(threshold=0.0)
for ret in returns
    fit!(stat, ret)
end
dd = value(stat)  # Semi-std of returns below 0
```

See also: [`UpsideDeviation`](@ref), [`Sortino`](@ref)
"""
mutable struct DownsideDeviation{T} <: PortfolioAnalyticsSingleOutput{T}
    value::T
    n::Int
    n_below::Int
    sum_sq_below::T
    threshold::T

    function DownsideDeviation{T}(; threshold::Real = zero(T)) where {T}
        new{T}(zero(T), 0, 0, zero(T), T(threshold))
    end
end

# Convenience constructor (default Float64)
DownsideDeviation(; T::Type = Float64, threshold::Real = 0.0) =
    DownsideDeviation{T}(; threshold=threshold)

function OnlineStatsBase._fit!(stat::DownsideDeviation{T}, ret) where {T}
    stat.n += 1

    # Check if below threshold
    if ret < stat.threshold
        deviation = ret - stat.threshold
        stat.sum_sq_below += deviation^2
        stat.n_below += 1
    end

    # Calculate downside deviation (using total n for consistency with Sortino)
    stat.value = stat.n > 0 ? T(sqrt(stat.sum_sq_below / stat.n)) : zero(T)

    nothing
end

function OnlineStatsBase.value(stat::DownsideDeviation)
    return stat.n == 0 ? zero(stat.value) : stat.value
end

function Base.empty!(stat::DownsideDeviation{T}) where {T}
    stat.value = zero(T)
    stat.n = 0
    stat.n_below = 0
    stat.sum_sq_below = zero(T)
    nothing
end

function OnlineStatsBase._merge!(stat1::DownsideDeviation, stat2::DownsideDeviation)
    stat1.n += stat2.n
    stat1.n_below += stat2.n_below
    stat1.sum_sq_below += stat2.sum_sq_below

    # Recalculate value
    stat1.value = stat1.n > 0 ?
        typeof(stat1.value)(sqrt(stat1.sum_sq_below / stat1.n)) :
        zero(typeof(stat1.value))

    return stat1
end
