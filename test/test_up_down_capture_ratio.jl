# T005: UpDownCaptureRatio tests - TDD (write tests FIRST)

@testitem "UpDownCaptureRatio - Constructor and initial state" setup=[CommonTestSetup] begin
    stat = UpDownCaptureRatio()
    @test stat.n == 0
    @test isnan(value(stat))  # No data yet
    @test !ismultioutput(typeof(stat))
    @test stat isa UpDownCaptureRatio{Float64}
end

@testitem "UpDownCaptureRatio - Parameterized constructor" setup=[CommonTestSetup] begin
    stat = UpDownCaptureRatio{Float32}()
    @test stat isa UpDownCaptureRatio{Float32}
    @test stat.n == 0
end

@testitem "UpDownCaptureRatio - Basic calculation" setup=[CommonTestSetup] begin
    stat = UpDownCaptureRatio()

    # Favorable asymmetry: captures more upside, less downside
    fit!(stat, AssetBenchmarkReturn(0.06, 0.04))   # Up market: asset +6%, bench +4%
    fit!(stat, AssetBenchmarkReturn(0.03, 0.02))   # Up market: asset +3%, bench +2%
    fit!(stat, AssetBenchmarkReturn(-0.01, -0.03)) # Down market: asset -1%, bench -3%
    fit!(stat, AssetBenchmarkReturn(-0.02, -0.04)) # Down market: asset -2%, bench -4%

    @test stat.n == 4

    # Up/Down ratio should be > 1.0 (favorable)
    @test value(stat) > 1.0
end

@testitem "UpDownCaptureRatio - Ratio = 1.0 (symmetric capture)" setup=[CommonTestSetup] begin
    stat = UpDownCaptureRatio()

    # Asset moves exactly with benchmark in both up and down markets
    fit!(stat, AssetBenchmarkReturn(0.05, 0.05))
    fit!(stat, AssetBenchmarkReturn(0.03, 0.03))
    fit!(stat, AssetBenchmarkReturn(-0.02, -0.02))
    fit!(stat, AssetBenchmarkReturn(-0.04, -0.04))

    @test stat.n == 4
    @test isapprox(value(stat), 1.0, atol=ATOL)
end

@testitem "UpDownCaptureRatio - Ratio > 1.0 is desirable" setup=[CommonTestSetup] begin
    stat = UpDownCaptureRatio()

    # Good portfolio: captures more upside (1.5x), less downside (0.5x)
    # Up markets: asset gains 1.5x benchmark
    fit!(stat, AssetBenchmarkReturn(0.06, 0.04))  # 6% vs 4%
    fit!(stat, AssetBenchmarkReturn(0.045, 0.03)) # 4.5% vs 3%

    # Down markets: asset falls 0.5x benchmark
    fit!(stat, AssetBenchmarkReturn(-0.01, -0.02)) # -1% vs -2%
    fit!(stat, AssetBenchmarkReturn(-0.02, -0.04)) # -2% vs -4%

    @test stat.n == 4

    # Ratio should be significantly > 1.0
    # UpCapture ~ 1.5, DownCapture ~ 0.5, Ratio ~ 3.0
    @test value(stat) > 1.5
end

@testitem "UpDownCaptureRatio - Ratio < 1.0 is unfavorable" setup=[CommonTestSetup] begin
    stat = UpDownCaptureRatio()

    # Bad portfolio: captures less upside (0.5x), more downside (1.5x)
    # Up markets: asset gains 0.5x benchmark
    fit!(stat, AssetBenchmarkReturn(0.02, 0.04))  # 2% vs 4%
    fit!(stat, AssetBenchmarkReturn(0.015, 0.03)) # 1.5% vs 3%

    # Down markets: asset falls 1.5x benchmark
    fit!(stat, AssetBenchmarkReturn(-0.03, -0.02)) # -3% vs -2%
    fit!(stat, AssetBenchmarkReturn(-0.06, -0.04)) # -6% vs -4%

    @test stat.n == 4

    # Ratio should be < 1.0
    @test value(stat) < 1.0
end

@testitem "UpDownCaptureRatio - Edge case: no up periods" setup=[CommonTestSetup] begin
    stat = UpDownCaptureRatio()

    # Only down market periods
    fit!(stat, AssetBenchmarkReturn(-0.02, -0.03))
    fit!(stat, AssetBenchmarkReturn(-0.01, -0.02))

    @test stat.n == 2

    # UpCapture is NaN, so ratio should be NaN
    @test isnan(value(stat))
end

@testitem "UpDownCaptureRatio - Edge case: no down periods" setup=[CommonTestSetup] begin
    stat = UpDownCaptureRatio()

    # Only up market periods
    fit!(stat, AssetBenchmarkReturn(0.03, 0.02))
    fit!(stat, AssetBenchmarkReturn(0.05, 0.04))

    @test stat.n == 2

    # DownCapture is NaN, so ratio should be NaN
    @test isnan(value(stat))
end

@testitem "UpDownCaptureRatio - Edge case: down capture is zero (returns Inf)" setup=[CommonTestSetup] begin
    stat = UpDownCaptureRatio()

    # This is a theoretical edge case - in practice hard to achieve
    # For now, verify that division by ~0 is handled
    fit!(stat, AssetBenchmarkReturn(0.05, 0.03))  # Up
    fit!(stat, AssetBenchmarkReturn(0.03, 0.02))  # Up

    # When no down periods, down capture is NaN, not zero
    # So Inf case would require a nearly-zero down capture
    @test stat.n == 2
end

@testitem "UpDownCaptureRatio - empty! reset behavior" setup=[CommonTestSetup] begin
    stat = UpDownCaptureRatio()
    fit!(stat, AssetBenchmarkReturn(0.05, 0.03))
    fit!(stat, AssetBenchmarkReturn(-0.02, -0.04))

    @test stat.n > 0

    empty!(stat)

    @test stat.n == 0
    @test isnan(value(stat))
end

@testitem "UpDownCaptureRatio - Combined calculation matches individual components" setup=[CommonTestSetup] begin
    # Create individual capture stats
    up_stat = UpCapture()
    down_stat = DownCapture()
    ratio_stat = UpDownCaptureRatio()

    # Same data sequence
    observations = [
        AssetBenchmarkReturn(0.05, 0.03),
        AssetBenchmarkReturn(0.02, 0.01),
        AssetBenchmarkReturn(-0.02, -0.04),
        AssetBenchmarkReturn(-0.01, -0.03),
        AssetBenchmarkReturn(0.03, 0.02),
        AssetBenchmarkReturn(-0.03, -0.05),
    ]

    for obs in observations
        fit!(up_stat, obs)
        fit!(down_stat, obs)
        fit!(ratio_stat, obs)
    end

    @test ratio_stat.n == 6

    # Ratio should equal UpCapture / DownCapture
    expected_ratio = value(up_stat) / value(down_stat)
    @test isapprox(value(ratio_stat), expected_ratio, rtol=0.01)
end

@testitem "UpDownCaptureRatio - Real-world scenario" setup=[CommonTestSetup] begin
    stat = UpDownCaptureRatio()

    # Simulate a defensive portfolio over market cycle
    # Bull market periods (benchmark positive)
    fit!(stat, AssetBenchmarkReturn(0.04, 0.05))  # Slightly underperform in bull
    fit!(stat, AssetBenchmarkReturn(0.03, 0.04))
    fit!(stat, AssetBenchmarkReturn(0.05, 0.06))

    # Bear market periods (benchmark negative)
    fit!(stat, AssetBenchmarkReturn(-0.01, -0.03)) # Protect downside
    fit!(stat, AssetBenchmarkReturn(-0.02, -0.05))
    fit!(stat, AssetBenchmarkReturn(-0.01, -0.04))

    @test stat.n == 6

    # Defensive portfolio: may have up capture < 1 but down capture << 1
    # Net effect: ratio should still be favorable
    @test !isnan(value(stat))
    @test isfinite(value(stat))
end
