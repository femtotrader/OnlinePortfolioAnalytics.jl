@doc """
    WIP
"""
mutable struct Sharpe{T} <: PortfolioAnalytics{T}
    value::T
    n::Int
    
    mean::Mean
    stddev::StdDev

    period::Int
    risk_free::T

    function Sharpe{T}(; period=252, risk_free=0) where {T}
        new{T}(T(0), 0, Mean(), StdDev{T}(), period, risk_free)
    end
end

function OnlineStatsBase._fit!(stat::Sharpe, data)
    fit!(stat.mean, data)
    fit!(stat.stddev, data)
    stat.n += 1
    mean_return = value(stat.mean)
    std_dev = value(stat.stddev)
    sharpe = sqrt(stat.period) * (mean_return - stat.risk_free) / std_dev
    stat.value = sharpe
end
