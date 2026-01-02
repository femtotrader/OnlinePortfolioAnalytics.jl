# AssetMarketReturn - Wrapper type for paired (asset, market) return observations

@doc """
$(TYPEDEF)

    AssetMarketReturn{T<:Real}(asset, market)

Wrapper type for paired (asset, market) return observations.
Used as input for [`Beta`](@ref) and [`ExpectedReturn`](@ref) statistics.

# Fields

- `asset::T`: Asset return for this observation
- `market::T`: Market/benchmark return for this observation

# Example

```julia
obs = AssetMarketReturn(0.05, 0.03)  # 5% asset return, 3% market return
fit!(beta_stat, obs)
```

See also: [`Beta`](@ref), [`ExpectedReturn`](@ref)
"""
struct AssetMarketReturn{T<:Real}
    asset::T
    market::T
end

# Convenience constructor with type promotion
AssetMarketReturn(asset, market) = AssetMarketReturn(promote(asset, market)...)
