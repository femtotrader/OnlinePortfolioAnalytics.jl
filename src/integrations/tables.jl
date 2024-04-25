using Tables

const DEFAULT_FIELD_INDEX = :Index
const DEFAULT_OTHERS_POSSIBLE_INDEX = [:timestamp]
const POSSIBLE_INDEX = [DEFAULT_FIELD_INDEX, DEFAULT_OTHERS_POSSIBLE_INDEX...]

struct PortfolioAnalyticsWrapper{T}
    portfolio_analytics_type::T
    args::Tuple
    kwargs::Base.Pairs
    function PortfolioAnalyticsWrapper(portfolio_analytics_type, args...; kwargs...)
        T = typeof(portfolio_analytics_type)
        new{T}(portfolio_analytics_type, args, kwargs)
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

function process_col(row, pa::PA, colname) where {PA<:PortfolioAnalyticsSingleOutput}
    data = row[colname]
    fit!(pa, data)

    _keys = (colname,)
    _values = (value(pa),)
    output_val = (; zip(_keys, _values)...)
    println(colname, " ", output_val)
    return output_val
end

function process_col(row, pa::PA, colname) where {PA<:PortfolioAnalyticsMultiOutput}
    data = row[colname]
    fit!(pa, data)

    output_val = value(pa)
    _keys = keys(output_val)
    _keys = map(v -> Symbol("$(colname)_$(v)"), _keys)
    _values = values(output_val)
    output_val = (; zip(_keys, _values)...)
    println(colname, " ", output_val)
    return output_val
end

function get_column_names(::Type{PA}, colnames) where {PA<:PortfolioAnalyticsSingleOutput}
    return colnames
end

function get_column_names(T::Type{PA}, colnames) where {PA<:PortfolioAnalyticsMultiOutput}
    values = expected_return_values(T)
    return tuple(
        [Symbol(join([col, "_", val])) for (val, col) in Base.product(values, colnames)]...,
    )
end

function process_row(row, _names, v_pa)
    j = 1

    #map(colname -> (process_col(row, pa, colname)), filter(colname -> !(colname in POSSIBLE_INDEX), _names))
    for colname in _names
        if !(colname in POSSIBLE_INDEX)
            pa = v_pa[j]
            process_col(row, pa, colname)
            j += 1
        end
    end
end

function load!(
    table,
    pa_wrap::PortfolioAnalyticsWrapper;
    index = DEFAULT_FIELD_INDEX,
    others_possible_index = DEFAULT_OTHERS_POSSIBLE_INDEX,
)
    rows = Tables.rows(table)
    sch = Tables.schema(table)
    _names = sch.names  # name of columns of input

    println("# input schema")
    println(sch)

    if index ∉ sch.names
        index = collect(intersect(Set(sch.names), Set(others_possible_index)))[1]
    end
    Ttime = Tables.columntype(sch, index)

    vTout = Type[]
    v_pa = PortfolioAnalytics[]
    _names_except_index = Symbol[]
    _name_possible_index = Symbol[]
    _type_possible_index = Type[]
    PA = pa_wrap.portfolio_analytics_type

    for colname in _names
        if !(colname in POSSIBLE_INDEX)
            push!(_names_except_index, colname)
            Tin = Tables.columntype(sch, colname)
            pa = PA{Tin}(pa_wrap.args...; pa_wrap.kwargs...)
            push!(v_pa, pa)
            Tout = expected_return_types(PA{Tin})
            push!(vTout, Tout...)
        else
            push!(_name_possible_index, colname)
            Tidx = Tables.columntype(sch, colname)
            push!(_type_possible_index, Tidx)
        end
    end
    #_names_except_index = filter(n -> !(n in POSSIBLE_INDEX), _names)
    col_names_out = get_column_names(PA, _names_except_index)
    sch_out = Tables.Schema(col_names_out, vTout)

    println("# output schema")
    println(sch_out)

    #for row in rows
    #    process_row(row, _names, v_pa)
    #end


end
