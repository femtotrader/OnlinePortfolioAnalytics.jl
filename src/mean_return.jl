abstract type AbstractMeanReturn{T} <: PortfolioAnalyticsSingleOutput{T} end

@doc """
$(TYPEDEF)

    ArithmeticMeanReturn{T}()

The `ArithmeticMeanReturn` type implements arithmetic mean returns calculations.
"""
mutable struct ArithmeticMeanReturn{T} <: AbstractMeanReturn{T}
    value::T
    n::Int

    sum::Sum

    function ArithmeticMeanReturn{T}() where {T}
        s = Sum()
        new{T}(zero(T), 0, s)
    end
end

ArithmeticMeanReturn(; T = Float64) = ArithmeticMeanReturn{T}()

function OnlineStatsBase._fit!(stat::ArithmeticMeanReturn, data)
    fit!(stat.sum, data)
    stat.n += 1
    stat.value = value(stat.sum) / stat.n
end


@doc """
$(TYPEDEF)

    GeometricMeanReturn{T}()

The `GeometricMeanReturn` type implements geometric mean returns calculations.
"""
mutable struct GeometricMeanReturn{T} <: AbstractMeanReturn{T}
    value::T
    n::Int

    prod::Prod

    function GeometricMeanReturn{T}() where {T}
        p = Prod(T)
        new{T}(zero(T), 0, p)
    end
end

GeometricMeanReturn(; T = Float64) = GeometricMeanReturn{T}()

function OnlineStatsBase._fit!(stat::GeometricMeanReturn, data)
    fit!(stat.prod, 1 + data)
    stat.n += 1
    stat.value = value(stat.prod)^(1 / stat.n) - 1
end
