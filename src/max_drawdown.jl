# Maximum Drawdown Statistics
# Tracks the worst (most negative) peak-to-trough decline in a streaming fashion

"""
Abstract supertype for maximum drawdown statistics.
Subtypes: MaxDrawDown (geometric), MaxArithmeticDrawDown (arithmetic)
"""
abstract type AbstractMaxDrawDown{T} <: PortfolioAnalyticsSingleOutput{T} end


@doc """
$(TYPEDEF)

    MaxDrawDown{T}()

Track the maximum (worst) peak-to-trough decline using geometric return compounding.

Maximum drawdown is the largest percentage decline from a cumulative return peak
to a subsequent trough. This implementation uses the geometric method where
cumulative returns are computed as the product of (1 + return).

The `value` returns the most negative drawdown observed, following industry
convention where "maximum drawdown" refers to the largest decline magnitude.

# Mathematical Definition

For a sequence of returns r₁, r₂, ..., rₙ:
- Cumulative return at time t: Cₜ = ∏ᵢ₌₁ᵗ (1 + rᵢ)
- Running peak at time t: Pₜ = max(C₁, C₂, ..., Cₜ)
- Drawdown at time t: Dₜ = Cₜ / Pₜ - 1
- Maximum drawdown: min(D₁, D₂, ..., Dₙ)

# Example

```julia
stat = MaxDrawDown{Float64}()
fit!(stat, 0.10)   # 10% gain
fit!(stat, -0.05)  # 5% loss
fit!(stat, -0.15)  # 15% loss
value(stat)        # Returns most negative drawdown observed (e.g., -0.19)
```

# References

- empyrical (Python): max_drawdown() returns negative value
- PerformanceAnalytics (R): maxDrawdown() returns positive magnitude

See also: [`MaxArithmeticDrawDown`](@ref), [`DrawDowns`](@ref)
"""
mutable struct MaxDrawDown{T} <: AbstractMaxDrawDown{T}
    value::T
    n::Int
    drawdowns::DrawDowns{T}
    max_dd_extrema::Extrema{T}

    function MaxDrawDown{T}() where {T}
        new{T}(zero(T), 0, DrawDowns{T}(), Extrema(T))
    end
end

# Convenience constructor (default Float64)
MaxDrawDown() = MaxDrawDown{Float64}()

function OnlineStatsBase._fit!(stat::MaxDrawDown, ret)
    # Update the internal drawdowns tracker
    fit!(stat.drawdowns, ret)

    # Get current drawdown value
    current_dd = value(stat.drawdowns)

    # Track the extrema of drawdown values (we want the minimum = most negative)
    fit!(stat.max_dd_extrema, current_dd)

    stat.n += 1

    # Maximum drawdown is the minimum (most negative) drawdown observed
    stat.value = value(stat.max_dd_extrema).min
end

function OnlineStatsBase.value(stat::MaxDrawDown)
    return stat.value
end

function Base.empty!(stat::MaxDrawDown{T}) where {T}
    stat.value = zero(T)
    stat.n = 0
    empty!(stat.drawdowns)
    stat.max_dd_extrema = Extrema(T)
end


@doc """
$(TYPEDEF)

    MaxArithmeticDrawDown{T}()

Track the maximum (worst) peak-to-trough decline using arithmetic return compounding.

This implementation uses the arithmetic method where cumulative returns are
computed as the sum of returns, suitable for simple (non-compounding) returns.

The `value` returns the most negative drawdown observed, following industry
convention where "maximum drawdown" refers to the largest decline magnitude.

# Mathematical Definition

For a sequence of returns r₁, r₂, ..., rₙ:
- Cumulative return at time t: Cₜ = 1 + Σᵢ₌₁ᵗ rᵢ
- Running peak at time t: Pₜ = max(C₁, C₂, ..., Cₜ)
- Drawdown at time t: Dₜ = Cₜ / Pₜ - 1
- Maximum drawdown: min(D₁, D₂, ..., Dₙ)

# Example

```julia
stat = MaxArithmeticDrawDown{Float64}()
fit!(stat, 0.10)   # 10% gain
fit!(stat, -0.05)  # 5% loss
value(stat)        # Returns most negative drawdown observed
```

See also: [`MaxDrawDown`](@ref), [`ArithmeticDrawDowns`](@ref)
"""
mutable struct MaxArithmeticDrawDown{T} <: AbstractMaxDrawDown{T}
    value::T
    n::Int
    drawdowns::ArithmeticDrawDowns{T}
    max_dd_extrema::Extrema{T}

    function MaxArithmeticDrawDown{T}() where {T}
        new{T}(zero(T), 0, ArithmeticDrawDowns{T}(), Extrema(T))
    end
end

# Convenience constructor (default Float64)
MaxArithmeticDrawDown() = MaxArithmeticDrawDown{Float64}()

function OnlineStatsBase._fit!(stat::MaxArithmeticDrawDown, ret)
    # Update the internal drawdowns tracker (arithmetic method)
    fit!(stat.drawdowns, ret)

    # Get current drawdown value
    current_dd = value(stat.drawdowns)

    # Track the extrema of drawdown values (we want the minimum = most negative)
    fit!(stat.max_dd_extrema, current_dd)

    stat.n += 1

    # Maximum drawdown is the minimum (most negative) drawdown observed
    stat.value = value(stat.max_dd_extrema).min
end

function OnlineStatsBase.value(stat::MaxArithmeticDrawDown)
    return stat.value
end

function Base.empty!(stat::MaxArithmeticDrawDown{T}) where {T}
    stat.value = zero(T)
    stat.n = 0
    empty!(stat.drawdowns)
    stat.max_dd_extrema = Extrema(T)
end


# Merge support for parallel computation
# Note: Merging max drawdown stats is an approximation. The true maximum drawdown
# across partitions could span the boundary between partitions, which cannot be
# perfectly computed without the full sequence. This implementation takes the
# minimum (worst) of the two partition max drawdowns, which is a conservative
# lower bound (the true max drawdown could be even worse).

function OnlineStatsBase.merge!(stat1::MaxDrawDown, stat2::MaxDrawDown)
    # Take the minimum (most negative) of both max drawdowns
    stat1.value = min(stat1.value, stat2.value)
    stat1.n += stat2.n

    # Merge the extrema tracker (tracks min/max of drawdown values)
    merge!(stat1.max_dd_extrema, stat2.max_dd_extrema)

    # Note: We don't merge drawdowns because DrawDowns doesn't support merge!
    # The max_dd_extrema contains the critical information we need

    return stat1
end

function OnlineStatsBase.merge!(stat1::MaxArithmeticDrawDown, stat2::MaxArithmeticDrawDown)
    # Take the minimum (most negative) of both max drawdowns
    stat1.value = min(stat1.value, stat2.value)
    stat1.n += stat2.n

    # Merge the extrema tracker (tracks min/max of drawdown values)
    merge!(stat1.max_dd_extrema, stat2.max_dd_extrema)

    # Note: We don't merge drawdowns because ArithmeticDrawDowns doesn't support merge!
    # The max_dd_extrema contains the critical information we need

    return stat1
end

