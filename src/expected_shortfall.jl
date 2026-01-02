# ExpectedShortfall (CVaR) - Conditional Value at Risk

@doc """
$(TYPEDEF)

    ExpectedShortfall{T}(; confidence=0.95)

Calculate Expected Shortfall (CVaR/ES) from a stream of returns.

Expected Shortfall measures the average loss in the tail beyond the VaR threshold.
Also known as Conditional VaR (CVaR) or Average Value at Risk (AVaR).
It is considered a more coherent risk measure than VaR.

# Mathematical Definition

``\\text{ES}_\\alpha = E[R | R \\leq \\text{VaR}_\\alpha]``

Where:
- ``\\alpha`` = confidence level (e.g., 0.95 for 95% ES)
- ``R`` = return distribution
- ES is the conditional expectation of returns below VaR

# Parameters

- `confidence`: Confidence level (default 0.95 for 95% ES)

# Input Type

Accepts single return values (Number) via `fit!`.

# Edge Cases

- Returns `0.0` when no observations (n=0)
- Returns VaR value when no observations below threshold

# Fields

- `value::T`: Current ES value
- `n::Int`: Number of observations
- `sum_below::T`: Sum of returns at or below VaR threshold
- `count_below::Int`: Count of returns at or below VaR
- `var_threshold::T`: Current VaR estimate used as threshold
- `confidence::Float64`: Confidence level

# Example

```julia
stat = ExpectedShortfall(confidence=0.95)
for ret in returns
    fit!(stat, ret)
end
es_95 = value(stat)  # Average of worst 5% returns
```

See also: [`VaR`](@ref)
"""
mutable struct ExpectedShortfall{T} <: PortfolioAnalyticsSingleOutput{T}
    value::T
    n::Int
    sum_below::T
    count_below::Int
    var_tracker::VaR{T}
    confidence::Float64

    function ExpectedShortfall{T}(; confidence::Float64 = 0.95) where {T}
        @assert 0 < confidence < 1 "Confidence must be between 0 and 1"
        new{T}(zero(T), 0, zero(T), 0, VaR{T}(confidence=confidence), confidence)
    end
end

# Convenience constructor (default Float64)
ExpectedShortfall(; T::Type = Float64, confidence::Float64 = 0.95) =
    ExpectedShortfall{T}(; confidence=confidence)

function OnlineStatsBase._fit!(stat::ExpectedShortfall{T}, ret) where {T}
    stat.n += 1

    # First, fit the VaR tracker
    fit!(stat.var_tracker, ret)

    # Get current VaR threshold
    var_threshold = value(stat.var_tracker)

    # If this return is at or below the VaR threshold, include in ES calculation
    if ret <= var_threshold
        stat.sum_below += ret
        stat.count_below += 1
    end

    # Update ES value
    if stat.count_below > 0
        stat.value = T(stat.sum_below / stat.count_below)
    else
        # If no observations below threshold yet, use VaR as estimate
        stat.value = T(var_threshold)
    end

    nothing
end

function OnlineStatsBase.value(stat::ExpectedShortfall)
    return stat.n == 0 ? zero(stat.value) : stat.value
end

function Base.empty!(stat::ExpectedShortfall{T}) where {T}
    stat.value = zero(T)
    stat.n = 0
    stat.sum_below = zero(T)
    stat.count_below = 0
    empty!(stat.var_tracker)
    nothing
end

function OnlineStatsBase._merge!(stat1::ExpectedShortfall, stat2::ExpectedShortfall)
    # Merge VaR trackers (with limitation warning)
    merge!(stat1.var_tracker, stat2.var_tracker)

    # Combine counts and sums
    stat1.n += stat2.n
    stat1.sum_below += stat2.sum_below
    stat1.count_below += stat2.count_below

    # Recalculate value
    if stat1.count_below > 0
        stat1.value = typeof(stat1.value)(stat1.sum_below / stat1.count_below)
    end

    return stat1
end
