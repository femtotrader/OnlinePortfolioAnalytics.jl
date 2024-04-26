using Documenter
push!(LOAD_PATH, "../src/")
using OnlinePortfolioAnalytics

makedocs(
    sitename = "OnlinePortfolioAnalytics.jl",
    format = Documenter.HTML(),
    modules = [OnlinePortfolioAnalytics],
    pages = ["Home" => "index.md", "Usage" => "usage.md", "API" => "api.md"],
)
deploydocs(; repo = "github.com/femtotrader/OnlinePortfolioAnalytics.jl")
