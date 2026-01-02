# Beta - Systematic risk measurement using CAPM

using OnlineStats: CovMatrix, cov, var, mean

@doc """
$(TYPEDEF)

    Beta{T}()

Calculate the beta coefficient (systematic risk) from paired asset/market returns.

Beta measures how an asset moves relative to a market benchmark. A beta of 1.0
means the asset moves with the market; beta > 1 means more volatile than market;
beta < 1 means less volatile; negative beta means inverse correlation.

# Mathematical Definition

``\\beta = \\frac{\\text{Cov}(R_a, R_m)}{\\text{Var}(R_m)}``

Where:
- ``R_a`` = asset returns
- ``R_m`` = market returns
- Cov = covariance
- Var = variance

# Input Type

Accepts [`AssetBenchmarkReturn`](@ref) observations via `fit!`.

# Edge Cases

- Returns `0.0` when fewer than 2 observations (insufficient data)
- Returns `0.0` when market variance is zero (avoid division by zero)

# Fields

- `value::T`: Current beta value
- `n::Int`: Number of observations
- `cov_matrix::CovMatrix`: Internal 2x2 covariance matrix tracker

# Example

```julia
stat = Beta()
fit!(stat, AssetBenchmarkReturn(0.05, 0.03))  # Asset +5%, Market +3%
fit!(stat, AssetBenchmarkReturn(0.02, 0.01))  # Asset +2%, Market +1%
fit!(stat, AssetBenchmarkReturn(-0.01, -0.02)) # Asset -1%, Market -2%
value(stat)  # Beta coefficient
```

See also: [`AssetBenchmarkReturn`](@ref), [`ExpectedReturn`](@ref)
"""
mutable struct Beta{T} <: PortfolioAnalyticsSingleOutput{AssetBenchmarkReturn{T}}
    value::T
    n::Int
    cov_matrix::CovMatrix

    function Beta{T}() where {T}
        new{T}(zero(T), 0, CovMatrix(2))
    end
end

# Convenience constructor (default Float64)
Beta(; T::Type = Float64) = Beta{T}()

function OnlineStatsBase._fit!(stat::Beta{T}, obs::AssetBenchmarkReturn) where {T}
    # Fit the covariance matrix with [asset, market] vector
    fit!(stat.cov_matrix, [obs.asset, obs.benchmark])
    stat.n += 1

    # Calculate beta = Cov(asset, market) / Var(market)
    if stat.n >= 2
        cov_mat = cov(stat.cov_matrix)
        market_var = cov_mat[2, 2]  # Var(market) is at [2,2]

        if market_var > 0
            covariance = cov_mat[1, 2]  # Cov(asset, market)
            stat.value = covariance / market_var
        else
            stat.value = zero(typeof(stat.value))
        end
    else
        stat.value = zero(typeof(stat.value))
    end
end

function OnlineStatsBase.value(stat::Beta)
    return stat.value
end

function Base.empty!(stat::Beta{T}) where {T}
    stat.value = zero(T)
    stat.n = 0
    stat.cov_matrix = CovMatrix(2)
end

function OnlineStatsBase._merge!(stat1::Beta, stat2::Beta)
    # Merge the underlying CovMatrix stats
    merge!(stat1.cov_matrix, stat2.cov_matrix)
    stat1.n += stat2.n

    # Recalculate beta from merged covariance matrix
    if stat1.n >= 2
        cov_mat = cov(stat1.cov_matrix)
        market_var = cov_mat[2, 2]

        if market_var > 0
            covariance = cov_mat[1, 2]
            stat1.value = covariance / market_var
        else
            stat1.value = zero(typeof(stat1.value))
        end
    end

    return stat1
end
