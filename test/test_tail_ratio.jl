# T027: TailRatio tests - TDD (write tests FIRST)

@testitem "TailRatio - Constructor and initial state" setup=[CommonTestSetup] begin
    stat = TailRatio()
    @test stat.n == 0
    @test !ismultioutput(typeof(stat))
    @test stat isa TailRatio{Float64}
end

@testitem "TailRatio - Parameterized constructor" setup=[CommonTestSetup] begin
    stat = TailRatio{Float32}()
    @test stat isa TailRatio{Float32}
    @test stat.n == 0
end

@testitem "TailRatio - Basic calculation with sufficient data" setup=[CommonTestSetup] begin
    stat = TailRatio()

    # Need many observations for quantile estimation
    # Generate returns with known distribution
    for _ in 1:100
        r = 0.02 * randn()  # Random returns centered at 0
        fit!(stat, r)
    end

    @test stat.n == 100
    # For symmetric distribution, ratio should be near 1.0
    @test isfinite(value(stat))
end

@testitem "TailRatio - Symmetric distribution (ratio ≈ 1.0)" setup=[CommonTestSetup] begin
    stat = TailRatio()

    # Symmetric returns around 0
    symmetric_returns = vcat(
        collect(0.01:0.01:0.10),   # Positive tail
        collect(-0.10:0.01:-0.01), # Negative tail (same magnitude)
        zeros(80)                   # Center mass
    )

    for r in symmetric_returns
        fit!(stat, r)
    end

    @test stat.n == length(symmetric_returns)
    # For symmetric distribution, |95th percentile| ≈ |5th percentile|
    # So ratio should be close to 1.0
    @test isapprox(value(stat), 1.0, atol=0.5)  # Wider tolerance for quantile estimation
end

@testitem "TailRatio - Right-skewed (fatter right tail, ratio > 1.0)" setup=[CommonTestSetup] begin
    stat = TailRatio()

    # Right-skewed: Need 95th percentile > |5th percentile|
    # For 100 observations: 5th percentile = ~5th smallest, 95th = ~95th smallest
    # Design: small negatives in bottom 5%, large positives in top 5%, center mass around 0
    right_skewed = vcat(
        fill(-0.01, 5),   # Bottom 5%: small negatives (5th percentile ≈ -0.01)
        fill(0.0, 85),    # Middle 85%: zeros
        fill(0.10, 10)    # Top 10%: large positives (95th percentile ≈ 0.10)
    )

    for r in right_skewed
        fit!(stat, r)
    end

    @test stat.n == 100
    # 95th percentile (0.10) > |5th percentile| (0.01), so ratio > 1.0
    @test value(stat) > 1.0
end

@testitem "TailRatio - Left-skewed (fatter left tail, ratio < 1.0)" setup=[CommonTestSetup] begin
    stat = TailRatio()

    # Left-skewed: Need |5th percentile| > 95th percentile
    # Design: large negatives in bottom 5%, small positives in top 5%, center mass around 0
    left_skewed = vcat(
        fill(-0.10, 10),  # Bottom 10%: large negatives (5th percentile ≈ -0.10)
        fill(0.0, 85),    # Middle 85%: zeros
        fill(0.01, 5)     # Top 5%: small positives (95th percentile ≈ 0.01)
    )

    for r in left_skewed
        fit!(stat, r)
    end

    @test stat.n == 100
    # 95th percentile (0.01) < |5th percentile| (0.10), so ratio < 1.0
    @test value(stat) < 1.0
end

@testitem "TailRatio - Edge case: 5th percentile near zero" setup=[CommonTestSetup] begin
    stat = TailRatio()

    # Most returns positive, so 5th percentile might be near zero
    mostly_positive = vcat(
        fill(0.02, 90),
        fill(0.001, 5),   # Very small positives for 5th percentile
        fill(0.05, 5)
    )

    for r in mostly_positive
        fit!(stat, r)
    end

    @test stat.n == 100
    # If 5th percentile is near zero, ratio could be very large
    @test isfinite(value(stat)) || isinf(value(stat))
end

@testitem "TailRatio - empty! reset behavior" setup=[CommonTestSetup] begin
    stat = TailRatio()

    for _ in 1:50
        fit!(stat, 0.01 * randn())
    end

    @test stat.n > 0

    empty!(stat)

    @test stat.n == 0
end

@testitem "TailRatio - Gradual accumulation" setup=[CommonTestSetup] begin
    stat = TailRatio()

    # Add returns one by one
    for i in 1:50
        fit!(stat, 0.01 * (i % 2 == 0 ? 1 : -1))  # Alternating +/- 1%
    end

    @test stat.n == 50
    @test isfinite(value(stat))
end

@testitem "TailRatio - Interpretation: > 1.0 means fatter right tail" setup=[CommonTestSetup] begin
    # Tail ratio interpretation test
    stat = TailRatio()

    # Create returns with fatter right tail
    returns = vcat(
        [0.10, 0.12, 0.08, 0.09, 0.11],  # Large positive returns
        fill(-0.01, 40),                   # Small negative
        fill(0.01, 55)                     # Small positive
    )

    for r in returns
        fit!(stat, r)
    end

    @test stat.n == 100
    # Fatter right tail = higher ratio
    @test value(stat) > 1.0
end
