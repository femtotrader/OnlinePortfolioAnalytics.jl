@doc """
$(TYPEDEF)

    StdDev{T}()

The `StdDev` type implements standard deviation calculations.
"""
mutable struct StdDev{T} <: PortfolioAnalyticsSingleOutput{T}
    value::T
    n::Int

    variance::Variance

    function StdDev{T}() where {T}
        variance = Variance(T)
        new{T}(one(T), 0, variance)
    end
end

function OnlineStatsBase._fit!(stat::StdDev, data)
    fit!(stat.variance, data)
    stat.n += 1
    stat.value = sqrt(value(stat.variance))
end

function Base.empty!(stat::StdDev{T}) where {T}
    stat.value = one(T)
    stat.n = 0
    stat.variance = Variance(T)
end
