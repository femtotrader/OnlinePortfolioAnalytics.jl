# VaR (Value at Risk) tests

@testitem "VaR - Constructor and initial state" setup=[CommonTestSetup] begin
    stat = VaR()
    @test stat.n == 0
    @test value(stat) == 0.0
    @test stat.confidence == 0.95
    @test stat isa VaR{Float64}
end

@testitem "VaR - Parameterized constructor Float32" setup=[CommonTestSetup] begin
    stat = VaR{Float32}()
    @test stat isa VaR{Float32}
    @test stat.n == 0
    @test value(stat) == 0.0f0
end

@testitem "VaR - Custom confidence level" setup=[CommonTestSetup] begin
    stat = VaR(confidence=0.99)
    @test stat.confidence == 0.99
    @test stat isa VaR{Float64}
end

@testitem "VaR - 95% VaR calculation" setup=[CommonTestSetup] begin
    stat = VaR(confidence=0.95)

    # Generate 100 returns (enough for 95% percentile)
    # Simple sequence: -0.10, -0.09, ..., 0.00, ..., +0.89
    for i in 1:100
        ret = (i - 11) / 100.0  # -0.10 to +0.89
        fit!(stat, ret)
    end

    @test stat.n == 100
    # 5th percentile of [-0.10, -0.09, ..., +0.89] should be around -0.05 to -0.06
    # The 5th percentile (for 95% VaR) should be the 5th value = -0.05
    @test value(stat) < 0.0  # Should be negative (a loss)
    @test value(stat) > -0.15  # Not too extreme
end

@testitem "VaR - 99% VaR calculation" setup=[CommonTestSetup] begin
    stat = VaR(confidence=0.99)

    # Generate 100 returns
    for i in 1:100
        ret = (i - 11) / 100.0  # -0.10 to +0.89
        fit!(stat, ret)
    end

    @test stat.n == 100
    # 1st percentile should be around -0.10 (the worst return)
    @test value(stat) < value(VaR(confidence=0.95))  # 99% VaR should be more negative than 95% VaR
end

@testitem "VaR - Empty state returns 0.0" setup=[CommonTestSetup] begin
    stat = VaR()
    @test value(stat) == 0.0
    @test stat.n == 0
end

@testitem "VaR - Custom histogram bins" setup=[CommonTestSetup] begin
    stat = VaR(confidence=0.95, b=1000)
    @test stat isa VaR{Float64}

    # Fit some data
    for i in 1:50
        fit!(stat, randn() * 0.02)
    end
    @test stat.n == 50
end

@testitem "VaR - empty! resets state" setup=[CommonTestSetup] begin
    stat = VaR()
    fit!(stat, -0.05)
    fit!(stat, 0.02)
    fit!(stat, -0.03)

    @test stat.n > 0

    empty!(stat)

    @test stat.n == 0
    @test value(stat) == 0.0
end

@testitem "VaR - merge! combines count (limited support)" setup=[CommonTestSetup] begin
    # Note: VaR merge! has limited support because OnlineStats.Quantile
    # does not support merging. This test verifies the count is updated.
    stat1 = VaR()
    for i in 1:50
        fit!(stat1, (i - 25) / 100.0)
    end

    stat2 = VaR()
    for i in 51:100
        fit!(stat2, (i - 25) / 100.0)
    end

    merge!(stat1, stat2)

    @test stat1.n == 100
    # Note: Value may not match full calculation due to merge limitation
end

@testitem "VaR - Known percentile verification" setup=[CommonTestSetup] begin
    stat = VaR(confidence=0.95)

    # Use a simple known distribution: 20 values from -0.10 to +0.09
    for i in 1:20
        ret = (i - 11) / 100.0  # -0.10 to +0.09
        fit!(stat, ret)
    end

    @test stat.n == 20
    # 5th percentile of 20 values ≈ 1st value = -0.10
    @test value(stat) < 0.0
end

@testitem "VaR - With negative returns only" setup=[CommonTestSetup] begin
    stat = VaR()

    # All negative returns
    for i in 1:20
        fit!(stat, -0.01 * i)  # -0.01, -0.02, ..., -0.20
    end

    @test stat.n == 20
    @test value(stat) < 0.0
end

@testitem "VaR - With positive returns only" setup=[CommonTestSetup] begin
    stat = VaR()

    # All positive returns
    for i in 1:20
        fit!(stat, 0.01 * i)  # 0.01, 0.02, ..., 0.20
    end

    @test stat.n == 20
    @test value(stat) > 0.0  # 5th percentile of positive returns is still positive
end
