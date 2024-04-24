@doc """
    WIP
"""
mutable struct SimpleAssetReturn{T} <: PortfolioAnalytics{T}
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

@doc """

$(TYPEDEF)

---

$(FIELDS)

---

$(TYPEDFIELDS)
"""
mutable struct LogAssetReturn{T} <: PortfolioAnalytics{T}
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
        stat.value = log(data / data_prev)  # log=ln (Neperian log not decimal log)
        return stat.value
    else
        stat.ready = true
        stat.value = missing
        return stat.value
    end
end
