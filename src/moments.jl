@doc """
$(TYPEDEF)

    AssetReturnMoments{T}()

Calculate the first four statistical moments of returns from a stream of observations.

This type computes mean, standard deviation, skewness, and kurtosis simultaneously,
providing a complete statistical profile of the return distribution. The output
is a NamedTuple with fields `:mean`, `:std`, `:skewness`, and `:kurtosis`.

# Mathematical Definition

- Mean: ``\\bar{R} = \\frac{1}{n}\\sum_{i=1}^{n} R_i``
- Standard deviation: ``\\sigma = \\sqrt{\\frac{1}{n-1}\\sum_{i=1}^{n}(R_i - \\bar{R})^2}``
- Skewness: ``\\gamma_1 = \\frac{\\frac{1}{n}\\sum_{i=1}^{n}(R_i - \\bar{R})^3}{\\sigma^3}``
- Kurtosis: ``\\gamma_2 = \\frac{\\frac{1}{n}\\sum_{i=1}^{n}(R_i - \\bar{R})^4}{\\sigma^4} - 3`` (excess kurtosis)

# Edge Cases

- Returns `(mean=0.0, std=0.0, skewness=0.0, kurtosis=0.0)` when no observations
- Skewness and kurtosis require at least 3-4 observations for meaningful values

# Fields

- `value::NamedTuple`: Current moments as (mean, std, skewness, kurtosis)
- `n::Int`: Number of observations
- `moments::Moments`: Internal moments tracker

# Example

```julia
stat = AssetReturnMoments{Float64}()
fit!(stat, 0.05)
fit!(stat, -0.02)
fit!(stat, 0.03)
fit!(stat, -0.01)
m = value(stat)
m.mean      # Mean return
m.std       # Standard deviation
m.skewness  # Skewness
m.kurtosis  # Excess kurtosis
```

See also: [`ArithmeticMeanReturn`](@ref), [`StdDev`](@ref)
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
