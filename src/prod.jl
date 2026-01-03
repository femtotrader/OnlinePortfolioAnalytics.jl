@doc """
$(TYPEDEF)

    Prod(T::Type = Float64)

Streaming product accumulator that computes the running product of observations.

# Mathematical Definition

``P = \\prod_{i=1}^{n} x_i``

Where:
- ``x_i`` = observation for period i
- ``n`` = number of observations

For weighted observations with weight ``w``:
``P = P \\cdot x^w``

This represents "fitting x with multiplicity w" - equivalent to fitting x exactly w times.

# Fields

- `prod::T`: Current accumulated product value
- `n::Int`: Number of observations (or total accumulated weight)

# Initial State

- `prod = one(T)` (multiplicative identity)
- `n = 0`

# Edge Cases

- Empty stat: `value(stat) == one(T)`, `nobs(stat) == 0`
- Zero input: Product becomes and stays zero
- For `T<:Integer`: inputs are rounded before multiplication

# Example

```julia
stat = Prod(Float64)
fit!(stat, 2.0)
fit!(stat, 3.0)
fit!(stat, 4.0)
value(stat)  # => 24.0
nobs(stat)   # => 3

# Weighted fit (x^w semantics)
stat2 = Prod(Float64)
fit!(stat2, 2.0, 3)  # 2^3 = 8
value(stat2)  # => 8.0
```

See also: [`LogProd`](@ref), [`CumulativeReturn`](@ref), [`GeometricMeanReturn`](@ref)
"""
mutable struct Prod{T} <: OnlineStat{Number}
    prod::T
    n::Int
end
Prod(T::Type = Float64) = Prod(one(T), 0)

# T002: Add OnlineStatsBase.value for canonical interface
OnlineStatsBase.value(o::Prod) = o.prod

# Keep Base.prod for backward compatibility
Base.prod(o::Prod) = o.prod
OnlineStatsBase._fit!(o::Prod{T}, x::Real) where {T<:AbstractFloat} =
    (o.prod *= convert(T, x); o.n += 1)
OnlineStatsBase._fit!(o::Prod{T}, x::Real) where {T<:Integer} =
    (o.prod *= round(T, x); o.n += 1)
# T015-T017: Fixed weighted _fit! to use x^w semantics (not x*w)
# Weight w represents multiplicity: fit!(stat, x, w) ≡ fitting x exactly w times
# Mathematically: prod(x,x,x) = x^3, so fit!(stat, x, 3) yields x^3
OnlineStatsBase._fit!(o::Prod{T}, x::Real, w) where {T<:AbstractFloat} =
    (o.prod *= convert(T, x)^w; o.n += w)
OnlineStatsBase._fit!(o::Prod{T}, x::Real, w) where {T<:Integer} =
    (o.prod *= round(T, x^w); o.n += w)
OnlineStatsBase._merge!(o::T, o2::T) where {T<:Prod} = (o.prod *= o2.prod; o.n += o2.n; o)

# T022: Implement Base.empty! for Prod
# Resets to initial state: prod = one(T), n = 0
function Base.empty!(o::Prod{T}) where {T}
    o.prod = one(T)
    o.n = 0
    return o
end

# ============================================================================
# LogProd: Numerically stable product accumulator (operates in log-space)
# ============================================================================

@doc """
$(TYPEDEF)

    LogProd(T::Type = Float64)

Numerically stable streaming product accumulator that operates in log-space.

For products of many values (>100), standard multiplication can overflow (`Inf`)
or underflow (`0.0`). `LogProd` avoids this by accumulating `log(x)` values
and returning `exp(sum_of_logs)`.

# Mathematical Definition

``P = \\prod_{i=1}^{n} x_i = \\exp\\left(\\sum_{i=1}^{n} \\log(x_i)\\right)``

For weighted observations:
``P = P \\cdot x^w = \\exp(\\text{log\\_sum} + w \\cdot \\log(x))``

# Fields

- `log_sum::T`: Sum of logarithms of observed values
- `n::Int`: Number of observations (or total accumulated weight)

# Initial State

- `log_sum = zero(T)`
- `n = 0`
- `value(stat) == 1.0` (since `exp(0) = 1`)

# Edge Cases

- Empty stat: `value(stat) == 1.0`, `nobs(stat) == 0`
- Zero input (`x = 0`): `log(0) = -Inf`, so `value(stat) == 0.0`
- Negative input (`x < 0`): `log(x)` returns `NaN` (undefined in real domain)
- For very large products: stays finite when `Prod` would overflow

# Example

```julia
# Standard Prod overflows
prod_stat = Prod(Float64)
for _ in 1:10000
    fit!(prod_stat, 1.001)
end
value(prod_stat)  # => Inf (overflow!)

# LogProd stays stable
log_stat = LogProd(Float64)
for _ in 1:10000
    fit!(log_stat, 1.001)
end
value(log_stat)  # => 21916.68... (finite and correct)
```

See also: [`Prod`](@ref)
"""
mutable struct LogProd{T} <: OnlineStat{Number}
    log_sum::T
    n::Int
end

# T038: LogProd constructor
LogProd(T::Type = Float64) = LogProd(zero(T), 0)

# T039: value returns exp(log_sum)
OnlineStatsBase.value(o::LogProd) = exp(o.log_sum)

# T040: Unweighted _fit! accumulates log(x)
OnlineStatsBase._fit!(o::LogProd{T}, x::Real) where {T} =
    (o.log_sum += convert(T, log(x)); o.n += 1)

# T041: Weighted _fit! accumulates w * log(x) = log(x^w)
OnlineStatsBase._fit!(o::LogProd{T}, x::Real, w) where {T} =
    (o.log_sum += convert(T, w * log(x)); o.n += w)

# T042: Merge sums log_sums (since log(a*b) = log(a) + log(b))
OnlineStatsBase._merge!(o::T, o2::T) where {T<:LogProd} = (o.log_sum += o2.log_sum; o.n += o2.n; o)

# T043: Implement Base.empty! for LogProd
function Base.empty!(o::LogProd{T}) where {T}
    o.log_sum = zero(T)
    o.n = 0
    return o
end

# https://github.com/joshday/OnlineStatsBase.jl/issues/41
