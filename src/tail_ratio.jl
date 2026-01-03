# TailRatio - Ratio of 95th to 5th percentile

@doc """
$(TYPEDEF)

    TailRatio{T}(; b=500)

Calculate the tail ratio as the ratio of the 95th percentile to the absolute value
of the 5th percentile of returns.

Tail ratio measures the symmetry of return distribution tails:
- Ratio > 1.0: Fatter right tail (larger gains than losses at extremes)
- Ratio ≈ 1.0: Symmetric tails
- Ratio < 1.0: Fatter left tail (larger losses than gains at extremes)

# Mathematical Definition

``\\text{Tail Ratio} = \\frac{\\text{Percentile}_{95}(R)}{|\\text{Percentile}_{5}(R)|}``

Where:
- ``\\text{Percentile}_{95}(R)`` = 95th percentile of returns
- ``\\text{Percentile}_{5}(R)`` = 5th percentile of returns

# Parameters

- `b`: Number of histogram bins for quantile estimation (default 500)

# Edge Cases

- Returns `Inf` if 5th percentile is zero
- May return `NaN` with insufficient data

# Fields

$(FIELDS)

# Example

```julia
stat = TailRatio()
for r in returns
    fit!(stat, r)
end
ratio = value(stat)  # > 1.0 means fatter right tail
```

See also: [`VaR`](@ref), [`ExpectedShortfall`](@ref)
"""
mutable struct TailRatio{T} <: PortfolioAnalyticsSingleOutput{T}
    "Current tail ratio value"
    value::T
    "Number of observations"
    n::Int
    "Internal quantile tracker for 5th and 95th percentiles"
    quantile::Quantile

    function TailRatio{T}(; b::Int = 500) where {T}
        new{T}(zero(T), 0, Quantile([0.05, 0.95], b=b))
    end
end

# Convenience constructor (default Float64)
TailRatio(; T::Type = Float64, b::Int = 500) = TailRatio{T}(b=b)

function OnlineStatsBase._fit!(stat::TailRatio{T}, ret) where {T}
    fit!(stat.quantile, ret)
    stat.n += 1

    # Get quantile values: [5th percentile, 95th percentile]
    q_vals = value(stat.quantile)
    p5 = q_vals[1]   # 5th percentile
    p95 = q_vals[2]  # 95th percentile

    # Tail ratio = 95th percentile / |5th percentile|
    abs_p5 = abs(p5)
    if abs_p5 > 0
        stat.value = T(p95 / abs_p5)
    else
        # If 5th percentile is 0, ratio is Inf (or undefined)
        stat.value = T(Inf)
    end
end

function OnlineStatsBase.value(stat::TailRatio)
    return stat.value
end

function Base.empty!(stat::TailRatio{T}) where {T}
    stat.value = zero(T)
    stat.n = 0
    stat.quantile = Quantile([0.05, 0.95], b=500)
end
