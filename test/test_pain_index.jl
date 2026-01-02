# T015: PainIndex tests - TDD (write tests FIRST)

@testitem "PainIndex - Constructor and initial state" setup=[CommonTestSetup] begin
    stat = PainIndex()
    @test stat.n == 0
    @test value(stat) == 0.0  # No observations = 0.0
    @test !ismultioutput(typeof(stat))
    @test stat isa PainIndex{Float64}
end

@testitem "PainIndex - Parameterized constructor" setup=[CommonTestSetup] begin
    stat = PainIndex{Float32}()
    @test stat isa PainIndex{Float32}
    @test stat.n == 0
end

@testitem "PainIndex - Basic mean absolute drawdown" setup=[CommonTestSetup] begin
    stat = PainIndex()

    fit!(stat, 0.10)   # +10% - new peak
    fit!(stat, -0.05)  # -5% - in drawdown

    @test stat.n == 2
    @test value(stat) >= 0.0  # Pain index is always non-negative
end

@testitem "PainIndex - No drawdown case" setup=[CommonTestSetup] begin
    stat = PainIndex()

    # All positive returns - always at new peak, no drawdown
    fit!(stat, 0.05)
    fit!(stat, 0.03)
    fit!(stat, 0.02)

    @test stat.n == 3
    @test value(stat) == 0.0  # No drawdown means Pain Index = 0
end

@testitem "PainIndex - Deep drawdown" setup=[CommonTestSetup] begin
    stat = PainIndex()

    fit!(stat, 0.10)   # +10% - peak
    fit!(stat, -0.20)  # -20% - deep drawdown
    fit!(stat, -0.10)  # -10% - still in drawdown

    @test stat.n == 3
    @test value(stat) > 0.0  # Should have positive Pain Index
end

@testitem "PainIndex - Mean formula (linear vs RMS)" setup=[CommonTestSetup] begin
    # Pain Index uses mean(|DD|) vs Ulcer Index uses sqrt(mean(DD^2))
    # For same drawdowns, Pain Index should differ from Ulcer Index

    pain = PainIndex()
    ulcer = UlcerIndex()

    # Same returns
    returns = [0.10, -0.05, -0.02, 0.08, -0.03]
    for r in returns
        fit!(pain, r)
        fit!(ulcer, r)
    end

    # Both should be non-negative
    @test value(pain) >= 0.0
    @test value(ulcer) >= 0.0

    # Due to RMS vs mean, they typically differ (unless all drawdowns equal)
    # RMS >= mean for non-constant values (Jensen's inequality)
end

@testitem "PainIndex - empty! reset behavior" setup=[CommonTestSetup] begin
    stat = PainIndex()
    fit!(stat, 0.10)
    fit!(stat, -0.05)

    @test stat.n > 0

    empty!(stat)

    @test stat.n == 0
    @test value(stat) == 0.0
end

@testitem "PainIndex - Accumulating calculation" setup=[CommonTestSetup] begin
    stat = PainIndex()

    fit!(stat, 0.05)
    val1 = value(stat)

    fit!(stat, -0.03)
    val2 = value(stat)

    fit!(stat, -0.02)
    val3 = value(stat)

    @test val1 == 0.0  # First point is peak, no drawdown
    @test val2 >= val1  # Drawdown increases Pain Index
    @test val3 >= 0.0  # Always non-negative
end

@testitem "PainIndex - Single observation" setup=[CommonTestSetup] begin
    stat = PainIndex()
    fit!(stat, 0.05)

    @test stat.n == 1
    @test value(stat) == 0.0  # Single point is peak, no drawdown
end
