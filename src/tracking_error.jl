# TrackingError - Standard deviation of return differences

using OnlineStats: Variance

@doc """
$(TYPEDEF)

    TrackingError{T}()

Calculate Tracking Error from paired asset/benchmark returns.

Tracking Error measures how closely a portfolio follows its benchmark by computing
the standard deviation of the difference between asset and benchmark returns.

# Mathematical Definition

``\\text{TE} = \\sigma(R_a - R_b)``

Where:
- ``R_a`` = asset/portfolio returns
- ``R_b`` = benchmark returns
- ``\\sigma`` = standard deviation

# Input Type

Accepts [`AssetBenchmarkReturn`](@ref) observations via `fit!`.

# Edge Cases

- Returns `0.0` when fewer than 2 observations (insufficient for std dev)
- Returns `0.0` for perfect tracking (identical returns)

# Fields

- `value::T`: Current tracking error value
- `n::Int`: Number of observations
- `diff_variance::Variance`: Internal variance tracker for return differences

# Example

```julia
stat = TrackingError()
fit!(stat, AssetBenchmarkReturn(0.05, 0.04))  # Asset +5%, Benchmark +4%
fit!(stat, AssetBenchmarkReturn(0.02, 0.03))  # Asset +2%, Benchmark +3%
fit!(stat, AssetBenchmarkReturn(-0.01, -0.02)) # Asset -1%, Benchmark -2%
value(stat)  # Standard deviation of differences
```

See also: [`AssetBenchmarkReturn`](@ref), [`InformationRatio`](@ref)
"""
mutable struct TrackingError{T} <: PortfolioAnalyticsSingleOutput{AssetBenchmarkReturn{T}}
    value::T
    n::Int
    diff_variance::Variance

    function TrackingError{T}() where {T}
        new{T}(zero(T), 0, Variance())
    end
end

# Convenience constructor (default Float64)
TrackingError(; T::Type = Float64) = TrackingError{T}()

function OnlineStatsBase._fit!(stat::TrackingError{T}, obs::AssetBenchmarkReturn) where {T}
    # Calculate the return difference
    diff = obs.asset - obs.benchmark

    # Update variance tracker
    fit!(stat.diff_variance, diff)
    stat.n += 1

    # Calculate tracking error (std dev)
    if stat.n >= 2
        stat.value = T(sqrt(value(stat.diff_variance)))
    else
        stat.value = zero(T)
    end

    nothing
end

function OnlineStatsBase.value(stat::TrackingError)
    return stat.n < 2 ? zero(stat.value) : stat.value
end

function Base.empty!(stat::TrackingError{T}) where {T}
    stat.value = zero(T)
    stat.n = 0
    stat.diff_variance = Variance()
    nothing
end

function OnlineStatsBase._merge!(stat1::TrackingError, stat2::TrackingError)
    # Merge the underlying Variance stats
    merge!(stat1.diff_variance, stat2.diff_variance)
    stat1.n += stat2.n

    # Recalculate tracking error from merged variance
    if stat1.n >= 2
        stat1.value = typeof(stat1.value)(sqrt(value(stat1.diff_variance)))
    end

    return stat1
end
