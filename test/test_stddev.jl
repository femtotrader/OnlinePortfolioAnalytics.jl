@testitem "StdDev of prices" setup=[CommonTestSetup] begin
    _stddev = StdDev()
    T = typeof(_stddev)
    @test !ismultioutput(T)
    @test expected_return_types(T) == (Float64,)
    fit!(_stddev, TSLA)
    @test isapprox(value(_stddev), 60.5448, atol = ATOL)
end

@testitem "StdDev of returns" setup=[CommonTestSetup] begin
    source = from(TSLA)
    _ret = SimpleAssetReturn()
    _stddev = StdDev()

    mapped_source =
        source |>
        map(Union{Missing,Float64}, price -> (fit!(_ret, price);
        value(_ret))) |>
        filter(!ismissing) |>
        map(Float64, r -> (fit!(_stddev, r); value(_stddev)))
    stddev_returns = Float64[]
    function observer(value)
        push!(stddev_returns, value)
    end
    subscribe!(mapped_source, observer)
    @test isapprox(stddev_returns[end], 0.1496, atol = ATOL)

    empty!(_stddev)
    @test value(_stddev) == 1
    @test _stddev.n == 0
    @test value(_stddev.variance) == 1
end
