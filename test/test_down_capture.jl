# T004: DownCapture tests - TDD (write tests FIRST)

@testitem "DownCapture - Constructor and initial state" setup=[CommonTestSetup] begin
    stat = DownCapture()
    @test stat.n == 0
    @test isnan(value(stat))  # No negative benchmark periods yet
    @test !ismultioutput(typeof(stat))
    @test stat isa DownCapture{Float64}
end

@testitem "DownCapture - Parameterized constructor" setup=[CommonTestSetup] begin
    stat = DownCapture{Float32}()
    @test stat isa DownCapture{Float32}
    @test stat.n == 0
end

@testitem "DownCapture - Basic down capture calculation" setup=[CommonTestSetup] begin
    stat = DownCapture()

    # Asset falls less than benchmark in down markets (good)
    fit!(stat, AssetBenchmarkReturn(-0.02, -0.05))  # Down market
    fit!(stat, AssetBenchmarkReturn(-0.01, -0.03))  # Down market
    fit!(stat, AssetBenchmarkReturn(0.03, 0.02))    # Up market (ignored)

    @test stat.n == 3
    @test stat.n_down == 2  # Only 2 down-market observations

    # Down capture should be < 1 (asset falls less in down markets)
    @test value(stat) < 1.0
end

@testitem "DownCapture - Perfect capture (ratio = 1.0)" setup=[CommonTestSetup] begin
    stat = DownCapture()

    # Asset matches benchmark exactly in down markets
    fit!(stat, AssetBenchmarkReturn(-0.05, -0.05))
    fit!(stat, AssetBenchmarkReturn(-0.03, -0.03))
    fit!(stat, AssetBenchmarkReturn(-0.01, -0.01))

    @test stat.n == 3
    @test stat.n_down == 3
    @test isapprox(value(stat), 1.0, atol=ATOL)
end

@testitem "DownCapture - Edge case: no negative benchmark periods" setup=[CommonTestSetup] begin
    stat = DownCapture()

    # Only positive or zero benchmark periods
    fit!(stat, AssetBenchmarkReturn(-0.01, 0.02))
    fit!(stat, AssetBenchmarkReturn(0.01, 0.03))
    fit!(stat, AssetBenchmarkReturn(-0.02, 0.0))  # Zero is not negative

    @test stat.n == 3
    @test stat.n_down == 0
    @test isnan(value(stat))  # Cannot compute without down periods
end

@testitem "DownCapture - Edge case: all negative benchmark periods" setup=[CommonTestSetup] begin
    stat = DownCapture()

    fit!(stat, AssetBenchmarkReturn(-0.03, -0.02))
    fit!(stat, AssetBenchmarkReturn(-0.01, -0.01))
    fit!(stat, AssetBenchmarkReturn(-0.04, -0.03))

    @test stat.n == 3
    @test stat.n_down == 3
    @test !isnan(value(stat))
    @test isfinite(value(stat))
end

@testitem "DownCapture - Asset falls more than benchmark (ratio > 1.0)" setup=[CommonTestSetup] begin
    stat = DownCapture()

    # Asset falls more than benchmark in down markets (bad)
    fit!(stat, AssetBenchmarkReturn(-0.06, -0.02))
    fit!(stat, AssetBenchmarkReturn(-0.04, -0.01))
    fit!(stat, AssetBenchmarkReturn(-0.05, -0.03))

    @test stat.n == 3
    @test stat.n_down == 3
    @test value(stat) > 1.0  # Asset falls more in down markets
end

@testitem "DownCapture - empty! reset behavior" setup=[CommonTestSetup] begin
    stat = DownCapture()
    fit!(stat, AssetBenchmarkReturn(-0.03, -0.02))
    fit!(stat, AssetBenchmarkReturn(-0.01, -0.01))

    @test stat.n > 0
    @test stat.n_down > 0

    empty!(stat)

    @test stat.n == 0
    @test stat.n_down == 0
    @test isnan(value(stat))
end

@testitem "DownCapture - Reference calculation verification" setup=[CommonTestSetup] begin
    # Verify against manual geometric mean calculation
    stat = DownCapture()

    # Down market observations only (benchmark < 0)
    fit!(stat, AssetBenchmarkReturn(-0.03, -0.04))
    fit!(stat, AssetBenchmarkReturn(-0.02, -0.05))
    fit!(stat, AssetBenchmarkReturn(-0.01, -0.02))
    fit!(stat, AssetBenchmarkReturn(0.03, 0.02))  # Up market (ignored)

    @test stat.n == 4
    @test stat.n_down == 3

    # Manual calculation using geometric mean formula
    asset_down = [-0.03, -0.02, -0.01]
    bench_down = [-0.04, -0.05, -0.02]

    # DownCapture = ratio of geometric mean returns in down markets
    expected = (prod(1 .+ asset_down)^(1/length(asset_down)) - 1) /
               (prod(1 .+ bench_down)^(1/length(bench_down)) - 1)

    @test isapprox(value(stat), expected, rtol=0.01)
end

@testitem "DownCapture - Low down capture is good" setup=[CommonTestSetup] begin
    # Defensive portfolio: falls less than benchmark in down markets
    stat = DownCapture()

    fit!(stat, AssetBenchmarkReturn(-0.01, -0.05))  # Asset -1% when benchmark -5%
    fit!(stat, AssetBenchmarkReturn(-0.02, -0.08))  # Asset -2% when benchmark -8%
    fit!(stat, AssetBenchmarkReturn(-0.005, -0.03)) # Asset -0.5% when benchmark -3%

    @test stat.n_down == 3
    # Down capture should be significantly less than 1.0
    @test value(stat) < 0.5
end
