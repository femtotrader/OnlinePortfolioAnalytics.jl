# Rolling - Generic rolling window wrapper for any OnlineStat

# Use OnlineStatsBase's CircBuff instead of DataStructures' CircularBuffer
using OnlineStatsBase: CircBuff

# Helper to extract the element type from parameterized stat types
_stat_eltype(::Type{S}) where {T, S<:OnlineStat{T}} = T
_stat_eltype(stat::OnlineStat) = _stat_eltype(typeof(stat))

# For our PortfolioAnalytics types, extract the type parameter directly
_stat_eltype(::Type{PA}) where {T, PA<:PortfolioAnalyticsSingleOutput{T}} = T

@doc """
$(TYPEDEF)

    Rolling(stat; window)

Wrap any OnlineStat to compute rolling window statistics.

The Rolling wrapper maintains a circular buffer of observations and recomputes
the wrapped statistic over only the most recent `window` observations. This enables
streaming computation of rolling metrics like rolling Sharpe ratio or rolling drawdown.

# Parameters

- `stat`: Any OnlineStat to wrap (e.g., `Sharpe{Float64}()`, `MaxDrawDown{Float64}()`)
- `window`: Size of the rolling window (must be > 0)

# Implementation Details

When a new observation arrives:
1. Add it to the circular buffer
2. If buffer exceeds window size, the oldest observation is automatically removed
3. Reset the wrapped stat and refit with all buffer contents

# Edge Cases

- Before window is full: Computes on available observations (partial window)
- After window is full: Computes on exactly `window` most recent observations

# Fields

$(FIELDS)

# Example

```julia
# Rolling 60-period Sharpe ratio
rolling_sharpe = Rolling(Sharpe{Float64}(), window=60)
for ret in daily_returns
    fit!(rolling_sharpe, ret)
    println("60-day rolling Sharpe: ", value(rolling_sharpe))
end

# Rolling 30-period max drawdown
rolling_dd = Rolling(MaxDrawDown{Float64}(), window=30)
for ret in returns
    fit!(rolling_dd, ret)
end
```

See also: [`Sharpe`](@ref), [`MaxDrawDown`](@ref), [`Calmar`](@ref)
"""
mutable struct Rolling{T,S<:OnlineStat} <: OnlineStat{T}
    "The wrapped OnlineStat"
    stat::S
    "Circular buffer storing observations (OnlineStatsBase.CircBuff)"
    buffer::CircBuff{T,false}
    "Rolling window size"
    window::Int
    "Total observations seen"
    n::Int

    function Rolling(stat::S; window::Int) where {S<:OnlineStat}
        window > 0 || throw(ArgumentError("window must be > 0, got $window"))
        T = _stat_eltype(stat)
        new{T,S}(stat, CircBuff(T, window), window, 0)
    end
end

function OnlineStatsBase._fit!(rolling::Rolling{T}, obs) where {T}
    # Add observation to circular buffer using fit!
    fit!(rolling.buffer, T(obs))
    rolling.n += 1

    # Reset the wrapped stat
    empty!(rolling.stat)

    # Refit with all observations in the buffer (value() returns properly ordered values)
    for buffered_obs in value(rolling.buffer)
        fit!(rolling.stat, buffered_obs)
    end
end

function OnlineStatsBase.value(rolling::Rolling)
    return value(rolling.stat)
end

function Base.empty!(rolling::Rolling{T}) where {T}
    empty!(rolling.stat)
    # CircBuff doesn't have empty!, recreate it
    rolling.buffer = CircBuff(T, rolling.window)
    rolling.n = 0
end

# Get the element type from the wrapped stat
function Base.eltype(::Type{Rolling{T,S}}) where {T,S}
    return T
end

function Base.eltype(::Rolling{T}) where {T}
    return T
end
