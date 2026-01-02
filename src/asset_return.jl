abstract type AssetReturn{T} <: PortfolioAnalyticsSingleOutput{T} end


@doc """
$(TYPEDEF)

    SimpleAssetReturn{T}(; period::Int = 1)

Calculate simple (arithmetic) returns from a stream of price observations.

Simple returns measure the percentage change in price between two periods using
the formula (P_t - P_{t-k}) / P_{t-k}, where k is the period.

# Mathematical Definition

``R_t = \\frac{P_t - P_{t-k}}{P_{t-k}}``

Where:
- ``P_t`` = price at time t
- ``P_{t-k}`` = price k periods ago
- ``k`` = period (default: 1)

# Parameters

- `period`: Number of periods for return calculation (default: 1)

# Edge Cases

- Returns `missing` until `period + 1` observations have been received
- Returns `missing` if price at t-k is zero (division by zero avoided)

# Fields

- `value::Union{Missing,T}`: Current return value
- `n::Int`: Number of observations
- `period::Int`: Return calculation period

# Example

```julia
stat = SimpleAssetReturn{Float64}()
fit!(stat, 100.0)  # First price observation
fit!(stat, 110.0)  # Second price observation
value(stat)        # Returns 0.1 (10% return)
```

See also: [`LogAssetReturn`](@ref), [`CumulativeReturn`](@ref)
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

SimpleAssetReturn(; T = Float64, period::Int = 1) = SimpleAssetReturn{T}(period = period)

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

Calculate logarithmic (continuously compounded) returns from a stream of price observations.

Log returns are additive across time periods and are commonly used in financial modeling
because they have better statistical properties than simple returns.

# Mathematical Definition

``R_t = \\ln\\left(\\frac{P_t}{P_{t-k}}\\right)``

Where:
- ``P_t`` = price at time t
- ``P_{t-k}`` = price k periods ago
- ``k`` = period (default: 1)
- ``\\ln`` = natural logarithm

# Parameters

- `period`: Number of periods for return calculation (default: 1)

# Edge Cases

- Returns `missing` until `period + 1` observations have been received
- Undefined behavior if price at t-k is zero or negative

# Fields

- `value::Union{Missing,T}`: Current return value
- `n::Int`: Number of observations
- `period::Int`: Return calculation period

# Example

```julia
stat = LogAssetReturn{Float64}()
fit!(stat, 100.0)  # First price observation
fit!(stat, 110.0)  # Second price observation
value(stat)        # Returns ~0.0953 (log return)
```

See also: [`SimpleAssetReturn`](@ref), [`CumulativeReturn`](@ref)
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

LogAssetReturn(; T = Float64, period::Int = 1) = LogAssetReturn{T}(period = period)

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
