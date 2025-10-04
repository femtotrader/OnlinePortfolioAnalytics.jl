@testitem "AssetReturnMoments" setup=[CommonTestSetup] begin
    source = from(TSLA)
    _ret = SimpleAssetReturn()
    _moments = AssetReturnMoments()
    T = typeof(_moments)
    @test ismultioutput(T)
    @test expected_return_types(T) == (Float64, Float64, Float64, Float64)
    @test expected_return_values(AssetReturnMoments) ==
          (:mean, :std, :skewness, :kurtosis)

    NT = NamedTuple{
        (:mean, :std, :skewness, :kurtosis),
        Tuple{Float64,Float64,Float64,Float64},
    }

    mapped_source =
        source |>
        map(Union{Missing,Float64}, price -> (fit!(_ret, price);
        value(_ret))) |>
        filter(!ismissing) |>
        map(NT, r -> (fit!(_moments, r); value(_moments)))

    moments = NT[]
    function observer(value)
        push!(moments, value)
    end
    subscribe!(mapped_source, observer)
    moments_latest = moments[end]
    @test isapprox(moments_latest.mean, 0.0432, atol = ATOL)
    @test isapprox(moments_latest.std, 0.1496, atol = ATOL)
    @test isapprox(moments_latest.skewness, 1.3688, atol = ATOL)
    @test isapprox(moments_latest.kurtosis, 2.1968, atol = ATOL)

    empty!(_moments)
    @test _moments.n == 0
    @test value(_moments).mean == 0.0
    @test value(_moments).std == 0.0
    @test value(_moments).skewness == 0.0
    @test value(_moments).kurtosis == 0.0
    @test _moments.moments == Moments()
end
