# T035: MSquaredExcess tests - TDD (write tests FIRST)

@testitem "MSquaredExcess - Constructor and initial state" setup=[CommonTestSetup] begin
    stat = MSquaredExcess()
    @test stat.n == 0
    @test value(stat) == 0.0
    @test !ismultioutput(typeof(stat))
    @test stat isa MSquaredExcess{Float64}
    @test stat.risk_free == 0.0
end

@testitem "MSquaredExcess - Parameterized constructor" setup=[CommonTestSetup] begin
    stat = MSquaredExcess{Float32}(risk_free=0.03)
    @test stat isa MSquaredExcess{Float32}
    @test stat.risk_free == Float32(0.03)
    @test stat.n == 0
end

@testitem "MSquaredExcess - Basic calculation" setup=[CommonTestSetup] begin
    stat = MSquaredExcess()

    fit!(stat, AssetBenchmarkReturn(0.05, 0.03))
    fit!(stat, AssetBenchmarkReturn(0.02, 0.01))
    fit!(stat, AssetBenchmarkReturn(-0.01, -0.02))
    fit!(stat, AssetBenchmarkReturn(0.04, 0.02))

    @test stat.n == 4
    @test isfinite(value(stat))
end

@testitem "MSquaredExcess - Formula verification: M2 - benchmark mean" setup=[CommonTestSetup] begin
    stat = MSquaredExcess(risk_free=0.02)

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
    m2 = rf + (mean_port - rf) * (std_bench / std_port)
    expected = m2 - mean_bench

    @test isapprox(value(stat), expected, atol=ATOL)
end

@testitem "MSquaredExcess - Composition with M2" setup=[CommonTestSetup] begin
    stat_m2 = M2(risk_free=0.01)
    stat_excess = MSquaredExcess(risk_free=0.01)

    returns = [
        AssetBenchmarkReturn(0.08, 0.05),
        AssetBenchmarkReturn(0.04, 0.03),
        AssetBenchmarkReturn(-0.02, -0.01),
        AssetBenchmarkReturn(0.06, 0.04)
    ]

    bench_returns = Float64[]
    for r in returns
        fit!(stat_m2, r)
        fit!(stat_excess, r)
        push!(bench_returns, r.benchmark)
    end

    mean_bench = sum(bench_returns) / length(bench_returns)

    # MSquaredExcess = M2 - mean(benchmark)
    @test isapprox(value(stat_excess), value(stat_m2) - mean_bench, atol=ATOL)
end

@testitem "MSquaredExcess - Positive excess indicates outperformance" setup=[CommonTestSetup] begin
    stat = MSquaredExcess()

    # Portfolio that significantly outperforms with similar risk
    fit!(stat, AssetBenchmarkReturn(0.15, 0.05))
    fit!(stat, AssetBenchmarkReturn(0.10, 0.03))
    fit!(stat, AssetBenchmarkReturn(-0.01, -0.02))
    fit!(stat, AssetBenchmarkReturn(0.12, 0.04))

    @test stat.n == 4
    # Strong outperformance should give positive excess
    @test value(stat) > 0.0
end

@testitem "MSquaredExcess - Negative excess indicates underperformance" setup=[CommonTestSetup] begin
    stat = MSquaredExcess()

    # Portfolio that underperforms
    fit!(stat, AssetBenchmarkReturn(0.02, 0.08))
    fit!(stat, AssetBenchmarkReturn(0.01, 0.06))
    fit!(stat, AssetBenchmarkReturn(-0.03, -0.01))
    fit!(stat, AssetBenchmarkReturn(0.01, 0.05))

    @test stat.n == 4
    @test value(stat) < 0.0
end

@testitem "MSquaredExcess - Edge case: insufficient observations" setup=[CommonTestSetup] begin
    stat = MSquaredExcess()
    fit!(stat, AssetBenchmarkReturn(0.05, 0.03))

    @test stat.n == 1
    @test value(stat) == 0.0
end

@testitem "MSquaredExcess - empty! reset behavior" setup=[CommonTestSetup] begin
    stat = MSquaredExcess()
    fit!(stat, AssetBenchmarkReturn(0.05, 0.03))
    fit!(stat, AssetBenchmarkReturn(0.02, 0.01))

    @test stat.n > 0

    empty!(stat)

    @test stat.n == 0
    @test value(stat) == 0.0
end
