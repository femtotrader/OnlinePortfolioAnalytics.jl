@testitem "Prod - US1 Core Product Computation" setup=[CommonTestSetup] begin
    using OnlinePortfolioAnalytics: Prod

    # T004: Test basic Float64 product computation
    @testset "basic Float64 product" begin
        stat = Prod(Float64)
        fit!(stat, 2.0)
        fit!(stat, 3.0)
        fit!(stat, 4.0)
        @test value(stat) == 24.0
        @test nobs(stat) == 3
    end

    # T005: Test floating-point accuracy
    @testset "floating-point accuracy" begin
        stat = Prod(Float64)
        fit!(stat, 1.1)
        fit!(stat, 1.05)
        fit!(stat, 0.95)
        @test value(stat) ≈ 1.09725 atol=1e-10
    end

    # T006: Test integer Prod
    @testset "integer Prod" begin
        stat = Prod(Int)
        fit!(stat, 2)
        fit!(stat, 3)
        fit!(stat, 4)
        @test value(stat) == 24
        @test typeof(value(stat)) == Int
    end

    # T007: Test empty Prod initial state
    @testset "empty initial state" begin
        stat = Prod(Float64)
        @test value(stat) == 1.0
        @test nobs(stat) == 0
    end

    # T008: Test zero handling
    @testset "zero handling" begin
        stat = Prod(Float64)
        fit!(stat, 2.0)
        fit!(stat, 0.0)
        fit!(stat, 3.0)
        @test value(stat) == 0.0
    end
end

@testitem "Prod - US2 Weighted Product Computation" setup=[CommonTestSetup] begin
    using OnlinePortfolioAnalytics: Prod

    # T011: Test weighted fit semantics (x^w, not x*w)
    @testset "weighted fit x^w semantics" begin
        stat = Prod(Float64)
        fit!(stat, 2.0, 3)  # Should be 2^3 = 8, not 2*3 = 6
        @test value(stat) == 8.0
    end

    # T012: Test mixed weighted/unweighted
    @testset "mixed weighted/unweighted" begin
        stat = Prod(Float64)
        fit!(stat, 2.0)        # 2
        fit!(stat, 3.0, 2)     # 3^2 = 9
        @test value(stat) == 18.0  # 2 * 9 = 18
    end

    # T013: Test weighted nobs accumulation
    @testset "weighted nobs accumulation" begin
        stat = Prod(Float64)
        fit!(stat, 2.0, 3)
        @test nobs(stat) == 3
    end

    # T014: Test that weighted fit with integer weight equals fitting value w times
    @testset "weighted fit equals repeated unweighted fits" begin
        # fit!(stat, x, 3) should equal fitting x three times
        stat1 = Prod(Float64)
        fit!(stat1, 2.0, 3)  # 2^3 = 8

        stat2 = Prod(Float64)
        fit!(stat2, 2.0)
        fit!(stat2, 2.0)
        fit!(stat2, 2.0)

        @test value(stat1) == value(stat2)  # Both should be 8.0
        @test nobs(stat1) == nobs(stat2)    # Both should be 3
    end
end

@testitem "Prod - US3 Reset Statistic State" setup=[CommonTestSetup] begin
    using OnlinePortfolioAnalytics: Prod

    # T019: Test empty! resets product
    @testset "empty! resets product" begin
        stat = Prod(Float64)
        fit!(stat, 2.0)
        fit!(stat, 3.0)
        fit!(stat, 4.0)
        @test value(stat) == 24.0
        empty!(stat)
        @test value(stat) == 1.0
    end

    # T020: Test empty! resets nobs
    @testset "empty! resets nobs" begin
        stat = Prod(Float64)
        fit!(stat, 2.0)
        fit!(stat, 3.0)
        fit!(stat, 4.0)
        @test nobs(stat) == 3
        empty!(stat)
        @test nobs(stat) == 0
    end

    # T021: Test reuse after empty!
    @testset "reuse after empty!" begin
        stat = Prod(Float64)
        fit!(stat, 2.0)
        fit!(stat, 3.0)
        empty!(stat)
        fit!(stat, 5.0)
        @test value(stat) == 5.0
        @test nobs(stat) == 1
    end
end

@testitem "Prod - US4 Merge Product Statistics" setup=[CommonTestSetup] begin
    using OnlinePortfolioAnalytics: Prod

    # T024: Test merge multiplies products
    @testset "merge multiplies products" begin
        stat1 = Prod(Float64)
        fit!(stat1, 2.0)
        fit!(stat1, 3.0)
        @test value(stat1) == 6.0

        stat2 = Prod(Float64)
        fit!(stat2, 4.0)
        fit!(stat2, 5.0)
        @test value(stat2) == 20.0

        merge!(stat1, stat2)
        @test value(stat1) == 120.0  # 6 * 20 = 120
    end

    # T025: Test merge sums nobs
    @testset "merge sums nobs" begin
        stat1 = Prod(Float64)
        fit!(stat1, 2.0)
        fit!(stat1, 3.0)

        stat2 = Prod(Float64)
        fit!(stat2, 4.0)
        fit!(stat2, 5.0)

        merge!(stat1, stat2)
        @test nobs(stat1) == 4
    end

    # T026: Test merge with empty Prod
    @testset "merge with empty Prod" begin
        stat1 = Prod(Float64)
        fit!(stat1, 2.0)
        fit!(stat1, 3.0)
        original_value = value(stat1)
        original_nobs = nobs(stat1)

        stat2 = Prod(Float64)  # empty
        merge!(stat1, stat2)

        @test value(stat1) == original_value
        @test nobs(stat1) == original_nobs
    end
end

@testitem "LogProd - US5 Numerical Stability" setup=[CommonTestSetup] begin
    using OnlinePortfolioAnalytics: LogProd, Prod

    # T029: Test LogProd basic computation
    @testset "basic computation matches Prod" begin
        prod_stat = Prod(Float64)
        log_stat = LogProd(Float64)

        for x in [2.0, 3.0, 4.0]
            fit!(prod_stat, x)
            fit!(log_stat, x)
        end

        @test value(log_stat) ≈ value(prod_stat) atol=1e-10
        @test nobs(log_stat) == nobs(prod_stat)
    end

    # T030: Test LogProd overflow prevention
    @testset "overflow prevention" begin
        stat = LogProd(Float64)
        for _ in 1:1000
            fit!(stat, 1.001)
        end
        # 1.001^1000 ≈ 2.7169
        @test isfinite(value(stat))
        @test value(stat) ≈ 1.001^1000 atol=1e-6
    end

    # T031: Test LogProd underflow prevention
    @testset "underflow prevention" begin
        stat = LogProd(Float64)
        for _ in 1:1000
            fit!(stat, 0.999)
        end
        # 0.999^1000 ≈ 0.3677
        @test isfinite(value(stat))
        @test value(stat) ≈ 0.999^1000 atol=1e-6
    end

    # T032: Test LogProd weighted fit
    @testset "weighted fit" begin
        stat = LogProd(Float64)
        fit!(stat, 2.0, 3)  # 2^3 = 8
        @test value(stat) ≈ 8.0 atol=1e-10
    end

    # T033: Test LogProd empty!
    @testset "empty!" begin
        stat = LogProd(Float64)
        fit!(stat, 2.0)
        fit!(stat, 3.0)
        empty!(stat)
        @test value(stat) == 1.0  # exp(0) = 1
        @test nobs(stat) == 0
    end

    # T034: Test LogProd merge
    @testset "merge" begin
        stat1 = LogProd(Float64)
        fit!(stat1, 2.0)
        fit!(stat1, 3.0)

        stat2 = LogProd(Float64)
        fit!(stat2, 4.0)
        fit!(stat2, 5.0)

        merge!(stat1, stat2)
        @test value(stat1) ≈ 120.0 atol=1e-10  # 2*3*4*5 = 120
        @test nobs(stat1) == 4
    end

    # T035: Test LogProd zero handling
    @testset "zero handling" begin
        stat = LogProd(Float64)
        fit!(stat, 2.0)
        fit!(stat, 0.0)  # log(0) = -Inf
        @test value(stat) == 0.0
    end

    # T036: Test LogProd equivalence with Prod
    @testset "equivalence with Prod" begin
        prod_stat = Prod(Float64)
        log_stat = LogProd(Float64)

        values = [1.5, 2.3, 0.8, 1.2, 3.1]
        for x in values
            fit!(prod_stat, x)
            fit!(log_stat, x)
        end

        @test value(log_stat) ≈ value(prod_stat) atol=1e-10
    end
end
