# AnnualizedReturn - CAGR (Compound Annual Growth Rate) calculation

const ANNUALIZED_RETURN_PERIOD = 252  # Daily trading days

@doc """
$(TYPEDEF)

    AnnualizedReturn{T}(; period=252)

Calculate annualized return (CAGR - Compound Annual Growth Rate) from a stream of
periodic returns using geometric compounding.

# Mathematical Definition

For a sequence of returns r₁, r₂, ..., rₙ:
- Cumulative return: C = ∏ᵢ₌₁ⁿ (1 + rᵢ)
- Annualized return: (C)^(period/n) - 1

This is equivalent to the CAGR (Compound Annual Growth Rate) formula.

# Parameters

- `period`: Annualization factor (default 252 for daily returns)
  - Daily: 252 (trading days per year)
  - Weekly: 52
  - Monthly: 12
  - Hourly: 252 × 6.5

# Fields

- `value::T`: Current annualized return
- `n::Int`: Number of observations
- `prod::Prod{T}`: Internal product tracker for cumulative return
- `period::Int`: Annualization factor

# Example

```julia
stat = AnnualizedReturn()
fit!(stat, 0.01)   # 1% daily return
fit!(stat, 0.02)   # 2% daily return
fit!(stat, -0.01)  # -1% daily return
value(stat)        # Annualized return
```

See also: [`Calmar`](@ref), [`CumulativeReturn`](@ref)
"""
mutable struct AnnualizedReturn{T} <: PortfolioAnalyticsSingleOutput{T}
    value::T
    n::Int
    prod::Prod{T}
    period::Int

    function AnnualizedReturn{T}(; period::Int = ANNUALIZED_RETURN_PERIOD) where {T}
        new{T}(zero(T), 0, Prod(T), period)
    end
end

# Convenience constructor (default Float64)
AnnualizedReturn(; T::Type = Float64, period::Int = ANNUALIZED_RETURN_PERIOD) =
    AnnualizedReturn{T}(period = period)

function OnlineStatsBase._fit!(stat::AnnualizedReturn, ret)
    # Update cumulative product: prod *= (1 + ret)
    fit!(stat.prod, 1 + ret)
    stat.n += 1

    # Calculate annualized return using CAGR formula
    if stat.n > 0
        cumulative_factor = prod(stat.prod)  # ∏(1 + rᵢ)
        exponent = stat.period / stat.n
        stat.value = cumulative_factor^exponent - 1
    end
end

function OnlineStatsBase.value(stat::AnnualizedReturn)
    return stat.value
end

function Base.empty!(stat::AnnualizedReturn{T}) where {T}
    stat.value = zero(T)
    stat.n = 0
    stat.prod = Prod(T)
end
