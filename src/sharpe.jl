const SHARPE_PERIOD = 252  # Daily

@doc """
$(TYPEDEF)

    Sharpe{T}(; period=252, risk_free=0)

Calculate the Sharpe ratio from a stream of periodic returns.

The Sharpe ratio measures risk-adjusted performance by dividing excess return
(above risk-free rate) by volatility. Higher values indicate better risk-adjusted returns.

# Mathematical Definition

``S = \\sqrt{T} \\times \\frac{E[R] - r_f}{\\sigma}``

Where:
- ``E[R]`` = expected (mean) return
- ``r_f`` = risk-free rate
- ``\\sigma`` = standard deviation of returns
- ``T`` = annualization period

# Parameters

- `period`: Annualization factor (default: 252)
  - Daily: 252 (trading days per year)
  - Weekly: 52
  - Monthly: 12
  - Hourly: 252 × 6.5
- `risk_free`: Risk-free rate per period (default: 0)

# Edge Cases

- Returns `NaN` when standard deviation is zero (all returns identical)
- Returns `0.0` when no observations

# Fields

- `value::T`: Current Sharpe ratio
- `n::Int`: Number of observations
- `mean::Mean`: Internal mean tracker
- `stddev::StdDev`: Internal standard deviation tracker
- `period::Int`: Annualization factor
- `risk_free::T`: Risk-free rate

# Example

```julia
stat = Sharpe{Float64}(period=252, risk_free=0.0)
fit!(stat, 0.02)   # 2% return
fit!(stat, -0.01)  # -1% return
fit!(stat, 0.03)   # 3% return
value(stat)        # Annualized Sharpe ratio
```

See also: [`Sortino`](@ref), [`Treynor`](@ref), [`Omega`](@ref)
"""
mutable struct Sharpe{T} <: PortfolioAnalyticsSingleOutput{T}
    value::T
    n::Int

    mean::Mean
    stddev::StdDev

    period::Int
    risk_free::T

    function Sharpe{T}(; period = SHARPE_PERIOD, risk_free = zero(T)) where {T}
        new{T}(zero(T), 0, Mean(T), StdDev{T}(), period, risk_free)
    end
end

Sharpe(; T = Float64, period::Int = SHARPE_PERIOD, risk_free = zero(T)) = Sharpe{T}(period = period, risk_free = risk_free)

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
