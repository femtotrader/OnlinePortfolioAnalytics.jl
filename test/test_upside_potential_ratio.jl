# T043: UpsidePotentialRatio tests - TDD (write tests FIRST)

@testitem "UpsidePotentialRatio - Constructor and initial state" setup=[CommonTestSetup] begin
    stat = UpsidePotentialRatio()
    @test stat.n == 0
    @test !ismultioutput(typeof(stat))
    @test stat isa UpsidePotentialRatio{Float64}
    @test stat.mar == 0.0  # Default MAR
end

@testitem "UpsidePotentialRatio - Parameterized constructor" setup=[CommonTestSetup] begin
    stat = UpsidePotentialRatio{Float32}(mar=0.05)
    @test stat isa UpsidePotentialRatio{Float32}
    @test stat.mar == Float32(0.05)
    @test stat.n == 0
end

@testitem "UpsidePotentialRatio - Basic calculation" setup=[CommonTestSetup] begin
    stat = UpsidePotentialRatio(mar=0.0)

    # Mix of positive and negative returns
    fit!(stat, 0.05)   # Above MAR
    fit!(stat, -0.03)  # Below MAR
    fit!(stat, 0.02)   # Above MAR
    fit!(stat, -0.01)  # Below MAR
    fit!(stat, 0.03)   # Above MAR

    @test stat.n == 5
    @test isfinite(value(stat))
    @test value(stat) > 0.0  # Positive upside potential
end

@testitem "UpsidePotentialRatio - Formula verification" setup=[CommonTestSetup] begin
    stat = UpsidePotentialRatio(mar=0.0)

    returns = [0.10, 0.05, -0.03, 0.08, -0.02, 0.04]
    for r in returns
        fit!(stat, r)
    end

    @test stat.n == 6

    # Manual calculation
    # Upside potential: E[max(R - MAR, 0)] = mean of positive parts
    upside = [max(r - 0.0, 0) for r in returns]
    upside_potential = sum(upside) / length(returns)

    # Downside deviation: sqrt(mean of squared negative deviations)
    downside_sq = [min(r - 0.0, 0)^2 for r in returns]
    downside_dev = sqrt(sum(downside_sq) / length(returns))

    expected = upside_potential / downside_dev

    @test isapprox(value(stat), expected, atol=ATOL)
end

@testitem "UpsidePotentialRatio - Different MAR values" setup=[CommonTestSetup] begin
    stat_mar0 = UpsidePotentialRatio(mar=0.0)
    stat_mar2 = UpsidePotentialRatio(mar=0.02)
    stat_mar5 = UpsidePotentialRatio(mar=0.05)

    returns = [0.10, 0.05, -0.03, 0.08, -0.02, 0.04]
    for r in returns
        fit!(stat_mar0, r)
        fit!(stat_mar2, r)
        fit!(stat_mar5, r)
    end

    # Different MARs should give different ratios
    @test value(stat_mar0) != value(stat_mar2)
    @test value(stat_mar2) != value(stat_mar5)
end

@testitem "UpsidePotentialRatio - Edge case: all returns above MAR" setup=[CommonTestSetup] begin
    stat = UpsidePotentialRatio(mar=0.0)

    # All positive returns
    fit!(stat, 0.05)
    fit!(stat, 0.03)
    fit!(stat, 0.02)
    fit!(stat, 0.04)

    @test stat.n == 4
    # No downside = Inf ratio
    @test isinf(value(stat))
end

@testitem "UpsidePotentialRatio - Edge case: all returns below MAR" setup=[CommonTestSetup] begin
    stat = UpsidePotentialRatio(mar=0.0)

    # All negative returns
    fit!(stat, -0.05)
    fit!(stat, -0.03)
    fit!(stat, -0.02)
    fit!(stat, -0.04)

    @test stat.n == 4
    # No upside potential = 0.0 ratio
    @test value(stat) == 0.0
end

@testitem "UpsidePotentialRatio - Edge case: insufficient observations" setup=[CommonTestSetup] begin
    stat = UpsidePotentialRatio()
    fit!(stat, 0.05)

    @test stat.n == 1
    # With only 1 observation, may return 0.0 or Inf depending on data
    @test isfinite(value(stat)) || isinf(value(stat))
end

@testitem "UpsidePotentialRatio - Higher upside means higher ratio" setup=[CommonTestSetup] begin
    stat_high = UpsidePotentialRatio(mar=0.0)
    stat_low = UpsidePotentialRatio(mar=0.0)

    # High upside portfolio
    high_returns = [0.15, 0.10, -0.02, 0.12, -0.01]
    for r in high_returns
        fit!(stat_high, r)
    end

    # Low upside portfolio (same downside)
    low_returns = [0.03, 0.02, -0.02, 0.01, -0.01]
    for r in low_returns
        fit!(stat_low, r)
    end

    @test value(stat_high) > value(stat_low)
end

@testitem "UpsidePotentialRatio - empty! reset behavior" setup=[CommonTestSetup] begin
    stat = UpsidePotentialRatio()
    fit!(stat, 0.05)
    fit!(stat, -0.02)
    fit!(stat, 0.03)

    @test stat.n > 0

    empty!(stat)

    @test stat.n == 0
end
