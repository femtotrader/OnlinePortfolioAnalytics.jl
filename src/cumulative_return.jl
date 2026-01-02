@doc """
$(TYPEDEF)

    CumulativeReturn{T}()

Calculate the cumulative (total) return from a stream of periodic returns.

Cumulative return represents the total growth factor of an investment over
the entire observation period using geometric compounding.

# Mathematical Definition

``C = \\prod_{i=1}^{n}(1+R_i)``

Where:
- ``R_i`` = return for period i
- ``n`` = number of observations

Note: The value represents the growth factor, not the percentage return.
Subtract 1 to get the percentage cumulative return.

# Edge Cases

- Returns `0.0` when no observations (n=0)
- Returns the running product as observations are added

# Fields

- `value::T`: Current cumulative growth factor
- `n::Int`: Number of observations
- `prod::Prod`: Internal product tracker

# Example

```julia
stat = CumulativeReturn{Float64}()
fit!(stat, 0.10)   # 10% return
fit!(stat, -0.05)  # -5% return
fit!(stat, 0.03)   # 3% return
value(stat)        # Cumulative growth factor (e.g., 1.0785)
# Percentage return: value(stat) - 1 = 0.0785 (7.85%)
```

See also: [`AnnualizedReturn`](@ref), [`DrawDowns`](@ref), [`GeometricMeanReturn`](@ref)
"""
mutable struct CumulativeReturn{T} <: PortfolioAnalyticsSingleOutput{T}
    value::T
    n::Int

    prod::Prod

    function CumulativeReturn{T}() where {T}
        val = zero(T)
        p = Prod(T)
        new{T}(val, 0, p)
    end
end

CumulativeReturn(; T = Float64) = CumulativeReturn{T}()

function OnlineStatsBase._fit!(stat::CumulativeReturn, data)
    fit!(stat.prod, 1 + data)
    stat.n += 1
    stat.value = value(stat.prod)
end

function Base.empty!(stat::CumulativeReturn{T}) where {T}
    stat.value = zero(T)
    stat.n = 0
    stat.prod = Prod(T)
end
