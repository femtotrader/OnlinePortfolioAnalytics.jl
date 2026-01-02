# UpDownCaptureRatio - Ratio of up capture to down capture

@doc """
$(TYPEDEF)

    UpDownCaptureRatio{T}()

Calculate the up/down capture ratio from paired asset/benchmark returns.

The up/down capture ratio measures the asymmetry of portfolio performance relative
to the benchmark across market conditions. A ratio > 1.0 indicates favorable
asymmetry (captures more upside, less downside).

# Mathematical Definition

``\\text{UpDownCaptureRatio} = \\frac{\\text{UpCapture}}{\\text{DownCapture}}``

Where:
- [`UpCapture`](@ref) = geometric mean ratio of returns in up markets
- [`DownCapture`](@ref) = geometric mean ratio of returns in down markets

# Input Type

Accepts [`AssetBenchmarkReturn`](@ref) observations via `fit!`.

# Edge Cases

- Returns `NaN` when either up capture or down capture is `NaN`
- Returns `Inf` if down capture is zero (undefined in practice)
- Returns `NaN` with no observations

# Interpretation

- Ratio > 1.0: Favorable asymmetry (desirable)
  - Portfolio captures more upside and/or less downside
- Ratio = 1.0: Symmetric performance
- Ratio < 1.0: Unfavorable asymmetry
  - Portfolio captures less upside and/or more downside

# Fields

$(FIELDS)

# Example

```julia
stat = UpDownCaptureRatio()
fit!(stat, AssetBenchmarkReturn(0.06, 0.04))   # Up market
fit!(stat, AssetBenchmarkReturn(-0.01, -0.03)) # Down market
fit!(stat, AssetBenchmarkReturn(0.03, 0.02))   # Up market
fit!(stat, AssetBenchmarkReturn(-0.02, -0.04)) # Down market
value(stat)  # Up/Down ratio (> 1.0 means favorable asymmetry)
```

See also: [`UpCapture`](@ref), [`DownCapture`](@ref), [`AssetBenchmarkReturn`](@ref)
"""
mutable struct UpDownCaptureRatio{T} <: PortfolioAnalyticsSingleOutput{AssetBenchmarkReturn{T}}
    "Current up/down capture ratio value"
    value::T
    "Total number of observations"
    n::Int
    "Internal up capture tracker"
    up_capture::UpCapture{T}
    "Internal down capture tracker"
    down_capture::DownCapture{T}

    function UpDownCaptureRatio{T}() where {T}
        new{T}(T(NaN), 0, UpCapture{T}(), DownCapture{T}())
    end
end

# Convenience constructor (default Float64)
UpDownCaptureRatio(; T::Type = Float64) = UpDownCaptureRatio{T}()

function OnlineStatsBase._fit!(stat::UpDownCaptureRatio{T}, obs::AssetBenchmarkReturn) where {T}
    stat.n += 1

    # Delegate to internal trackers
    fit!(stat.up_capture, obs)
    fit!(stat.down_capture, obs)

    # Calculate ratio
    up_val = value(stat.up_capture)
    down_val = value(stat.down_capture)

    if isnan(up_val) || isnan(down_val)
        stat.value = T(NaN)
    elseif down_val == 0
        stat.value = T(Inf)
    else
        stat.value = up_val / down_val
    end
end

function OnlineStatsBase.value(stat::UpDownCaptureRatio)
    return stat.value
end

function Base.empty!(stat::UpDownCaptureRatio{T}) where {T}
    stat.value = T(NaN)
    stat.n = 0
    empty!(stat.up_capture)
    empty!(stat.down_capture)
end
