# T034: M2 (Modigliani-Modigliani) tests - TDD (write tests FIRST)

@testitem "M2 - Constructor and initial state" setup=[CommonTestSetup] begin
    stat = M2()
    @test stat.n == 0
    @test value(stat) == 0.0
    @test !ismultioutput(typeof(stat))
    @test stat isa M2{Float64}
    @test stat.risk_free == 0.0  # Default risk-free rate
end

@testitem "M2 - Parameterized constructor" setup=[CommonTestSetup] begin
    stat = M2{Float32}(risk_free=0.02)
    @test stat isa M2{Float32}
    @test stat.risk_free == Float32(0.02)
    @test stat.n == 0
end

@testitem "M2 - Basic calculation" setup=[CommonTestSetup] begin
    stat = M2(risk_free=0.0)

    # Portfolio and benchmark returns
    fit!(stat, AssetBenchmarkReturn(0.05, 0.03))
    fit!(stat, AssetBenchmarkReturn(0.02, 0.01))
    fit!(stat, AssetBenchmarkReturn(-0.01, -0.02))
    fit!(stat, AssetBenchmarkReturn(0.04, 0.02))

    @test stat.n == 4
    @test isfinite(value(stat))
end

@testitem "M2 - Formula verification: Rf + (R_port - Rf) * (σ_bench / σ_port)" setup=[CommonTestSetup] begin
    stat = M2(risk_free=0.02)

    # Generate some returns for calculation
    returns_port = [0.10, 0.05, -0.03, 0.08, 0.02]
    returns_bench = [0.06, 0.03, -0.02, 0.05, 0.01]

    for (rp, rb) in zip(returns_port, returns_bench)
        fit!(stat, AssetBenchmarkReturn(rp, rb))
    end

    @test stat.n == 5

    # Manual calculation
    rf = 0.02
    mean_port = sum(returns_port) / length(returns_port)
    mean_bench = sum(returns_bench) / length(returns_bench)
    std_port = sqrt(sum((returns_port .- mean_port).^2) / (length(returns_port) - 1))
    std_bench = sqrt(sum((returns_bench .- mean_bench).^2) / (length(returns_bench) - 1))
    expected_m2 = rf + (mean_port - rf) * (std_bench / std_port)

    @test isapprox(value(stat), expected_m2, atol=ATOL)
end

@testitem "M2 - Edge case: portfolio volatility is zero" setup=[CommonTestSetup] begin
    stat = M2()

    # Constant portfolio returns (zero volatility)
    fit!(stat, AssetBenchmarkReturn(0.02, 0.05))
    fit!(stat, AssetBenchmarkReturn(0.02, -0.01))
    fit!(stat, AssetBenchmarkReturn(0.02, 0.03))
    fit!(stat, AssetBenchmarkReturn(0.02, -0.02))

    @test stat.n == 4
    # When portfolio volatility is zero, M2 should be 0.0 or Inf
    # Our implementation returns 0.0 to avoid Inf
    @test value(stat) == 0.0 || isinf(value(stat))
end

@testitem "M2 - Edge case: benchmark volatility is zero" setup=[CommonTestSetup] begin
    stat = M2()

    # Constant benchmark returns (zero volatility)
    fit!(stat, AssetBenchmarkReturn(0.05, 0.02))
    fit!(stat, AssetBenchmarkReturn(-0.01, 0.02))
    fit!(stat, AssetBenchmarkReturn(0.03, 0.02))
    fit!(stat, AssetBenchmarkReturn(0.04, 0.02))

    @test stat.n == 4
    # When benchmark volatility is zero, M2 should handle gracefully
    @test isfinite(value(stat)) || value(stat) == 0.0
end

@testitem "M2 - Edge case: insufficient observations" setup=[CommonTestSetup] begin
    stat = M2()
    fit!(stat, AssetBenchmarkReturn(0.05, 0.03))

    @test stat.n == 1
    @test value(stat) == 0.0  # Not enough data
end

@testitem "M2 - Positive risk-free rate" setup=[CommonTestSetup] begin
    stat_rf0 = M2(risk_free=0.0)
    stat_rf5 = M2(risk_free=0.05)

    returns = [
        AssetBenchmarkReturn(0.10, 0.08),
        AssetBenchmarkReturn(0.05, 0.04),
        AssetBenchmarkReturn(-0.02, -0.01),
        AssetBenchmarkReturn(0.07, 0.05)
    ]

    for r in returns
        fit!(stat_rf0, r)
        fit!(stat_rf5, r)
    end

    # Different risk-free rates should give different M2 values
    @test value(stat_rf0) != value(stat_rf5)
end

@testitem "M2 - empty! reset behavior" setup=[CommonTestSetup] begin
    stat = M2()
    fit!(stat, AssetBenchmarkReturn(0.05, 0.03))
    fit!(stat, AssetBenchmarkReturn(0.02, 0.01))

    @test stat.n > 0

    empty!(stat)

    @test stat.n == 0
    @test value(stat) == 0.0
end

@testitem "M2 - Outperforming portfolio has higher M2" setup=[CommonTestSetup] begin
    # M2 adjusts portfolio return for risk
    stat_good = M2()
    stat_poor = M2()

    # Same benchmark, different portfolios
    # Good portfolio: higher return, same risk level
    fit!(stat_good, AssetBenchmarkReturn(0.10, 0.05))
    fit!(stat_good, AssetBenchmarkReturn(0.08, 0.03))
    fit!(stat_good, AssetBenchmarkReturn(-0.02, -0.01))
    fit!(stat_good, AssetBenchmarkReturn(0.06, 0.04))

    # Poor portfolio: lower return, same risk level
    fit!(stat_poor, AssetBenchmarkReturn(0.03, 0.05))
    fit!(stat_poor, AssetBenchmarkReturn(0.02, 0.03))
    fit!(stat_poor, AssetBenchmarkReturn(-0.04, -0.01))
    fit!(stat_poor, AssetBenchmarkReturn(0.01, 0.04))

    @test value(stat_good) > value(stat_poor)
end
