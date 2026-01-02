# M2 (Modigliani-Modigliani) - Risk-adjusted performance measure

@doc """
$(TYPEDEF)

    M2{T}(; risk_free=0.0)

Calculate the M2 (Modigliani-Modigliani) risk-adjusted performance measure from a stream
of paired portfolio and benchmark returns.

M2 adjusts the portfolio return to have the same volatility as the benchmark, making
performance comparison between portfolios with different risk levels more meaningful.

# Mathematical Definition

``M^2 = R_f + (\\bar{R}_{port} - R_f) \\times \\frac{\\sigma_{bench}}{\\sigma_{port}}``

Where:
- ``R_f`` = risk-free rate
- ``\\bar{R}_{port}`` = mean portfolio return
- ``\\sigma_{port}`` = portfolio standard deviation
- ``\\sigma_{bench}`` = benchmark standard deviation

# Interpretation

- M2 represents what the portfolio return would have been if it had the same risk as the benchmark
- Higher M2 indicates better risk-adjusted performance
- M2 is directly comparable to benchmark return (same scale and units)

# Parameters

- `risk_free`: Risk-free rate (default 0.0)

# Edge Cases

- Returns `0.0` when portfolio volatility is zero (undefined)
- Returns `0.0` when fewer than 2 observations (insufficient data)

# Fields

$(FIELDS)

# Example

```julia
stat = M2(risk_free=0.02)
fit!(stat, AssetBenchmarkReturn(0.10, 0.08))  # Portfolio +10%, Benchmark +8%
fit!(stat, AssetBenchmarkReturn(0.05, 0.04))  # Portfolio +5%, Benchmark +4%
value(stat)  # Risk-adjusted portfolio return
```

See also: [`MSquaredExcess`](@ref), [`Sharpe`](@ref), [`InformationRatio`](@ref)
"""
mutable struct M2{T} <: PortfolioAnalyticsSingleOutput{AssetBenchmarkReturn{T}}
    "Current M2 value"
    value::T
    "Number of observations"
    n::Int
    "Portfolio mean tracker"
    port_mean::Mean{T}
    "Portfolio variance tracker"
    port_variance::Variance
    "Benchmark variance tracker"
    bench_variance::Variance
    "Risk-free rate"
    risk_free::T

    function M2{T}(; risk_free::Real = zero(T)) where {T}
        new{T}(zero(T), 0, Mean(T), Variance(T), Variance(T), T(risk_free))
    end
end

# Convenience constructor (default Float64)
M2(; T::Type = Float64, risk_free::Real = 0.0) = M2{T}(risk_free = T(risk_free))

function OnlineStatsBase._fit!(stat::M2{T}, obs::AssetBenchmarkReturn) where {T}
    fit!(stat.port_mean, obs.asset)
    fit!(stat.port_variance, obs.asset)
    fit!(stat.bench_variance, obs.benchmark)
    stat.n += 1

    # M2 = Rf + (R_port - Rf) * (σ_bench / σ_port)
    if stat.n >= 2
        port_std = sqrt(value(stat.port_variance))
        bench_std = sqrt(value(stat.bench_variance))

        if port_std > 0
            port_mean_val = value(stat.port_mean)
            stat.value = stat.risk_free + (port_mean_val - stat.risk_free) * (bench_std / port_std)
        else
            stat.value = zero(T)
        end
    else
        stat.value = zero(T)
    end
end

function OnlineStatsBase.value(stat::M2)
    return stat.value
end

function Base.empty!(stat::M2{T}) where {T}
    stat.value = zero(T)
    stat.n = 0
    stat.port_mean = Mean(T)
    stat.port_variance = Variance(T)
    stat.bench_variance = Variance(T)
end
