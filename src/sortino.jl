const SORTINO_PERIOD = 252  # Daily

@doc """
$(TYPEDEF)

    Sortino{T}(; period=252, risk_free=0)

Calculate the Sortino ratio from a stream of periodic returns.

The Sortino ratio is similar to the Sharpe ratio but uses only downside deviation
(volatility of negative returns) in the denominator, making it more appropriate
for asymmetric return distributions.

# Mathematical Definition

``So = \\sqrt{T} \\times \\frac{E[R] - r_f}{\\sigma_{down}}``

Where:
- ``E[R]`` = expected (mean) return
- ``r_f`` = risk-free rate
- ``\\sigma_{down}`` = standard deviation of negative returns only
- ``T`` = annualization period

# Parameters

- `period`: Annualization factor (default: 252)
  - Daily: 252 (trading days per year)
  - Weekly: 52
  - Monthly: 12
  - Hourly: 252 × 6.5
- `risk_free`: Risk-free rate per period (default: 0)

# Edge Cases

- Returns `NaN` or `Inf` when downside deviation is zero (no negative returns)
- Returns `0.0` when no observations

# Fields

- `value::T`: Current Sortino ratio
- `n::Int`: Number of observations
- `mean_ret::Mean`: Internal mean return tracker
- `stddev_neg_ret::StdDev`: Internal downside deviation tracker
- `period::Int`: Annualization factor
- `risk_free::T`: Risk-free rate

# Example

```julia
stat = Sortino{Float64}(period=252, risk_free=0.0)
fit!(stat, 0.02)   # 2% return (positive, not included in downside)
fit!(stat, -0.01)  # -1% return (negative, included in downside)
fit!(stat, 0.03)   # 3% return
value(stat)        # Annualized Sortino ratio
```

See also: [`Sharpe`](@ref), [`DownsideDeviation`](@ref), [`Calmar`](@ref)
"""
mutable struct Sortino{T} <: PortfolioAnalyticsSingleOutput{T}
    value::T
    n::Int

    mean_ret::Mean
    stddev_neg_ret::StdDev

    period::Int
    risk_free::T

    function Sortino{T}(; period = SORTINO_PERIOD, risk_free = zero(T)) where {T}
        new{T}(zero(T), 0, Mean(), StdDev{T}(), period, risk_free)
    end
end

Sortino(; T = Float64, period::Int = SORTINO_PERIOD, risk_free = zero(T)) = Sortino{T}(period = period, risk_free = risk_free)

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

function Base.empty!(stat::Sortino{T}) where {T}
    stat.value = zero(T)
    stat.n = 0
    stat.mean_ret = Mean(T)
    stat.stddev_neg_ret = StdDev{T}()
end
