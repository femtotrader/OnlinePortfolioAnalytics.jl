mutable struct DrawDowns{T} <: PortfolioAnalytics{T}
    value::T
    n::Int

    prod::Prod
    extrema::Extrema

    function DrawDowns{T}() where {T}
        new{T}(T(0), 0, Prod(), Extrema(T))
    end
end

function OnlineStatsBase._fit!(stat::DrawDowns, ret)
    r1 = 1 + ret
    fit!(stat.prod, r1)
    rprod = value(stat.prod)
    fit!(stat.extrema, rprod)
    stat.n += 1
    max_cumulative_returns = value(stat.extrema).max
    ddowns = (rprod / max_cumulative_returns) - 1
    stat.value = ddowns
end


mutable struct ArithmeticDrawDowns{T} <: PortfolioAnalytics{T}
    value::T
    n::Int

    sum::Sum
    extrema::Extrema

    function ArithmeticDrawDowns{T}() where {T}
        new{T}(T(0), 0, Sum(), Extrema(T))
    end
end

function OnlineStatsBase._fit!(stat::ArithmeticDrawDowns, ret)
    fit!(stat.sum, ret)
    r1 = value(stat.sum) + 1
    fit!(stat.extrema, r1)
    stat.n += 1
    max_cumulative_returns = value(stat.extrema).max
    ddowns = (r1 / max_cumulative_returns) - 1
    stat.value = ddowns
end