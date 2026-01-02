@testitem "TSFrames - SimpleAssetReturn (SingleOutput)" setup=[CommonTestSetup] begin
    prices_ts = TSFrame([TSLA NFLX MSFT], dates, colnames = [:TSLA, :NFLX, :MSFT])
    
    pa_wrapper = PortfolioAnalyticsWrapper(SimpleAssetReturn)
    par = PortfolioAnalyticsResults()
    
    load!(prices_ts, par, pa_wrapper)
    expected = -0.0768
    @test isapprox(par._columns[:TSLA][end], expected, atol = ATOL)

    # test that the PortfolioAnalyticsResults `istable`
    @test Tables.istable(typeof(par))
    # test that it defines column access
    @test Tables.columnaccess(typeof(par))
    # test that we can access the first "column" of our PortfolioAnalyticsResults table by column name
    @test isapprox(par.TSLA[end], expected, atol = ATOL)
    @test isapprox(Tables.getcolumn(par, :TSLA)[end], expected, atol = ATOL)
    @test isapprox(Tables.getcolumn(par, 2)[end], expected, atol = ATOL)
    @test Tables.columnnames(par) == [:Index, :TSLA, :NFLX, :MSFT]
    # convert a PortfolioAnalyticsResults to TSFrame thanks to Tables.jl API
    ts_out = par |> TSFrame
    @test isapprox(ts_out.coredata[end, [:TSLA]][1], expected, atol = ATOL)
end

@testitem "TSFrames - Moments (MultiOutput)" setup=[CommonTestSetup] begin
    prices_ts = TSFrame([TSLA NFLX MSFT], dates, colnames = [:TSLA, :NFLX, :MSFT])
    
    pa_wrapper = PortfolioAnalyticsWrapper(AssetReturnMoments)
    par = PortfolioAnalyticsResults()
    
    load!(prices_ts, par, pa_wrapper)
    ts_out = par |> TSFrame
    data_last = ts_out.coredata[end, [:TSLA]][1]
    @test isapprox(data_last.mean, 265.9177, atol = ATOL)  # shouldn't use prices but returns
end

@testitem "TSFrames - Higher level functions" setup=[CommonTestSetup] begin
    prices_ts = TSFrame([TSLA NFLX MSFT], dates, colnames = [:TSLA, :NFLX, :MSFT])
    
    # Calculate asset returns from prices
    returns = SimpleAssetReturn(prices_ts)
    # Drop missing from returns
    returns = dropmissing(returns.coredata) |> TSFrame
    @test isapprox(returns.coredata[end, [:TSLA]][1], -0.0768, atol = ATOL)
    
    # Calculate standard deviation of returns
    stddev = StdDev(returns)
    @test isapprox(stddev.coredata[end, [:TSLA]][1], 0.1496, atol = ATOL)
    
    # Calculate arithmetic mean returns
    amr = ArithmeticMeanReturn(returns)
    @test isapprox(amr.coredata[end, [:TSLA]][1], 0.0432, atol = ATOL)
    
    # Calculate geometric mean returns
    gmr = GeometricMeanReturn(returns)
    @test isapprox(gmr.coredata[end, [:TSLA]][1], 0.0342, atol = ATOL)
    
    # Calculate asset log returns from prices
    log_returns = LogAssetReturn(prices_ts)[2:end]
    @test isapprox(log_returns.coredata[end, [:TSLA]][1], -0.0800, atol = ATOL)
    
    # Calculate cumulative return
    cum_returns = CumulativeReturn(returns)
    @test isapprox(cum_returns.coredata[end, [:TSLA]][1], 1.4976, atol = ATOL)
    
    # Calculate Drawdowns
    dd = DrawDowns(returns)
    @test isapprox(dd.coredata[end, [:TSLA]][1], -0.0768, atol = ATOL)
    
    # Calculate Drawdowns (Arithmetic method)
    add = ArithmeticDrawDowns(returns)
    @test isapprox(add.coredata[end, [:TSLA]][1], -0.0482, atol = ATOL)
    
    # Calculate statistical moments of returns
    moments = AssetReturnMoments(returns)
    last_moments = moments.coredata[end, [:TSLA]][1]
    @test isapprox(last_moments.mean, 0.0432, atol = ATOL)
    @test isapprox(last_moments.std, 0.1496, atol = ATOL)
    @test isapprox(last_moments.skewness, 1.3688, atol = ATOL)
    @test isapprox(last_moments.kurtosis, 2.1968, atol = ATOL)
    
    # Calculate Sharpe ratio (from returns)
    sharpe = Sharpe(returns, period = 1)
    @test isapprox(sharpe.coredata[end, [:TSLA]][1], 0.2886, atol = ATOL)
    
    # Calculate Sortino ratio (from returns)
    sortino = Sortino(returns)
    @test isapprox(sortino.coredata[end, [:TSLA]][1], 11.4992, atol = ATOL)
end

@testitem "TSFrames - VaR and ExpectedShortfall" setup=[CommonTestSetup] begin
    prices_ts = TSFrame([TSLA NFLX MSFT], dates, colnames = [:TSLA, :NFLX, :MSFT])
    returns = SimpleAssetReturn(prices_ts)
    returns = dropmissing(returns.coredata) |> TSFrame

    # Calculate VaR at 95%
    var_ts = VaR(returns, confidence=0.95)
    @test var_ts isa TSFrame
    @test length(var_ts.coredata[:, :TSLA]) == length(returns.coredata[:, :TSLA])

    # Calculate Expected Shortfall at 95%
    es_ts = ExpectedShortfall(returns, confidence=0.95)
    @test es_ts isa TSFrame
    @test length(es_ts.coredata[:, :TSLA]) == length(returns.coredata[:, :TSLA])
end

@testitem "TSFrames - DownsideDeviation and UpsideDeviation" setup=[CommonTestSetup] begin
    prices_ts = TSFrame([TSLA NFLX MSFT], dates, colnames = [:TSLA, :NFLX, :MSFT])
    returns = SimpleAssetReturn(prices_ts)
    returns = dropmissing(returns.coredata) |> TSFrame

    # Calculate DownsideDeviation
    dd_ts = DownsideDeviation(returns, threshold=0.0)
    @test dd_ts isa TSFrame
    @test length(dd_ts.coredata[:, :TSLA]) == length(returns.coredata[:, :TSLA])

    # Calculate UpsideDeviation
    ud_ts = UpsideDeviation(returns, threshold=0.0)
    @test ud_ts isa TSFrame
    @test length(ud_ts.coredata[:, :TSLA]) == length(returns.coredata[:, :TSLA])
end

@testitem "TSFrames - Omega Ratio" setup=[CommonTestSetup] begin
    prices_ts = TSFrame([TSLA NFLX MSFT], dates, colnames = [:TSLA, :NFLX, :MSFT])
    returns = SimpleAssetReturn(prices_ts)
    returns = dropmissing(returns.coredata) |> TSFrame

    # Calculate Omega
    omega_ts = Omega(returns, threshold=0.0)
    @test omega_ts isa TSFrame
    @test length(omega_ts.coredata[:, :TSLA]) == length(returns.coredata[:, :TSLA])
    # Final omega should be positive for TSLA (if gains > losses)
    @test omega_ts.coredata[end, :TSLA] > 0.0 || omega_ts.coredata[end, :TSLA] == Inf
end
