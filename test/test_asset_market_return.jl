@testitem "AssetMarketReturn - Basic construction" setup=[CommonTestSetup] begin
    obs = AssetMarketReturn(0.05, 0.03)
    @test obs.asset == 0.05
    @test obs.market == 0.03
    @test obs isa AssetMarketReturn{Float64}
end

@testitem "AssetMarketReturn - Type promotion" setup=[CommonTestSetup] begin
    # Int and Float should promote to Float
    obs = AssetMarketReturn(1, 0.5)
    @test obs isa AssetMarketReturn{Float64}
    @test obs.asset == 1.0
    @test obs.market == 0.5
end

@testitem "AssetMarketReturn - Same type Int" setup=[CommonTestSetup] begin
    obs = AssetMarketReturn(1, 2)
    @test obs isa AssetMarketReturn{Int}
    @test obs.asset == 1
    @test obs.market == 2
end

@testitem "AssetMarketReturn - Explicit type parameter" setup=[CommonTestSetup] begin
    obs = AssetMarketReturn{Float32}(0.05f0, 0.03f0)
    @test obs isa AssetMarketReturn{Float32}
    @test obs.asset ≈ 0.05f0
    @test obs.market ≈ 0.03f0
end

@testitem "AssetMarketReturn - Negative values" setup=[CommonTestSetup] begin
    obs = AssetMarketReturn(-0.02, -0.05)
    @test obs.asset == -0.02
    @test obs.market == -0.05
end

@testitem "AssetMarketReturn - Zero values" setup=[CommonTestSetup] begin
    obs = AssetMarketReturn(0.0, 0.0)
    @test obs.asset == 0.0
    @test obs.market == 0.0
end
