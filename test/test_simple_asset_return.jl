@testitem "SimpleAssetReturn with period=1" setup=[CommonTestSetup] begin
    stat = SimpleAssetReturn()
    fit!(stat, TSLA[1])
    fit!(stat, TSLA[2])
    @test round(value(stat), digits = 4) == 0.1245
    T = typeof(stat)
    @test !ismultioutput(T)
    @test expected_return_types(T) == (Union{Missing,Float64},)
end

@testitem "SimpleAssetReturn with period=3" setup=[CommonTestSetup] begin
    stat = SimpleAssetReturn(period = 3)
    fit!(stat, TSLA[1])
    fit!(stat, TSLA[2])
    fit!(stat, TSLA[3])
    fit!(stat, TSLA[4])
    @test isapprox(value(stat), (222.64 - 235.22) / 235.2, atol = ATOL)
end

@testitem "SimpleAssetReturn with period=1 and Rocket" setup=[CommonTestSetup] begin
    stat = SimpleAssetReturn()
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
        0.1245,
        -0.1487,
        -0.0112,
        0.0622,
        -0.1187,
        0.0871,
        0.0110,
        0.0706,
        0.0540,
        0.4365,
        0.0276,
        -0.0768,
    ]
    @test sum(ismissing.(returns)) == sum(ismissing.(expected_returns))
    @test all(isapprox.(returns[2:end], expected_returns[2:end], atol = ATOL))

    empty!(stat)
    @test ismissing(value(stat))
    @test stat.n == 0
end
