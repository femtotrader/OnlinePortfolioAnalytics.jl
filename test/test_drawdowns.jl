@testitem "DrawDowns - Geometric" setup=[CommonTestSetup] begin
    source = from(TSLA)
    _ret = SimpleAssetReturn()
    _ddowns = DrawDowns()
    T = typeof(_ddowns)
    @test !ismultioutput(T)
    @test expected_return_types(T) == (Float64,)

    mapped_source =
        source |>
        map(Union{Missing,Float64}, price -> (fit!(_ret, price);
        value(_ret))) |>
        filter(!ismissing) |>
        map(Float64, r -> (fit!(_ddowns, r); value(_ddowns)))

    drawdowns = Float64[]
    function observer(value)
        push!(drawdowns, value)
    end
    subscribe!(mapped_source, observer)

    expected_drawdowns = [
        0.0,
        -0.1488,
        -0.1583,
        -0.1060,
        -0.2121,
        -0.1435,
        -0.1340,
        -0.0729,
        -0.0228,
        0.0,
        0.0,
        -0.0768,
    ]
    @test all(isapprox.(drawdowns, expected_drawdowns, atol = ATOL))

    empty!(_ddowns)
    @test _ddowns.n == 0
    @test value(_ddowns) == 0.0
    @test value(_ddowns.prod) == 1.0
    @test _ddowns.extrema == Extrema()
end

@testitem "DrawDowns - Arithmetic" setup=[CommonTestSetup] begin
    source = from(TSLA)
    _ret = SimpleAssetReturn()
    _ddowns = ArithmeticDrawDowns()
    T = typeof(_ddowns)
    @test !ismultioutput(T)
    @test expected_return_types(T) == (Float64,)

    mapped_source =
        source |>
        map(Union{Missing,Float64}, price -> (fit!(_ret, price);
        value(_ret))) |>
        filter(!ismissing) |>
        map(Float64, r -> (fit!(_ddowns, r); value(_ddowns)))

    drawdowns = Float64[]
    function observer(value)
        push!(drawdowns, value)
    end
    subscribe!(mapped_source, observer)

    expected_drawdowns = [
        0.0,
        -0.1323,
        -0.1422,
        -0.0870,
        -0.1926,
        -0.1151,
        -0.1053,
        -0.0424,
        0.0,
        0.0,
        0.0,
        -0.0482,
    ]
    @test all(isapprox.(drawdowns, expected_drawdowns, atol = ATOL))

    empty!(_ddowns)
    @test _ddowns.n == 0
    @test value(_ddowns) == 0.0
    @test value(_ddowns.sum) == 0.0
    @test _ddowns.extrema == Extrema()
end
