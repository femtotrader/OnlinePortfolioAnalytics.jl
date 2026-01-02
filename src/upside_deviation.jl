# UpsideDeviation - Semi-standard deviation above threshold

@doc """
$(TYPEDEF)

    UpsideDeviation{T}(; threshold=0.0)

Calculate Upside Deviation (semi-standard deviation) from a stream of returns.

Upside Deviation measures the volatility of returns above a threshold.
It captures only positive volatility, complementing Downside Deviation.

# Mathematical Definition

``\\text{UD} = \\sqrt{\\frac{1}{n} \\sum_{i=1}^{n} \\max(R_i - \\tau, 0)^2}``

Where:
- ``R_i`` = return for period i
- ``\\tau`` = threshold (Minimum Acceptable Return)
- ``n`` = total number of observations

# Parameters

- `threshold`: Minimum Acceptable Return (default 0.0)

# Input Type

Accepts single return values (Number) via `fit!`.

# Edge Cases

- Returns `0.0` when no observations (n=0)
- Returns `0.0` when all returns are below threshold

# Fields

- `value::T`: Current upside deviation
- `n::Int`: Total observation count
- `n_above::Int`: Count of observations above threshold
- `sum_sq_above::T`: Sum of squared deviations above threshold
- `threshold::T`: MAR threshold

# Example

```julia
stat = UpsideDeviation(threshold=0.0)
for ret in returns
    fit!(stat, ret)
end
ud = value(stat)  # Semi-std of returns above 0
```

See also: [`DownsideDeviation`](@ref)
"""
mutable struct UpsideDeviation{T} <: PortfolioAnalyticsSingleOutput{T}
    value::T
    n::Int
    n_above::Int
    sum_sq_above::T
    threshold::T

    function UpsideDeviation{T}(; threshold::Real = zero(T)) where {T}
        new{T}(zero(T), 0, 0, zero(T), T(threshold))
    end
end

# Convenience constructor (default Float64)
UpsideDeviation(; T::Type = Float64, threshold::Real = 0.0) =
    UpsideDeviation{T}(; threshold=threshold)

function OnlineStatsBase._fit!(stat::UpsideDeviation{T}, ret) where {T}
    stat.n += 1

    # Check if above threshold
    if ret > stat.threshold
        deviation = ret - stat.threshold
        stat.sum_sq_above += deviation^2
        stat.n_above += 1
    end

    # Calculate upside deviation (using total n for consistency)
    stat.value = stat.n > 0 ? T(sqrt(stat.sum_sq_above / stat.n)) : zero(T)

    nothing
end

function OnlineStatsBase.value(stat::UpsideDeviation)
    return stat.n == 0 ? zero(stat.value) : stat.value
end

function Base.empty!(stat::UpsideDeviation{T}) where {T}
    stat.value = zero(T)
    stat.n = 0
    stat.n_above = 0
    stat.sum_sq_above = zero(T)
    nothing
end

function OnlineStatsBase._merge!(stat1::UpsideDeviation, stat2::UpsideDeviation)
    stat1.n += stat2.n
    stat1.n_above += stat2.n_above
    stat1.sum_sq_above += stat2.sum_sq_above

    # Recalculate value
    stat1.value = stat1.n > 0 ?
        typeof(stat1.value)(sqrt(stat1.sum_sq_above / stat1.n)) :
        zero(typeof(stat1.value))

    return stat1
end
