abstract type AssetReturn{T} <: PortfolioAnalyticsSingleOutput{T} end


@doc """
$(TYPEDEF)

    SimpleAssetReturn{T}(; period::Int = 1)

The `SimpleAssetReturn` implements asset return (simple method) calculations.

# Parameters

- `period`

# Usage

## Feed `SimpleAssetReturn` one observation at a time

    julia> using OnlinePortfolioAnalytics

    julia> ret = SimpleAssetReturn{Float64}()
    SimpleAssetReturn: n=0 | value=missing

    julia> fit!(ret, 10.0)
    SimpleAssetReturn: n=1 | value=missing

    julia> fit!(ret, 11.0)
    SimpleAssetReturn: n=2 | value=0.1

    julia> value(ret)
    0.1
"""
mutable struct SimpleAssetReturn{T} <: AssetReturn{T}
    value::Union{Missing,T}
    n::Int

    ready::Bool

    period::Int

    input_values::CircBuff

    function SimpleAssetReturn{T}(; period::Int = 1) where {T}
        input_values = CircBuff(T, period + 1, rev = false)
        new{T}(missing, 0, false, period, input_values)
    end
end

function OnlineStatsBase._fit!(stat::SimpleAssetReturn, data)
    fit!(stat.input_values, data)
    stat.n += 1
    if stat.n > stat.period
        data_prev = stat.input_values[end-stat.period]
        stat.value = (data - data_prev) / data_prev
        return stat.value
    else
        stat.ready = true
        stat.value = missing
        return stat.value
    end
end

function Base.empty!(stat::SimpleAssetReturn{T}) where {T}
    stat.value = missing
    stat.n = 0
    stat.ready = false
    stat.input_values.value = []
    stat.input_values.n = 0
end

function expected_return_types(::Type{SimpleAssetReturn{T}}) where {T}
    (Union{Missing,T},)
end


@doc """
$(TYPEDEF)

    LogAssetReturn{T}(; period::Int = 1)

The `LogAssetReturn` implements asset return (natural log method) calculations.

# Parameters

- `period`

# Usage

## Feed `LogAssetReturn` one observation at a time

    julia> using OnlinePortfolioAnalytics

    julia> ret = LogAssetReturn{Float64}()
    LogAssetReturn: n=0 | value=missing
    
    julia> fit!(ret, 10.0)
    LogAssetReturn: n=1 | value=missing
    
    julia> fit!(ret, 11.0)
    LogAssetReturn: n=2 | value=0.0953102
    
    julia> value(ret)
    0.09531017980432493
"""
mutable struct LogAssetReturn{T} <: AssetReturn{T}
    value::Union{Missing,T}
    n::Int

    ready::Bool

    period::Int

    input_values::CircBuff

    function LogAssetReturn{T}(; period::Int = 1) where {T}
        input_values = CircBuff(T, period + 1, rev = false)
        new{T}(missing, 0, false, period, input_values)
    end
end

function OnlineStatsBase._fit!(stat::LogAssetReturn, data)
    fit!(stat.input_values, data)
    stat.n += 1
    if stat.n > stat.period
        data_prev = stat.input_values[end-stat.period]
        stat.value = log(data / data_prev)  # log=ln (natural log not decimal log)
        return stat.value
    else
        stat.ready = true
        stat.value = missing
        return stat.value
    end
end

function Base.empty!(stat::LogAssetReturn{T}) where {T}
    stat.value = missing
    stat.n = 0
    stat.ready = false
    stat.input_values.value = []
    stat.input_values.n = 0
end

function expected_return_types(::Type{LogAssetReturn{T}}) where {T}
    (Union{Missing,T},)
end
