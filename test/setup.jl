@testsnippet CommonTestSetup begin
    using OnlinePortfolioAnalytics
    using OnlinePortfolioAnalytics.SampleData: dates, TSLA, NFLX, MSFT, weights
    using OnlinePortfolioAnalytics: ismultioutput, expected_return_types, expected_return_values, load!, PortfolioAnalyticsWrapper, PortfolioAnalyticsResults
    using OnlineStatsBase
    using Rocket: from, map, filter, subscribe!
    using Test
    using TSFrames
    using DataFrames
    using Dates
    using Tables

    const ATOL = 0.0001
end

@testsnippet ReferenceValidationSetup begin
    using OnlinePortfolioAnalytics
    using OnlineStatsBase
    using Test

    # Include reference values from R PerformanceAnalytics
    include(joinpath(@__DIR__, "reference_data", "r_reference_values.jl"))
    using .RReferenceValues

    # Tolerance constants for numerical comparison
    # TOL_EXACT: For deterministic calculations (exact formulas)
    # TOL_ESTIMATION: For estimation-based metrics (VaR, ES, Omega)
    # TOL_RATIO: For ratios with potentially small denominators
    const TOL_EXACT = 1e-10
    const TOL_ESTIMATION = 1e-6
    const TOL_RATIO = 1e-8

    # Helper function for relative tolerance comparison
    # Handles near-zero expected values gracefully
    function isapprox_rel(computed, expected; rtol)
        if abs(expected) < 1e-15
            # For near-zero expected values, use absolute tolerance
            return abs(computed - expected) < rtol
        end
        return abs(computed - expected) / abs(expected) < rtol
    end

    # Helper function for detailed comparison with error reporting
    function validate_against_reference(computed, expected, name; rtol=TOL_EXACT)
        passed = isapprox(computed, expected; rtol=rtol)
        if !passed
            rel_diff = abs(expected) > 1e-15 ? abs(computed - expected) / abs(expected) : abs(computed - expected)
            @warn "Validation failed for $name" computed expected rtol rel_diff
        end
        return passed
    end
end
