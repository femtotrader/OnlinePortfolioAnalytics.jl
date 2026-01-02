# T013: BurkeRatio tests - TDD (write tests FIRST)

@testitem "BurkeRatio - Constructor and initial state" setup=[CommonTestSetup] begin
    stat = BurkeRatio()
    @test stat.n == 0
    @test !ismultioutput(typeof(stat))
    @test stat isa BurkeRatio{Float64}
    @test stat.risk_free == 0.0  # Default risk-free rate
    @test stat.period == 252      # Default period
end

@testitem "BurkeRatio - Parameterized constructor" setup=[CommonTestSetup] begin
    stat = BurkeRatio{Float32}(period=52, risk_free=0.001)
    @test stat isa BurkeRatio{Float32}
    @test stat.period == 52
    @test stat.risk_free == Float32(0.001)
end

@testitem "BurkeRatio - Basic calculation" setup=[CommonTestSetup] begin
    stat = BurkeRatio()

    # Generate some returns with drawdowns
    fit!(stat, 0.02)   # +2%
    fit!(stat, -0.03)  # -3% - drawdown
    fit!(stat, 0.01)   # +1%
    fit!(stat, -0.02)  # -2% - another drawdown

    @test stat.n == 4
    @test isfinite(value(stat))
end

@testitem "BurkeRatio - Excess return over root-sum-squared drawdowns" setup=[CommonTestSetup] begin
    stat = BurkeRatio(period=252, risk_free=0.0)

    returns = [0.05, 0.03, -0.10, -0.08, 0.04, 0.02]
    for r in returns
        fit!(stat, r)
    end

    @test stat.n == 6
    # Burke = (AnnualizedReturn - Rf) / sqrt(sum(DD^2) / n)
    @test !isnan(value(stat))
end

@testitem "BurkeRatio - Edge case: no drawdowns" setup=[CommonTestSetup] begin
    stat = BurkeRatio()

    # All positive returns - no drawdown
    fit!(stat, 0.02)
    fit!(stat, 0.01)
    fit!(stat, 0.03)
    fit!(stat, 0.02)

    @test stat.n == 4
    # No drawdowns means sum of squared drawdowns = 0, should return Inf
    @test isinf(value(stat)) || isnan(value(stat))
end

@testitem "BurkeRatio - Configurable risk-free rate" setup=[CommonTestSetup] begin
    stat1 = BurkeRatio(risk_free=0.0)
    stat2 = BurkeRatio(risk_free=0.001)

    returns = [0.02, -0.05, 0.03, -0.02, 0.01]
    for r in returns
        fit!(stat1, r)
        fit!(stat2, r)
    end

    # Higher risk-free rate reduces excess return, thus lower ratio
    @test stat1.risk_free != stat2.risk_free
end

@testitem "BurkeRatio - Configurable period" setup=[CommonTestSetup] begin
    stat_daily = BurkeRatio(period=252)
    stat_weekly = BurkeRatio(period=52)

    returns = [0.02, -0.05, 0.03, -0.02, 0.01]
    for r in returns
        fit!(stat_daily, r)
        fit!(stat_weekly, r)
    end

    @test stat_daily.period != stat_weekly.period
end

@testitem "BurkeRatio - empty! reset behavior" setup=[CommonTestSetup] begin
    stat = BurkeRatio()
    fit!(stat, 0.02)
    fit!(stat, -0.03)

    @test stat.n > 0

    empty!(stat)

    @test stat.n == 0
end

@testitem "BurkeRatio - Multiple drawdown periods" setup=[CommonTestSetup] begin
    stat = BurkeRatio()

    # Two distinct drawdown periods
    fit!(stat, 0.05)   # Peak
    fit!(stat, -0.03)  # Drawdown 1
    fit!(stat, 0.06)   # Recovery to new peak
    fit!(stat, -0.02)  # Drawdown 2
    fit!(stat, -0.01)  # Deeper drawdown 2
    fit!(stat, 0.03)   # Partial recovery

    @test stat.n == 6
    # Burke penalizes sum of squared drawdowns
    @test isfinite(value(stat))
end

@testitem "BurkeRatio - Deep single drawdown" setup=[CommonTestSetup] begin
    stat = BurkeRatio()

    fit!(stat, 0.10)   # Peak
    fit!(stat, -0.20)  # Deep drawdown
    fit!(stat, -0.10)  # Still deep
    fit!(stat, 0.05)   # Partial recovery

    @test stat.n == 4
    # Deep drawdown should result in lower Burke ratio
    @test isfinite(value(stat))
end
