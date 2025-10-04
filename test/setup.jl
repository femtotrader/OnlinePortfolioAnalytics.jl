@testsnippet CommonTestSetup begin
    using OnlinePortfolioAnalytics
    using OnlinePortfolioAnalytics.SampleData: dates, TSLA, NFLX, MSFT, weights
    using OnlinePortfolioAnalytics: ismultioutput, expected_return_types, expected_return_values, load!, PortfolioAnalyticsWrapper, PortfolioAnalyticsResults
    using OnlineStatsBase
    using Rocket: from, map, filter, subscribe!
    using Test
    using TSFrames
    using DataFrames
    using Dates
    using Tables
    
    const ATOL = 0.0001
end
