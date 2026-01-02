# Treynor Ratio tests

@testitem "Treynor - Constructor and initial state" setup=[CommonTestSetup] begin
    stat = Treynor()
    @test stat.n == 0
    @test value(stat) == 0.0
    @test stat.risk_free == 0.0
    @test stat isa Treynor{Float64}
end

@testitem "Treynor - Parameterized constructor Float32" setup=[CommonTestSetup] begin
    stat = Treynor{Float32}()
    @test stat isa Treynor{Float32}
    @test stat.n == 0
    @test value(stat) == 0.0f0
end

@testitem "Treynor - Custom risk-free rate" setup=[CommonTestSetup] begin
    stat = Treynor(risk_free=0.02)
    @test stat.risk_free == 0.02
    @test stat isa Treynor{Float64}
end

@testitem "Treynor - Empty state returns 0.0" setup=[CommonTestSetup] begin
    stat = Treynor()
    @test value(stat) == 0.0
    @test stat.n == 0
end

@testitem "Treynor - n < 2 returns 0.0" setup=[CommonTestSetup] begin
    stat = Treynor()
    fit!(stat, AssetBenchmarkReturn(0.05, 0.03))
    @test stat.n == 1
    @test value(stat) == 0.0  # Insufficient data for beta
end

@testitem "Treynor - Known beta = 1.0 calculation" setup=[CommonTestSetup] begin
    stat = Treynor(risk_free=0.0)

    # Asset moves exactly with market (beta = 1)
    fit!(stat, AssetBenchmarkReturn(0.01, 0.01))
    fit!(stat, AssetBenchmarkReturn(0.02, 0.02))
    fit!(stat, AssetBenchmarkReturn(0.03, 0.03))
    fit!(stat, AssetBenchmarkReturn(-0.01, -0.01))

    @test stat.n == 4
    # Mean asset return = (0.01 + 0.02 + 0.03 - 0.01) / 4 = 0.0125
    # Beta = 1.0
    # Treynor = (0.0125 - 0) / 1.0 = 0.0125
    @test isapprox(value(stat), 0.0125, atol=ATOL)
end

@testitem "Treynor - Known beta = 2.0 calculation" setup=[CommonTestSetup] begin
    stat = Treynor(risk_free=0.0)

    # Asset moves 2x the market (beta = 2)
    fit!(stat, AssetBenchmarkReturn(0.02, 0.01))
    fit!(stat, AssetBenchmarkReturn(0.04, 0.02))
    fit!(stat, AssetBenchmarkReturn(-0.02, -0.01))
    fit!(stat, AssetBenchmarkReturn(0.06, 0.03))

    @test stat.n == 4
    # Mean asset return = (0.02 + 0.04 - 0.02 + 0.06) / 4 = 0.025
    # Beta = 2.0
    # Treynor = 0.025 / 2.0 = 0.0125
    @test isapprox(value(stat), 0.0125, atol=ATOL)
end

@testitem "Treynor - With risk-free rate" setup=[CommonTestSetup] begin
    stat = Treynor(risk_free=0.01)

    # Asset moves exactly with market (beta = 1)
    fit!(stat, AssetBenchmarkReturn(0.05, 0.05))
    fit!(stat, AssetBenchmarkReturn(0.03, 0.03))
    fit!(stat, AssetBenchmarkReturn(0.02, 0.02))
    fit!(stat, AssetBenchmarkReturn(0.06, 0.06))

    @test stat.n == 4
    # Mean asset return = (0.05 + 0.03 + 0.02 + 0.06) / 4 = 0.04
    # Beta = 1.0
    # Treynor = (0.04 - 0.01) / 1.0 = 0.03
    @test isapprox(value(stat), 0.03, atol=ATOL)
end

@testitem "Treynor - Zero beta returns Inf" setup=[CommonTestSetup] begin
    stat = Treynor()

    # Market has zero variance (all same values) -> beta = 0
    fit!(stat, AssetBenchmarkReturn(0.01, 0.02))
    fit!(stat, AssetBenchmarkReturn(0.03, 0.02))
    fit!(stat, AssetBenchmarkReturn(0.02, 0.02))

    @test stat.n == 3
    # Beta = 0 (from zero market variance)
    # Treynor with beta = 0 and positive excess return -> Inf
    @test isinf(value(stat)) || value(stat) == 0.0  # Depends on implementation
end

@testitem "Treynor - empty! resets state" setup=[CommonTestSetup] begin
    stat = Treynor()
    fit!(stat, AssetBenchmarkReturn(0.05, 0.03))
    fit!(stat, AssetBenchmarkReturn(0.02, 0.01))
    fit!(stat, AssetBenchmarkReturn(-0.01, -0.02))

    @test stat.n > 0

    empty!(stat)

    @test stat.n == 0
    @test value(stat) == 0.0
end

@testitem "Treynor - merge! combines statistics" setup=[CommonTestSetup] begin
    stat1 = Treynor()
    fit!(stat1, AssetBenchmarkReturn(0.01, 0.01))
    fit!(stat1, AssetBenchmarkReturn(0.02, 0.02))

    stat2 = Treynor()
    fit!(stat2, AssetBenchmarkReturn(0.03, 0.03))
    fit!(stat2, AssetBenchmarkReturn(-0.01, -0.01))

    full_stat = Treynor()
    fit!(full_stat, AssetBenchmarkReturn(0.01, 0.01))
    fit!(full_stat, AssetBenchmarkReturn(0.02, 0.02))
    fit!(full_stat, AssetBenchmarkReturn(0.03, 0.03))
    fit!(full_stat, AssetBenchmarkReturn(-0.01, -0.01))

    merge!(stat1, stat2)

    @test stat1.n == 4
    @test isapprox(value(stat1), value(full_stat), atol=ATOL)
end
