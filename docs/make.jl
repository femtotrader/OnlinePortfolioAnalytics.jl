using Documenter
using DocumenterMermaid
push!(LOAD_PATH, "../src/")
using OnlinePortfolioAnalytics

makedocs(
    sitename = "OnlinePortfolioAnalytics.jl",
    format = Documenter.HTML(),
    modules = [OnlinePortfolioAnalytics],
    pages = [
        "Home" => "index.md",
        "Architecture" => "architecture.md",
        "Metrics" => "metrics.md",
        "Internals" => "internals.md",
        "Usage" => "usage.md",
        "Examples" => "examples.md",
        "API" => "api.md",
    ],
)
deploydocs(; repo = "github.com/femtotrader/OnlinePortfolioAnalytics.jl")
