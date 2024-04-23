using OnlinePortfolioAnalytics
using OnlineStatsBase
using Rocket
using Test

const ATOL = 0.0001
const TSLA = [
    235.22,
    264.51,
    225.16,
    222.64,
    236.48,
    208.40,
    226.56,
    229.06,
    245.24,
    258.49,
    371.33,
    381.58,
    352.26,
]
const NFLX = [
    540.73,
    532.39,
    538.85,
    521.66,
    513.47,
    502.81,
    528.21,
    517.57,
    569.19,
    610.34,
    690.31,
    641.90,
    602.44,
]
const MSFT = [
    222.42,
    231.96,
    232.38,
    235.77,
    252.18,
    249.68,
    270.90,
    284.91,
    301.88,
    281.92,
    331.62,
    330.59,
    336.32,
]
const weights = [0.4, 0.4, 0.2]

@testset "OnlinePortfolioAnalytics.jl" begin
    @testset "SimpleAssetReturn" begin
        @testset "SimpleAssetReturn with period=1" begin
            stat = SimpleAssetReturn{Float64}()
            fit!(stat, TSLA[1])
            fit!(stat, TSLA[2])
            @test round(value(stat), digits = 4) == 0.1245
        end
        @testset "SimpleAssetReturn with period=3" begin
            stat = SimpleAssetReturn{Float64}(period = 3)
            fit!(stat, TSLA[1])
            fit!(stat, TSLA[2])
            fit!(stat, TSLA[3])
            fit!(stat, TSLA[4])
            @test isapprox(value(stat), (222.64 - 235.22) / 235.2, atol = ATOL)
        end
        @testset "SimpleAssetReturn with period=1 and Rocket" begin
            stat = SimpleAssetReturn{Float64}()
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
        end
    end

    @testset "LogAssetReturn" begin
        @testset "1 point" begin
            stat = LogAssetReturn{Float64}()
            fit!(stat, TSLA[1])
            fit!(stat, TSLA[2])
            @test isapprox(value(stat), 0.1174, atol = ATOL)
        end

        @testset "several points" begin
            stat = LogAssetReturn{Float64}()
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
        end
    end

    @testset "StdDev" begin
        stat = StdDev{Float64}()
        fit!(stat, TSLA)
        @test isapprox(value(stat), 60.5448, atol = ATOL)
    end

    @testset "ArithmeticMeanReturn" begin
        source = from(TSLA)
        _ret = SimpleAssetReturn{Float64}()
        _mean = Mean()
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

    @testset "GeometricMeanReturn" begin
        source = from(TSLA)
        _ret = SimpleAssetReturn{Float64}()
        _mean = GeometricMeanReturn{Float64}()
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

    @testset "CumulativeReturn" begin
        source = from(TSLA)
        ret = SimpleAssetReturn{Float64}()
        cum_ret = CumulativeReturn{Float64}()

        mapped_source =
            source |>
            map(Union{Missing,Float64}, price -> (fit!(ret, price);
            # println("Received price value: ", price);
            value(ret))) |>
            filter(!ismissing) |>
            map(Float64, r -> (fit!(cum_ret, r); value(cum_ret)))

        cum_returns = Float64[]
        function observer(value)
            # println("Received cum_ret value: ", value)
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

    end


    @testset "DrawDowns" begin
        @testset "Geometric" begin
            source = from(TSLA)
            _ret = SimpleAssetReturn{Float64}()
            _ddowns = DrawDowns{Float64}()

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
        end

        @testset "Arithmetic" begin
            source = from(TSLA)
            _ret = SimpleAssetReturn{Float64}()
            _ddowns = ArithmeticDrawDowns{Float64}()

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
        end

    end

    @testset "Moments" begin

        source = from(TSLA)
        _ret = SimpleAssetReturn{Float64}()
        _moments = AssetReturnMoments{Float64}()
        #_moments = Moments()

        mapped_source =
            source |>
            map(Union{Missing,Float64}, price -> (fit!(_ret, price);
            value(_ret))) |>
            filter(!ismissing) |>
            map(Any, r -> (fit!(_moments, r); value(_moments)))

        NT = NamedTuple{
            (:mean, :std, :skewness, :kurtosis),
            Tuple{Float64,Float64,Float64,Float64},
        }
        expected_moments = NT[]
        function observer(value)
            push!(expected_moments, value)
        end
        subscribe!(mapped_source, observer)
        moments = expected_moments[end]
        @test isapprox(moments.mean, 0.0431772, atol = ATOL)
        @test isapprox(moments.std, 0.1496, atol = ATOL)
        @test isapprox(moments.skewness, 1.3688, atol = ATOL)
        @test isapprox(moments.kurtosis, 2.1968, atol = ATOL)
    end


end
