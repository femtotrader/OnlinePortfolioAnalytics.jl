@doc """
$(TYPEDEF)

    Sharpe{T}(; period=252, risk_free=0)

The `Sharpe` type implements sharpe ratio calculations.

# Parameters

- `period`: default is `252`. Daily (`252`), Hourly (`252*6.5`), Minutely(`252*6.5*60`) etc...
- `risk_free`: default is `0`. Constant risk-free return throughout the period.
"""
mutable struct Sharpe{T} <: PortfolioAnalyticsSingleOutput{T}
    value::T
    n::Int

    mean::Mean
    stddev::StdDev

    period::Int
    risk_free::T

    function Sharpe{T}(; period = 252, risk_free = 0) where {T}
        new{T}(zero(T), 0, Mean(T), StdDev{T}(), period, risk_free)
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

function Base.empty!(stat::Sharpe{T}) where {T}
    stat.value = zero(T)
    stat.n = 0
    stat.mean = Mean(T)
    stat.stddev = StdDev{T}()
end
