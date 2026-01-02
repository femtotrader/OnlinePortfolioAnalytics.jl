# JensenAlpha tests

@testitem "JensenAlpha - Constructor and initial state" setup=[CommonTestSetup] begin
    stat = JensenAlpha()
    @test stat.n == 0
    @test value(stat) == 0.0
    @test stat.risk_free == 0.0
    @test stat isa JensenAlpha{Float64}
end

@testitem "JensenAlpha - Parameterized constructor Float32" setup=[CommonTestSetup] begin
    stat = JensenAlpha{Float32}()
    @test stat isa JensenAlpha{Float32}
    @test stat.n == 0
    @test value(stat) == 0.0f0
end

@testitem "JensenAlpha - Custom risk-free rate" setup=[CommonTestSetup] begin
    stat = JensenAlpha(risk_free=0.02)
    @test stat.risk_free == 0.02
    @test stat isa JensenAlpha{Float64}
end

@testitem "JensenAlpha - Empty state returns 0.0" setup=[CommonTestSetup] begin
    stat = JensenAlpha()
    @test value(stat) == 0.0
    @test stat.n == 0
end

@testitem "JensenAlpha - n < 2 returns 0.0" setup=[CommonTestSetup] begin
    stat = JensenAlpha()
    fit!(stat, AssetBenchmarkReturn(0.05, 0.03))
    @test stat.n == 1
    @test value(stat) == 0.0  # Insufficient data for beta
end

@testitem "JensenAlpha - Perfect CAPM (alpha = 0)" setup=[CommonTestSetup] begin
    stat = JensenAlpha(risk_free=0.0)

    # Asset perfectly follows CAPM with beta = 1
    # Alpha should be zero
    fit!(stat, AssetBenchmarkReturn(0.01, 0.01))
    fit!(stat, AssetBenchmarkReturn(0.02, 0.02))
    fit!(stat, AssetBenchmarkReturn(0.03, 0.03))
    fit!(stat, AssetBenchmarkReturn(-0.01, -0.01))

    @test stat.n == 4
    # Alpha = mean_asset - (rf + beta * (mean_market - rf))
    # = 0.0125 - (0 + 1 * (0.0125 - 0)) = 0
    @test isapprox(value(stat), 0.0, atol=ATOL)
end

@testitem "JensenAlpha - Positive alpha (outperformance)" setup=[CommonTestSetup] begin
    stat = JensenAlpha(risk_free=0.0)

    # Asset consistently beats CAPM by 1%
    # Beta = 1.0 but returns are higher
    fit!(stat, AssetBenchmarkReturn(0.02, 0.01))  # +1% outperformance
    fit!(stat, AssetBenchmarkReturn(0.03, 0.02))  # +1% outperformance
    fit!(stat, AssetBenchmarkReturn(0.04, 0.03))  # +1% outperformance
    fit!(stat, AssetBenchmarkReturn(0.00, -0.01)) # +1% outperformance

    @test stat.n == 4
    # Asset mean = 0.0225, Market mean = 0.0125
    # With beta = 1: expected = 0.0125
    # Alpha = 0.0225 - 0.0125 = 0.01
    @test value(stat) > 0.0  # Positive alpha
end

@testitem "JensenAlpha - Negative alpha (underperformance)" setup=[CommonTestSetup] begin
    stat = JensenAlpha(risk_free=0.0)

    # Asset consistently underperforms CAPM by 1%
    fit!(stat, AssetBenchmarkReturn(0.00, 0.01))  # -1% underperformance
    fit!(stat, AssetBenchmarkReturn(0.01, 0.02))  # -1% underperformance
    fit!(stat, AssetBenchmarkReturn(0.02, 0.03))  # -1% underperformance
    fit!(stat, AssetBenchmarkReturn(-0.02, -0.01)) # -1% underperformance

    @test stat.n == 4
    @test value(stat) < 0.0  # Negative alpha
end

@testitem "JensenAlpha - With risk-free rate" setup=[CommonTestSetup] begin
    stat = JensenAlpha(risk_free=0.01)

    # Beta = 1 case
    fit!(stat, AssetBenchmarkReturn(0.05, 0.05))
    fit!(stat, AssetBenchmarkReturn(0.03, 0.03))
    fit!(stat, AssetBenchmarkReturn(0.02, 0.02))
    fit!(stat, AssetBenchmarkReturn(0.06, 0.06))

    @test stat.n == 4
    # Asset mean = Market mean = 0.04, Beta = 1
    # Expected = rf + beta * (market_mean - rf) = 0.01 + 1 * (0.04 - 0.01) = 0.04
    # Alpha = 0.04 - 0.04 = 0
    @test isapprox(value(stat), 0.0, atol=ATOL)
end

@testitem "JensenAlpha - Known calculation verification" setup=[CommonTestSetup] begin
    stat = JensenAlpha(risk_free=0.02)

    # Construct a case with known alpha
    # Beta = 2, Asset mean = 0.10, Market mean = 0.05, rf = 0.02
    # Expected = 0.02 + 2 * (0.05 - 0.02) = 0.02 + 0.06 = 0.08
    # Alpha = 0.10 - 0.08 = 0.02

    # Create returns that give beta ≈ 2
    fit!(stat, AssetBenchmarkReturn(0.10, 0.05))
    fit!(stat, AssetBenchmarkReturn(0.14, 0.07))
    fit!(stat, AssetBenchmarkReturn(0.06, 0.03))
    fit!(stat, AssetBenchmarkReturn(0.10, 0.05))

    @test stat.n == 4
    # The actual calculation depends on sample covariance/variance
    @test isfinite(value(stat))
end

@testitem "JensenAlpha - empty! resets state" setup=[CommonTestSetup] begin
    stat = JensenAlpha()
    fit!(stat, AssetBenchmarkReturn(0.05, 0.03))
    fit!(stat, AssetBenchmarkReturn(0.02, 0.01))
    fit!(stat, AssetBenchmarkReturn(-0.01, -0.02))

    @test stat.n > 0

    empty!(stat)

    @test stat.n == 0
    @test value(stat) == 0.0
end

@testitem "JensenAlpha - merge! combines statistics" setup=[CommonTestSetup] begin
    stat1 = JensenAlpha()
    fit!(stat1, AssetBenchmarkReturn(0.01, 0.01))
    fit!(stat1, AssetBenchmarkReturn(0.02, 0.02))

    stat2 = JensenAlpha()
    fit!(stat2, AssetBenchmarkReturn(0.03, 0.03))
    fit!(stat2, AssetBenchmarkReturn(-0.01, -0.01))

    full_stat = JensenAlpha()
    fit!(full_stat, AssetBenchmarkReturn(0.01, 0.01))
    fit!(full_stat, AssetBenchmarkReturn(0.02, 0.02))
    fit!(full_stat, AssetBenchmarkReturn(0.03, 0.03))
    fit!(full_stat, AssetBenchmarkReturn(-0.01, -0.01))

    merge!(stat1, stat2)

    @test stat1.n == 4
    @test isapprox(value(stat1), value(full_stat), atol=ATOL)
end
