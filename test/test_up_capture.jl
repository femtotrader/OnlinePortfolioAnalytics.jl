# T003: UpCapture tests - TDD (write tests FIRST)

@testitem "UpCapture - Constructor and initial state" setup=[CommonTestSetup] begin
    stat = UpCapture()
    @test stat.n == 0
    @test isnan(value(stat))  # No positive benchmark periods yet
    @test !ismultioutput(typeof(stat))
    @test stat isa UpCapture{Float64}
end

@testitem "UpCapture - Parameterized constructor" setup=[CommonTestSetup] begin
    stat = UpCapture{Float32}()
    @test stat isa UpCapture{Float32}
    @test stat.n == 0
end

@testitem "UpCapture - Basic up capture calculation" setup=[CommonTestSetup] begin
    stat = UpCapture()

    # Asset captures more than benchmark in up markets
    fit!(stat, AssetBenchmarkReturn(0.05, 0.03))  # Up market
    fit!(stat, AssetBenchmarkReturn(0.02, 0.02))  # Up market (equal capture)
    fit!(stat, AssetBenchmarkReturn(-0.01, -0.02)) # Down market (ignored)

    @test stat.n == 3
    @test stat.n_up == 2  # Only 2 up-market observations

    # Up capture should be > 1 (asset outperforms in up markets)
    @test value(stat) > 1.0
end

@testitem "UpCapture - Perfect capture (ratio = 1.0)" setup=[CommonTestSetup] begin
    stat = UpCapture()

    # Asset matches benchmark exactly in up markets
    fit!(stat, AssetBenchmarkReturn(0.05, 0.05))
    fit!(stat, AssetBenchmarkReturn(0.03, 0.03))
    fit!(stat, AssetBenchmarkReturn(0.01, 0.01))

    @test stat.n == 3
    @test stat.n_up == 3
    @test isapprox(value(stat), 1.0, atol=ATOL)
end

@testitem "UpCapture - Edge case: no positive benchmark periods" setup=[CommonTestSetup] begin
    stat = UpCapture()

    # Only negative or zero benchmark periods
    fit!(stat, AssetBenchmarkReturn(0.01, -0.02))
    fit!(stat, AssetBenchmarkReturn(-0.01, -0.03))
    fit!(stat, AssetBenchmarkReturn(0.02, 0.0))  # Zero is not positive

    @test stat.n == 3
    @test stat.n_up == 0
    @test isnan(value(stat))  # Cannot compute without up periods
end

@testitem "UpCapture - Edge case: all positive benchmark periods" setup=[CommonTestSetup] begin
    stat = UpCapture()

    fit!(stat, AssetBenchmarkReturn(0.05, 0.02))
    fit!(stat, AssetBenchmarkReturn(0.03, 0.01))
    fit!(stat, AssetBenchmarkReturn(0.04, 0.03))

    @test stat.n == 3
    @test stat.n_up == 3
    @test !isnan(value(stat))
    @test isfinite(value(stat))
end

@testitem "UpCapture - Asset underperforms in up markets (ratio < 1.0)" setup=[CommonTestSetup] begin
    stat = UpCapture()

    # Asset captures less than benchmark in up markets
    fit!(stat, AssetBenchmarkReturn(0.02, 0.05))
    fit!(stat, AssetBenchmarkReturn(0.01, 0.03))
    fit!(stat, AssetBenchmarkReturn(0.015, 0.04))

    @test stat.n == 3
    @test stat.n_up == 3
    @test value(stat) < 1.0  # Asset underperforms in up markets
end

@testitem "UpCapture - empty! reset behavior" setup=[CommonTestSetup] begin
    stat = UpCapture()
    fit!(stat, AssetBenchmarkReturn(0.05, 0.03))
    fit!(stat, AssetBenchmarkReturn(0.02, 0.01))

    @test stat.n > 0
    @test stat.n_up > 0

    empty!(stat)

    @test stat.n == 0
    @test stat.n_up == 0
    @test isnan(value(stat))
end

@testitem "UpCapture - Reference calculation verification" setup=[CommonTestSetup] begin
    # Verify against manual geometric mean calculation
    stat = UpCapture()

    # Up market observations only (benchmark > 0)
    # Asset returns: [0.10, 0.05, 0.02]
    # Benchmark returns: [0.08, 0.04, 0.01]
    fit!(stat, AssetBenchmarkReturn(0.10, 0.08))
    fit!(stat, AssetBenchmarkReturn(0.05, 0.04))
    fit!(stat, AssetBenchmarkReturn(0.02, 0.01))
    fit!(stat, AssetBenchmarkReturn(-0.02, -0.03))  # Down market (ignored)

    @test stat.n == 4
    @test stat.n_up == 3

    # Manual calculation using geometric mean formula:
    # UpCapture = (prod(1 + R_asset))^(1/n_up) / (prod(1 + R_bench))^(1/n_up) - 1 adjusted
    # Actually: UpCapture = AnnualReturn(asset|up) / AnnualReturn(bench|up)
    # Which simplifies to ratio of geometric mean returns

    asset_up = [0.10, 0.05, 0.02]
    bench_up = [0.08, 0.04, 0.01]

    asset_geom = prod(1 .+ asset_up)^(1/length(asset_up)) - 1
    bench_geom = prod(1 .+ bench_up)^(1/length(bench_up)) - 1

    # UpCapture per empyrical: uses annualized returns, but simplified here
    # We use the ratio of cumulative returns raised to 1/n power
    expected = (prod(1 .+ asset_up)^(1/length(asset_up)) - 1) /
               (prod(1 .+ bench_up)^(1/length(bench_up)) - 1)

    @test isapprox(value(stat), expected, rtol=0.01)
end
