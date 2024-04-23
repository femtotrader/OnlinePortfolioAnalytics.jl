using OnlinePortfolioAnalysis
using OnlineStatsBase
using Test

const ATOL = 0.0001
const TSLA = [235.22,264.51,225.16,222.64,236.48,208.40,226.56,229.06,245.24,258.49,371.33,381.58,352.26]
const NFLX = [540.73,532.39,538.85,521.66,513.47,502.81,528.21,517.57,569.19,610.34,690.31,641.90,602.44]
const MSFT = [222.42,231.96,232.38,235.77,252.18,249.68,270.90,284.91,301.88,281.92,331.62,330.59,336.32]
const weights = [0.4, 0.4, 0.2]

@testset "OnlinePortfolioAnalysis.jl" begin
    @testset "SimpleAssetReturn" begin
        stat = SimpleAssetReturn{Float64}()
        fit!(stat, TSLA[1])
        fit!(stat, TSLA[2])
        @test round(value(stat), digits=4) == 0.1245
    end

    @testset "SimpleAssetReturn with period=3" begin
        stat = SimpleAssetReturn{Float64}(period=3)
        fit!(stat, TSLA[1])
        fit!(stat, TSLA[2])
        fit!(stat, TSLA[3])
        fit!(stat, TSLA[4])
        @test isapprox(value(stat), (222.64 - 235.22) / 235.2, atol=ATOL)
    end

    @testset "LogAssetReturn" begin
        stat = LogAssetReturn{Float64}()
        fit!(stat, TSLA[1])
        fit!(stat, TSLA[2])
        @test isapprox(value(stat), 0.1174, atol=ATOL)
    end

    @testset "StdDev" begin
        stat = StdDev{Float64}()
        fit!(stat, TSLA)
        @test isapprox(value(stat), 60.5448, atol=ATOL)
    end

    @testset "MeanReturn" begin
        stat = Mean()
        fit!(stat, TSLA)
        @test isapprox(value(stat), 265.9177, atol=ATOL)
    end

    @testset "GeometricMeanReturn" begin
        
    end


end
