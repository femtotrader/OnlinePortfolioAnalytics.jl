@testitem "Sharpe" begin
    using OnlinePortfolioAnalytics
    using OnlinePortfolioAnalytics.SampleData: TSLA
    using OnlinePortfolioAnalytics: ismultioutput, expected_return_types
    using OnlineStatsBase
    using Rocket
    
    const ATOL = 0.0001
    
    source = from(TSLA)
    _ret = SimpleAssetReturn()
    _sharpe = Sharpe(period = 1)
    T = typeof(_sharpe)
    @test !ismultioutput(T)
    @test expected_return_types(T) == (Float64,)

    mapped_source =
        source |>
        map(Union{Missing,Float64}, price -> (fit!(_ret, price);
        value(_ret))) |>
        filter(!ismissing) |>
        map(Float64, r -> (fit!(_sharpe, r); value(_sharpe)))

    sharpes = Float64[]
    function observer(value)
        push!(sharpes, value)
    end
    subscribe!(mapped_source, observer)

    @test isapprox(sharpes[end], 0.2886, atol = ATOL)

    empty!(_sharpe)
    @test _sharpe.n == 0
    @test value(_sharpe) == 0.0
    @test _sharpe.mean == Mean()
    @test value(_sharpe.stddev) == 1
end
