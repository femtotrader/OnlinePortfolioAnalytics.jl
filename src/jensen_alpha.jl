# JensenAlpha - Excess return above CAPM prediction

@doc """
$(TYPEDEF)

    JensenAlpha{T}(; risk_free=0.0)

Calculate Jensen's Alpha from paired asset/market returns.

Jensen's Alpha measures the excess return of a portfolio above what the CAPM
(Capital Asset Pricing Model) would predict, given its beta. Positive alpha
indicates outperformance, negative alpha indicates underperformance.

# Mathematical Definition

``\\alpha = E[R_a] - (r_f + \\beta \\times (E[R_m] - r_f))``

Where:
- ``R_a`` = asset returns
- ``R_m`` = market returns
- ``r_f`` = risk-free rate
- ``\\beta`` = systematic risk coefficient

# Parameters

- `risk_free`: Risk-free rate (default 0.0)

# Input Type

Accepts [`AssetBenchmarkReturn`](@ref) observations via `fit!`.

# Edge Cases

- Returns `0.0` when fewer than 2 observations (insufficient for beta)

# Fields

- `value::T`: Current Jensen's alpha
- `n::Int`: Number of observations
- `asset_mean::Mean`: Mean asset return tracker
- `market_mean::Mean`: Mean market return tracker
- `beta::Beta{T}`: Beta coefficient tracker
- `risk_free::T`: Risk-free rate

# Example

```julia
stat = JensenAlpha(risk_free=0.02)
fit!(stat, AssetBenchmarkReturn(0.05, 0.03))  # Asset +5%, Market +3%
fit!(stat, AssetBenchmarkReturn(0.02, 0.01))  # Asset +2%, Market +1%
value(stat)  # Actual return - CAPM expected return
```

See also: [`AssetBenchmarkReturn`](@ref), [`Beta`](@ref), [`ExpectedReturn`](@ref)
"""
mutable struct JensenAlpha{T} <: PortfolioAnalyticsSingleOutput{AssetBenchmarkReturn{T}}
    value::T
    n::Int
    asset_mean::Mean
    market_mean::Mean
    beta::Beta{T}
    risk_free::T

    function JensenAlpha{T}(; risk_free::Real = zero(T)) where {T}
        new{T}(zero(T), 0, Mean(), Mean(), Beta{T}(), T(risk_free))
    end
end

# Convenience constructor (default Float64)
JensenAlpha(; T::Type = Float64, risk_free::Real = 0.0) = JensenAlpha{T}(; risk_free=risk_free)

function OnlineStatsBase._fit!(stat::JensenAlpha{T}, obs::AssetBenchmarkReturn) where {T}
    # Update trackers
    fit!(stat.asset_mean, obs.asset)
    fit!(stat.market_mean, obs.benchmark)
    fit!(stat.beta, obs)
    stat.n += 1

    # Calculate Jensen's Alpha
    if stat.n >= 2
        mean_asset = value(stat.asset_mean)
        mean_market = value(stat.market_mean)
        beta_val = value(stat.beta)

        # CAPM expected return: E[R] = rf + beta * (E[Rm] - rf)
        expected_return = stat.risk_free + beta_val * (mean_market - stat.risk_free)

        # Alpha = actual - expected
        stat.value = T(mean_asset - expected_return)
    else
        stat.value = zero(T)
    end

    nothing
end

function OnlineStatsBase.value(stat::JensenAlpha)
    return stat.n < 2 ? zero(stat.value) : stat.value
end

function Base.empty!(stat::JensenAlpha{T}) where {T}
    stat.value = zero(T)
    stat.n = 0
    stat.asset_mean = Mean()
    stat.market_mean = Mean()
    empty!(stat.beta)
    nothing
end

function OnlineStatsBase._merge!(stat1::JensenAlpha, stat2::JensenAlpha)
    # Merge the underlying stats
    merge!(stat1.asset_mean, stat2.asset_mean)
    merge!(stat1.market_mean, stat2.market_mean)
    merge!(stat1.beta, stat2.beta)
    stat1.n += stat2.n

    # Recalculate alpha from merged stats
    if stat1.n >= 2
        mean_asset = value(stat1.asset_mean)
        mean_market = value(stat1.market_mean)
        beta_val = value(stat1.beta)

        expected_return = stat1.risk_free + beta_val * (mean_market - stat1.risk_free)
        stat1.value = typeof(stat1.value)(mean_asset - expected_return)
    end

    return stat1
end
