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

mutable struct PortfolioAnalyticsResults
    _colnames::Vector
    _columns::Dict
    function PortfolioAnalyticsResults()
        new(Symbol[], Dict{Symbol,Vector}())
    end
end
function Base.setindex!(par::PortfolioAnalyticsResults, col::Vector, colname::Symbol)
    if !(colname in par._colnames)
        par._columns[colname] = col
        push!(par._colnames, colname)
    else
        error("colname $(colname) ever exists")
    end
end

Tables.istable(::Type{PortfolioAnalyticsResults}) = true
Tables.columnaccess(::Type{PortfolioAnalyticsResults}) = true
Tables.columns(par::PortfolioAnalyticsResults) = par._columns
function Base.getproperty(par::PortfolioAnalyticsResults, name::Symbol)
    if name == :_columns
        return getfield(par, :_columns)
    elseif name == :_colnames
        return getfield(par, :_colnames)
    else
        return par._columns[name]
    end
end
function Tables.getcolumn(par::PortfolioAnalyticsResults, i::Int64)
    colname = par._colnames[i]
    return par._columns[colname]
end
Tables.columnnames(par::PortfolioAnalyticsResults) = par._colnames

function process_col_by_row(row, pa::PA, colname) where {PA<:PortfolioAnalyticsSingleOutput}
    data = row[colname]
    fit!(pa, data)

    _keys = (colname,)
    _values = (value(pa),)
    output_val = (; zip(_keys, _values)...)
    return output_val
end

function process_col_by_row(row, pa::PA, colname) where {PA<:PortfolioAnalyticsMultiOutput}
    data = row[colname]
    fit!(pa, data)

    output_val = value(pa)
    _keys = keys(output_val)
    _keys = map(v -> Symbol("$(colname)_$(v)"), _keys)
    _values = values(output_val)
    output_val = (; zip(_keys, _values)...)
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

function process_row(row, _colnames, v_pa)
    j = 1
    v = NamedTuple[]
    for colname in _colnames
        if !(colname in POSSIBLE_INDEX)
            pa = v_pa[j]
            out_val = process_col_by_row(row, pa, colname)
            push!(v, out_val)
            println(colname, " ", out_val)
            j += 1
        end
    end
    println(v)
end

function process_col(col::Vector, pa::PA) where {PA<:PortfolioAnalyticsSingleOutput}
    Tout = expected_return_types(typeof(pa))
    output = Vector{Tout[1]}()
    for data in col
        fit!(pa, data)
        push!(output, value(pa))
    end
    return output
end

function process_col(col::Vector, pa::PA) where {PA<:PortfolioAnalyticsMultiOutput}
    Tout = expected_return_types(typeof(pa))
    output = Vector{Any}()
    for data in col
        fit!(pa, data)
        push!(output, value(pa))
    end
    return output
end

function load!(
    table,
    par::PortfolioAnalyticsResults,
    pa_wrap::PortfolioAnalyticsWrapper;
    index = DEFAULT_FIELD_INDEX,
    others_possible_index = DEFAULT_OTHERS_POSSIBLE_INDEX,
)
    #rows = Tables.rows(table)
    #cols = Tables.columns(table)
    sch = Tables.schema(table)
    _colnames = sch.names  # name of columns of input

    #if index ∉ sch.names
    #    index = collect(intersect(Set(sch.names), Set(others_possible_index)))[1]
    #end
    #Ttime = Tables.columntype(sch, index)
    #vTout = Type[]
    #v_pa = PortfolioAnalytics[]
    #_names_except_index = Symbol[]
    #_name_possible_index = Symbol[]
    #_type_possible_index = Type[]
    PA = pa_wrap.portfolio_analytics_type
    #for colname in _colnames
    #    if !(colname in POSSIBLE_INDEX)
    #        push!(_names_except_index, colname)
    #        Tin = Tables.columntype(sch, colname)
    #        pa = PA{Tin}(pa_wrap.args...; pa_wrap.kwargs...)
    #        push!(v_pa, pa)
    #        Tout = expected_return_types(PA{Tin})
    #        push!(vTout, Tout...)
    #    else
    #        push!(_name_possible_index, colname)
    #        Tidx = Tables.columntype(sch, colname)
    #        push!(_type_possible_index, Tidx)
    #    end
    #end
    #colnames_out = get_column_names(PA, _names_except_index)
    #sch_out = Tables.Schema(colnames_out, vTout)
    for colname in _colnames
        col = Tables.getcolumn(table, colname)
        if !(colname in POSSIBLE_INDEX)
            Tin = Tables.columntype(sch, colname)
            pa = PA{Tin}(pa_wrap.args...; pa_wrap.kwargs...)
            par[colname] = process_col(col, pa)
        else
            par[colname] = col
        end
    end
    return
end


# === "High-level" functions which deal with Tables.jl

function apply_pa(
    portfolio_analytics_type,
    table,
    args...;
    index = DEFAULT_FIELD_INDEX,
    others_possible_index = DEFAULT_OTHERS_POSSIBLE_INDEX,
    kwargs...,
)
    pa_wrapper = PortfolioAnalyticsWrapper(portfolio_analytics_type, args...; kwargs...)
    par = PortfolioAnalyticsResults()
    load!(
        table,
        par,
        pa_wrapper;
        index = index,
        others_possible_index = others_possible_index,
    )
    return typeof(table)(par)
end

SimpleAssetReturn(table, args...; kwargs...) =
    apply_pa(SimpleAssetReturn, table, args...; kwargs...)
LogAssetReturn(table, args...; kwargs...) =
    apply_pa(LogAssetReturn, table, args...; kwargs...)
ArithmeticMeanReturn(table, args...; kwargs...) =
    apply_pa(ArithmeticMeanReturn, table, args...; kwargs...)
GeometricMeanReturn(table, args...; kwargs...) =
    apply_pa(GeometricMeanReturn, table, args...; kwargs...)
StdDev(table, args...; kwargs...) = apply_pa(StdDev, table, args...; kwargs...)
CumulativeReturn(table, args...; kwargs...) =
    apply_pa(CumulativeReturn, table, args...; kwargs...)
DrawDowns(table, args...; kwargs...) = apply_pa(DrawDowns, table, args...; kwargs...)
ArithmeticDrawDowns(table, args...; kwargs...) =
    apply_pa(ArithmeticDrawDowns, table, args...; kwargs...)
AssetReturnMoments(table, args...; kwargs...) =
    apply_pa(AssetReturnMoments, table, args...; kwargs...)
Sharpe(table, args...; kwargs...) = apply_pa(Sharpe, table, args...; kwargs...)
Sortino(table, args...; kwargs...) = apply_pa(Sortino, table, args...; kwargs...)
MaxDrawDown(table, args...; kwargs...) = apply_pa(MaxDrawDown, table, args...; kwargs...)
MaxArithmeticDrawDown(table, args...; kwargs...) =
    apply_pa(MaxArithmeticDrawDown, table, args...; kwargs...)
AnnualizedReturn(table, args...; kwargs...) =
    apply_pa(AnnualizedReturn, table, args...; kwargs...)
Calmar(table, args...; kwargs...) = apply_pa(Calmar, table, args...; kwargs...)
VaR(table, args...; kwargs...) = apply_pa(VaR, table, args...; kwargs...)
ExpectedShortfall(table, args...; kwargs...) =
    apply_pa(ExpectedShortfall, table, args...; kwargs...)
DownsideDeviation(table, args...; kwargs...) =
    apply_pa(DownsideDeviation, table, args...; kwargs...)
UpsideDeviation(table, args...; kwargs...) =
    apply_pa(UpsideDeviation, table, args...; kwargs...)
Omega(table, args...; kwargs...) = apply_pa(Omega, table, args...; kwargs...)
