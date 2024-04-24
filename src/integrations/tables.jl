using Tables

const DEFAULT_FIELD_INDEX = :Index
const DEFAULT_OTHERS_POSSIBLE_INDEX = [:timestamp]
const POSSIBLE_INDEX = [DEFAULT_FIELD_INDEX, DEFAULT_OTHERS_POSSIBLE_INDEX...]

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
    output::Dict

    function PortfolioAnalyticsResults{Ttime,Tout}(
        name,
        fieldnames,
        fieldtypes,
    ) where {Ttime,Tout}
        new(name, fieldnames, fieldtypes, Ttime[], Dict{Symbol,Tout}())
    end
end

function Base.push!(results::PortfolioAnalyticsResults, result)
    (tim, val) = result
    push!(results.index, tim)
    push!(results.output, val)
end
=#

function load!(
    table,
    pa_wrap::PortfolioAnalyticsWrapper;
    index = DEFAULT_FIELD_INDEX,
    others_possible_index = DEFAULT_OTHERS_POSSIBLE_INDEX,
)
    rows = Tables.rows(table)
    sch = Tables.schema(table)
    _names = sch.names  # name of columns of input

    println(sch)
    println(fieldnames(typeof(sch)))

    if index ∉ sch.names
        index = collect(intersect(Set(sch.names), Set(others_possible_index)))[1]
    end
    Ttime = Tables.columntype(sch, index)

    #all_pa = [pa_wrap.portfolio_analytics_type{Tin}(pa_wrap.args...; pa_wrap.kwargs...) for colname in _names]
    #println(all_pa)

    for colname in _names
        if !(colname in POSSIBLE_INDEX)
            Tin = Tables.columntype(sch, colname)
            pa = pa_wrap.portfolio_analytics_type{Tin}(pa_wrap.args...; pa_wrap.kwargs...)
            println(pa)
            #println(expected_return_type(pa))
        else

        end
    end

    for colname in _names
        if !(colname in POSSIBLE_INDEX)
            Tin = Tables.columntype(sch, colname)
            pa = pa_wrap.portfolio_analytics_type{Tin}(pa_wrap.args...; pa_wrap.kwargs...)

            for row in rows
                data = row[colname]
                fit!(pa, data)
            end
            println(colname, " ", pa)
        else

        end
    end

end
