# UpsidePotentialRatio - Upside potential relative to downside deviation

@doc """
$(TYPEDEF)

    UpsidePotentialRatio{T}(; mar=0.0)

Calculate the Upside Potential Ratio from a stream of returns.

The Upside Potential Ratio measures the ratio of expected positive deviation above
a Minimum Acceptable Return (MAR) to the downside deviation below that threshold.
It captures the asymmetry between upside gains and downside losses.

# Mathematical Definition

``\\text{UPR} = \\frac{E[\\max(R - MAR, 0)]}{\\text{DownsideDeviation}}``

Where:
- ``R`` = return
- ``MAR`` = Minimum Acceptable Return (threshold)
- Upside Potential = ``\\frac{1}{n} \\sum_{i=1}^{n} \\max(R_i - MAR, 0)``
- Downside Deviation = ``\\sqrt{\\frac{1}{n} \\sum_{i=1}^{n} \\min(R_i - MAR, 0)^2}``

# Interpretation

- UPR > 1: Upside potential exceeds downside risk (favorable)
- UPR = 1: Upside potential equals downside risk
- UPR < 1: Downside risk exceeds upside potential (unfavorable)
- UPR = Inf: No downside (all returns above MAR)
- UPR = 0: No upside (all returns below MAR)

# Parameters

- `mar`: Minimum Acceptable Return threshold (default 0.0)

# Fields

$(FIELDS)

# Example

```julia
stat = UpsidePotentialRatio(mar=0.0)
fit!(stat, 0.10)   # +10% return
fit!(stat, -0.03)  # -3% return
fit!(stat, 0.05)   # +5% return
value(stat)  # Upside potential / downside deviation
```

See also: [`DownsideDeviation`](@ref), [`UpsideDeviation`](@ref), [`Sortino`](@ref)
"""
mutable struct UpsidePotentialRatio{T} <: PortfolioAnalyticsSingleOutput{T}
    "Current Upside Potential Ratio value"
    value::T
    "Number of observations"
    n::Int
    "Sum of positive deviations from MAR"
    sum_upside::T
    "Internal downside deviation tracker"
    downside_deviation::DownsideDeviation{T}
    "Minimum Acceptable Return threshold"
    mar::T

    function UpsidePotentialRatio{T}(; mar::Real = zero(T)) where {T}
        new{T}(zero(T), 0, zero(T), DownsideDeviation{T}(threshold = T(mar)), T(mar))
    end
end

# Convenience constructor (default Float64)
UpsidePotentialRatio(; T::Type = Float64, mar::Real = 0.0) =
    UpsidePotentialRatio{T}(mar = T(mar))

function OnlineStatsBase._fit!(stat::UpsidePotentialRatio{T}, ret) where {T}
    stat.n += 1

    # Track upside potential
    upside = max(ret - stat.mar, zero(T))
    stat.sum_upside += upside

    # Update downside deviation
    fit!(stat.downside_deviation, ret)

    # Calculate ratio: upside potential / downside deviation
    upside_potential = stat.sum_upside / stat.n
    dd = value(stat.downside_deviation)

    if dd > 0
        stat.value = upside_potential / dd
    elseif upside_potential > 0
        stat.value = T(Inf)  # No downside, positive upside
    else
        stat.value = zero(T)  # No upside, no downside
    end
end

function OnlineStatsBase.value(stat::UpsidePotentialRatio)
    return stat.value
end

function Base.empty!(stat::UpsidePotentialRatio{T}) where {T}
    stat.value = zero(T)
    stat.n = 0
    stat.sum_upside = zero(T)
    empty!(stat.downside_deviation)
end
