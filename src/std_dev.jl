@doc """
$(TYPEDEF)

    StdDev{T}()

Calculate the sample standard deviation of returns from a stream of observations.

Standard deviation measures the volatility or dispersion of returns around the mean.
It is a fundamental risk measure in portfolio analysis.

# Mathematical Definition

``\\sigma = \\sqrt{\\frac{1}{n-1}\\sum_{i=1}^{n}(R_i - \\bar{R})^2}``

Where:
- ``R_i`` = return for period i
- ``\\bar{R}`` = mean return
- ``n`` = number of observations

# Edge Cases

- Returns `1.0` when no observations (initial value)
- Returns `0.0` when only one observation (no variance)

# Fields

- `value::T`: Current standard deviation
- `n::Int`: Number of observations
- `variance::Variance`: Internal variance tracker

# Example

```julia
stat = StdDev{Float64}()
fit!(stat, 0.05)   # 5% return
fit!(stat, -0.02)  # -2% return
fit!(stat, 0.03)   # 3% return
value(stat)        # Standard deviation of returns
```

See also: [`ArithmeticMeanReturn`](@ref), [`Sharpe`](@ref)
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

StdDev(; T = Float64) = StdDev{T}()

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
