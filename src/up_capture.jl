# UpCapture - Portfolio capture during positive benchmark periods

@doc """
$(TYPEDEF)

    UpCapture{T}()

Calculate up-market capture ratio from paired asset/benchmark returns.

Up capture measures how much of the benchmark's gains the portfolio captures during
positive market periods. A ratio > 1.0 means the portfolio outperforms in up markets.

# Mathematical Definition

``\\text{UpCapture} = \\frac{\\left(\\prod_{R_b > 0}(1 + R_a)\\right)^{1/n_{up}} - 1}{\\left(\\prod_{R_b > 0}(1 + R_b)\\right)^{1/n_{up}} - 1}``

Where:
- ``R_a`` = asset return when benchmark is positive
- ``R_b`` = benchmark return (> 0)
- ``n_{up}`` = count of positive benchmark periods

This is the ratio of annualized geometric mean returns in up markets.

# Input Type

Accepts [`AssetBenchmarkReturn`](@ref) observations via `fit!`.
Only observations where benchmark return > 0 are included.

# Edge Cases

- Returns `NaN` when no positive benchmark periods observed
- Returns `NaN` with no observations

# Interpretation

- Ratio > 1.0: Portfolio outperforms benchmark in up markets
- Ratio = 1.0: Portfolio matches benchmark in up markets
- Ratio < 1.0: Portfolio underperforms benchmark in up markets

# Fields

$(FIELDS)

# Example

```julia
stat = UpCapture()
fit!(stat, AssetBenchmarkReturn(0.05, 0.03))  # Up market: +5% vs +3%
fit!(stat, AssetBenchmarkReturn(-0.02, -0.04)) # Down market (ignored)
fit!(stat, AssetBenchmarkReturn(0.02, 0.01))  # Up market: +2% vs +1%
value(stat)  # Up capture ratio (> 1.0 in this case)
```

See also: [`DownCapture`](@ref), [`UpDownCaptureRatio`](@ref), [`AssetBenchmarkReturn`](@ref)
"""
mutable struct UpCapture{T} <: PortfolioAnalyticsSingleOutput{AssetBenchmarkReturn{T}}
    "Current up capture ratio value"
    value::T
    "Total number of observations"
    n::Int
    "Count of up-market observations (benchmark > 0)"
    n_up::Int
    "Product of (1 + R_asset) for up periods"
    asset_prod::Prod{T}
    "Product of (1 + R_benchmark) for up periods"
    benchmark_prod::Prod{T}

    function UpCapture{T}() where {T}
        new{T}(T(NaN), 0, 0, Prod(T), Prod(T))
    end
end

# Convenience constructor (default Float64)
UpCapture(; T::Type = Float64) = UpCapture{T}()

function OnlineStatsBase._fit!(stat::UpCapture{T}, obs::AssetBenchmarkReturn) where {T}
    stat.n += 1

    # Only track positive benchmark periods
    if obs.benchmark > 0
        stat.n_up += 1
        fit!(stat.asset_prod, 1 + obs.asset)
        fit!(stat.benchmark_prod, 1 + obs.benchmark)

        # Calculate up capture ratio
        # Using geometric mean: (prod)^(1/n) - 1 for each, then divide
        asset_geom_return = prod(stat.asset_prod)^(1/stat.n_up) - 1
        bench_geom_return = prod(stat.benchmark_prod)^(1/stat.n_up) - 1

        if bench_geom_return != 0
            stat.value = asset_geom_return / bench_geom_return
        else
            stat.value = T(NaN)
        end
    end
    # If no up periods yet, value remains NaN
end

function OnlineStatsBase.value(stat::UpCapture)
    return stat.value
end

function Base.empty!(stat::UpCapture{T}) where {T}
    stat.value = T(NaN)
    stat.n = 0
    stat.n_up = 0
    stat.asset_prod = Prod(T)
    stat.benchmark_prod = Prod(T)
end
