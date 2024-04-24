"""
[`OnlinePortfolioAnalytics`](@ref) module aims to provide users with functionality for performing quantitative portfolio analytics via [online algorithms](https://en.wikipedia.org/wiki/Online_algorithm).

[`EXPORTS`](@ref)
$(EXPORTS)

[`IMPORTS`](@ref)
$(IMPORTS)

---

$(README)

---

The [`LICENSE`](@ref) abbreviation can be used in the same way for the `LICENSE.md` file.
"""
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
export Sharpe
export Sortino

export fit!, value

abstract type PortfolioAnalytics{T} <: OnlineStat{T} end

include("asset_return.jl")
include("mean_return.jl")
include("cumulative_return.jl")
include("std_dev.jl")
include("drawdowns.jl")
include("moments.jl")
include("sharpe.jl")
include("sortino.jl")

include("value_at_risk.jl")

end
