using Dates
using OnlinePortfolioAnalytics
using OnlinePortfolioAnalytics.SampleData: dates, TSLA, NFLX, MSFT, weights
using OnlinePortfolioAnalytics: ismultioutput, expected_return_types, expected_return_values
using Tables
using OnlinePortfolioAnalytics: load!, PortfolioAnalyticsWrapper, PortfolioAnalyticsResults
using OnlineStatsBase
using Rocket
using Test
using TSFrames, DataFrames

const ATOL = 0.0001

@testset "OnlinePortfolioAnalytics.jl" begin
    @testset "Basic types" begin
        @testset "SimpleAssetReturn" begin
            @testset "SimpleAssetReturn with period=1" begin
                stat = SimpleAssetReturn{Float64}()
                fit!(stat, TSLA[1])
                fit!(stat, TSLA[2])
                @test round(value(stat), digits = 4) == 0.1245
                T = typeof(stat)
                @test !ismultioutput(T)
                @test expected_return_types(T) == (Union{Missing,Float64},)
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

                empty!(stat)
                @test ismissing(value(stat))
                @test stat.n == 0

            end
        end

        @testset "LogAssetReturn" begin
            @testset "1 point" begin
                stat = LogAssetReturn{Float64}()
                T = typeof(stat)
                @test !ismultioutput(T)
                @test expected_return_types(T) == (Union{Missing,Float64},)
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

                empty!(stat)
                @test ismissing(value(stat))
                @test stat.n == 0
            end
        end

        @testset "StdDev" begin
            @testset "StdDev of prices" begin
                _stddev = StdDev{Float64}()
                T = typeof(_stddev)
                @test !ismultioutput(T)
                @test expected_return_types(T) == (Float64,)
                fit!(_stddev, TSLA)
                @test isapprox(value(_stddev), 60.5448, atol = ATOL)
            end

            @testset "StdDev of returns" begin
                source = from(TSLA)
                _ret = SimpleAssetReturn{Float64}()
                _stddev = StdDev{Float64}()

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
        end

        @testset "MeanReturn" begin
            @testset "ArithmeticMeanReturn" begin
                source = from(TSLA)
                _ret = SimpleAssetReturn{Float64}()
                _mean = ArithmeticMeanReturn{Float64}()
                @test !ismultioutput(typeof(_mean))  # ToFix

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
        end

        @testset "CumulativeReturn" begin
            source = from(TSLA)
            ret = SimpleAssetReturn{Float64}()
            cum_ret = CumulativeReturn{Float64}()
            T = typeof(cum_ret)
            @test !ismultioutput(T)
            @test expected_return_types(T) == (Float64,)

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

            empty!(cum_ret)
            @test cum_ret.n == 0
            @test value(cum_ret) == 0.0
            @test value(cum_ret.prod) == 1.0
        end

        @testset "DrawDowns" begin
            @testset "Geometric" begin
                source = from(TSLA)
                _ret = SimpleAssetReturn{Float64}()
                _ddowns = DrawDowns{Float64}()
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

            @testset "Arithmetic" begin
                source = from(TSLA)
                _ret = SimpleAssetReturn{Float64}()
                _ddowns = ArithmeticDrawDowns{Float64}()
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

        end

        @testset "Moments" begin
            source = from(TSLA)
            _ret = SimpleAssetReturn{Float64}()
            _moments = AssetReturnMoments{Float64}()
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

        @testset "Sharpe" begin
            source = from(TSLA)
            _ret = SimpleAssetReturn{Float64}()
            _sharpe = Sharpe{Float64}(period = 1)
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

            #empty!(_sharpe)
            #@test _sharpe.n == 0
            #@test value(_sharpe) == 0.0
            #@test _sharpe.mean == Mean()
            #@test _sharpe.stddev == StdDev()
        end

        @testset "Sortino" begin
            source = from(TSLA)
            _ret = SimpleAssetReturn{Float64}()
            _sortino = Sortino{Float64}()
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

            #empty!(_sortino)
            #@test _sortino.n == 0
            #@test value(_sortino) == 0.0
            #@test _sortino.mean == Mean()
            #@test _sortino.stddev == StdDev()

        end
    end


    @testset "Tables.jl integration" begin


        @testset "TSFrames" begin
            prices_ts = TSFrame([TSLA NFLX MSFT], dates, colnames = [:TSLA, :NFLX, :MSFT])

            @testset "Low level (using PortfolioAnalyticsWrapper)" begin
                @testset "SimpleAssetReturn (SingleOutput)" begin
                    pa_wrapper = PortfolioAnalyticsWrapper(SimpleAssetReturn)
                    par = PortfolioAnalyticsResults()
                    @testset "Using Tables.jl interface" begin
                        load!(prices_ts, par, pa_wrapper)
                        expected = -0.0768
                        @test isapprox(par._columns[:TSLA][end], expected, atol = ATOL)

                        # test that the PortfolioAnalyticsResults `istable`
                        @test Tables.istable(typeof(par))
                        # test that it defines column access
                        @test Tables.columnaccess(typeof(par))
                        #@test Tables.columns(par) === mattbl  #
                        # test that we can access the first "column" of our PortfolioAnalyticsResults table by column name
                        @test isapprox(par.TSLA[end], expected, atol = ATOL)
                        @test isapprox(
                            Tables.getcolumn(par, :TSLA)[end],
                            expected,
                            atol = ATOL,
                        )
                        @test isapprox(Tables.getcolumn(par, 2)[end], expected, atol = ATOL)
                        @test Tables.columnnames(par) == [:Index, :TSLA, :NFLX, :MSFT]
                        # convert a PortfolioAnalyticsResults to TSFrame thanks to Tables.jl API
                        ts_out = par |> TSFrame
                        @test isapprox(
                            ts_out.coredata[end, [:TSLA]][1],
                            expected,
                            atol = ATOL,
                        )
                    end
                end

                @testset "Moments (MultiOutput)" begin
                    pa_wrapper = PortfolioAnalyticsWrapper(AssetReturnMoments)
                    par = PortfolioAnalyticsResults()
                    @testset "Using Tables.jl interface" begin
                        load!(prices_ts, par, pa_wrapper)
                        ts_out = par |> TSFrame
                        data_last = ts_out.coredata[end, [:TSLA]][1]
                        @test isapprox(data_last.mean, 265.9177, atol = ATOL)  # shouldn't use prices but returns
                        #@test isapprox(data_last.std, ..., atol=ATOL)
                        #@test isapprox(data_last.skewness, ..., atol=ATOL)
                        #@test isapprox(data_last.kurtosis, ..., atol=ATOL)
                    end
                end
            end
            @testset "Higher level functions" begin
                # Calculate asset returns from prices
                returns = SimpleAssetReturn(prices_ts)
                # Drop missing from returns
                returns = dropmissing(returns.coredata) |> TSFrame
                @test isapprox(returns.coredata[end, [:TSLA]][1], -0.0768, atol = ATOL)
                # Calculate standard deviation of returns
                stddev = StdDev(returns)
                @test isapprox(stddev.coredata[end, [:TSLA]][1], 0.1496, atol = ATOL)
                # Calculate arithmetic mean returns
                amr = ArithmeticMeanReturn(returns)
                @test isapprox(amr.coredata[end, [:TSLA]][1], 0.0432, atol = ATOL)
                # Calculate geometric mean returns
                gmr = GeometricMeanReturn(returns)
                @test isapprox(gmr.coredata[end, [:TSLA]][1], 0.0342, atol = ATOL)
                ## Calculate asset log returns from prices
                log_returns = LogAssetReturn(prices_ts)[2:end]
                @test isapprox(log_returns.coredata[end, [:TSLA]][1], -0.0800, atol = ATOL)
                # Calculate cumulative return (from)
                cum_returns = CumulativeReturn(returns)
                @test isapprox(cum_returns.coredata[end, [:TSLA]][1], 1.4976, atol = ATOL)
                # Calculate Drawdowns
                dd = DrawDowns(returns)
                @test isapprox(dd.coredata[end, [:TSLA]][1], -0.0768, atol = ATOL)
                # Calculate Drawdowns (Arithmetic method)
                add = ArithmeticDrawDowns(returns)
                @test isapprox(add.coredata[end, [:TSLA]][1], -0.0482, atol = ATOL)
                # Calculate statistical moments of returns
                moments = AssetReturnMoments(returns)
                last_moments = moments.coredata[end, [:TSLA]][1]
                @test isapprox(last_moments.mean, 0.0432, atol = ATOL)
                @test isapprox(last_moments.std, 0.1496, atol = ATOL)
                @test isapprox(last_moments.skewness, 1.3688, atol = ATOL)
                @test isapprox(last_moments.kurtosis, 2.1968, atol = ATOL)
                # Calculate Sharpe ratio (from returns)
                sharpe = Sharpe(returns, period = 1)
                @test isapprox(sharpe.coredata[end, [:TSLA]][1], 0.2886, atol = ATOL)
                # Calculate Sortino ratio (from returns)
                sortino = Sortino(returns)
                @test isapprox(sortino.coredata[end, [:TSLA]][1], 11.4992, atol = ATOL)                
            end
        end
    end

end
