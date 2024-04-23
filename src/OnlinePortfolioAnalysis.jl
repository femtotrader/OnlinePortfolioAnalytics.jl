module OnlinePortfolioAnalysis

using OnlineStatsBase

export SimpleAssetReturn
export LogAssetReturn
export StdDev

export fit!, value

abstract type PortfolioAnalysis{T} <: OnlineStat{T} end

include("asset_return.jl")
include("std_dev.jl")

include("value_at_risk.jl")

end
