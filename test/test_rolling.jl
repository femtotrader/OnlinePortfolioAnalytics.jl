# T048: Rolling wrapper tests - TDD (write tests FIRST)

@testitem "Rolling - Constructor with window" setup=[CommonTestSetup] begin
    stat = Rolling(Sharpe{Float64}(), window=60)
    @test stat.n == 0
    @test stat.window == 60
    @test stat isa Rolling{Float64,Sharpe{Float64}}
end

@testitem "Rolling - Constructor validation" setup=[CommonTestSetup] begin
    # Window must be > 0
    @test_throws ArgumentError Rolling(Sharpe{Float64}(), window=0)
    @test_throws ArgumentError Rolling(Sharpe{Float64}(), window=-1)
end

@testitem "Rolling - Basic rolling Sharpe calculation" setup=[CommonTestSetup] begin
    stat = Rolling(Sharpe{Float64}(), window=5)

    # Add 7 observations
    returns = [0.02, -0.01, 0.03, 0.01, -0.02, 0.04, 0.02]
    for r in returns
        fit!(stat, r)
    end

    @test stat.n == 7
    # Value should be Sharpe of last 5 observations only
    @test isfinite(value(stat))
end

@testitem "Rolling - Partial window behavior" setup=[CommonTestSetup] begin
    stat = Rolling(Sharpe{Float64}(), window=10)

    # Add fewer observations than window size
    fit!(stat, 0.02)
    fit!(stat, -0.01)
    fit!(stat, 0.03)

    @test stat.n == 3
    # Should still compute on available data
    @test isfinite(value(stat))
end

@testitem "Rolling - Full window behavior" setup=[CommonTestSetup] begin
    stat = Rolling(StdDev{Float64}(), window=3)

    # Fill buffer
    fit!(stat, 0.01)
    @test stat.n == 1

    fit!(stat, 0.02)
    @test stat.n == 2

    fit!(stat, 0.03)
    @test stat.n == 3

    # Buffer is full, next observation replaces oldest
    fit!(stat, 0.04)
    @test stat.n == 4

    # Value is now StdDev of [0.02, 0.03, 0.04] (last 3)
    @test isfinite(value(stat))
end

@testitem "Rolling - Wrapped stat type preserved" setup=[CommonTestSetup] begin
    sharpe_rolling = Rolling(Sharpe{Float64}(), window=30)
    maxdd_rolling = Rolling(MaxDrawDown{Float64}(), window=30)
    calmar_rolling = Rolling(Calmar{Float64}(), window=30)

    @test sharpe_rolling.stat isa Sharpe{Float64}
    @test maxdd_rolling.stat isa MaxDrawDown{Float64}
    @test calmar_rolling.stat isa Calmar{Float64}
end

@testitem "Rolling - Rolling MaxDrawDown" setup=[CommonTestSetup] begin
    stat = Rolling(MaxDrawDown{Float64}(), window=5)

    returns = [0.05, -0.02, -0.03, 0.01, 0.02, 0.04, -0.01]
    for r in returns
        fit!(stat, r)
    end

    @test stat.n == 7
    @test isfinite(value(stat))
    @test value(stat) <= 0.0  # Max drawdown is non-positive
end

@testitem "Rolling - Rolling Calmar" setup=[CommonTestSetup] begin
    stat = Rolling(Calmar{Float64}(), window=10)

    # Need observations for meaningful Calmar
    for i in 1:15
        ret = 0.01 * sin(i)  # Oscillating returns
        fit!(stat, ret)
    end

    @test stat.n == 15
    @test isfinite(value(stat)) || isinf(value(stat))
end

@testitem "Rolling - Works with multiple existing metrics" setup=[CommonTestSetup] begin
    # SC-007 requirement: Rolling should work with 10+ existing metrics
    metrics = [
        Rolling(Sharpe{Float64}(), window=5),
        Rolling(MaxDrawDown{Float64}(), window=5),
        Rolling(Calmar{Float64}(), window=5),
        Rolling(StdDev{Float64}(), window=5),
        Rolling(ArithmeticMeanReturn{Float64}(), window=5),
        Rolling(GeometricMeanReturn{Float64}(), window=5),
        Rolling(CumulativeReturn{Float64}(), window=5),
        Rolling(DrawDowns{Float64}(), window=5),
        Rolling(VaR{Float64}(), window=5),
        Rolling(Sortino{Float64}(), window=5),
        Rolling(UlcerIndex{Float64}(), window=5),
        Rolling(AnnualVolatility{Float64}(), window=5)
    ]

    returns = [0.02, -0.01, 0.03, -0.02, 0.01, 0.04, -0.03]
    for r in returns
        for stat in metrics
            fit!(stat, r)
        end
    end

    # All should have processed observations
    for stat in metrics
        @test stat.n == 7
    end
end

@testitem "Rolling - empty! reset behavior" setup=[CommonTestSetup] begin
    stat = Rolling(Sharpe{Float64}(), window=5)

    for r in [0.02, -0.01, 0.03]
        fit!(stat, r)
    end

    @test stat.n > 0

    empty!(stat)

    @test stat.n == 0
end

@testitem "Rolling - Window slides correctly" setup=[CommonTestSetup] begin
    stat = Rolling(ArithmeticMeanReturn{Float64}(), window=3)

    fit!(stat, 0.10)  # Window: [0.10], mean = 0.10
    @test isapprox(value(stat), 0.10, atol=ATOL)

    fit!(stat, 0.20)  # Window: [0.10, 0.20], mean = 0.15
    @test isapprox(value(stat), 0.15, atol=ATOL)

    fit!(stat, 0.30)  # Window: [0.10, 0.20, 0.30], mean = 0.20
    @test isapprox(value(stat), 0.20, atol=ATOL)

    fit!(stat, 0.40)  # Window: [0.20, 0.30, 0.40], mean = 0.30
    @test isapprox(value(stat), 0.30, atol=ATOL)

    fit!(stat, 0.50)  # Window: [0.30, 0.40, 0.50], mean = 0.40
    @test isapprox(value(stat), 0.40, atol=ATOL)
end

@testitem "Rolling - Different window sizes" setup=[CommonTestSetup] begin
    stat3 = Rolling(ArithmeticMeanReturn{Float64}(), window=3)
    stat5 = Rolling(ArithmeticMeanReturn{Float64}(), window=5)
    stat10 = Rolling(ArithmeticMeanReturn{Float64}(), window=10)

    returns = [0.01 * i for i in 1:15]
    for r in returns
        fit!(stat3, r)
        fit!(stat5, r)
        fit!(stat10, r)
    end

    # Different window sizes should give different results
    @test value(stat3) != value(stat5)
    @test value(stat5) != value(stat10)
end
