@doc """
[`OnlinePortfolioAnalytics`](@ref) provides streaming portfolio analytics using
online algorithms that process data incrementally without storing the full history.

## Features

- **Return Calculations**: [`SimpleAssetReturn`](@ref), [`LogAssetReturn`](@ref), [`CumulativeReturn`](@ref), [`AnnualizedReturn`](@ref)
- **Mean Returns**: [`ArithmeticMeanReturn`](@ref), [`GeometricMeanReturn`](@ref)
- **Volatility**: [`StdDev`](@ref), [`DownsideDeviation`](@ref), [`UpsideDeviation`](@ref)
- **Drawdown Analysis**: [`DrawDowns`](@ref), [`ArithmeticDrawDowns`](@ref), [`MaxDrawDown`](@ref), [`MaxArithmeticDrawDown`](@ref)
- **Risk-Adjusted Returns**: [`Sharpe`](@ref), [`Sortino`](@ref), [`Calmar`](@ref), [`Omega`](@ref)
- **CAPM Metrics**: [`Beta`](@ref), [`ExpectedReturn`](@ref), [`Treynor`](@ref), [`JensenAlpha`](@ref)
- **Relative Performance**: [`TrackingError`](@ref), [`InformationRatio`](@ref)
- **Risk Metrics**: [`VaR`](@ref), [`ExpectedShortfall`](@ref)
- **Statistical Moments**: [`AssetReturnMoments`](@ref)

## Usage

All types implement the OnlineStatsBase interface:

```julia
using OnlinePortfolioAnalytics

# Create a statistic
stat = Sharpe{Float64}()

# Feed observations one at a time
for return_value in returns
    fit!(stat, return_value)
end

# Get current value
result = value(stat)
```

For metrics requiring paired asset/benchmark data, use [`AssetBenchmarkReturn`](@ref):

```julia
stat = Beta{Float64}()
fit!(stat, AssetBenchmarkReturn(0.05, 0.03))  # Asset +5%, Market +3%
value(stat)
```

---

$(LICENSE)
"""
module OnlinePortfolioAnalytics

using DocStringExtensions
using OnlineStatsBase
#using OnlineStats: GeometricMean
using Statistics
import StatsBase

export SimpleAssetReturn, LogAssetReturn
# export Mean  # from OnlineStatsBase
export ArithmeticMeanReturn, GeometricMeanReturn  # GeometricMeanReturn is different from OnlineStats: GeometricMean
export StdDev
export CumulativeReturn
export DrawDowns, ArithmeticDrawDowns
export MaxDrawDown, MaxArithmeticDrawDown
export AssetReturnMoments
export Sharpe
export Sortino
export AssetBenchmarkReturn
export AnnualizedReturn
export Calmar
export Beta
export ExpectedReturn
export VaR
export ExpectedShortfall
export TrackingError
export InformationRatio
export Treynor
export DownsideDeviation
export UpsideDeviation
export Omega
export JensenAlpha

# Phase 1: Market Capture Ratios
export UpCapture, DownCapture, UpDownCaptureRatio

# Phase 2: Extended Risk-Adjusted Ratios
export SterlingRatio, BurkeRatio, UlcerIndex, PainIndex, PainRatio

# Phase 3: Volatility & Stability Metrics
export AnnualVolatility, Stability, TailRatio

# Phase 4: Modigliani Measures
export M2, MSquaredExcess, ActivePremium

# Phase 5: Upside Potential Ratio
export UpsidePotentialRatio

# Phase 6: Rolling Window Framework
export Rolling

# Phase 7: Fundamental Statistics
export RMS

export fit!, value

abstract type PortfolioAnalytics{T} <: OnlineStat{T} end
abstract type PortfolioAnalyticsSingleOutput{T} <: PortfolioAnalytics{T} end
abstract type PortfolioAnalyticsMultiOutput{T} <: PortfolioAnalytics{T} end

function ismultioutput(ind::Type{O}) where {O<:PortfolioAnalytics}
    return ind <: PortfolioAnalyticsMultiOutput
end

function expected_return_types(ind::Type{O}) where {O<:PortfolioAnalyticsSingleOutput}
    return (ind.parameters[end],)
end

include("asset_return.jl")
include("prod.jl")
include("mean_return.jl")
include("cumulative_return.jl")
include("std_dev.jl")
include("drawdowns.jl")
include("max_drawdown.jl")
include("moments.jl")
include("sharpe.jl")
include("sortino.jl")
include("asset_benchmark_return.jl")
include("tracking_error.jl")
include("information_ratio.jl")
include("annualized_return.jl")
include("calmar.jl")
include("beta.jl")
include("treynor.jl")
include("expected_return.jl")
include("var.jl")
include("expected_shortfall.jl")
include("downside_deviation.jl")
include("upside_deviation.jl")
include("omega.jl")
include("jensen_alpha.jl")

# Phase 1: Market Capture Ratios
include("up_capture.jl")
include("down_capture.jl")
include("up_down_capture_ratio.jl")

# Fundamental Statistics (required by UlcerIndex)
include("rms.jl")

# Phase 2: Extended Risk-Adjusted Ratios
include("ulcer_index.jl")
include("pain_index.jl")
include("sterling_ratio.jl")
include("burke_ratio.jl")
include("pain_ratio.jl")

# Phase 3: Volatility & Stability Metrics
include("annual_volatility.jl")
include("stability.jl")
include("tail_ratio.jl")

# Phase 4: Modigliani Measures
include("m2.jl")
include("m_squared_excess.jl")
include("active_premium.jl")

# Phase 5: Upside Potential Ratio
include("upside_potential_ratio.jl")

# Phase 6: Rolling Window Framework
include("rolling.jl")

include("integrations/tables.jl")

include("sample_data.jl")

end
