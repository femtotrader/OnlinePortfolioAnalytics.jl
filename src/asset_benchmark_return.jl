# AssetBenchmarkReturn - Wrapper type for paired (asset, benchmark) return observations

@doc """
$(TYPEDEF)

    AssetBenchmarkReturn{T<:Real}(asset, benchmark)

Wrapper type for paired (asset, benchmark) return observations.

Used as input for relative performance metrics (e.g., [`TrackingError`](@ref), [`InformationRatio`](@ref))
and CAPM-based metrics (e.g., [`Beta`](@ref), [`ExpectedReturn`](@ref), [`Treynor`](@ref), [`JensenAlpha`](@ref)).

The benchmark can be any reference portfolio or market index depending on the analysis context.

# Fields

- `asset::T`: Asset/portfolio return for this observation
- `benchmark::T`: Benchmark/market return for this observation

# Example

```julia
obs = AssetBenchmarkReturn(0.05, 0.03)  # 5% asset return, 3% benchmark return
fit!(beta_stat, obs)
fit!(tracking_error_stat, obs)
```

See also: [`Beta`](@ref), [`ExpectedReturn`](@ref), [`Treynor`](@ref), [`JensenAlpha`](@ref), [`TrackingError`](@ref), [`InformationRatio`](@ref)
"""
struct AssetBenchmarkReturn{T<:Real}
    asset::T
    benchmark::T
end

# Convenience constructor with type promotion
AssetBenchmarkReturn(asset, benchmark) = AssetBenchmarkReturn(promote(asset, benchmark)...)
