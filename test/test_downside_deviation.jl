# DownsideDeviation tests

@testitem "DownsideDeviation - Constructor and initial state" setup=[CommonTestSetup] begin
    stat = DownsideDeviation()
    @test stat.n == 0
    @test value(stat) == 0.0
    @test stat.threshold == 0.0
    @test stat isa DownsideDeviation{Float64}
end

@testitem "DownsideDeviation - Parameterized constructor Float32" setup=[CommonTestSetup] begin
    stat = DownsideDeviation{Float32}()
    @test stat isa DownsideDeviation{Float32}
    @test stat.n == 0
    @test value(stat) == 0.0f0
end

@testitem "DownsideDeviation - Custom threshold" setup=[CommonTestSetup] begin
    stat = DownsideDeviation(threshold=0.02)
    @test stat.threshold == 0.02
    @test stat isa DownsideDeviation{Float64}
end

@testitem "DownsideDeviation - Empty state returns 0.0" setup=[CommonTestSetup] begin
    stat = DownsideDeviation()
    @test value(stat) == 0.0
    @test stat.n == 0
end

@testitem "DownsideDeviation - All returns above threshold" setup=[CommonTestSetup] begin
    stat = DownsideDeviation(threshold=0.0)

    fit!(stat, 0.05)
    fit!(stat, 0.02)
    fit!(stat, 0.03)
    fit!(stat, 0.01)

    @test stat.n == 4
    @test value(stat) == 0.0  # No returns below threshold
end

@testitem "DownsideDeviation - All returns below threshold" setup=[CommonTestSetup] begin
    stat = DownsideDeviation(threshold=0.0)

    # All negative returns
    fit!(stat, -0.05)
    fit!(stat, -0.02)
    fit!(stat, -0.03)
    fit!(stat, -0.01)

    @test stat.n == 4
    @test value(stat) > 0.0

    # Manual calculation: sqrt(sum(min(ret-0, 0)^2) / n)
    # deviations = [-0.05, -0.02, -0.03, -0.01]
    # sum_sq = 0.0025 + 0.0004 + 0.0009 + 0.0001 = 0.0039
    # DD = sqrt(0.0039 / 4) = 0.03122...
    expected = sqrt((0.05^2 + 0.02^2 + 0.03^2 + 0.01^2) / 4)
    @test isapprox(value(stat), expected, atol=ATOL)
end

@testitem "DownsideDeviation - Mixed returns" setup=[CommonTestSetup] begin
    stat = DownsideDeviation(threshold=0.0)

    # Mix of positive and negative
    fit!(stat, 0.05)   # above
    fit!(stat, -0.02)  # below
    fit!(stat, 0.03)   # above
    fit!(stat, -0.03)  # below

    @test stat.n == 4
    @test value(stat) > 0.0

    # Only negative returns contribute: -0.02, -0.03
    # sum_sq = 0.0004 + 0.0009 = 0.0013
    # DD = sqrt(0.0013 / 4) = 0.01803...  (uses total n)
    expected = sqrt((0.02^2 + 0.03^2) / 4)
    @test isapprox(value(stat), expected, atol=ATOL)
end

@testitem "DownsideDeviation - With custom threshold (MAR)" setup=[CommonTestSetup] begin
    stat = DownsideDeviation(threshold=0.02)

    # Returns relative to MAR = 2%
    fit!(stat, 0.05)   # above: +3% vs MAR
    fit!(stat, 0.01)   # below: -1% vs MAR
    fit!(stat, 0.03)   # above: +1% vs MAR
    fit!(stat, -0.01)  # below: -3% vs MAR

    @test stat.n == 4
    @test value(stat) > 0.0

    # Below threshold: (0.01 - 0.02)^2 = 0.0001, (-0.01 - 0.02)^2 = 0.0009
    # sum_sq = 0.0010
    # DD = sqrt(0.0010 / 4) = 0.01581...
    expected = sqrt((0.01^2 + 0.03^2) / 4)
    @test isapprox(value(stat), expected, atol=ATOL)
end

@testitem "DownsideDeviation - empty! resets state" setup=[CommonTestSetup] begin
    stat = DownsideDeviation()
    fit!(stat, -0.05)
    fit!(stat, 0.02)
    fit!(stat, -0.03)

    @test stat.n > 0

    empty!(stat)

    @test stat.n == 0
    @test value(stat) == 0.0
end

@testitem "DownsideDeviation - merge! combines statistics" setup=[CommonTestSetup] begin
    stat1 = DownsideDeviation()
    fit!(stat1, -0.02)
    fit!(stat1, 0.03)

    stat2 = DownsideDeviation()
    fit!(stat2, -0.01)
    fit!(stat2, 0.04)

    full_stat = DownsideDeviation()
    fit!(full_stat, -0.02)
    fit!(full_stat, 0.03)
    fit!(full_stat, -0.01)
    fit!(full_stat, 0.04)

    merge!(stat1, stat2)

    @test stat1.n == 4
    @test isapprox(value(stat1), value(full_stat), atol=ATOL)
end
