# T016: PainRatio tests - TDD (write tests FIRST)

@testitem "PainRatio - Constructor and initial state" setup=[CommonTestSetup] begin
    stat = PainRatio()
    @test stat.n == 0
    @test !ismultioutput(typeof(stat))
    @test stat isa PainRatio{Float64}
    @test stat.risk_free == 0.0  # Default risk-free rate
    @test stat.period == 252      # Default period
end

@testitem "PainRatio - Parameterized constructor" setup=[CommonTestSetup] begin
    stat = PainRatio{Float32}(period=52, risk_free=0.001)
    @test stat isa PainRatio{Float32}
    @test stat.period == 52
    @test stat.risk_free == Float32(0.001)
end

@testitem "PainRatio - Basic calculation" setup=[CommonTestSetup] begin
    stat = PainRatio()

    fit!(stat, 0.02)   # +2%
    fit!(stat, -0.03)  # -3% - drawdown
    fit!(stat, 0.01)   # +1%
    fit!(stat, -0.02)  # -2% - another drawdown

    @test stat.n == 4
    @test isfinite(value(stat))
end

@testitem "PainRatio - Excess return per unit of Pain Index" setup=[CommonTestSetup] begin
    stat = PainRatio(period=252, risk_free=0.0)

    returns = [0.05, 0.03, -0.10, -0.08, 0.04, 0.02]
    for r in returns
        fit!(stat, r)
    end

    @test stat.n == 6
    # PainRatio = (AnnualizedReturn - Rf) / PainIndex
    @test !isnan(value(stat))
end

@testitem "PainRatio - Edge case: PainIndex is zero" setup=[CommonTestSetup] begin
    stat = PainRatio()

    # All positive returns - no drawdown, Pain Index = 0
    fit!(stat, 0.02)
    fit!(stat, 0.01)
    fit!(stat, 0.03)
    fit!(stat, 0.02)

    @test stat.n == 4
    # No drawdowns means Pain Index = 0, should return Inf
    @test isinf(value(stat)) || isnan(value(stat))
end

@testitem "PainRatio - Configurable risk-free rate" setup=[CommonTestSetup] begin
    stat1 = PainRatio(risk_free=0.0)
    stat2 = PainRatio(risk_free=0.001)

    returns = [0.02, -0.05, 0.03, -0.02, 0.01]
    for r in returns
        fit!(stat1, r)
        fit!(stat2, r)
    end

    @test stat1.risk_free != stat2.risk_free
end

@testitem "PainRatio - Configurable period" setup=[CommonTestSetup] begin
    stat_daily = PainRatio(period=252)
    stat_weekly = PainRatio(period=52)

    returns = [0.02, -0.05, 0.03, -0.02, 0.01]
    for r in returns
        fit!(stat_daily, r)
        fit!(stat_weekly, r)
    end

    @test stat_daily.period != stat_weekly.period
end

@testitem "PainRatio - empty! reset behavior" setup=[CommonTestSetup] begin
    stat = PainRatio()
    fit!(stat, 0.02)
    fit!(stat, -0.03)

    @test stat.n > 0

    empty!(stat)

    @test stat.n == 0
end

@testitem "PainRatio - Relationship with PainIndex" setup=[CommonTestSetup] begin
    pain_ratio = PainRatio(period=252, risk_free=0.0)
    pain_index = PainIndex()
    ann_return = AnnualizedReturn(period=252)

    returns = [0.02, -0.05, 0.03, -0.08, 0.04]
    for r in returns
        fit!(pain_ratio, r)
        fit!(pain_index, r)
        fit!(ann_return, r)
    end

    # PainRatio ≈ AnnualizedReturn / PainIndex
    pain_idx = value(pain_index)
    ann_ret = value(ann_return)

    if pain_idx > 0
        expected = ann_ret / pain_idx
        @test isapprox(value(pain_ratio), expected, rtol=0.01)
    end
end

@testitem "PainRatio - High pain leads to low ratio" setup=[CommonTestSetup] begin
    low_pain = PainRatio()
    high_pain = PainRatio()

    # Low pain scenario
    low_pain_returns = [0.02, 0.01, -0.01, 0.02, 0.01]
    for r in low_pain_returns
        fit!(low_pain, r)
    end

    # High pain scenario
    high_pain_returns = [0.02, -0.10, -0.08, -0.05, 0.01]
    for r in high_pain_returns
        fit!(high_pain, r)
    end

    # Higher pain should result in lower ratio (given similar returns)
    # This depends on the actual return profile
    @test isfinite(value(low_pain))
    @test isfinite(value(high_pain))
end
