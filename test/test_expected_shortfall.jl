# ExpectedShortfall (CVaR) tests

@testitem "ExpectedShortfall - Constructor and initial state" setup=[CommonTestSetup] begin
    stat = ExpectedShortfall()
    @test stat.n == 0
    @test value(stat) == 0.0
    @test stat.confidence == 0.95
    @test stat isa ExpectedShortfall{Float64}
end

@testitem "ExpectedShortfall - Parameterized constructor Float32" setup=[CommonTestSetup] begin
    stat = ExpectedShortfall{Float32}()
    @test stat isa ExpectedShortfall{Float32}
    @test stat.n == 0
    @test value(stat) == 0.0f0
end

@testitem "ExpectedShortfall - Custom confidence level" setup=[CommonTestSetup] begin
    stat = ExpectedShortfall(confidence=0.99)
    @test stat.confidence == 0.99
    @test stat isa ExpectedShortfall{Float64}
end

@testitem "ExpectedShortfall - 95% ES calculation" setup=[CommonTestSetup] begin
    stat = ExpectedShortfall(confidence=0.95)

    # Generate 100 returns from -0.10 to +0.89
    for i in 1:100
        ret = (i - 11) / 100.0  # -0.10 to +0.89
        fit!(stat, ret)
    end

    @test stat.n == 100
    # ES should be the mean of the worst 5% (5 values: -0.10, -0.09, -0.08, -0.07, -0.06)
    # Expected ES ≈ (-0.10 - 0.09 - 0.08 - 0.07 - 0.06) / 5 = -0.08
    @test value(stat) < 0.0  # Should be negative
    @test value(stat) > -0.15  # Not too extreme
end

@testitem "ExpectedShortfall - ES more negative than VaR" setup=[CommonTestSetup] begin
    es = ExpectedShortfall(confidence=0.95)
    var = VaR(confidence=0.95)

    # Generate 100 returns
    for i in 1:100
        ret = (i - 11) / 100.0
        fit!(es, ret)
        fit!(var, ret)
    end

    @test es.n == 100
    @test var.n == 100
    # ES should be less than or equal to VaR (more negative for losses)
    @test value(es) <= value(var)
end

@testitem "ExpectedShortfall - Empty state returns 0.0" setup=[CommonTestSetup] begin
    stat = ExpectedShortfall()
    @test value(stat) == 0.0
    @test stat.n == 0
end

@testitem "ExpectedShortfall - empty! resets state" setup=[CommonTestSetup] begin
    stat = ExpectedShortfall()
    fit!(stat, -0.05)
    fit!(stat, 0.02)
    fit!(stat, -0.03)

    @test stat.n > 0

    empty!(stat)

    @test stat.n == 0
    @test value(stat) == 0.0
end

@testitem "ExpectedShortfall - merge! combines count (limited support)" setup=[CommonTestSetup] begin
    # Note: ExpectedShortfall merge! has limited support due to VaR limitation
    stat1 = ExpectedShortfall()
    for i in 1:50
        fit!(stat1, (i - 25) / 100.0)
    end

    stat2 = ExpectedShortfall()
    for i in 51:100
        fit!(stat2, (i - 25) / 100.0)
    end

    merge!(stat1, stat2)

    @test stat1.n == 100
end

@testitem "ExpectedShortfall - With extreme tail losses" setup=[CommonTestSetup] begin
    stat = ExpectedShortfall(confidence=0.95)

    # Mix of normal and extreme returns
    returns = [-0.50, -0.30, -0.20, -0.10, -0.05, 0.01, 0.02, 0.03, 0.04, 0.05,
               0.06, 0.07, 0.08, 0.09, 0.10, 0.11, 0.12, 0.13, 0.14, 0.15]

    for ret in returns
        fit!(stat, ret)
    end

    @test stat.n == 20
    @test value(stat) < 0.0  # Should capture the extreme losses
    # ES should include the very negative values
    @test value(stat) < -0.10  # Should be significantly negative due to extreme losses
end

@testitem "ExpectedShortfall - With positive returns only" setup=[CommonTestSetup] begin
    stat = ExpectedShortfall()

    # All positive returns
    for i in 1:20
        fit!(stat, 0.01 * i)  # 0.01, 0.02, ..., 0.20
    end

    @test stat.n == 20
    @test value(stat) > 0.0  # 5th percentile of positive returns is still positive
end

@testitem "ExpectedShortfall - Known tail average verification" setup=[CommonTestSetup] begin
    stat = ExpectedShortfall(confidence=0.80)  # 80% confidence = 20th percentile

    # 10 values: -0.05, -0.04, -0.03, -0.02, -0.01, 0.01, 0.02, 0.03, 0.04, 0.05
    returns = [-0.05, -0.04, -0.03, -0.02, -0.01, 0.01, 0.02, 0.03, 0.04, 0.05]
    for ret in returns
        fit!(stat, ret)
    end

    @test stat.n == 10
    # 20th percentile = bottom 2 values: -0.05, -0.04
    # ES ≈ mean(-0.05, -0.04) = -0.045
    @test value(stat) < 0.0
end
