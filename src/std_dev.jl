mutable struct StdDev{T} <: PortfolioAnalysis{T}
    value::T
    n::Int

    variance::Variance

    function StdDev{T}() where {T}
        variance = Variance()
        new{T}(1, 0, variance)
    end
end

function OnlineStatsBase._fit!(stat::StdDev, data)
    fit!(stat.variance, data)
    stat.n += 1
    stat.value = sqrt(value(stat.variance))
end
