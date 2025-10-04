@testitem "CumulativeReturn" setup=[CommonTestSetup] begin
    
    source = from(TSLA)
    ret = SimpleAssetReturn()
    cum_ret = CumulativeReturn()
    T = typeof(cum_ret)
    @test !ismultioutput(T)
    @test expected_return_types(T) == (Float64,)

    mapped_source =
        source |>
        map(Union{Missing,Float64}, price -> (fit!(ret, price); value(ret))) |>
        filter(!ismissing) |>
        map(Float64, r -> (fit!(cum_ret, r); value(cum_ret)))

    cum_returns = Float64[]
    function observer(value)
        push!(cum_returns, value)
    end
    subscribe!(mapped_source, observer)

    expected_cum_returns = [
        1.1245,
        0.9572,
        0.9465,
        1.0054,
        0.8860,
        0.9632,
        0.9738,
        1.0426,
        1.0989,
        1.5787,
        1.6222,
        1.4976,
    ]
    @test all(isapprox.(cum_returns, expected_cum_returns, atol = ATOL))

    empty!(cum_ret)
    @test cum_ret.n == 0
    @test value(cum_ret) == 0.0
    @test value(cum_ret.prod) == 1.0
end
