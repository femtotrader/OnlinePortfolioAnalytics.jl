abstract type AbstractMeanReturn{T} <: PortfolioAnalyticsSingleOutput{T} end

@doc """
$(TYPEDEF)

    ArithmeticMeanReturn{T}()

Calculate the arithmetic mean of returns from a stream of observations.

The arithmetic mean is the simple average of all returns. It is commonly used
for short-term performance analysis but can overestimate long-term growth.

# Mathematical Definition

``\\bar{R} = \\frac{1}{n}\\sum_{i=1}^{n} R_i``

Where:
- ``R_i`` = return for period i
- ``n`` = number of observations

# Edge Cases

- Returns `0.0` when no observations (n=0)

# Fields

- `value::T`: Current mean return
- `n::Int`: Number of observations
- `sum::Sum`: Internal sum tracker

# Example

```julia
stat = ArithmeticMeanReturn{Float64}()
fit!(stat, 0.05)   # 5% return
fit!(stat, -0.02)  # -2% return
fit!(stat, 0.03)   # 3% return
value(stat)        # Returns 0.02 (2% average)
```

See also: [`GeometricMeanReturn`](@ref), [`StdDev`](@ref)
"""
mutable struct ArithmeticMeanReturn{T} <: AbstractMeanReturn{T}
    value::T
    n::Int

    sum::Sum

    function ArithmeticMeanReturn{T}() where {T}
        s = Sum()
        new{T}(zero(T), 0, s)
    end
end

ArithmeticMeanReturn(; T = Float64) = ArithmeticMeanReturn{T}()

function OnlineStatsBase._fit!(stat::ArithmeticMeanReturn, data)
    fit!(stat.sum, data)
    stat.n += 1
    stat.value = value(stat.sum) / stat.n
end


@doc """
$(TYPEDEF)

    GeometricMeanReturn{T}()

Calculate the geometric mean of returns from a stream of observations.

The geometric mean accounts for compounding and provides a better measure of
long-term average return than arithmetic mean. It represents the constant
return rate that would produce the same final value.

# Mathematical Definition

``G = \\left(\\prod_{i=1}^{n}(1+R_i)\\right)^{1/n} - 1``

Where:
- ``R_i`` = return for period i
- ``n`` = number of observations

# Edge Cases

- Returns `0.0` when no observations (n=0)
- Returns `-1.0` if cumulative product becomes zero

# Fields

- `value::T`: Current geometric mean return
- `n::Int`: Number of observations
- `prod::Prod`: Internal product tracker

# Example

```julia
stat = GeometricMeanReturn{Float64}()
fit!(stat, 0.10)   # 10% return
fit!(stat, -0.05)  # -5% return
fit!(stat, 0.08)   # 8% return
value(stat)        # Geometric mean return
```

See also: [`ArithmeticMeanReturn`](@ref), [`CumulativeReturn`](@ref)
"""
mutable struct GeometricMeanReturn{T} <: AbstractMeanReturn{T}
    value::T
    n::Int

    prod::Prod

    function GeometricMeanReturn{T}() where {T}
        p = Prod(T)
        new{T}(zero(T), 0, p)
    end
end

GeometricMeanReturn(; T = Float64) = GeometricMeanReturn{T}()

function OnlineStatsBase._fit!(stat::GeometricMeanReturn, data)
    fit!(stat.prod, 1 + data)
    stat.n += 1
    stat.value = value(stat.prod)^(1 / stat.n) - 1
end
