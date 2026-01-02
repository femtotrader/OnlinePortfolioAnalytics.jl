# T026: Stability tests - TDD (write tests FIRST)

@testitem "Stability - Constructor and initial state" setup=[CommonTestSetup] begin
    stat = Stability()
    @test stat.n == 0
    @test value(stat) == 0.0  # No observations = 0.0
    @test !ismultioutput(typeof(stat))
    @test stat isa Stability{Float64}
end

@testitem "Stability - Parameterized constructor" setup=[CommonTestSetup] begin
    stat = Stability{Float32}()
    @test stat isa Stability{Float32}
    @test stat.n == 0
end

@testitem "Stability - Perfect linear growth (R² ≈ 1.0)" setup=[CommonTestSetup] begin
    stat = Stability()

    # Constant positive returns = perfect linear cumulative log return
    for _ in 1:20
        fit!(stat, 0.01)  # Consistent 1% return
    end

    @test stat.n == 20
    # R² should be very close to 1.0 for perfectly consistent returns
    @test value(stat) > 0.99
end

@testitem "Stability - Random returns (R² < 1.0)" setup=[CommonTestSetup] begin
    stat = Stability()

    # Variable returns - not perfectly linear
    returns = [0.03, -0.02, 0.04, -0.01, 0.02, -0.03, 0.01, 0.05, -0.04, 0.02]
    for r in returns
        fit!(stat, r)
    end

    @test stat.n == 10
    # R² should be between 0 and 1 for non-constant returns
    @test 0.0 <= value(stat) <= 1.0
end

@testitem "Stability - Edge case: < 2 observations" setup=[CommonTestSetup] begin
    stat = Stability()
    fit!(stat, 0.01)

    @test stat.n == 1
    @test value(stat) == 0.0  # Not enough data for R²
end

@testitem "Stability - Range [0, 1]" setup=[CommonTestSetup] begin
    stat = Stability()

    returns = [0.02, -0.03, 0.01, -0.02, 0.04, -0.01, 0.03, -0.02]
    for r in returns
        fit!(stat, r)
    end

    @test stat.n == 8
    @test value(stat) >= 0.0
    @test value(stat) <= 1.0
end

@testitem "Stability - High stability vs low stability" setup=[CommonTestSetup] begin
    # High stability: consistent returns
    high_stab = Stability()
    for _ in 1:20
        fit!(high_stab, 0.01)  # Same return every period
    end

    # Low stability: highly variable returns
    low_stab = Stability()
    variable_returns = [0.10, -0.08, 0.12, -0.10, 0.09, -0.07, 0.11, -0.09]
    for r in variable_returns
        fit!(low_stab, r)
    end

    # High stability should have higher R²
    @test value(high_stab) > value(low_stab)
end

@testitem "Stability - empty! reset behavior" setup=[CommonTestSetup] begin
    stat = Stability()
    fit!(stat, 0.02)
    fit!(stat, -0.01)
    fit!(stat, 0.03)

    @test stat.n > 0

    empty!(stat)

    @test stat.n == 0
    @test value(stat) == 0.0
end

@testitem "Stability - Accumulating calculation" setup=[CommonTestSetup] begin
    stat = Stability()

    fit!(stat, 0.01)
    @test value(stat) == 0.0  # n=1, not enough

    fit!(stat, 0.01)
    @test stat.n == 2
    # Now we have 2 observations, R² can be computed
    # For identical returns, R² should be high
    @test value(stat) > 0.0

    fit!(stat, 0.01)
    fit!(stat, 0.01)
    @test stat.n == 4
    # Still consistent, should have high R²
end

@testitem "Stability - Downtrending returns" setup=[CommonTestSetup] begin
    stat = Stability()

    # Consistent negative returns = still linear (just downward)
    for _ in 1:15
        fit!(stat, -0.005)  # Consistent -0.5% return
    end

    @test stat.n == 15
    # R² measures linearity, not direction - should be high
    @test value(stat) > 0.95
end
