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
        val = (mean = zero(T), std = zero(T), skewness = zero(T), kurtosis = zero(T))
        new{T}(val, 0, Moments())
    end
end

AssetReturnMoments(; T = Float64) = AssetReturnMoments{T}()

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

function Base.empty!(stat::AssetReturnMoments{T}) where {T}
    stat.value = (mean = zero(T), std = zero(T), skewness = zero(T), kurtosis = zero(T))
    stat.n = 0
    stat.moments = Moments()
end

function expected_return_types(::Type{AssetReturnMoments{T}}) where {T}
    #return NamedTuple{
    #    (:mean, :std, :skewness, :kurtosis),
    #    Tuple{T,T,T,T},
    #}
    return (T, T, T, T)
end

function expected_return_values(::Type{AssetReturnMoments})
    return (:mean, :std, :skewness, :kurtosis)
end
