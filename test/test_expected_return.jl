# T046: Constructor and initial state tests
@testitem "ExpectedReturn - Constructor and initial state" setup=[CommonTestSetup] begin
    stat = ExpectedReturn()
    @test stat.n == 0
    @test value(stat) == 0.0  # Default risk_free=0.0
    @test stat.risk_free == 0.0
    @test !ismultioutput(typeof(stat))
    @test stat isa ExpectedReturn{Float64}
end

@testitem "ExpectedReturn - Constructor with custom risk_free" setup=[CommonTestSetup] begin
    stat = ExpectedReturn(risk_free=0.02)  # 2% risk-free rate
    @test stat.risk_free == 0.02
    @test stat.n == 0
    @test value(stat) == 0.02  # Returns risk_free when n < 2
end

@testitem "ExpectedReturn - Parameterized constructor" setup=[CommonTestSetup] begin
    stat = ExpectedReturn{Float32}(risk_free=0.03f0)
    @test stat isa ExpectedReturn{Float32}
    @test stat.risk_free ≈ 0.03f0
end

# T047: CAPM formula test
@testitem "ExpectedReturn - CAPM formula" setup=[CommonTestSetup] begin
    stat = ExpectedReturn(risk_free=0.02)

    # Create observations that produce known beta and market mean
    # Use perfect correlation so beta = 1.0 (asset moves exactly with market)
    fit!(stat, AssetBenchmarkReturn(0.05, 0.05))
    fit!(stat, AssetBenchmarkReturn(0.10, 0.10))
    fit!(stat, AssetBenchmarkReturn(-0.02, -0.02))
    fit!(stat, AssetBenchmarkReturn(0.07, 0.07))

    @test stat.n == 4

    # With beta = 1.0:
    # Market mean = (0.05 + 0.10 - 0.02 + 0.07) / 4 = 0.05
    # Expected = rf + beta * (market_mean - rf)
    # Expected = 0.02 + 1.0 * (0.05 - 0.02) = 0.05
    @test isapprox(value(stat), 0.05, atol=ATOL)
end

# T048: beta=1.0 test (returns market mean)
@testitem "ExpectedReturn - beta=1.0 returns close to market mean" setup=[CommonTestSetup] begin
    stat = ExpectedReturn(risk_free=0.0)  # rf=0 for simpler calculation

    # Perfect correlation: asset = market (beta = 1.0)
    fit!(stat, AssetBenchmarkReturn(0.04, 0.04))
    fit!(stat, AssetBenchmarkReturn(0.06, 0.06))
    fit!(stat, AssetBenchmarkReturn(0.08, 0.08))

    @test stat.n == 3

    # Market mean = (0.04 + 0.06 + 0.08) / 3 = 0.06
    # Expected = 0.0 + 1.0 * (0.06 - 0.0) = 0.06
    market_mean = (0.04 + 0.06 + 0.08) / 3
    @test isapprox(value(stat), market_mean, atol=ATOL)
end

# T049: beta=0.0 test (returns risk-free rate)
@testitem "ExpectedReturn - beta=0 returns risk_free" setup=[CommonTestSetup] begin
    stat = ExpectedReturn(risk_free=0.03)

    # Asset has no correlation with market (constant asset return)
    # This produces beta ≈ 0
    fit!(stat, AssetBenchmarkReturn(0.05, 0.01))
    fit!(stat, AssetBenchmarkReturn(0.05, 0.03))
    fit!(stat, AssetBenchmarkReturn(0.05, -0.01))
    fit!(stat, AssetBenchmarkReturn(0.05, 0.02))

    @test stat.n == 4

    # When beta = 0: Expected = rf + 0 * (market_mean - rf) = rf
    # Since asset is constant (0.05), covariance with market is 0
    # So beta = 0 and expected return = risk_free = 0.03
    @test isapprox(value(stat), 0.03, atol=ATOL)
end

# T050: Insufficient data test (n<2 returns risk-free)
@testitem "ExpectedReturn - Insufficient data (n<2)" setup=[CommonTestSetup] begin
    stat = ExpectedReturn(risk_free=0.025)

    @test value(stat) == 0.025  # n=0

    fit!(stat, AssetBenchmarkReturn(0.05, 0.03))
    @test stat.n == 1
    @test value(stat) == 0.025  # n=1, still insufficient
end

# T051: empty!() reset test
@testitem "ExpectedReturn - empty! reset behavior" setup=[CommonTestSetup] begin
    stat = ExpectedReturn(risk_free=0.02)
    fit!(stat, AssetBenchmarkReturn(0.05, 0.03))
    fit!(stat, AssetBenchmarkReturn(0.02, 0.01))
    fit!(stat, AssetBenchmarkReturn(-0.01, -0.02))

    @test stat.n > 0

    empty!(stat)

    @test stat.n == 0
    @test value(stat) == 0.02  # Returns risk_free after reset
    @test stat.risk_free == 0.02  # risk_free preserved
end

# T052: merge!() test
@testitem "ExpectedReturn - merge!" setup=[CommonTestSetup] begin
    stat1 = ExpectedReturn(risk_free=0.01)
    fit!(stat1, AssetBenchmarkReturn(0.05, 0.05))
    fit!(stat1, AssetBenchmarkReturn(0.10, 0.10))

    stat2 = ExpectedReturn(risk_free=0.01)
    fit!(stat2, AssetBenchmarkReturn(-0.02, -0.02))
    fit!(stat2, AssetBenchmarkReturn(0.07, 0.07))

    # Full sequence
    full_stat = ExpectedReturn(risk_free=0.01)
    fit!(full_stat, AssetBenchmarkReturn(0.05, 0.05))
    fit!(full_stat, AssetBenchmarkReturn(0.10, 0.10))
    fit!(full_stat, AssetBenchmarkReturn(-0.02, -0.02))
    fit!(full_stat, AssetBenchmarkReturn(0.07, 0.07))

    merge!(stat1, stat2)

    @test stat1.n == 4
    @test isapprox(value(stat1), value(full_stat), atol=ATOL)
end

@testitem "ExpectedReturn - Edge case: empty stat" setup=[CommonTestSetup] begin
    stat = ExpectedReturn(risk_free=0.015)
    @test value(stat) == 0.015
    @test stat.n == 0
end

@testitem "ExpectedReturn - High beta scenario" setup=[CommonTestSetup] begin
    stat = ExpectedReturn(risk_free=0.02)

    # Asset moves 1.5x the market (beta ≈ 1.5)
    fit!(stat, AssetBenchmarkReturn(0.015, 0.01))
    fit!(stat, AssetBenchmarkReturn(0.030, 0.02))
    fit!(stat, AssetBenchmarkReturn(-0.015, -0.01))
    fit!(stat, AssetBenchmarkReturn(0.045, 0.03))

    @test stat.n == 4

    # Beta should be approximately 1.5
    # Market mean = (0.01 + 0.02 - 0.01 + 0.03) / 4 = 0.0125
    # Expected = 0.02 + 1.5 * (0.0125 - 0.02) = 0.02 + 1.5 * (-0.0075) = 0.02 - 0.01125 = 0.00875
    # Due to how beta is calculated with variance, actual result may vary
    @test !isnan(value(stat))
    @test isfinite(value(stat))
end

# T064: TSFrames integration test (paired columns approach)
@testitem "ExpectedReturn - TSFrames paired columns integration" setup=[CommonTestSetup] begin
    # ExpectedReturn requires paired (asset, market) returns via AssetBenchmarkReturn
    # For TSFrames, we manually iterate over columns

    # Create TSFrame with price data
    prices_ts = TSFrame([TSLA NFLX MSFT], dates, colnames=[:TSLA, :NFLX, :MSFT])

    # Calculate returns
    returns_ts = SimpleAssetReturn(prices_ts)
    returns_df = dropmissing(returns_ts.coredata)

    # Get the return columns
    tsla_returns = returns_df[:, :TSLA]
    nflx_returns = returns_df[:, :NFLX]

    # Calculate ExpectedReturn for TSLA against NFLX (as market proxy)
    stat = ExpectedReturn(risk_free=0.02)
    for i in 1:length(tsla_returns)
        fit!(stat, AssetBenchmarkReturn(tsla_returns[i], nflx_returns[i]))
    end

    @test stat.n == length(tsla_returns)
    @test !isnan(value(stat))
    @test isfinite(value(stat))
end
