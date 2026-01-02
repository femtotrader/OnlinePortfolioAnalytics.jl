abstract type AbstractDrawDowns{T} <: PortfolioAnalyticsSingleOutput{T} end

@doc """
$(TYPEDEF)

    DrawDowns{T}()

Calculate the current drawdown from a stream of returns using the geometric method.

Drawdown measures the percentage decline from the peak cumulative return to the
current cumulative return. This implementation uses geometric compounding where
cumulative returns are computed as the product of (1 + return).

# Mathematical Definition

For a sequence of returns r₁, r₂, ..., rₙ:
- Cumulative return at time t: ``C_t = \\prod_{i=1}^{t}(1+R_i)``
- Running peak at time t: ``P_t = \\max(C_1, C_2, ..., C_t)``
- Drawdown at time t: ``D_t = \\frac{C_t}{P_t} - 1``

# Edge Cases

- Returns `0.0` when no observations (n=0)
- Returns `0.0` at new peaks (no drawdown)
- Returns negative values during drawdown periods

# Fields

- `value::T`: Current drawdown value (negative or zero)
- `n::Int`: Number of observations
- `prod::Prod`: Internal cumulative return tracker
- `extrema::Extrema`: Internal peak tracker

# Example

```julia
stat = DrawDowns{Float64}()
fit!(stat, 0.10)   # 10% gain - new peak
fit!(stat, -0.05)  # 5% loss - in drawdown
fit!(stat, -0.03)  # 3% loss - deeper drawdown
value(stat)        # Current drawdown (negative value)
```

See also: [`ArithmeticDrawDowns`](@ref), [`MaxDrawDown`](@ref)
"""
mutable struct DrawDowns{T} <: AbstractDrawDowns{T}
    value::T
    n::Int

    prod::Prod
    extrema::Extrema

    function DrawDowns{T}() where {T}
        new{T}(zero(T), 0, Prod(T), Extrema(T))
    end
end

DrawDowns(; T = Float64) = DrawDowns{T}()

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

function Base.empty!(stat::DrawDowns{T}) where {T}
    stat.value = zero(T)
    stat.n = 0
    stat.prod = Prod(T)
    stat.extrema = Extrema(T)
end


@doc """
$(TYPEDEF)

    ArithmeticDrawDowns{T}()

Calculate the current drawdown from a stream of returns using the arithmetic method.

Drawdown measures the percentage decline from the peak cumulative return to the
current cumulative return. This implementation uses arithmetic compounding where
cumulative returns are computed as the sum of returns.

# Mathematical Definition

For a sequence of returns r₁, r₂, ..., rₙ:
- Cumulative return at time t: ``C_t = 1 + \\sum_{i=1}^{t} R_i``
- Running peak at time t: ``P_t = \\max(C_1, C_2, ..., C_t)``
- Drawdown at time t: ``D_t = \\frac{C_t}{P_t} - 1``

# Edge Cases

- Returns `0.0` when no observations (n=0)
- Returns `0.0` at new peaks (no drawdown)
- Returns negative values during drawdown periods

# Fields

- `value::T`: Current drawdown value (negative or zero)
- `n::Int`: Number of observations
- `sum::Sum`: Internal cumulative return tracker
- `extrema::Extrema`: Internal peak tracker

# Example

```julia
stat = ArithmeticDrawDowns{Float64}()
fit!(stat, 0.10)   # 10% gain - new peak
fit!(stat, -0.05)  # 5% loss - in drawdown
fit!(stat, -0.03)  # 3% loss - deeper drawdown
value(stat)        # Current drawdown (negative value)
```

See also: [`DrawDowns`](@ref), [`MaxArithmeticDrawDown`](@ref)
"""
mutable struct ArithmeticDrawDowns{T} <: AbstractDrawDowns{T}
    value::T
    n::Int

    sum::Sum
    extrema::Extrema

    function ArithmeticDrawDowns{T}() where {T}
        new{T}(zero(T), 0, Sum(), Extrema(T))
    end
end

ArithmeticDrawDowns(; T = Float64) = ArithmeticDrawDowns{T}()

function OnlineStatsBase._fit!(stat::ArithmeticDrawDowns, ret)
    fit!(stat.sum, ret)
    r1 = value(stat.sum) + 1
    fit!(stat.extrema, r1)
    stat.n += 1
    max_cumulative_returns = value(stat.extrema).max
    ddowns = (r1 / max_cumulative_returns) - 1
    stat.value = ddowns
end

function Base.empty!(stat::ArithmeticDrawDowns{T}) where {T}
    stat.value = zero(T)
    stat.n = 0
    stat.sum = Sum(T)
    stat.extrema = Extrema(T)
end
