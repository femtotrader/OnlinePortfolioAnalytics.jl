@doc """
[`OnlinePortfolioAnalytics`](@ref) module aims to provide users with functionality for performing quantitative portfolio analytics via [online algorithms](https://en.wikipedia.org/wiki/Online_algorithm).

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
export Mean  # from OnlineStatsBase
export GeometricMeanReturn  # different from OnlineStats: GeometricMean
export StdDev
export CumulativeReturn
export DrawDowns, ArithmeticDrawDowns
export AssetReturnMoments
export Sharpe
export Sortino

export fit!, value

abstract type PortfolioAnalytics{T} <: OnlineStat{T} end
abstract type PortfolioAnalyticsSingleOutput{T} <: PortfolioAnalytics{T} end
abstract type PortfolioAnalyticsMultiOutput{T} <: PortfolioAnalytics{T} end

ismultioutput(ind::Type{O}) where {O<:PortfolioAnalytics} =
    ind <: PortfolioAnalyticsMultiOutput

include("asset_return.jl")
include("mean_return.jl")
include("cumulative_return.jl")
include("std_dev.jl")
include("drawdowns.jl")
include("moments.jl")
include("sharpe.jl")
include("sortino.jl")

include("value_at_risk.jl")

include("integrations/tables.jl")

end