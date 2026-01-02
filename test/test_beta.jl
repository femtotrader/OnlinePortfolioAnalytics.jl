# T031: Constructor and initial state tests
@testitem "Beta - Constructor and initial state" setup=[CommonTestSetup] begin
    stat = Beta()
    @test stat.n == 0
    @test value(stat) == 0.0
    @test !ismultioutput(typeof(stat))
    # Beta accepts AssetMarketReturn input
    @test stat isa Beta{Float64}
end

@testitem "Beta - Parameterized constructor" setup=[CommonTestSetup] begin
    stat = Beta{Float32}()
    @test stat isa Beta{Float32}
    @test stat.n == 0
end

# T032: Perfect correlation test (beta=1.0)
@testitem "Beta - Perfect correlation (beta=1.0)" setup=[CommonTestSetup] begin
    stat = Beta()
    # Asset moves exactly with market
    fit!(stat, AssetMarketReturn(0.01, 0.01))
    fit!(stat, AssetMarketReturn(0.02, 0.02))
    fit!(stat, AssetMarketReturn(0.03, 0.03))
    fit!(stat, AssetMarketReturn(-0.01, -0.01))

    @test stat.n == 4
    @test isapprox(value(stat), 1.0, atol=ATOL)
end

@testitem "Beta - Asset moves twice as much as market (beta=2.0)" setup=[CommonTestSetup] begin
    stat = Beta()
    # Asset moves 2x the market
    fit!(stat, AssetMarketReturn(0.02, 0.01))
    fit!(stat, AssetMarketReturn(0.04, 0.02))
    fit!(stat, AssetMarketReturn(-0.02, -0.01))
    fit!(stat, AssetMarketReturn(0.06, 0.03))

    @test stat.n == 4
    @test isapprox(value(stat), 2.0, atol=ATOL)
end

@testitem "Beta - Asset moves half as much as market (beta=0.5)" setup=[CommonTestSetup] begin
    stat = Beta()
    # Asset moves 0.5x the market
    fit!(stat, AssetMarketReturn(0.005, 0.01))
    fit!(stat, AssetMarketReturn(0.01, 0.02))
    fit!(stat, AssetMarketReturn(-0.005, -0.01))
    fit!(stat, AssetMarketReturn(0.015, 0.03))

    @test stat.n == 4
    @test isapprox(value(stat), 0.5, atol=ATOL)
end

# T033: Negative correlation test (beta<0)
@testitem "Beta - Negative correlation (beta<0)" setup=[CommonTestSetup] begin
    stat = Beta()
    # Asset moves opposite to market
    fit!(stat, AssetMarketReturn(-0.01, 0.01))
    fit!(stat, AssetMarketReturn(-0.02, 0.02))
    fit!(stat, AssetMarketReturn(0.01, -0.01))
    fit!(stat, AssetMarketReturn(-0.03, 0.03))

    @test stat.n == 4
    @test value(stat) < 0.0
    @test isapprox(value(stat), -1.0, atol=ATOL)
end

# T034: Insufficient data edge case test (n<2 returns 0.0)
@testitem "Beta - Insufficient data (n<2)" setup=[CommonTestSetup] begin
    stat = Beta()
    @test value(stat) == 0.0  # n=0

    fit!(stat, AssetMarketReturn(0.05, 0.03))
    @test stat.n == 1
    @test value(stat) == 0.0  # n=1, still insufficient
end

# T035: Zero variance edge case test (returns 0.0)
@testitem "Beta - Zero market variance (returns 0.0)" setup=[CommonTestSetup] begin
    stat = Beta()
    # Market has zero variance (all same values)
    fit!(stat, AssetMarketReturn(0.01, 0.02))
    fit!(stat, AssetMarketReturn(0.03, 0.02))
    fit!(stat, AssetMarketReturn(0.02, 0.02))

    @test stat.n == 3
    @test value(stat) == 0.0  # Avoid division by zero
end

# T036: empty!() reset test
@testitem "Beta - empty! reset behavior" setup=[CommonTestSetup] begin
    stat = Beta()
    fit!(stat, AssetMarketReturn(0.05, 0.03))
    fit!(stat, AssetMarketReturn(0.02, 0.01))
    fit!(stat, AssetMarketReturn(-0.01, -0.02))

    @test stat.n > 0

    empty!(stat)

    @test stat.n == 0
    @test value(stat) == 0.0
end

# T037: merge!() test
@testitem "Beta - merge!" setup=[CommonTestSetup] begin
    stat1 = Beta()
    fit!(stat1, AssetMarketReturn(0.01, 0.01))
    fit!(stat1, AssetMarketReturn(0.02, 0.02))

    stat2 = Beta()
    fit!(stat2, AssetMarketReturn(0.03, 0.03))
    fit!(stat2, AssetMarketReturn(-0.01, -0.01))

    # Full sequence
    full_stat = Beta()
    fit!(full_stat, AssetMarketReturn(0.01, 0.01))
    fit!(full_stat, AssetMarketReturn(0.02, 0.02))
    fit!(full_stat, AssetMarketReturn(0.03, 0.03))
    fit!(full_stat, AssetMarketReturn(-0.01, -0.01))

    merge!(stat1, stat2)

    @test stat1.n == 4
    @test isapprox(value(stat1), value(full_stat), atol=ATOL)
end

@testitem "Beta - Edge case: empty stat" setup=[CommonTestSetup] begin
    stat = Beta()
    @test value(stat) == 0.0
    @test stat.n == 0
end

@testitem "Beta - Known formula verification" setup=[CommonTestSetup] begin
    stat = Beta()
    # Known sequence for manual verification
    # Asset returns: [0.10, 0.05, -0.02, 0.08]
    # Market returns: [0.08, 0.04, -0.01, 0.06]
    fit!(stat, AssetMarketReturn(0.10, 0.08))
    fit!(stat, AssetMarketReturn(0.05, 0.04))
    fit!(stat, AssetMarketReturn(-0.02, -0.01))
    fit!(stat, AssetMarketReturn(0.08, 0.06))

    @test stat.n == 4

    # Manual calculation:
    # Mean asset = (0.10 + 0.05 - 0.02 + 0.08) / 4 = 0.0525
    # Mean market = (0.08 + 0.04 - 0.01 + 0.06) / 4 = 0.0425
    asset = [0.10, 0.05, -0.02, 0.08]
    market = [0.08, 0.04, -0.01, 0.06]
    mean_a = sum(asset) / 4  # 0.0525
    mean_m = sum(market) / 4  # 0.0425

    # Cov = sum((ai - mean_a)(mi - mean_m)) / (n-1)
    cov_am = sum((asset .- mean_a) .* (market .- mean_m)) / 3  # n-1=3

    # Var = sum((mi - mean_m)^2) / (n-1)
    var_m = sum((market .- mean_m).^2) / 3  # n-1=3

    # Beta = Cov / Var
    expected_beta = cov_am / var_m

    @test isapprox(value(stat), expected_beta, atol=ATOL)
end

# T063: TSFrames integration test (paired columns approach)
@testitem "Beta - TSFrames paired columns integration" setup=[CommonTestSetup] begin
    # Beta requires paired (asset, market) returns via AssetMarketReturn
    # For TSFrames, we manually iterate over columns

    # Create TSFrame with price data
    prices_ts = TSFrame([TSLA NFLX MSFT], dates, colnames=[:TSLA, :NFLX, :MSFT])

    # Calculate returns
    returns_ts = SimpleAssetReturn(prices_ts)
    returns_df = dropmissing(returns_ts.coredata)

    # Get the return columns
    tsla_returns = returns_df[:, :TSLA]
    nflx_returns = returns_df[:, :NFLX]

    # Calculate Beta for TSLA against NFLX (as market proxy)
    stat = Beta()
    for i in 1:length(tsla_returns)
        fit!(stat, AssetMarketReturn(tsla_returns[i], nflx_returns[i]))
    end

    @test stat.n == length(tsla_returns)
    @test !isnan(value(stat))
    @test isfinite(value(stat))
end
