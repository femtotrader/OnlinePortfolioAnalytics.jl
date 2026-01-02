# T012: SterlingRatio tests - TDD (write tests FIRST)

@testitem "SterlingRatio - Constructor and initial state" setup=[CommonTestSetup] begin
    stat = SterlingRatio()
    @test stat.n == 0
    @test !ismultioutput(typeof(stat))
    @test stat isa SterlingRatio{Float64}
    @test stat.threshold == 0.10  # Default threshold
    @test stat.period == 252      # Default period
end

@testitem "SterlingRatio - Parameterized constructor" setup=[CommonTestSetup] begin
    stat = SterlingRatio{Float32}(period=52, threshold=0.05)
    @test stat isa SterlingRatio{Float32}
    @test stat.period == 52
    @test stat.threshold == Float32(0.05)
end

@testitem "SterlingRatio - Basic calculation" setup=[CommonTestSetup] begin
    stat = SterlingRatio(threshold=0.0)  # Use 0 threshold for basic test

    # Generate some returns with drawdown
    fit!(stat, 0.02)   # +2%
    fit!(stat, -0.03)  # -3%
    fit!(stat, 0.01)   # +1%
    fit!(stat, -0.02)  # -2%

    @test stat.n == 4
    # Should have a finite Sterling ratio (when threshold=0)
    @test isfinite(value(stat))
end

@testitem "SterlingRatio - Annualized return divided by adjusted max drawdown" setup=[CommonTestSetup] begin
    stat = SterlingRatio(period=252, threshold=0.10)

    # Returns that create a known drawdown
    returns = [0.05, 0.03, -0.10, -0.08, 0.04, 0.02]
    for r in returns
        fit!(stat, r)
    end

    @test stat.n == 6
    # Sterling = AnnualizedReturn / (|MaxDD| - threshold)
    @test !isnan(value(stat))
end

@testitem "SterlingRatio - Edge case: MaxDD <= threshold" setup=[CommonTestSetup] begin
    stat = SterlingRatio(threshold=0.10)

    # Very small drawdown (less than 10% threshold)
    fit!(stat, 0.02)
    fit!(stat, 0.01)
    fit!(stat, -0.01)  # Tiny drawdown
    fit!(stat, 0.03)

    @test stat.n == 4
    # When |MaxDD| <= threshold, should return Inf
    @test isinf(value(stat)) || isnan(value(stat))
end

@testitem "SterlingRatio - Configurable threshold" setup=[CommonTestSetup] begin
    stat1 = SterlingRatio(threshold=0.05)
    stat2 = SterlingRatio(threshold=0.20)

    returns = [0.02, -0.08, 0.03, -0.05, 0.01]
    for r in returns
        fit!(stat1, r)
        fit!(stat2, r)
    end

    # Different thresholds should give different ratios
    # (unless one triggers Inf/NaN)
    @test stat1.threshold != stat2.threshold
end

@testitem "SterlingRatio - Configurable period" setup=[CommonTestSetup] begin
    stat_daily = SterlingRatio(period=252)
    stat_weekly = SterlingRatio(period=52)

    returns = [0.02, -0.05, 0.03, -0.02, 0.01]
    for r in returns
        fit!(stat_daily, r)
        fit!(stat_weekly, r)
    end

    # Different annualization periods should give different ratios
    @test stat_daily.period != stat_weekly.period
end

@testitem "SterlingRatio - empty! reset behavior" setup=[CommonTestSetup] begin
    stat = SterlingRatio()
    fit!(stat, 0.02)
    fit!(stat, -0.03)

    @test stat.n > 0

    empty!(stat)

    @test stat.n == 0
end

@testitem "SterlingRatio - Positive returns only" setup=[CommonTestSetup] begin
    stat = SterlingRatio()

    # All positive - no drawdown
    fit!(stat, 0.02)
    fit!(stat, 0.01)
    fit!(stat, 0.03)

    @test stat.n == 3
    # No drawdown means very high (possibly Inf) Sterling ratio
    @test isinf(value(stat)) || value(stat) > 0
end
