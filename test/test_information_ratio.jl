# InformationRatio tests

@testitem "InformationRatio - Constructor and initial state" setup=[CommonTestSetup] begin
    stat = InformationRatio()
    @test stat.n == 0
    @test value(stat) == 0.0
    @test stat isa InformationRatio{Float64}
end

@testitem "InformationRatio - Parameterized constructor Float32" setup=[CommonTestSetup] begin
    stat = InformationRatio{Float32}()
    @test stat isa InformationRatio{Float32}
    @test stat.n == 0
    @test value(stat) == 0.0f0
end

@testitem "InformationRatio - Empty state returns 0.0" setup=[CommonTestSetup] begin
    stat = InformationRatio()
    @test value(stat) == 0.0
    @test stat.n == 0
end

@testitem "InformationRatio - n < 2 returns 0.0" setup=[CommonTestSetup] begin
    stat = InformationRatio()
    fit!(stat, AssetBenchmarkReturn(0.05, 0.03))
    @test stat.n == 1
    @test value(stat) == 0.0  # Insufficient data for IR
end

@testitem "InformationRatio - Zero tracking error returns 0.0" setup=[CommonTestSetup] begin
    stat = InformationRatio()
    # Perfect tracking with constant excess return
    fit!(stat, AssetBenchmarkReturn(0.05, 0.05))
    fit!(stat, AssetBenchmarkReturn(0.02, 0.02))
    fit!(stat, AssetBenchmarkReturn(-0.01, -0.01))
    fit!(stat, AssetBenchmarkReturn(0.03, 0.03))

    @test stat.n == 4
    @test value(stat) == 0.0  # TE = 0, so IR = 0 (not Inf)
end

@testitem "InformationRatio - Positive excess return with positive TE" setup=[CommonTestSetup] begin
    stat = InformationRatio()

    # Asset consistently outperforms with some variability
    fit!(stat, AssetBenchmarkReturn(0.05, 0.03))  # excess = 0.02
    fit!(stat, AssetBenchmarkReturn(0.04, 0.02))  # excess = 0.02
    fit!(stat, AssetBenchmarkReturn(0.03, 0.02))  # excess = 0.01
    fit!(stat, AssetBenchmarkReturn(0.06, 0.03))  # excess = 0.03

    @test stat.n == 4
    @test value(stat) > 0.0  # Positive excess return / positive TE
end

@testitem "InformationRatio - Known calculation verification" setup=[CommonTestSetup] begin
    stat = InformationRatio()

    # Excess returns: 0.02, -0.01, 0.01, 0.00
    fit!(stat, AssetBenchmarkReturn(0.05, 0.03))  # excess = 0.02
    fit!(stat, AssetBenchmarkReturn(0.02, 0.03))  # excess = -0.01
    fit!(stat, AssetBenchmarkReturn(0.04, 0.03))  # excess = 0.01
    fit!(stat, AssetBenchmarkReturn(0.03, 0.03))  # excess = 0.00

    @test stat.n == 4

    # Manual calculation
    excess = [0.02, -0.01, 0.01, 0.00]
    mean_excess = sum(excess) / length(excess)  # 0.005
    te = sqrt(sum((excess .- mean_excess).^2) / (length(excess) - 1))
    expected_ir = mean_excess / te

    @test isapprox(value(stat), expected_ir, atol=ATOL)
end

@testitem "InformationRatio - Negative excess return" setup=[CommonTestSetup] begin
    stat = InformationRatio()

    # Asset consistently underperforms
    fit!(stat, AssetBenchmarkReturn(0.02, 0.05))  # excess = -0.03
    fit!(stat, AssetBenchmarkReturn(0.01, 0.04))  # excess = -0.03
    fit!(stat, AssetBenchmarkReturn(0.00, 0.02))  # excess = -0.02
    fit!(stat, AssetBenchmarkReturn(-0.01, 0.03)) # excess = -0.04

    @test stat.n == 4
    @test value(stat) < 0.0  # Negative IR indicates underperformance
end

@testitem "InformationRatio - empty! resets state" setup=[CommonTestSetup] begin
    stat = InformationRatio()
    fit!(stat, AssetBenchmarkReturn(0.05, 0.03))
    fit!(stat, AssetBenchmarkReturn(0.02, 0.01))
    fit!(stat, AssetBenchmarkReturn(-0.01, -0.02))

    @test stat.n > 0

    empty!(stat)

    @test stat.n == 0
    @test value(stat) == 0.0
end

@testitem "InformationRatio - merge! combines statistics" setup=[CommonTestSetup] begin
    stat1 = InformationRatio()
    fit!(stat1, AssetBenchmarkReturn(0.05, 0.03))
    fit!(stat1, AssetBenchmarkReturn(0.02, 0.01))

    stat2 = InformationRatio()
    fit!(stat2, AssetBenchmarkReturn(-0.01, -0.02))
    fit!(stat2, AssetBenchmarkReturn(0.04, 0.03))

    full_stat = InformationRatio()
    fit!(full_stat, AssetBenchmarkReturn(0.05, 0.03))
    fit!(full_stat, AssetBenchmarkReturn(0.02, 0.01))
    fit!(full_stat, AssetBenchmarkReturn(-0.01, -0.02))
    fit!(full_stat, AssetBenchmarkReturn(0.04, 0.03))

    merge!(stat1, stat2)

    @test stat1.n == 4
    @test isapprox(value(stat1), value(full_stat), atol=ATOL)
end
