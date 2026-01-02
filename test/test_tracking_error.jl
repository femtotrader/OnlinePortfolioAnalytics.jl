# TrackingError tests

@testitem "TrackingError - Constructor and initial state" setup=[CommonTestSetup] begin
    stat = TrackingError()
    @test stat.n == 0
    @test value(stat) == 0.0
    @test stat isa TrackingError{Float64}
end

@testitem "TrackingError - Parameterized constructor Float32" setup=[CommonTestSetup] begin
    stat = TrackingError{Float32}()
    @test stat isa TrackingError{Float32}
    @test stat.n == 0
    @test value(stat) == 0.0f0
end

@testitem "TrackingError - Empty state returns 0.0" setup=[CommonTestSetup] begin
    stat = TrackingError()
    @test value(stat) == 0.0
    @test stat.n == 0
end

@testitem "TrackingError - n < 2 returns 0.0" setup=[CommonTestSetup] begin
    stat = TrackingError()
    fit!(stat, AssetBenchmarkReturn(0.05, 0.03))
    @test stat.n == 1
    @test value(stat) == 0.0  # Insufficient data for std dev
end

@testitem "TrackingError - Perfect tracking (identical returns)" setup=[CommonTestSetup] begin
    stat = TrackingError()
    # Asset perfectly tracks benchmark
    fit!(stat, AssetBenchmarkReturn(0.05, 0.05))
    fit!(stat, AssetBenchmarkReturn(0.02, 0.02))
    fit!(stat, AssetBenchmarkReturn(-0.01, -0.01))
    fit!(stat, AssetBenchmarkReturn(0.03, 0.03))

    @test stat.n == 4
    @test value(stat) == 0.0  # No tracking error
end

@testitem "TrackingError - Known return differences" setup=[CommonTestSetup] begin
    stat = TrackingError()

    # Asset = Benchmark + constant difference
    # Differences: 0.02, 0.02, 0.02, 0.02 -> std dev = 0
    fit!(stat, AssetBenchmarkReturn(0.05, 0.03))
    fit!(stat, AssetBenchmarkReturn(0.04, 0.02))
    fit!(stat, AssetBenchmarkReturn(0.03, 0.01))
    fit!(stat, AssetBenchmarkReturn(0.06, 0.04))

    @test stat.n == 4
    @test isapprox(value(stat), 0.0, atol=ATOL)  # Constant difference = 0 std dev
end

@testitem "TrackingError - Variable differences" setup=[CommonTestSetup] begin
    stat = TrackingError()

    # Differences: 0.02, -0.01, 0.01, 0.00
    fit!(stat, AssetBenchmarkReturn(0.05, 0.03))  # diff = 0.02
    fit!(stat, AssetBenchmarkReturn(0.02, 0.03))  # diff = -0.01
    fit!(stat, AssetBenchmarkReturn(0.04, 0.03))  # diff = 0.01
    fit!(stat, AssetBenchmarkReturn(0.03, 0.03))  # diff = 0.00

    @test stat.n == 4
    @test value(stat) > 0.0  # Should have positive tracking error

    # Manual calculation:
    # diffs = [0.02, -0.01, 0.01, 0.00]
    # mean = 0.005
    # std = sqrt(sum((diffs .- mean).^2) / 3) ≈ 0.01291
    diffs = [0.02, -0.01, 0.01, 0.00]
    mean_diff = sum(diffs) / length(diffs)
    expected_te = sqrt(sum((diffs .- mean_diff).^2) / (length(diffs) - 1))
    @test isapprox(value(stat), expected_te, atol=ATOL)
end

@testitem "TrackingError - empty! resets state" setup=[CommonTestSetup] begin
    stat = TrackingError()
    fit!(stat, AssetBenchmarkReturn(0.05, 0.03))
    fit!(stat, AssetBenchmarkReturn(0.02, 0.01))
    fit!(stat, AssetBenchmarkReturn(-0.01, -0.02))

    @test stat.n > 0

    empty!(stat)

    @test stat.n == 0
    @test value(stat) == 0.0
end

@testitem "TrackingError - merge! combines statistics" setup=[CommonTestSetup] begin
    stat1 = TrackingError()
    fit!(stat1, AssetBenchmarkReturn(0.05, 0.03))
    fit!(stat1, AssetBenchmarkReturn(0.02, 0.01))

    stat2 = TrackingError()
    fit!(stat2, AssetBenchmarkReturn(-0.01, -0.02))
    fit!(stat2, AssetBenchmarkReturn(0.04, 0.03))

    full_stat = TrackingError()
    fit!(full_stat, AssetBenchmarkReturn(0.05, 0.03))
    fit!(full_stat, AssetBenchmarkReturn(0.02, 0.01))
    fit!(full_stat, AssetBenchmarkReturn(-0.01, -0.02))
    fit!(full_stat, AssetBenchmarkReturn(0.04, 0.03))

    merge!(stat1, stat2)

    @test stat1.n == 4
    @test isapprox(value(stat1), value(full_stat), atol=ATOL)
end

@testitem "TrackingError - Negative differences" setup=[CommonTestSetup] begin
    stat = TrackingError()

    # Asset underperforms benchmark consistently
    fit!(stat, AssetBenchmarkReturn(0.02, 0.05))  # diff = -0.03
    fit!(stat, AssetBenchmarkReturn(0.01, 0.04))  # diff = -0.03
    fit!(stat, AssetBenchmarkReturn(0.00, 0.03))  # diff = -0.03
    fit!(stat, AssetBenchmarkReturn(-0.01, 0.02)) # diff = -0.03

    @test stat.n == 4
    @test isapprox(value(stat), 0.0, atol=ATOL)  # Constant difference = 0 std dev
end
