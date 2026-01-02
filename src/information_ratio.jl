# InformationRatio - Excess return per unit of tracking error

using OnlineStats: Mean

@doc """
$(TYPEDEF)

    InformationRatio{T}()

Calculate Information Ratio from paired asset/benchmark returns.

Information Ratio measures the excess return of an asset relative to its benchmark,
adjusted for the tracking error. It is a key metric for evaluating active management skill.

# Mathematical Definition

``\\text{IR} = \\frac{E[R_a - R_b]}{\\sigma(R_a - R_b)} = \\frac{\\text{Mean Excess Return}}{\\text{Tracking Error}}``

Where:
- ``R_a`` = asset/portfolio returns
- ``R_b`` = benchmark returns
- ``E[.]`` = expected value (mean)
- ``\\sigma`` = standard deviation

# Input Type

Accepts [`AssetBenchmarkReturn`](@ref) observations via `fit!`.

# Edge Cases

- Returns `0.0` when fewer than 2 observations (insufficient for TE)
- Returns `0.0` when tracking error is zero (perfect tracking)

# Fields

- `value::T`: Current IR value
- `n::Int`: Number of observations
- `excess_mean::Mean`: Tracker for mean excess return
- `tracking_error::TrackingError{T}`: Tracker for tracking error

# Example

```julia
stat = InformationRatio()
fit!(stat, AssetBenchmarkReturn(0.05, 0.04))  # Asset +5%, Benchmark +4%
fit!(stat, AssetBenchmarkReturn(0.02, 0.03))  # Asset +2%, Benchmark +3%
fit!(stat, AssetBenchmarkReturn(-0.01, -0.02)) # Asset -1%, Benchmark -2%
value(stat)  # Mean(excess) / TrackingError
```

See also: [`AssetBenchmarkReturn`](@ref), [`TrackingError`](@ref)
"""
mutable struct InformationRatio{T} <: PortfolioAnalyticsSingleOutput{AssetBenchmarkReturn{T}}
    value::T
    n::Int
    excess_mean::Mean
    tracking_error::TrackingError{T}

    function InformationRatio{T}() where {T}
        new{T}(zero(T), 0, Mean(), TrackingError{T}())
    end
end

# Convenience constructor (default Float64)
InformationRatio(; T::Type = Float64) = InformationRatio{T}()

function OnlineStatsBase._fit!(stat::InformationRatio{T}, obs::AssetBenchmarkReturn) where {T}
    # Calculate excess return
    excess = obs.asset - obs.benchmark

    # Update trackers
    fit!(stat.excess_mean, excess)
    fit!(stat.tracking_error, obs)
    stat.n += 1

    # Calculate IR
    if stat.n >= 2
        te = value(stat.tracking_error)
        if te > 0
            stat.value = T(value(stat.excess_mean) / te)
        else
            stat.value = zero(T)  # Zero TE -> IR = 0 (not Inf)
        end
    else
        stat.value = zero(T)
    end

    nothing
end

function OnlineStatsBase.value(stat::InformationRatio)
    return stat.n < 2 ? zero(stat.value) : stat.value
end

function Base.empty!(stat::InformationRatio{T}) where {T}
    stat.value = zero(T)
    stat.n = 0
    stat.excess_mean = Mean()
    empty!(stat.tracking_error)
    nothing
end

function OnlineStatsBase._merge!(stat1::InformationRatio, stat2::InformationRatio)
    # Merge the underlying stats
    merge!(stat1.excess_mean, stat2.excess_mean)
    merge!(stat1.tracking_error, stat2.tracking_error)
    stat1.n += stat2.n

    # Recalculate IR from merged stats
    if stat1.n >= 2
        te = value(stat1.tracking_error)
        if te > 0
            stat1.value = typeof(stat1.value)(value(stat1.excess_mean) / te)
        else
            stat1.value = zero(typeof(stat1.value))
        end
    end

    return stat1
end
