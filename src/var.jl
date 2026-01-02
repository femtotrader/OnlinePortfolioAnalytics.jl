# VaR - Value at Risk using online quantile estimation

using OnlineStats: Quantile

@doc """
$(TYPEDEF)

    VaR{T}(; confidence=0.95, b=500)

Calculate Value at Risk (VaR) from a stream of returns using online quantile estimation.

VaR measures the potential loss at a given confidence level. For example, a 95% VaR
of -0.05 means there is a 5% chance of losing more than 5% of the portfolio value.

# Mathematical Definition

``\\text{VaR}_\\alpha = \\text{Quantile}_{1-\\alpha}(R)``

Where:
- ``\\alpha`` = confidence level (e.g., 0.95 for 95% VaR)
- ``R`` = return distribution
- The result is the ``(1-\\alpha)`` percentile of returns

# Parameters

- `confidence`: Confidence level (default 0.95 for 95% VaR)
- `b`: Number of histogram bins for quantile estimation (default 500)

# Input Type

Accepts single return values (Number) via `fit!`.

# Edge Cases

- Returns `0.0` when no observations (n=0)

# Fields

- `value::T`: Current VaR value
- `n::Int`: Number of observations
- `quantile::Quantile`: Internal quantile tracker
- `confidence::Float64`: Confidence level

# Example

```julia
stat = VaR(confidence=0.95)
for ret in returns
    fit!(stat, ret)
end
var_95 = value(stat)  # 5th percentile loss
```

See also: [`ExpectedShortfall`](@ref)
"""
mutable struct VaR{T} <: PortfolioAnalyticsSingleOutput{T}
    value::T
    n::Int
    quantile::Quantile
    confidence::Float64

    function VaR{T}(; confidence::Float64 = 0.95, b::Int = 500) where {T}
        @assert 0 < confidence < 1 "Confidence must be between 0 and 1"
        alpha = 1 - confidence  # For 95% VaR, we want the 5th percentile
        new{T}(zero(T), 0, Quantile([alpha], b=b), confidence)
    end
end

# Convenience constructor (default Float64)
VaR(; T::Type = Float64, confidence::Float64 = 0.95, b::Int = 500) = VaR{T}(; confidence=confidence, b=b)

function OnlineStatsBase._fit!(stat::VaR{T}, ret) where {T}
    fit!(stat.quantile, ret)
    stat.n += 1
    stat.value = T(value(stat.quantile)[1])
    nothing
end

function OnlineStatsBase.value(stat::VaR)
    return stat.n == 0 ? zero(stat.value) : stat.value
end

function Base.empty!(stat::VaR{T}) where {T}
    alpha = 1 - stat.confidence
    stat.value = zero(T)
    stat.n = 0
    stat.quantile = Quantile([alpha], b=500)
    nothing
end

function OnlineStatsBase._merge!(stat1::VaR, stat2::VaR)
    # Note: OnlineStats.Quantile does not support merging
    # We accumulate the count but cannot merge the quantile estimate accurately
    # This is a limitation of the underlying algorithm
    @warn "VaR merge! is not fully supported - quantile estimates cannot be merged. Consider fitting all data to a single VaR instance." maxlog=1
    stat1.n += stat2.n
    return stat1
end
