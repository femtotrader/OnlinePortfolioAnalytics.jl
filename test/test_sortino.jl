@testitem "Sortino" begin
    using OnlinePortfolioAnalytics
    using OnlinePortfolioAnalytics.SampleData: TSLA
    using OnlinePortfolioAnalytics: ismultioutput, expected_return_types
    using OnlineStatsBase
    using Rocket
    
    const ATOL = 0.0001
    
    source = from(TSLA)
    _ret = SimpleAssetReturn()
    _sortino = Sortino()
    T = typeof(_sortino)
    @test !ismultioutput(T)
    @test expected_return_types(T) == (Float64,)

    mapped_source =
        source |>
        map(Union{Missing,Float64}, price -> (fit!(_ret, price);
        value(_ret))) |>
        filter(!ismissing) |>
        map(Float64, r -> (fit!(_sortino, r); value(_sortino)))

    sortinos = Float64[]
    function observer(value)
        push!(sortinos, value)
    end
    subscribe!(mapped_source, observer)

    @test isapprox(sortinos[end], 11.4992, atol = ATOL)

    empty!(_sortino)
    @test _sortino.n == 0
    @test value(_sortino) == 0.0
    @test _sortino.mean_ret == Mean()
    @test value(_sortino.stddev_neg_ret) == 1
end
