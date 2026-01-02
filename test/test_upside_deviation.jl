# UpsideDeviation tests

@testitem "UpsideDeviation - Constructor and initial state" setup=[CommonTestSetup] begin
    stat = UpsideDeviation()
    @test stat.n == 0
    @test value(stat) == 0.0
    @test stat.threshold == 0.0
    @test stat isa UpsideDeviation{Float64}
end

@testitem "UpsideDeviation - Parameterized constructor Float32" setup=[CommonTestSetup] begin
    stat = UpsideDeviation{Float32}()
    @test stat isa UpsideDeviation{Float32}
    @test stat.n == 0
    @test value(stat) == 0.0f0
end

@testitem "UpsideDeviation - Custom threshold" setup=[CommonTestSetup] begin
    stat = UpsideDeviation(threshold=0.02)
    @test stat.threshold == 0.02
    @test stat isa UpsideDeviation{Float64}
end

@testitem "UpsideDeviation - Empty state returns 0.0" setup=[CommonTestSetup] begin
    stat = UpsideDeviation()
    @test value(stat) == 0.0
    @test stat.n == 0
end

@testitem "UpsideDeviation - All returns below threshold" setup=[CommonTestSetup] begin
    stat = UpsideDeviation(threshold=0.0)

    fit!(stat, -0.05)
    fit!(stat, -0.02)
    fit!(stat, -0.03)
    fit!(stat, -0.01)

    @test stat.n == 4
    @test value(stat) == 0.0  # No returns above threshold
end

@testitem "UpsideDeviation - All returns above threshold" setup=[CommonTestSetup] begin
    stat = UpsideDeviation(threshold=0.0)

    # All positive returns
    fit!(stat, 0.05)
    fit!(stat, 0.02)
    fit!(stat, 0.03)
    fit!(stat, 0.01)

    @test stat.n == 4
    @test value(stat) > 0.0

    # Manual calculation: sqrt(sum(max(ret-0, 0)^2) / n)
    # deviations = [0.05, 0.02, 0.03, 0.01]
    # sum_sq = 0.0025 + 0.0004 + 0.0009 + 0.0001 = 0.0039
    # UD = sqrt(0.0039 / 4) = 0.03122...
    expected = sqrt((0.05^2 + 0.02^2 + 0.03^2 + 0.01^2) / 4)
    @test isapprox(value(stat), expected, atol=ATOL)
end

@testitem "UpsideDeviation - Mixed returns" setup=[CommonTestSetup] begin
    stat = UpsideDeviation(threshold=0.0)

    # Mix of positive and negative
    fit!(stat, 0.05)   # above
    fit!(stat, -0.02)  # below
    fit!(stat, 0.03)   # above
    fit!(stat, -0.03)  # below

    @test stat.n == 4
    @test value(stat) > 0.0

    # Only positive returns contribute: 0.05, 0.03
    # sum_sq = 0.0025 + 0.0009 = 0.0034
    # UD = sqrt(0.0034 / 4) = 0.02915...  (uses total n)
    expected = sqrt((0.05^2 + 0.03^2) / 4)
    @test isapprox(value(stat), expected, atol=ATOL)
end

@testitem "UpsideDeviation - With custom threshold (MAR)" setup=[CommonTestSetup] begin
    stat = UpsideDeviation(threshold=0.02)

    # Returns relative to MAR = 2%
    fit!(stat, 0.05)   # above: +3% vs MAR
    fit!(stat, 0.01)   # below: -1% vs MAR
    fit!(stat, 0.03)   # above: +1% vs MAR
    fit!(stat, -0.01)  # below: -3% vs MAR

    @test stat.n == 4
    @test value(stat) > 0.0

    # Above threshold: (0.05 - 0.02)^2 = 0.0009, (0.03 - 0.02)^2 = 0.0001
    # sum_sq = 0.0010
    # UD = sqrt(0.0010 / 4) = 0.01581...
    expected = sqrt((0.03^2 + 0.01^2) / 4)
    @test isapprox(value(stat), expected, atol=ATOL)
end

@testitem "UpsideDeviation - empty! resets state" setup=[CommonTestSetup] begin
    stat = UpsideDeviation()
    fit!(stat, 0.05)
    fit!(stat, -0.02)
    fit!(stat, 0.03)

    @test stat.n > 0

    empty!(stat)

    @test stat.n == 0
    @test value(stat) == 0.0
end

@testitem "UpsideDeviation - merge! combines statistics" setup=[CommonTestSetup] begin
    stat1 = UpsideDeviation()
    fit!(stat1, 0.02)
    fit!(stat1, -0.03)

    stat2 = UpsideDeviation()
    fit!(stat2, 0.01)
    fit!(stat2, -0.04)

    full_stat = UpsideDeviation()
    fit!(full_stat, 0.02)
    fit!(full_stat, -0.03)
    fit!(full_stat, 0.01)
    fit!(full_stat, -0.04)

    merge!(stat1, stat2)

    @test stat1.n == 4
    @test isapprox(value(stat1), value(full_stat), atol=ATOL)
end
