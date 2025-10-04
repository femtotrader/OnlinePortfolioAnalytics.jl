@testitem "LogAssetReturn with 1 point" begin
    using OnlinePortfolioAnalytics
    using OnlinePortfolioAnalytics.SampleData: TSLA
    using OnlinePortfolioAnalytics: ismultioutput, expected_return_types
    using OnlineStatsBase
    using Test
    
    const ATOL = 0.0001
    
    stat = LogAssetReturn()
    T = typeof(stat)
    @test !ismultioutput(T)
    @test expected_return_types(T) == (Union{Missing,Float64},)
    fit!(stat, TSLA[1])
    fit!(stat, TSLA[2])
    @test isapprox(value(stat), 0.1174, atol = ATOL)
end

@testitem "LogAssetReturn with several points" begin
    using OnlinePortfolioAnalytics
    using OnlinePortfolioAnalytics.SampleData: TSLA
    using OnlineStatsBase
    using Rocket
    
    const ATOL = 0.0001
    
    stat = LogAssetReturn()
    source = from(TSLA)

    mapped_source =
        source |>
        map(Union{Missing,Float64}, price -> (fit!(stat, price); value(stat)))
    returns = Union{Missing,Float64}[]
    function observer(value)
        push!(returns, value)
    end
    subscribe!(mapped_source, observer)
    expected_returns = [
        missing,
        0.1174,
        -0.1611,
        -0.0113,
        0.0603,
        -0.1264,
        0.0836,
        0.0110,
        0.0683,
        0.0526,
        0.3622,
        0.0272,
        -0.0800,
    ]
    @test sum(ismissing.(returns)) == sum(ismissing.(expected_returns))
    @test all(isapprox.(returns[2:end], expected_returns[2:end], atol = ATOL))

    empty!(stat)
    @test ismissing(value(stat))
    @test stat.n == 0
end
