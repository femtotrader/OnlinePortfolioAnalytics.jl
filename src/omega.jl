# Omega Ratio - Probability-weighted gain/loss ratio

@doc """
$(TYPEDEF)

    Omega{T}(; threshold=0.0)

Calculate Omega Ratio from a stream of returns.

Omega Ratio measures the probability-weighted ratio of gains to losses above/below
a threshold. It considers the entire return distribution, not just mean and variance.

# Mathematical Definition

``\\Omega(\\tau) = \\frac{\\sum_{R_i > \\tau} (R_i - \\tau)}{\\sum_{R_i < \\tau} (\\tau - R_i)}``

Where:
- ``R_i`` = return for period i
- ``\\tau`` = threshold (typically 0)

# Parameters

- `threshold`: Reference threshold (default 0.0)

# Input Type

Accepts single return values (Number) via `fit!`.

# Edge Cases

- Returns `0.0` when no observations (n=0)
- Returns `Inf` when no losses (all returns above threshold)
- Returns `0.0` when no gains (all returns below threshold)

# Fields

- `value::T`: Current Omega ratio
- `n::Int`: Observation count
- `sum_gains::T`: Sum of returns above threshold
- `sum_losses::T`: Sum of absolute shortfall below threshold
- `threshold::T`: Reference threshold

# Example

```julia
stat = Omega(threshold=0.0)
for ret in returns
    fit!(stat, ret)
end
omega = value(stat)  # sum(gains) / sum(losses)
```

See also: [`Sharpe`](@ref), [`Sortino`](@ref)
"""
mutable struct Omega{T} <: PortfolioAnalyticsSingleOutput{T}
    value::T
    n::Int
    sum_gains::T
    sum_losses::T
    threshold::T

    function Omega{T}(; threshold::Real = zero(T)) where {T}
        new{T}(zero(T), 0, zero(T), zero(T), T(threshold))
    end
end

# Convenience constructor (default Float64)
Omega(; T::Type = Float64, threshold::Real = 0.0) = Omega{T}(; threshold=threshold)

function OnlineStatsBase._fit!(stat::Omega{T}, ret) where {T}
    stat.n += 1

    if ret > stat.threshold
        # Gain: return above threshold
        stat.sum_gains += (ret - stat.threshold)
    elseif ret < stat.threshold
        # Loss: return below threshold (store as positive value)
        stat.sum_losses += (stat.threshold - ret)
    end
    # If ret == threshold, it contributes to neither

    # Calculate Omega ratio
    if stat.sum_losses > 0
        stat.value = T(stat.sum_gains / stat.sum_losses)
    elseif stat.sum_gains > 0
        stat.value = T(Inf)  # All gains, no losses
    else
        stat.value = zero(T)  # No gains or no observations
    end

    nothing
end

function OnlineStatsBase.value(stat::Omega)
    return stat.n == 0 ? zero(stat.value) : stat.value
end

function Base.empty!(stat::Omega{T}) where {T}
    stat.value = zero(T)
    stat.n = 0
    stat.sum_gains = zero(T)
    stat.sum_losses = zero(T)
    nothing
end

function OnlineStatsBase._merge!(stat1::Omega, stat2::Omega)
    stat1.n += stat2.n
    stat1.sum_gains += stat2.sum_gains
    stat1.sum_losses += stat2.sum_losses

    # Recalculate value
    if stat1.sum_losses > 0
        stat1.value = typeof(stat1.value)(stat1.sum_gains / stat1.sum_losses)
    elseif stat1.sum_gains > 0
        stat1.value = typeof(stat1.value)(Inf)
    else
        stat1.value = zero(typeof(stat1.value))
    end

    return stat1
end
