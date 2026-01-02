# ExpectedReturn - CAPM Expected Return calculation

@doc """
$(TYPEDEF)

    ExpectedReturn{T}(; risk_free=0.0)

Calculate the CAPM (Capital Asset Pricing Model) expected return from paired
asset/market returns.

The expected return represents the theoretical return an asset should earn based
on its systematic risk (beta) relative to the market.

# Mathematical Definition

``E[R_a] = r_f + \\beta \\times (E[R_m] - r_f)``

Where:
- ``E[R_a]`` = expected return of the asset
- ``r_f`` = risk-free rate
- ``\\beta`` = beta coefficient (systematic risk)
- ``E[R_m]`` = expected market return (mean)

# Parameters

- `risk_free`: Risk-free rate of return (default 0.0)

# Input Type

Accepts [`AssetBenchmarkReturn`](@ref) observations via `fit!`.

# Edge Cases

- Returns `risk_free` when fewer than 2 observations (insufficient data for beta)

# Fields

- `value::T`: Current expected return
- `n::Int`: Number of observations
- `beta::Beta{T}`: Internal beta tracker
- `risk_free::T`: Risk-free rate

# Example

```julia
stat = ExpectedReturn(risk_free=0.02)  # 2% risk-free rate
fit!(stat, AssetBenchmarkReturn(0.05, 0.03))  # Asset +5%, Market +3%
fit!(stat, AssetBenchmarkReturn(0.02, 0.01))  # Asset +2%, Market +1%
value(stat)  # CAPM expected return
```

See also: [`AssetBenchmarkReturn`](@ref), [`Beta`](@ref)
"""
mutable struct ExpectedReturn{T} <: PortfolioAnalyticsSingleOutput{AssetBenchmarkReturn{T}}
    value::T
    n::Int
    beta::Beta{T}
    market_mean::Mean
    risk_free::T

    function ExpectedReturn{T}(; risk_free::T = zero(T)) where {T}
        new{T}(risk_free, 0, Beta{T}(), Mean(), risk_free)
    end
end

# Convenience constructor (default Float64)
ExpectedReturn(; T::Type = Float64, risk_free = zero(T)) =
    ExpectedReturn{T}(risk_free = convert(T, risk_free))

function OnlineStatsBase._fit!(stat::ExpectedReturn{T}, obs::AssetBenchmarkReturn) where {T}
    # Delegate to internal beta tracker
    fit!(stat.beta, obs)

    # Track market mean separately
    fit!(stat.market_mean, obs.benchmark)

    stat.n += 1

    # Calculate expected return using CAPM formula
    if stat.n >= 2
        beta_val = value(stat.beta)
        market_mean_val = value(stat.market_mean)
        # E[Ra] = rf + β × (E[Rm] - rf)
        stat.value = stat.risk_free + beta_val * (market_mean_val - stat.risk_free)
    else
        stat.value = stat.risk_free
    end
end

function OnlineStatsBase.value(stat::ExpectedReturn)
    return stat.value
end

function Base.empty!(stat::ExpectedReturn{T}) where {T}
    stat.value = stat.risk_free
    stat.n = 0
    empty!(stat.beta)
    stat.market_mean = Mean()
end

function OnlineStatsBase._merge!(stat1::ExpectedReturn{T}, stat2::ExpectedReturn{T}) where {T}
    # Merge the underlying Beta stats
    merge!(stat1.beta, stat2.beta)

    # Merge market mean trackers
    merge!(stat1.market_mean, stat2.market_mean)

    stat1.n += stat2.n

    # Recalculate expected return from merged stats
    if stat1.n >= 2
        beta_val = value(stat1.beta)
        market_mean_val = value(stat1.market_mean)
        stat1.value = stat1.risk_free + beta_val * (market_mean_val - stat1.risk_free)
    end

    return stat1
end
