# DownCapture - Portfolio capture during negative benchmark periods

@doc """
$(TYPEDEF)

    DownCapture{T}()

Calculate down-market capture ratio from paired asset/benchmark returns.

Down capture measures how much of the benchmark's losses the portfolio captures during
negative market periods. A ratio < 1.0 means the portfolio falls less than the benchmark
in down markets, which is desirable.

# Mathematical Definition

``\\text{DownCapture} = \\frac{\\left(\\prod_{R_b < 0}(1 + R_a)\\right)^{1/n_{down}} - 1}{\\left(\\prod_{R_b < 0}(1 + R_b)\\right)^{1/n_{down}} - 1}``

Where:
- ``R_a`` = asset return when benchmark is negative
- ``R_b`` = benchmark return (< 0)
- ``n_{down}`` = count of negative benchmark periods

This is the ratio of annualized geometric mean returns in down markets.

# Input Type

Accepts [`AssetBenchmarkReturn`](@ref) observations via `fit!`.
Only observations where benchmark return < 0 are included.

# Edge Cases

- Returns `NaN` when no negative benchmark periods observed
- Returns `NaN` with no observations

# Interpretation

- Ratio < 1.0: Portfolio falls less than benchmark in down markets (desirable)
- Ratio = 1.0: Portfolio matches benchmark in down markets
- Ratio > 1.0: Portfolio falls more than benchmark in down markets (unfavorable)

# Fields

$(FIELDS)

# Example

```julia
stat = DownCapture()
fit!(stat, AssetBenchmarkReturn(-0.02, -0.05))  # Down market: -2% vs -5%
fit!(stat, AssetBenchmarkReturn(0.03, 0.04))    # Up market (ignored)
fit!(stat, AssetBenchmarkReturn(-0.01, -0.03))  # Down market: -1% vs -3%
value(stat)  # Down capture ratio (< 1.0 in this case - good!)
```

See also: [`UpCapture`](@ref), [`UpDownCaptureRatio`](@ref), [`AssetBenchmarkReturn`](@ref)
"""
mutable struct DownCapture{T} <: PortfolioAnalyticsSingleOutput{AssetBenchmarkReturn{T}}
    "Current down capture ratio value"
    value::T
    "Total number of observations"
    n::Int
    "Count of down-market observations (benchmark < 0)"
    n_down::Int
    "Product of (1 + R_asset) for down periods"
    asset_prod::Prod{T}
    "Product of (1 + R_benchmark) for down periods"
    benchmark_prod::Prod{T}

    function DownCapture{T}() where {T}
        new{T}(T(NaN), 0, 0, Prod(T), Prod(T))
    end
end

# Convenience constructor (default Float64)
DownCapture(; T::Type = Float64) = DownCapture{T}()

function OnlineStatsBase._fit!(stat::DownCapture{T}, obs::AssetBenchmarkReturn) where {T}
    stat.n += 1

    # Only track negative benchmark periods
    if obs.benchmark < 0
        stat.n_down += 1
        fit!(stat.asset_prod, 1 + obs.asset)
        fit!(stat.benchmark_prod, 1 + obs.benchmark)

        # Calculate down capture ratio
        # Using geometric mean: (prod)^(1/n) - 1 for each, then divide
        asset_geom_return = prod(stat.asset_prod)^(1/stat.n_down) - 1
        bench_geom_return = prod(stat.benchmark_prod)^(1/stat.n_down) - 1

        if bench_geom_return != 0
            stat.value = asset_geom_return / bench_geom_return
        else
            stat.value = T(NaN)
        end
    end
    # If no down periods yet, value remains NaN
end

function OnlineStatsBase.value(stat::DownCapture)
    return stat.value
end

function Base.empty!(stat::DownCapture{T}) where {T}
    stat.value = T(NaN)
    stat.n = 0
    stat.n_down = 0
    stat.asset_prod = Prod(T)
    stat.benchmark_prod = Prod(T)
end
