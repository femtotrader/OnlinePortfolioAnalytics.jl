# RMS (Root Mean Square) tests - TDD (write tests FIRST)

@testitem "RMS - Constructor and initial state" setup=[CommonTestSetup] begin
    stat = RMS()
    @test stat.n == 0
    @test value(stat) == 0.0
    @test stat isa RMS{Float64}
    @test !ismultioutput(typeof(stat))
end

@testitem "RMS - Parameterized constructor Float32" setup=[CommonTestSetup] begin
    stat = RMS{Float32}()
    @test stat isa RMS{Float32}
    @test stat.n == 0
    @test value(stat) == 0.0f0
end

@testitem "RMS - Single observation returns absolute value" setup=[CommonTestSetup] begin
    stat = RMS()
    fit!(stat, 3.0)

    @test stat.n == 1
    # RMS of single value x = sqrt(x^2 / 1) = |x|
    @test isapprox(value(stat), 3.0, atol=ATOL)
end

@testitem "RMS - Two observations [3.0, 4.0]" setup=[CommonTestSetup] begin
    stat = RMS()
    fit!(stat, 3.0)
    fit!(stat, 4.0)

    @test stat.n == 2
    # RMS = sqrt((9 + 16) / 2) = sqrt(12.5) ≈ 3.5355
    expected = sqrt((3.0^2 + 4.0^2) / 2)
    @test isapprox(value(stat), expected, atol=ATOL)
end

@testitem "RMS - Five observations [1,2,3,4,5]" setup=[CommonTestSetup] begin
    stat = RMS()
    for x in 1:5
        fit!(stat, Float64(x))
    end

    @test stat.n == 5
    # RMS = sqrt((1 + 4 + 9 + 16 + 25) / 5) = sqrt(55/5) = sqrt(11) ≈ 3.3166
    expected = sqrt((1 + 4 + 9 + 16 + 25) / 5)
    @test isapprox(value(stat), expected, atol=ATOL)
end

@testitem "RMS - Negative values square correctly" setup=[CommonTestSetup] begin
    stat = RMS()
    fit!(stat, -3.0)
    fit!(stat, -4.0)

    @test stat.n == 2
    # RMS of [-3, -4] = sqrt((9 + 16) / 2) = sqrt(12.5)
    # Same as RMS of [3, 4] since values are squared
    expected = sqrt((3.0^2 + 4.0^2) / 2)
    @test isapprox(value(stat), expected, atol=ATOL)
end

@testitem "RMS - Mixed positive and negative values" setup=[CommonTestSetup] begin
    stat = RMS()
    fit!(stat, 3.0)
    fit!(stat, -4.0)

    @test stat.n == 2
    # RMS of [3, -4] = sqrt((9 + 16) / 2) = sqrt(12.5)
    expected = sqrt((3.0^2 + 4.0^2) / 2)
    @test isapprox(value(stat), expected, atol=ATOL)
end

@testitem "RMS - All zeros returns 0.0" setup=[CommonTestSetup] begin
    stat = RMS()
    fit!(stat, 0.0)
    fit!(stat, 0.0)
    fit!(stat, 0.0)

    @test stat.n == 3
    @test value(stat) == 0.0
end

@testitem "RMS - empty! resets to initial state" setup=[CommonTestSetup] begin
    stat = RMS()
    fit!(stat, 3.0)
    fit!(stat, 4.0)

    @test stat.n == 2
    @test value(stat) > 0.0

    empty!(stat)

    @test stat.n == 0
    @test value(stat) == 0.0
    @test stat.sum_sq == 0.0
end

@testitem "RMS - merge! combines two statistics" setup=[CommonTestSetup] begin
    stat1 = RMS()
    fit!(stat1, 3.0)
    fit!(stat1, 4.0)

    stat2 = RMS()
    fit!(stat2, 5.0)
    fit!(stat2, 6.0)

    # Compute expected combined RMS
    full_stat = RMS()
    for x in [3.0, 4.0, 5.0, 6.0]
        fit!(full_stat, x)
    end

    merge!(stat1, stat2)

    @test stat1.n == 4
    @test isapprox(value(stat1), value(full_stat), atol=ATOL)
end

@testitem "RMS - merge! with empty stat preserves values" setup=[CommonTestSetup] begin
    stat1 = RMS()
    fit!(stat1, 3.0)
    fit!(stat1, 4.0)
    val_before = value(stat1)
    n_before = stat1.n

    stat2 = RMS()  # empty

    merge!(stat1, stat2)

    @test stat1.n == n_before
    @test value(stat1) == val_before
end

@testitem "RMS - merge! empty with non-empty" setup=[CommonTestSetup] begin
    stat1 = RMS()  # empty

    stat2 = RMS()
    fit!(stat2, 3.0)
    fit!(stat2, 4.0)

    merge!(stat1, stat2)

    @test stat1.n == 2
    expected = sqrt((9 + 16) / 2)
    @test isapprox(value(stat1), expected, atol=ATOL)
end

@testitem "RMS - Rolling window compatibility" setup=[CommonTestSetup] begin
    # 3-period rolling RMS
    rolling_rms = Rolling(RMS(), window=3)

    fit!(rolling_rms, 1.0)
    # RMS of [1] = 1.0
    @test isapprox(value(rolling_rms), 1.0, atol=ATOL)

    fit!(rolling_rms, 2.0)
    # RMS of [1, 2] = sqrt((1+4)/2) = sqrt(2.5)
    @test isapprox(value(rolling_rms), sqrt(2.5), atol=ATOL)

    fit!(rolling_rms, 3.0)
    # RMS of [1, 2, 3] = sqrt((1+4+9)/3) = sqrt(14/3)
    @test isapprox(value(rolling_rms), sqrt(14/3), atol=ATOL)

    fit!(rolling_rms, 4.0)
    # Window drops 1, now [2, 3, 4]
    # RMS of [2, 3, 4] = sqrt((4+9+16)/3) = sqrt(29/3)
    @test isapprox(value(rolling_rms), sqrt(29/3), atol=ATOL)
end
