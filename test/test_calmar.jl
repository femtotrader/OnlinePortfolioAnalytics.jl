# T020: Constructor and initial state tests
@testitem "Calmar - Constructor and initial state" setup=[CommonTestSetup] begin
    stat = Calmar()
    @test stat.n == 0
    @test value(stat) == 0.0
    @test stat.period == 252  # Default daily period
    @test !ismultioutput(typeof(stat))
    @test expected_return_types(typeof(stat)) == (Float64,)
end

@testitem "Calmar - Constructor with custom period" setup=[CommonTestSetup] begin
    stat = Calmar(period=12)  # Monthly
    @test stat.period == 12
    @test stat.n == 0
    @test value(stat) == 0.0
end

@testitem "Calmar - Parameterized constructor" setup=[CommonTestSetup] begin
    stat = Calmar{Float32}(period=52)  # Weekly
    @test stat isa Calmar{Float32}
    @test stat.period == 52
end

# T021: Known sequence test (verify ratio formula)
@testitem "Calmar - Known sequence (ratio formula)" setup=[CommonTestSetup] begin
    stat = Calmar()
    # Create a sequence with known annualized return and max drawdown
    returns = [0.05, -0.03, 0.02, -0.08, 0.04, 0.03]
    for ret in returns
        fit!(stat, ret)
    end
    @test stat.n == 6

    # Calculate expected values
    # Annualized return
    cumulative = prod([1 + r for r in returns])
    ann_return = cumulative^(252/6) - 1

    # Max drawdown (use internal stat)
    mdd_stat = MaxDrawDown()
    for ret in returns
        fit!(mdd_stat, ret)
    end
    max_dd = value(mdd_stat)

    # Calmar = annualized_return / |max_drawdown|
    expected_calmar = ann_return / abs(max_dd)
    @test isapprox(value(stat), expected_calmar, atol=ATOL)
end

@testitem "Calmar - Matches component stats" setup=[CommonTestSetup] begin
    stat = Calmar()
    ann_stat = AnnualizedReturn()
    mdd_stat = MaxDrawDown()

    returns = [0.02, -0.05, 0.03, -0.02, 0.01]
    for ret in returns
        fit!(stat, ret)
        fit!(ann_stat, ret)
        fit!(mdd_stat, ret)
    end

    ann_return = value(ann_stat)
    max_dd = value(mdd_stat)

    if max_dd != 0.0
        expected = ann_return / abs(max_dd)
        @test isapprox(value(stat), expected, atol=ATOL)
    end
end

# T022: Zero drawdown edge case test (returns Inf)
@testitem "Calmar - Zero drawdown returns Inf" setup=[CommonTestSetup] begin
    stat = Calmar()
    # All positive returns = no drawdown
    fit!(stat, 0.01)
    fit!(stat, 0.02)
    fit!(stat, 0.03)
    fit!(stat, 0.01)

    @test stat.n == 4
    @test isinf(value(stat))  # Should be Inf
    @test value(stat) > 0  # Positive infinity
end

@testitem "Calmar - Single positive return" setup=[CommonTestSetup] begin
    stat = Calmar()
    fit!(stat, 0.05)

    @test stat.n == 1
    # No drawdown after first positive return -> Inf
    @test isinf(value(stat))
end

# T023: empty!() reset test
@testitem "Calmar - empty! reset behavior" setup=[CommonTestSetup] begin
    stat = Calmar()
    fit!(stat, 0.05)
    fit!(stat, -0.03)
    fit!(stat, 0.02)

    @test stat.n > 0

    empty!(stat)

    @test stat.n == 0
    @test value(stat) == 0.0
end

@testitem "Calmar - Edge case: empty stat" setup=[CommonTestSetup] begin
    stat = Calmar()
    @test value(stat) == 0.0
    @test stat.n == 0
end

@testitem "Calmar - Monthly period" setup=[CommonTestSetup] begin
    stat = Calmar(period=12)
    returns = [0.08, -0.05, 0.03, -0.10, 0.06]  # Monthly returns
    for ret in returns
        fit!(stat, ret)
    end

    @test stat.n == 5
    # Verify it uses the correct period
    @test stat.period == 12
    @test !isnan(value(stat))
end

# T062: TSFrames integration test
@testitem "Calmar - TSFrames integration" setup=[CommonTestSetup] begin
    # Create TSFrame with price data
    prices_ts = TSFrame([TSLA NFLX MSFT], dates, colnames=[:TSLA, :NFLX, :MSFT])

    # Calculate returns first
    returns_ts = SimpleAssetReturn(prices_ts)
    returns_ts = dropmissing(returns_ts.coredata) |> TSFrame

    # Test Calmar with TSFrames
    calmar_ts = Calmar(returns_ts)

    # Verify we have results for each column
    @test :TSLA in Tables.columnnames(calmar_ts.coredata)
    @test :NFLX in Tables.columnnames(calmar_ts.coredata)
    @test :MSFT in Tables.columnnames(calmar_ts.coredata)

    # Final Calmar should be a valid number
    @test !isnan(calmar_ts.coredata[end, :TSLA])
    @test isfinite(calmar_ts.coredata[end, :TSLA]) || isinf(calmar_ts.coredata[end, :TSLA])
end
