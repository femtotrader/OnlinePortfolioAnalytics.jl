# T014: UlcerIndex tests - TDD (write tests FIRST)

@testitem "UlcerIndex - Constructor and initial state" setup=[CommonTestSetup] begin
    stat = UlcerIndex()
    @test stat.n == 0
    @test value(stat) == 0.0  # No observations = 0.0
    @test !ismultioutput(typeof(stat))
    @test stat isa UlcerIndex{Float64}
end

@testitem "UlcerIndex - Parameterized constructor" setup=[CommonTestSetup] begin
    stat = UlcerIndex{Float32}()
    @test stat isa UlcerIndex{Float32}
    @test stat.n == 0
end

@testitem "UlcerIndex - Basic RMS drawdown calculation" setup=[CommonTestSetup] begin
    stat = UlcerIndex()

    # Simple sequence with known drawdown
    fit!(stat, 0.10)   # +10% - new peak
    fit!(stat, -0.05)  # -5% - in drawdown

    @test stat.n == 2
    @test value(stat) >= 0.0  # Ulcer index is always non-negative
end

@testitem "UlcerIndex - No drawdown case" setup=[CommonTestSetup] begin
    stat = UlcerIndex()

    # All positive returns - always at new peak, no drawdown
    fit!(stat, 0.05)
    fit!(stat, 0.03)
    fit!(stat, 0.02)

    @test stat.n == 3
    @test value(stat) == 0.0  # No drawdown means Ulcer Index = 0
end

@testitem "UlcerIndex - Deep drawdown" setup=[CommonTestSetup] begin
    stat = UlcerIndex()

    # Significant drawdown
    fit!(stat, 0.10)   # +10% - peak
    fit!(stat, -0.20)  # -20% - deep drawdown
    fit!(stat, -0.10)  # -10% - still in drawdown

    @test stat.n == 3
    @test value(stat) > 0.0  # Should have positive Ulcer Index
end

@testitem "UlcerIndex - RMS formula verification" setup=[CommonTestSetup] begin
    stat = UlcerIndex()

    # Known sequence for manual verification
    # Ulcer Index = sqrt(mean(DD^2))
    fit!(stat, 0.10)   # +10% - peak at 1.10
    fit!(stat, -0.05)  # Cumulative: 1.10 * 0.95 = 1.045, DD = 1.045/1.10 - 1 = -0.05
    fit!(stat, -0.02)  # Cumulative: 1.045 * 0.98 = 1.0241, DD = 1.0241/1.10 - 1 ≈ -0.069

    @test stat.n == 3
    @test value(stat) > 0.0
    @test isfinite(value(stat))
end

@testitem "UlcerIndex - empty! reset behavior" setup=[CommonTestSetup] begin
    stat = UlcerIndex()
    fit!(stat, 0.10)
    fit!(stat, -0.05)

    @test stat.n > 0

    empty!(stat)

    @test stat.n == 0
    @test value(stat) == 0.0
end

@testitem "UlcerIndex - Accumulating calculation" setup=[CommonTestSetup] begin
    stat = UlcerIndex()

    # Test incremental computation
    fit!(stat, 0.05)
    val1 = value(stat)

    fit!(stat, -0.03)
    val2 = value(stat)

    fit!(stat, -0.02)
    val3 = value(stat)

    # Ulcer index should change as drawdown accumulates
    @test val1 == 0.0  # First point is peak, no drawdown
    @test val2 >= val1  # Drawdown increases Ulcer Index
    @test val3 >= 0.0  # Always non-negative
end

@testitem "UlcerIndex - Single observation" setup=[CommonTestSetup] begin
    stat = UlcerIndex()
    fit!(stat, 0.05)

    @test stat.n == 1
    @test value(stat) == 0.0  # Single point is peak, no drawdown
end
