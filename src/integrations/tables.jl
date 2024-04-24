using Tables


const DEFAULT_POSSIBLE_INDEX_COLUMNS = [:Index, :timestamp]

struct PortfolioAnalyticsWrapper{T}
    portfolio_analytics_type::T
    args::Tuple
    kwargs::Base.Pairs
    function PortfolioAnalyticsWrapper(portfolio_analytics_type, args...; kwargs...)
        new{typeof(portfolio_analytics_type)}(portfolio_analytics_type, args, kwargs)
    end
end

#=
struct PortfolioAnalyticsResults{Ttime,Tout}
    name::Symbol
    fieldnames::Tuple
    fieldtypes::Tuple

    index::Vector
    output::Vector

    function PortfolioAnalyticsResults{Ttime,Tout}(
        name,
        fieldnames,
        fieldtypes,
    ) where {Ttime,Tout}
        new(name, fieldnames, fieldtypes, Ttime[], Tout[])
    end
end
=#

function load!(
    table,
    pa_wrap::PortfolioAnalyticsWrapper
)
    rows = Tables.rows(table)
    sch = Tables.schema(table)
    _names = sch.names  # name of columns of input

    for colname in _names
        if !(colname in DEFAULT_POSSIBLE_INDEX_COLUMNS)
            T = Tables.columntype(sch, colname)
            pa = pa_wrap.portfolio_analytics_type{T}(
                pa_wrap.args...;
                pa_wrap.kwargs...,
            )
    
            for row in rows
                data = row[colname]
                fit!(pa, data)
            end

            println(pa)
        end
    end

end