@testitem "AssetBenchmarkReturn - Basic construction" setup=[CommonTestSetup] begin
    obs = AssetBenchmarkReturn(0.05, 0.04)
    @test obs.asset == 0.05
    @test obs.benchmark == 0.04
    @test obs isa AssetBenchmarkReturn{Float64}
end

@testitem "AssetBenchmarkReturn - Type promotion" setup=[CommonTestSetup] begin
    # Int and Float should promote to Float
    obs = AssetBenchmarkReturn(1, 0.5)
    @test obs isa AssetBenchmarkReturn{Float64}
    @test obs.asset == 1.0
    @test obs.benchmark == 0.5
end

@testitem "AssetBenchmarkReturn - Same type Int" setup=[CommonTestSetup] begin
    obs = AssetBenchmarkReturn(1, 2)
    @test obs isa AssetBenchmarkReturn{Int}
    @test obs.asset == 1
    @test obs.benchmark == 2
end

@testitem "AssetBenchmarkReturn - Explicit type parameter" setup=[CommonTestSetup] begin
    obs = AssetBenchmarkReturn{Float32}(0.05f0, 0.04f0)
    @test obs isa AssetBenchmarkReturn{Float32}
    @test obs.asset ≈ 0.05f0
    @test obs.benchmark ≈ 0.04f0
end

@testitem "AssetBenchmarkReturn - Negative values" setup=[CommonTestSetup] begin
    obs = AssetBenchmarkReturn(-0.02, -0.05)
    @test obs.asset == -0.02
    @test obs.benchmark == -0.05
end

@testitem "AssetBenchmarkReturn - Zero values" setup=[CommonTestSetup] begin
    obs = AssetBenchmarkReturn(0.0, 0.0)
    @test obs.asset == 0.0
    @test obs.benchmark == 0.0
end

@testitem "AssetBenchmarkReturn - Mixed sign values" setup=[CommonTestSetup] begin
    obs = AssetBenchmarkReturn(0.03, -0.02)
    @test obs.asset == 0.03
    @test obs.benchmark == -0.02
end
