@testitem "ArithmeticMeanReturn" begin
    using OnlinePortfolioAnalytics
    using OnlinePortfolioAnalytics.SampleData: TSLA
    using OnlinePortfolioAnalytics: ismultioutput
    using OnlineStatsBase
    using Rocket
    
    const ATOL = 0.0001
    
    source = from(TSLA)
    _ret = SimpleAssetReturn()
    _mean = ArithmeticMeanReturn()
    @test !ismultioutput(typeof(_mean))

    mapped_source =
        source |>
        map(Union{Missing,Float64}, price -> (fit!(_ret, price);
        value(_ret))) |>
        filter(!ismissing) |>
        map(Float64, r -> (fit!(_mean, r); value(_mean)))
    mean_returns = Float64[]
    function observer(value)
        push!(mean_returns, value)
    end
    subscribe!(mapped_source, observer)
    @test isapprox(mean_returns[end], 0.0432, atol = ATOL)
end

@testitem "GeometricMeanReturn" begin
    using OnlinePortfolioAnalytics
    using OnlinePortfolioAnalytics.SampleData: TSLA
    using OnlinePortfolioAnalytics: ismultioutput, expected_return_types
    using OnlineStatsBase
    using Rocket
    
    const ATOL = 0.0001
    
    source = from(TSLA)
    _ret = SimpleAssetReturn()
    _mean = GeometricMeanReturn()
    T = typeof(_mean)
    @test !ismultioutput(T)
    @test expected_return_types(T) == (Float64,)

    mapped_source =
        source |>
        map(Union{Missing,Float64}, price -> (fit!(_ret, price);
        value(_ret))) |>
        filter(!ismissing) |>
        map(Float64, r -> (fit!(_mean, r); value(_mean)))
    mean_returns = Float64[]
    function observer(value)
        push!(mean_returns, value)
    end
    subscribe!(mapped_source, observer)
    @test isapprox(mean_returns[end], 0.0342, atol = ATOL)
end
