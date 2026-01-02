# Omega Ratio tests

@testitem "Omega - Constructor and initial state" setup=[CommonTestSetup] begin
    stat = Omega()
    @test stat.n == 0
    @test value(stat) == 0.0
    @test stat.threshold == 0.0
    @test stat isa Omega{Float64}
end

@testitem "Omega - Parameterized constructor Float32" setup=[CommonTestSetup] begin
    stat = Omega{Float32}()
    @test stat isa Omega{Float32}
    @test stat.n == 0
    @test value(stat) == 0.0f0
end

@testitem "Omega - Custom threshold" setup=[CommonTestSetup] begin
    stat = Omega(threshold=0.02)
    @test stat.threshold == 0.02
    @test stat isa Omega{Float64}
end

@testitem "Omega - Empty state returns 0.0" setup=[CommonTestSetup] begin
    stat = Omega()
    @test value(stat) == 0.0
    @test stat.n == 0
end

@testitem "Omega - All gains (no losses)" setup=[CommonTestSetup] begin
    stat = Omega(threshold=0.0)

    fit!(stat, 0.05)
    fit!(stat, 0.02)
    fit!(stat, 0.03)
    fit!(stat, 0.01)

    @test stat.n == 4
    @test isinf(value(stat))  # No losses -> Inf
end

@testitem "Omega - All losses (no gains)" setup=[CommonTestSetup] begin
    stat = Omega(threshold=0.0)

    fit!(stat, -0.05)
    fit!(stat, -0.02)
    fit!(stat, -0.03)
    fit!(stat, -0.01)

    @test stat.n == 4
    @test value(stat) == 0.0  # No gains -> 0
end

@testitem "Omega - Mixed gains and losses" setup=[CommonTestSetup] begin
    stat = Omega(threshold=0.0)

    # Gains: 0.05, 0.03 -> sum = 0.08
    # Losses: 0.02, 0.01 -> sum = 0.03
    fit!(stat, 0.05)   # gain
    fit!(stat, -0.02)  # loss
    fit!(stat, 0.03)   # gain
    fit!(stat, -0.01)  # loss

    @test stat.n == 4
    @test value(stat) > 0.0

    # Omega = sum_gains / sum_losses = 0.08 / 0.03 = 2.666...
    expected = 0.08 / 0.03
    @test isapprox(value(stat), expected, atol=ATOL)
end

@testitem "Omega - With custom threshold" setup=[CommonTestSetup] begin
    stat = Omega(threshold=0.02)

    # Relative to threshold=0.02:
    # 0.05: gain of 0.03
    # 0.01: loss of 0.01
    # 0.03: gain of 0.01
    # -0.01: loss of 0.03
    fit!(stat, 0.05)
    fit!(stat, 0.01)
    fit!(stat, 0.03)
    fit!(stat, -0.01)

    @test stat.n == 4
    @test value(stat) > 0.0

    # Omega = (0.03 + 0.01) / (0.01 + 0.03) = 0.04 / 0.04 = 1.0
    expected = 0.04 / 0.04
    @test isapprox(value(stat), expected, atol=ATOL)
end

@testitem "Omega - Equal gains and losses" setup=[CommonTestSetup] begin
    stat = Omega(threshold=0.0)

    # Symmetric: gains = losses
    fit!(stat, 0.02)
    fit!(stat, -0.02)
    fit!(stat, 0.03)
    fit!(stat, -0.03)

    @test stat.n == 4
    # Omega = (0.02 + 0.03) / (0.02 + 0.03) = 1.0
    @test isapprox(value(stat), 1.0, atol=ATOL)
end

@testitem "Omega - empty! resets state" setup=[CommonTestSetup] begin
    stat = Omega()
    fit!(stat, 0.05)
    fit!(stat, -0.02)
    fit!(stat, 0.03)

    @test stat.n > 0

    empty!(stat)

    @test stat.n == 0
    @test value(stat) == 0.0
end

@testitem "Omega - merge! combines statistics" setup=[CommonTestSetup] begin
    stat1 = Omega()
    fit!(stat1, 0.02)
    fit!(stat1, -0.01)

    stat2 = Omega()
    fit!(stat2, 0.03)
    fit!(stat2, -0.02)

    full_stat = Omega()
    fit!(full_stat, 0.02)
    fit!(full_stat, -0.01)
    fit!(full_stat, 0.03)
    fit!(full_stat, -0.02)

    merge!(stat1, stat2)

    @test stat1.n == 4
    @test isapprox(value(stat1), value(full_stat), atol=ATOL)
end
