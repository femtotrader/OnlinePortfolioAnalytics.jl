# T025: AnnualVolatility tests - TDD (write tests FIRST)

@testitem "AnnualVolatility - Constructor and initial state" setup=[CommonTestSetup] begin
    stat = AnnualVolatility()
    @test stat.n == 0
    @test value(stat) == 0.0  # No observations = 0.0
    @test !ismultioutput(typeof(stat))
    @test stat isa AnnualVolatility{Float64}
    @test stat.period == 252  # Default period
end

@testitem "AnnualVolatility - Parameterized constructor" setup=[CommonTestSetup] begin
    stat = AnnualVolatility{Float32}(period=52)
    @test stat isa AnnualVolatility{Float32}
    @test stat.period == 52
    @test stat.n == 0
end

@testitem "AnnualVolatility - Basic calculation" setup=[CommonTestSetup] begin
    stat = AnnualVolatility(period=252)

    # Add some returns
    fit!(stat, 0.02)
    fit!(stat, -0.01)
    fit!(stat, 0.03)
    fit!(stat, -0.02)
    fit!(stat, 0.01)

    @test stat.n == 5
    @test value(stat) > 0.0  # Should have positive volatility
end

@testitem "AnnualVolatility - StdDev * sqrt(period)" setup=[CommonTestSetup] begin
    # Verify relationship with StdDev
    stat = AnnualVolatility(period=252)
    stddev = StdDev()

    returns = [0.01, -0.02, 0.03, -0.01, 0.02]
    for r in returns
        fit!(stat, r)
        fit!(stddev, r)
    end

    # AnnualVolatility = StdDev * sqrt(period)
    expected = value(stddev) * sqrt(252)
    @test isapprox(value(stat), expected, rtol=0.01)
end

@testitem "AnnualVolatility - Different periods" setup=[CommonTestSetup] begin
    daily = AnnualVolatility(period=252)
    weekly = AnnualVolatility(period=52)
    monthly = AnnualVolatility(period=12)

    returns = [0.01, -0.02, 0.03, -0.01, 0.02, -0.015, 0.025]
    for r in returns
        fit!(daily, r)
        fit!(weekly, r)
        fit!(monthly, r)
    end

    # All should be positive
    @test value(daily) > 0.0
    @test value(weekly) > 0.0
    @test value(monthly) > 0.0

    # Daily should be highest (sqrt(252) > sqrt(52) > sqrt(12))
    @test value(daily) > value(weekly)
    @test value(weekly) > value(monthly)
end

@testitem "AnnualVolatility - Edge case: insufficient observations" setup=[CommonTestSetup] begin
    stat = AnnualVolatility()
    fit!(stat, 0.01)

    @test stat.n == 1
    # With only 1 observation, std dev is 0 or NaN depending on implementation
    # Our implementation should return 0.0 for insufficient data
end

@testitem "AnnualVolatility - Edge case: constant returns" setup=[CommonTestSetup] begin
    stat = AnnualVolatility()

    # All same returns - zero volatility
    fit!(stat, 0.01)
    fit!(stat, 0.01)
    fit!(stat, 0.01)
    fit!(stat, 0.01)

    @test stat.n == 4
    @test value(stat) == 0.0  # No variation = zero volatility
end

@testitem "AnnualVolatility - empty! reset behavior" setup=[CommonTestSetup] begin
    stat = AnnualVolatility()
    fit!(stat, 0.02)
    fit!(stat, -0.01)

    @test stat.n > 0

    empty!(stat)

    @test stat.n == 0
    @test value(stat) == 0.0
end

@testitem "AnnualVolatility - Non-negative result" setup=[CommonTestSetup] begin
    stat = AnnualVolatility()

    # Various returns
    for r in [0.05, -0.03, 0.02, -0.08, 0.04, -0.01]
        fit!(stat, r)
    end

    @test value(stat) >= 0.0  # Volatility is always non-negative
end
