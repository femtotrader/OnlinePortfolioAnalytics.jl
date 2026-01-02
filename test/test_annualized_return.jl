# T007: Constructor and initial state tests
@testitem "AnnualizedReturn - Constructor and initial state" setup=[CommonTestSetup] begin
    stat = AnnualizedReturn()
    @test stat.n == 0
    @test value(stat) == 0.0
    @test stat.period == 252  # Default daily period
    @test !ismultioutput(typeof(stat))
    @test expected_return_types(typeof(stat)) == (Float64,)
end

@testitem "AnnualizedReturn - Constructor with custom period" setup=[CommonTestSetup] begin
    stat = AnnualizedReturn(period=12)  # Monthly
    @test stat.period == 12
    @test stat.n == 0
    @test value(stat) == 0.0
end

@testitem "AnnualizedReturn - Parameterized constructor" setup=[CommonTestSetup] begin
    stat = AnnualizedReturn{Float32}(period=52)  # Weekly
    @test stat isa AnnualizedReturn{Float32}
    @test stat.period == 52
end

# T008: Single observation test
@testitem "AnnualizedReturn - Single observation" setup=[CommonTestSetup] begin
    stat = AnnualizedReturn()
    fit!(stat, 0.01)  # 1% return
    @test stat.n == 1
    # With n=1, annualized = (1.01)^(252/1) - 1
    expected = (1.01)^252 - 1
    @test isapprox(value(stat), expected, atol=ATOL)
end

# T009: Known sequence test (CAGR formula verification)
@testitem "AnnualizedReturn - Known sequence (CAGR formula)" setup=[CommonTestSetup] begin
    stat = AnnualizedReturn()
    returns = [0.01, 0.02, -0.01, 0.03]
    for ret in returns
        fit!(stat, ret)
    end
    @test stat.n == 4

    # Cumulative = 1.01 * 1.02 * 0.99 * 1.03 = 1.050906
    cumulative = 1.01 * 1.02 * 0.99 * 1.03
    # Annualized = cumulative^(252/4) - 1
    expected = cumulative^(252/4) - 1
    @test isapprox(value(stat), expected, atol=ATOL)
end

@testitem "AnnualizedReturn - Monthly period" setup=[CommonTestSetup] begin
    stat = AnnualizedReturn(period=12)
    returns = [0.05, 0.03, -0.02]  # 3 monthly returns
    for ret in returns
        fit!(stat, ret)
    end
    @test stat.n == 3

    # Cumulative = 1.05 * 1.03 * 0.98 = 1.05987
    cumulative = 1.05 * 1.03 * 0.98
    # Annualized = cumulative^(12/3) - 1
    expected = cumulative^(12/3) - 1
    @test isapprox(value(stat), expected, atol=ATOL)
end

# T010: empty!() reset test
@testitem "AnnualizedReturn - empty! reset behavior" setup=[CommonTestSetup] begin
    stat = AnnualizedReturn()
    fit!(stat, 0.05)
    fit!(stat, 0.03)

    @test stat.n > 0
    @test value(stat) != 0.0

    empty!(stat)

    @test stat.n == 0
    @test value(stat) == 0.0
end

# T011: Edge case tests
@testitem "AnnualizedReturn - Edge case: empty stat" setup=[CommonTestSetup] begin
    stat = AnnualizedReturn()
    @test value(stat) == 0.0
    @test stat.n == 0
end

@testitem "AnnualizedReturn - Edge case: single observation extrapolation" setup=[CommonTestSetup] begin
    stat = AnnualizedReturn(period=252)
    fit!(stat, 0.001)  # 0.1% daily return
    @test stat.n == 1
    # Should extrapolate based on period
    expected = (1.001)^252 - 1
    @test isapprox(value(stat), expected, atol=ATOL)
end

@testitem "AnnualizedReturn - Edge case: all negative returns" setup=[CommonTestSetup] begin
    stat = AnnualizedReturn()
    fit!(stat, -0.01)
    fit!(stat, -0.02)
    fit!(stat, -0.01)

    @test stat.n == 3
    @test value(stat) < 0.0  # Negative annualized return
end

@testitem "AnnualizedReturn - Edge case: zero returns" setup=[CommonTestSetup] begin
    stat = AnnualizedReturn()
    fit!(stat, 0.0)
    fit!(stat, 0.0)

    @test stat.n == 2
    @test value(stat) == 0.0  # (1.0)^any - 1 = 0
end

# T061: TSFrames integration test
@testitem "AnnualizedReturn - TSFrames integration" setup=[CommonTestSetup] begin
    # Create TSFrame with price data
    prices_ts = TSFrame([TSLA NFLX MSFT], dates, colnames=[:TSLA, :NFLX, :MSFT])

    # Calculate returns first
    returns_ts = SimpleAssetReturn(prices_ts)
    returns_ts = dropmissing(returns_ts.coredata) |> TSFrame

    # Test AnnualizedReturn with TSFrames
    ann_ts = AnnualizedReturn(returns_ts)

    # Verify we have results for each column
    @test :TSLA in Tables.columnnames(ann_ts.coredata)
    @test :NFLX in Tables.columnnames(ann_ts.coredata)
    @test :MSFT in Tables.columnnames(ann_ts.coredata)

    # Final annualized return should be a valid number
    @test !isnan(ann_ts.coredata[end, :TSLA])
    @test isfinite(ann_ts.coredata[end, :TSLA])
end
