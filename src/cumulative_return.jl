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
        p = Prod()
        new{T}(val, 0, p)
    end
end

function OnlineStatsBase._fit!(stat::CumulativeReturn, data)
    fit!(stat.prod, 1 + data)
    stat.n += 1
    stat.value = value(stat.prod)
end
