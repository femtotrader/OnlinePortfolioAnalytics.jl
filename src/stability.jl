# Stability - R-squared of cumulative log returns

@doc """
$(TYPEDEF)

    Stability{T}()

Calculate stability as the R-squared of a linear regression of cumulative log returns.

Stability measures how consistently returns grow over time. A stability of 1.0 indicates
perfectly linear growth (constant returns), while lower values indicate more erratic growth.

# Mathematical Definition

Stability is the coefficient of determination (R²) from regressing cumulative log returns
on the observation index:

``R^2 = 1 - \\frac{SS_{res}}{SS_{tot}}``

Where we track cumulative log returns: ``y_i = \\sum_{j=1}^{i} \\log(1 + r_j)``

And regress against time index ``x_i = i``.

# Edge Cases

- Returns `0.0` when fewer than 2 observations (cannot compute regression)
- Returns values in [0, 1] for valid regressions

# Fields

$(FIELDS)

# Example

```julia
stat = Stability()
for _ in 1:20
    fit!(stat, 0.01)  # Consistent 1% return
end
value(stat)  # Should be close to 1.0 (highly stable)
```

See also: [`AnnualizedReturn`](@ref)
"""
mutable struct Stability{T} <: PortfolioAnalyticsSingleOutput{T}
    "Current R-squared value"
    value::T
    "Number of observations"
    n::Int
    "Sum of x (time indices)"
    sum_x::T
    "Sum of x squared"
    sum_x2::T
    "Sum of y (cumulative log returns)"
    sum_y::T
    "Sum of y squared"
    sum_y2::T
    "Sum of x*y"
    sum_xy::T
    "Current cumulative log return"
    cum_log_return::T

    function Stability{T}() where {T}
        new{T}(zero(T), 0, zero(T), zero(T), zero(T), zero(T), zero(T), zero(T))
    end
end

# Convenience constructor (default Float64)
Stability(; T::Type = Float64) = Stability{T}()

function OnlineStatsBase._fit!(stat::Stability{T}, ret) where {T}
    stat.n += 1
    x = T(stat.n)  # Time index

    # Update cumulative log return
    stat.cum_log_return += log(1 + ret)
    y = stat.cum_log_return

    # Update sufficient statistics for linear regression
    stat.sum_x += x
    stat.sum_x2 += x * x
    stat.sum_y += y
    stat.sum_y2 += y * y
    stat.sum_xy += x * y

    # Calculate R-squared if we have enough data
    if stat.n >= 2
        n = T(stat.n)

        # Linear regression formulas
        # slope = (n*sum_xy - sum_x*sum_y) / (n*sum_x2 - sum_x^2)
        # R² = (n*sum_xy - sum_x*sum_y)² / ((n*sum_x2 - sum_x²) * (n*sum_y2 - sum_y²))

        ss_xx = n * stat.sum_x2 - stat.sum_x^2
        ss_yy = n * stat.sum_y2 - stat.sum_y^2
        ss_xy = n * stat.sum_xy - stat.sum_x * stat.sum_y

        if ss_xx > 0 && ss_yy > 0
            stat.value = (ss_xy^2) / (ss_xx * ss_yy)
            # Clamp to [0, 1] to handle numerical precision issues
            stat.value = clamp(stat.value, zero(T), one(T))
        else
            stat.value = zero(T)
        end
    else
        stat.value = zero(T)
    end
end

function OnlineStatsBase.value(stat::Stability)
    return stat.value
end

function Base.empty!(stat::Stability{T}) where {T}
    stat.value = zero(T)
    stat.n = 0
    stat.sum_x = zero(T)
    stat.sum_x2 = zero(T)
    stat.sum_y = zero(T)
    stat.sum_y2 = zero(T)
    stat.sum_xy = zero(T)
    stat.cum_log_return = zero(T)
end
