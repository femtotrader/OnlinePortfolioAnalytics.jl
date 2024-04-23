module OnlinePortfolioAnalytics

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

export fit!, value

abstract type PortfolioAnalytics{T} <: OnlineStat{T} end

include("asset_return.jl")
include("mean_return.jl")
include("cumulative_return.jl")
include("std_dev.jl")
include("drawdowns.jl")
include("moments.jl")

include("value_at_risk.jl")

end
