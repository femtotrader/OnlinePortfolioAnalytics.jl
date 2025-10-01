@doc """
$(TYPEDEF)

    CumulativeReturn{T}()

The `CumulativeReturn` type implements cumulative return calculations.
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
