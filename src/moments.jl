@doc """
$(TYPEDEF)

    AssetReturnMoments{T}()

The `AssetReturnMoments` type implements 4 first statistical moments (`mean`, `std`, `skewness`, `kurtosis`) calculations.
"""
mutable struct AssetReturnMoments{T} <: PortfolioAnalyticsMultiOutput{T}
    value::NamedTuple
    n::Int

    moments::Moments

    function AssetReturnMoments{T}() where {T}
        val = (mean = T(0), std = T(0), skewness = T(0), kurtosis = T(0))
        new{T}(val, 0, Moments())
    end
end

function OnlineStatsBase._fit!(stat::AssetReturnMoments, ret)
    stat.n += 1
    fit!(stat.moments, ret)
    stat.value = (
        mean = Statistics.mean(stat.moments),
        std = Statistics.std(stat.moments),
        skewness = StatsBase.skewness(stat.moments),
        kurtosis = StatsBase.kurtosis(stat.moments),
    )
end
