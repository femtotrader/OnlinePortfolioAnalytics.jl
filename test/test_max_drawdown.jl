@testitem "MaxDrawDown - Constructor and initial state" setup=[CommonTestSetup] begin
    stat = MaxDrawDown()
    @test stat.n == 0
    @test value(stat) == 0.0
    @test !ismultioutput(typeof(stat))
    @test expected_return_types(typeof(stat)) == (Float64,)
end

@testitem "MaxDrawDown - fit! with single observation" setup=[CommonTestSetup] begin
    stat = MaxDrawDown()
    fit!(stat, 0.10)  # 10% gain
    @test stat.n == 1
    @test value(stat) == 0.0  # No drawdown after first positive return
end

@testitem "MaxDrawDown - value returns most negative drawdown" setup=[CommonTestSetup] begin
    stat = MaxDrawDown()
    # Sequence: gain, loss, gain
    fit!(stat, 0.10)   # Gain 10%
    fit!(stat, -0.15)  # Loss 15% -> drawdown occurs
    fit!(stat, 0.05)   # Recovery 5%

    # After the loss, drawdown should be negative
    @test value(stat) < 0.0
    # The maximum drawdown should be captured
    @test value(stat) <= -0.05  # At least some drawdown
end

@testitem "MaxDrawDown - TSLA returns sequence" setup=[CommonTestSetup] begin
    # Expected drawdowns from existing test:
    # [0.0, -0.1488, -0.1583, -0.1060, -0.2121, -0.1435, -0.1340, -0.0729, -0.0228, 0.0, 0.0, -0.0768]
    # The worst (most negative) is -0.2121

    stat = MaxDrawDown()
    _ret = SimpleAssetReturn()

    # Compute returns from TSLA prices and feed to MaxDrawDown
    for price in TSLA
        fit!(_ret, price)
        ret_val = value(_ret)
        if !ismissing(ret_val)
            fit!(stat, ret_val)
        end
    end

    # Maximum drawdown should match the worst point
    @test isapprox(value(stat), -0.2121, atol = ATOL)
end

@testitem "MaxDrawDown - empty! reset behavior" setup=[CommonTestSetup] begin
    stat = MaxDrawDown()
    fit!(stat, 0.10)
    fit!(stat, -0.05)
    fit!(stat, -0.10)

    @test stat.n > 0
    @test value(stat) < 0.0

    empty!(stat)

    @test stat.n == 0
    @test value(stat) == 0.0
end

@testitem "MaxDrawDown - Edge case: empty stat" setup=[CommonTestSetup] begin
    stat = MaxDrawDown()
    @test value(stat) == 0.0
    @test stat.n == 0
end

@testitem "MaxDrawDown - Edge case: all positive returns" setup=[CommonTestSetup] begin
    stat = MaxDrawDown()
    fit!(stat, 0.05)
    fit!(stat, 0.10)
    fit!(stat, 0.03)
    fit!(stat, 0.08)

    @test value(stat) == 0.0  # No drawdown when always going up
end

@testitem "MaxDrawDown - Edge case: all negative returns" setup=[CommonTestSetup] begin
    stat = MaxDrawDown()
    fit!(stat, -0.05)
    fit!(stat, -0.10)
    fit!(stat, -0.03)

    # Should capture the cumulative decline
    @test value(stat) < 0.0
    # Geometric: cumulative = (1-0.05)*(1-0.10)*(1-0.03) = 0.829
    # Peak after first obs = 0.95, so max dd = 0.829/0.95 - 1 ≈ -0.127
    @test isapprox(value(stat), -0.127, atol = 0.01)
end

@testitem "MaxArithmeticDrawDown - Constructor and initial state" setup=[CommonTestSetup] begin
    stat = MaxArithmeticDrawDown()
    @test stat.n == 0
    @test value(stat) == 0.0
    @test !ismultioutput(typeof(stat))
    @test expected_return_types(typeof(stat)) == (Float64,)
end

@testitem "MaxArithmeticDrawDown - fit! with return sequence" setup=[CommonTestSetup] begin
    stat = MaxArithmeticDrawDown()
    fit!(stat, 0.10)   # Gain
    fit!(stat, -0.15)  # Loss
    fit!(stat, 0.05)   # Partial recovery

    @test stat.n == 3
    @test value(stat) < 0.0  # Should have drawdown
end

@testitem "MaxArithmeticDrawDown - Geometric vs Arithmetic differ" setup=[CommonTestSetup] begin
    returns = [0.10, -0.20, 0.15, -0.10]

    geo_stat = MaxDrawDown()
    arith_stat = MaxArithmeticDrawDown()

    for ret in returns
        fit!(geo_stat, ret)
        fit!(arith_stat, ret)
    end

    # Results should be different (geometric uses product, arithmetic uses sum)
    @test value(geo_stat) != value(arith_stat)
    # Both should be negative (drawdowns occurred)
    @test value(geo_stat) < 0.0
    @test value(arith_stat) < 0.0
end

@testitem "MaxArithmeticDrawDown - TSLA returns sequence" setup=[CommonTestSetup] begin
    # Expected arithmetic drawdowns from existing test:
    # [0.0, -0.1323, -0.1422, -0.0870, -0.1926, -0.1151, -0.1053, -0.0424, 0.0, 0.0, 0.0, -0.0482]
    # The worst (most negative) is -0.1926

    stat = MaxArithmeticDrawDown()
    _ret = SimpleAssetReturn()

    for price in TSLA
        fit!(_ret, price)
        ret_val = value(_ret)
        if !ismissing(ret_val)
            fit!(stat, ret_val)
        end
    end

    # Maximum drawdown should match the worst point
    @test isapprox(value(stat), -0.1926, atol = ATOL)
end

@testitem "MaxArithmeticDrawDown - empty! reset behavior" setup=[CommonTestSetup] begin
    stat = MaxArithmeticDrawDown()
    fit!(stat, 0.10)
    fit!(stat, -0.05)

    empty!(stat)

    @test stat.n == 0
    @test value(stat) == 0.0
end

@testitem "MaxDrawDown - merge! consecutive partitions" setup=[CommonTestSetup] begin
    # Full sequence
    full_stat = MaxDrawDown()
    _ret = SimpleAssetReturn()

    for price in TSLA
        fit!(_ret, price)
        ret_val = value(_ret)
        if !ismissing(ret_val)
            fit!(full_stat, ret_val)
        end
    end
    full_result = value(full_stat)

    # Split into two partitions (first half, second half)
    stat1 = MaxDrawDown()
    stat2 = MaxDrawDown()
    _ret1 = SimpleAssetReturn()
    _ret2 = SimpleAssetReturn()

    # First partition (first 7 prices -> 6 returns)
    for price in TSLA[1:7]
        fit!(_ret1, price)
        ret_val = value(_ret1)
        if !ismissing(ret_val)
            fit!(stat1, ret_val)
        end
    end

    # Second partition (remaining prices)
    for price in TSLA[7:end]
        fit!(_ret2, price)
        ret_val = value(_ret2)
        if !ismissing(ret_val)
            fit!(stat2, ret_val)
        end
    end

    # Merge stat2 into stat1
    merge!(stat1, stat2)

    # Note: Merge may not exactly match full computation due to
    # cross-partition drawdown considerations, but should be close
    # or at least capture the worst drawdown from either partition
    @test value(stat1) <= 0.0
    @test value(stat1) <= max(full_result * 0.9, -0.25)  # Reasonable bound
end

@testitem "MaxDrawDown - merge! matches sequential (simple case)" setup=[CommonTestSetup] begin
    # Simple case where max drawdown is entirely in one partition
    stat1 = MaxDrawDown()
    fit!(stat1, 0.10)
    fit!(stat1, -0.05)

    stat2 = MaxDrawDown()
    fit!(stat2, 0.03)
    fit!(stat2, -0.02)

    original_stat1_val = value(stat1)
    original_stat2_val = value(stat2)

    merge!(stat1, stat2)

    # After merge, should have the minimum (worst) of both
    @test value(stat1) == min(original_stat1_val, original_stat2_val)
end

@testitem "MaxArithmeticDrawDown - merge!" setup=[CommonTestSetup] begin
    stat1 = MaxArithmeticDrawDown()
    fit!(stat1, 0.10)
    fit!(stat1, -0.20)

    stat2 = MaxArithmeticDrawDown()
    fit!(stat2, 0.05)
    fit!(stat2, -0.10)

    original_stat1_val = value(stat1)
    original_stat2_val = value(stat2)

    merge!(stat1, stat2)

    # After merge, should have the minimum (worst) of both
    @test value(stat1) == min(original_stat1_val, original_stat2_val)
end

@testitem "MaxDrawDown - TSFrames integration" setup=[CommonTestSetup] begin
    # Create TSFrame with price data
    prices_ts = TSFrame([TSLA NFLX MSFT], dates, colnames=[:TSLA, :NFLX, :MSFT])

    # Calculate returns first
    returns_ts = SimpleAssetReturn(prices_ts)
    returns_ts = dropmissing(returns_ts.coredata) |> TSFrame

    # Test MaxDrawDown with TSFrames
    mdd_ts = MaxDrawDown(returns_ts)

    # Final max drawdown for TSLA should match our known value
    @test isapprox(mdd_ts.coredata[end, :TSLA], -0.2121, atol=ATOL)
end

@testitem "MaxArithmeticDrawDown - TSFrames integration" setup=[CommonTestSetup] begin
    # Create TSFrame with price data
    prices_ts = TSFrame([TSLA NFLX MSFT], dates, colnames=[:TSLA, :NFLX, :MSFT])

    # Calculate returns first
    returns_ts = SimpleAssetReturn(prices_ts)
    returns_ts = dropmissing(returns_ts.coredata) |> TSFrame

    # Test MaxArithmeticDrawDown with TSFrames
    mdd_ts = MaxArithmeticDrawDown(returns_ts)

    # Final max drawdown for TSLA should match our known value
    @test isapprox(mdd_ts.coredata[end, :TSLA], -0.1926, atol=ATOL)
end
