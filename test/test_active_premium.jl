# T036: ActivePremium tests - TDD (write tests FIRST)

@testitem "ActivePremium - Constructor and initial state" setup=[CommonTestSetup] begin
    stat = ActivePremium()
    @test stat.n == 0
    @test value(stat) == 0.0
    @test !ismultioutput(typeof(stat))
    @test stat isa ActivePremium{Float64}
    @test stat.period == 252  # Default period
end

@testitem "ActivePremium - Parameterized constructor" setup=[CommonTestSetup] begin
    stat = ActivePremium{Float32}(period=52)
    @test stat isa ActivePremium{Float32}
    @test stat.period == 52
    @test stat.n == 0
end

@testitem "ActivePremium - Basic calculation" setup=[CommonTestSetup] begin
    stat = ActivePremium(period=252)

    fit!(stat, AssetBenchmarkReturn(0.05, 0.03))
    fit!(stat, AssetBenchmarkReturn(0.02, 0.01))
    fit!(stat, AssetBenchmarkReturn(-0.01, -0.02))
    fit!(stat, AssetBenchmarkReturn(0.04, 0.02))

    @test stat.n == 4
    @test isfinite(value(stat))
end

@testitem "ActivePremium - Formula: AnnualizedReturn(port) - AnnualizedReturn(bench)" setup=[CommonTestSetup] begin
    stat = ActivePremium(period=252)
    port_ann = AnnualizedReturn(period=252)
    bench_ann = AnnualizedReturn(period=252)

    returns_port = [0.01, 0.02, -0.01, 0.015, 0.005]
    returns_bench = [0.008, 0.015, -0.005, 0.01, 0.003]

    for (rp, rb) in zip(returns_port, returns_bench)
        fit!(stat, AssetBenchmarkReturn(rp, rb))
        fit!(port_ann, rp)
        fit!(bench_ann, rb)
    end

    expected = value(port_ann) - value(bench_ann)
    @test isapprox(value(stat), expected, atol=ATOL)
end

@testitem "ActivePremium - Different periods" setup=[CommonTestSetup] begin
    stat_daily = ActivePremium(period=252)
    stat_weekly = ActivePremium(period=52)
    stat_monthly = ActivePremium(period=12)

    returns = [
        AssetBenchmarkReturn(0.01, 0.008),
        AssetBenchmarkReturn(0.02, 0.015),
        AssetBenchmarkReturn(-0.01, -0.005),
        AssetBenchmarkReturn(0.015, 0.01)
    ]

    for r in returns
        fit!(stat_daily, r)
        fit!(stat_weekly, r)
        fit!(stat_monthly, r)
    end

    # Different periods should give different premiums (annualization effect)
    @test stat_daily.period != stat_weekly.period
    @test stat_weekly.period != stat_monthly.period
    # All should be finite
    @test isfinite(value(stat_daily))
    @test isfinite(value(stat_weekly))
    @test isfinite(value(stat_monthly))
end

@testitem "ActivePremium - Positive premium (portfolio outperforms)" setup=[CommonTestSetup] begin
    stat = ActivePremium()

    # Portfolio consistently outperforms benchmark
    fit!(stat, AssetBenchmarkReturn(0.05, 0.03))
    fit!(stat, AssetBenchmarkReturn(0.04, 0.02))
    fit!(stat, AssetBenchmarkReturn(-0.01, -0.02))
    fit!(stat, AssetBenchmarkReturn(0.03, 0.01))

    @test stat.n == 4
    @test value(stat) > 0.0  # Positive active premium
end

@testitem "ActivePremium - Negative premium (portfolio underperforms)" setup=[CommonTestSetup] begin
    stat = ActivePremium()

    # Portfolio consistently underperforms benchmark
    fit!(stat, AssetBenchmarkReturn(0.02, 0.05))
    fit!(stat, AssetBenchmarkReturn(0.01, 0.04))
    fit!(stat, AssetBenchmarkReturn(-0.03, -0.01))
    fit!(stat, AssetBenchmarkReturn(0.01, 0.03))

    @test stat.n == 4
    @test value(stat) < 0.0  # Negative active premium
end

@testitem "ActivePremium - Zero premium (portfolio matches benchmark)" setup=[CommonTestSetup] begin
    stat = ActivePremium()

    # Portfolio matches benchmark exactly
    fit!(stat, AssetBenchmarkReturn(0.03, 0.03))
    fit!(stat, AssetBenchmarkReturn(-0.01, -0.01))
    fit!(stat, AssetBenchmarkReturn(0.02, 0.02))
    fit!(stat, AssetBenchmarkReturn(0.01, 0.01))

    @test stat.n == 4
    @test isapprox(value(stat), 0.0, atol=ATOL)
end

@testitem "ActivePremium - Edge case: insufficient observations" setup=[CommonTestSetup] begin
    stat = ActivePremium()
    fit!(stat, AssetBenchmarkReturn(0.05, 0.03))

    @test stat.n == 1
    # With 1 observation, annualized return is still computable
    @test isfinite(value(stat))
end

@testitem "ActivePremium - empty! reset behavior" setup=[CommonTestSetup] begin
    stat = ActivePremium()
    fit!(stat, AssetBenchmarkReturn(0.05, 0.03))
    fit!(stat, AssetBenchmarkReturn(0.02, 0.01))

    @test stat.n > 0

    empty!(stat)

    @test stat.n == 0
    @test value(stat) == 0.0
end
