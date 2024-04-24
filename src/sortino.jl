@doc """
    WIP
"""
mutable struct Sortino{T} <: PortfolioAnalytics{T}
    value::T
    n::Int
    
    mean_ret::Mean
    stddev_neg_ret::StdDev

    period::Int
    risk_free::T

    function Sortino{T}(; period=252, risk_free=0) where {T}
        new{T}(T(0), 0, Mean(), StdDev{T}(), period, risk_free)
    end
end

function OnlineStatsBase._fit!(stat::Sortino, ret)
    fit!(stat.mean_ret, ret)
    if ret < 0
        fit!(stat.stddev_neg_ret, ret)
    end
    stat.n += 1
    mean_return = value(stat.mean_ret)
    stddev_neg_return = value(stat.stddev_neg_ret)
    sortino = sqrt(stat.period) * (mean_return - stat.risk_free) / stddev_neg_return
    stat.value = sortino
end
