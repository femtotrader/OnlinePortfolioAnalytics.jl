# Treynor Ratio - Excess return per unit of systematic risk

@doc """
$(TYPEDEF)

    Treynor{T}(; risk_free=0.0)

Calculate Treynor Ratio from paired asset/market returns.

Treynor Ratio measures the excess return per unit of systematic risk (beta).
Unlike Sharpe Ratio which uses total risk, Treynor uses only market-related risk.

# Mathematical Definition

``\\text{Treynor} = \\frac{E[R_a] - r_f}{\\beta}``

Where:
- ``R_a`` = asset returns
- ``r_f`` = risk-free rate
- ``\\beta`` = systematic risk (from CAPM)

# Parameters

- `risk_free`: Risk-free rate (default 0.0)

# Input Type

Accepts [`AssetBenchmarkReturn`](@ref) observations via `fit!`.

# Edge Cases

- Returns `0.0` when fewer than 2 observations (insufficient for beta)
- Returns `Inf` or `-Inf` when beta is zero (division by zero)

# Fields

- `value::T`: Current Treynor ratio
- `n::Int`: Number of observations
- `beta::Beta{T}`: Internal beta tracker
- `asset_mean::Mean`: Mean asset return tracker
- `risk_free::T`: Risk-free rate

# Example

```julia
stat = Treynor(risk_free=0.02)
fit!(stat, AssetBenchmarkReturn(0.05, 0.03))  # Asset +5%, Market +3%
fit!(stat, AssetBenchmarkReturn(0.02, 0.01))  # Asset +2%, Market +1%
value(stat)  # (mean_return - rf) / beta
```

See also: [`AssetBenchmarkReturn`](@ref), [`Beta`](@ref), [`Sharpe`](@ref)
"""
mutable struct Treynor{T} <: PortfolioAnalyticsSingleOutput{AssetBenchmarkReturn{T}}
    value::T
    n::Int
    beta::Beta{T}
    asset_mean::Mean
    risk_free::T

    function Treynor{T}(; risk_free::Real = zero(T)) where {T}
        new{T}(zero(T), 0, Beta{T}(), Mean(), T(risk_free))
    end
end

# Convenience constructor (default Float64)
Treynor(; T::Type = Float64, risk_free::Real = 0.0) = Treynor{T}(; risk_free=risk_free)

function OnlineStatsBase._fit!(stat::Treynor{T}, obs::AssetBenchmarkReturn) where {T}
    # Update trackers
    fit!(stat.beta, obs)
    fit!(stat.asset_mean, obs.asset)
    stat.n += 1

    # Calculate Treynor ratio
    if stat.n >= 2
        beta_val = value(stat.beta)
        mean_return = value(stat.asset_mean)
        excess_return = mean_return - stat.risk_free

        if beta_val != 0
            stat.value = T(excess_return / beta_val)
        else
            # Division by zero: return Inf or -Inf based on excess return sign
            if excess_return > 0
                stat.value = T(Inf)
            elseif excess_return < 0
                stat.value = T(-Inf)
            else
                stat.value = zero(T)
            end
        end
    else
        stat.value = zero(T)
    end

    nothing
end

function OnlineStatsBase.value(stat::Treynor)
    return stat.n < 2 ? zero(stat.value) : stat.value
end

function Base.empty!(stat::Treynor{T}) where {T}
    stat.value = zero(T)
    stat.n = 0
    empty!(stat.beta)
    stat.asset_mean = Mean()
    nothing
end

function OnlineStatsBase._merge!(stat1::Treynor, stat2::Treynor)
    # Merge the underlying stats
    merge!(stat1.beta, stat2.beta)
    merge!(stat1.asset_mean, stat2.asset_mean)
    stat1.n += stat2.n

    # Recalculate Treynor from merged stats
    if stat1.n >= 2
        beta_val = value(stat1.beta)
        mean_return = value(stat1.asset_mean)
        excess_return = mean_return - stat1.risk_free

        if beta_val != 0
            stat1.value = typeof(stat1.value)(excess_return / beta_val)
        else
            if excess_return > 0
                stat1.value = typeof(stat1.value)(Inf)
            elseif excess_return < 0
                stat1.value = typeof(stat1.value)(-Inf)
            else
                stat1.value = zero(typeof(stat1.value))
            end
        end
    end

    return stat1
end
