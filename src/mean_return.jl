"""
    Prod(T::Type = Float64)

Track the overall product.
"""
mutable struct Prod{T} <: OnlineStat{Number}
    prod::T
    n::Int
end
Prod(T::Type = Float64) = Prod(T(1), 0)
Base.prod(o::Prod) = o.prod
OnlineStatsBase._fit!(o::Prod{T}, x::Real) where {T<:AbstractFloat} =
    (o.prod *= convert(T, x); o.n += 1)
OnlineStatsBase._fit!(o::Prod{T}, x::Real) where {T<:Integer} =
    (o.prod *= round(T, x); o.n += 1)
OnlineStatsBase._fit!(o::Prod{T}, x::Real, n) where {T<:AbstractFloat} =
    (o.prod *= convert(T, x * n); o.n += n)
OnlineStatsBase._fit!(o::Prod{T}, x::Real, n) where {T<:Integer} =
    (o.prod *= round(T, x * n); o.n += n)
OnlineStatsBase._merge!(o::T, o2::T) where {T<:Prod} = (o.prod *= o2.prod; o.n += o2.n; o)

# https://github.com/joshday/OnlineStatsBase.jl/issues/41

@doc """
$(TYPEDEF)

    GeometricMeanReturn{T}()

The `GeometricMeanReturn` type implements geometric mean returns calculations.
"""
mutable struct GeometricMeanReturn{T} <: PortfolioAnalyticsSingleOutput{T}
    value::T
    n::Int

    prod::Prod

    function GeometricMeanReturn{T}() where {T}
        p = Prod()
        new{T}(T(0), 0, p)
    end
end

function OnlineStatsBase._fit!(stat::GeometricMeanReturn, data)
    fit!(stat.prod, 1 + data)
    stat.n += 1
    stat.value = value(stat.prod)^(1 / stat.n) - 1
end
