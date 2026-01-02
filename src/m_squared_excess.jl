# MSquaredExcess - M2 excess over benchmark mean

@doc """
$(TYPEDEF)

    MSquaredExcess{T}(; risk_free=0.0)

Calculate the M-Squared Excess (M2 minus benchmark mean return) from a stream
of paired portfolio and benchmark returns.

M-Squared Excess represents the risk-adjusted excess return of the portfolio
relative to the benchmark. It shows how much the portfolio would have outperformed
(or underperformed) the benchmark if both had the same volatility.

# Mathematical Definition

``M^2_{excess} = M^2 - \\bar{R}_{bench}``

Where:
- ``M^2 = R_f + (\\bar{R}_{port} - R_f) \\times \\frac{\\sigma_{bench}}{\\sigma_{port}}``
- ``\\bar{R}_{bench}`` = mean benchmark return

# Interpretation

- Positive value: Portfolio outperforms on a risk-adjusted basis
- Negative value: Portfolio underperforms on a risk-adjusted basis
- Zero: Portfolio performs exactly as expected for its risk level

# Parameters

- `risk_free`: Risk-free rate (default 0.0)

# Edge Cases

- Returns `0.0` when fewer than 2 observations (insufficient data)

# Fields

$(FIELDS)

# Example

```julia
stat = MSquaredExcess(risk_free=0.02)
fit!(stat, AssetBenchmarkReturn(0.10, 0.08))
fit!(stat, AssetBenchmarkReturn(0.05, 0.04))
value(stat)  # Risk-adjusted excess return vs benchmark
```

See also: [`M2`](@ref), [`InformationRatio`](@ref), [`ActivePremium`](@ref)
"""
mutable struct MSquaredExcess{T} <: PortfolioAnalyticsSingleOutput{AssetBenchmarkReturn{T}}
    "Current M-Squared Excess value"
    value::T
    "Number of observations"
    n::Int
    "Internal M2 tracker"
    m2::M2{T}
    "Benchmark mean tracker"
    bench_mean::Mean{T}
    "Risk-free rate"
    risk_free::T

    function MSquaredExcess{T}(; risk_free::Real = zero(T)) where {T}
        new{T}(zero(T), 0, M2{T}(risk_free = T(risk_free)), Mean(T), T(risk_free))
    end
end

# Convenience constructor (default Float64)
MSquaredExcess(; T::Type = Float64, risk_free::Real = 0.0) =
    MSquaredExcess{T}(risk_free = T(risk_free))

function OnlineStatsBase._fit!(stat::MSquaredExcess{T}, obs::AssetBenchmarkReturn) where {T}
    fit!(stat.m2, obs)
    fit!(stat.bench_mean, obs.benchmark)
    stat.n += 1

    # MSquaredExcess = M2 - benchmark mean
    if stat.n >= 2
        stat.value = value(stat.m2) - value(stat.bench_mean)
    else
        stat.value = zero(T)
    end
end

function OnlineStatsBase.value(stat::MSquaredExcess)
    return stat.value
end

function Base.empty!(stat::MSquaredExcess{T}) where {T}
    stat.value = zero(T)
    stat.n = 0
    empty!(stat.m2)
    stat.bench_mean = Mean(T)
end
