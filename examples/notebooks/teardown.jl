### A Pluto.jl notebook ###
# v0.19.40

using Markdown
using InteractiveUtils

# ╔═╡ a1861f50-046e-11ef-348b-cb9f60ea0d1b
begin
	import Pkg
	Pkg.activate(mktempdir())
	Pkg.add([
		Pkg.PackageSpec(url = "https://github.com/femtotrader/OnlinePortfolioAnalytics.jl"),
	])
	using TSFrames
	using DataFrames
	using Dates
	using Random
	using Plots
	using Printf
	using OnlinePortfolioAnalytics
end

# ╔═╡ accbd5bc-4976-48cf-91c1-e12b62a94edf
function random_data(rng::AbstractRNG = Random.GLOBAL_RNG;
	start = Dates.Date(2010, 1, 1),
	step = Dates.Day(1),
	stop = Dates.Date(2023, 1, 1) - Dates.Day(1),
	price_init = nothing,
	price_init_min = 1.00,
	price_init_step = 0.01,
	price_init_max = 1000.00,
	price_var_min = -5.0,
	price_var_step = 0.1,
	price_var_max = 5.0,
)
	idx = range(start, stop = stop, step = step)
	n = length(idx)
	if isnothing(price_init)
		price_init = rand(rng, price_init_min:price_init_step:price_init_max)
	end
	return TSFrame(DataFrame(Index=collect(idx),
		STOCK1=price_init .+ cumsum(rand(rng, price_var_min:price_var_step:price_var_max, n))))
end

# ╔═╡ da790f5a-874b-4c65-9c7d-4243d3852859
begin
	Random.seed!(123)
	year_min, year_max = 2010, 2022
	years = year_min:year_max
	ts = random_data()
end

# ╔═╡ 21600f87-228d-4cd0-8f24-ec821de8ef8c
plot(ts)

# ╔═╡ c0fd125c-70d3-4e42-a0a5-4daff44a2c96
begin
	returns = SimpleAssetReturn(ts)
	#returns = dropmissing(returns.coredata) |> TSFrame
	#replace(returns.coredata, missing => 0)
	returns.coredata.STOCK1[ismissing.(returns.coredata.STOCK1)] .= 0
	returns = dropmissing(returns.coredata) |> TSFrame
	returns
end

# ╔═╡ b0e1d632-1b86-4259-8f28-464e0af0c3e0
cum_returns = CumulativeReturn(returns)

# ╔═╡ a208fb00-cfe1-46d9-9751-e9e5f423f8fb
begin
	plot(cum_returns, title="Cumulative returns", color=:green, yformatter=y -> @sprintf("%.01f", y))
	hline!([1.0], color=:green, linestyle=:dashdot, label="")
end

# ╔═╡ 2d92945c-1ad5-4ef6-8c6e-1d77b23698f6
begin
	dd = DrawDowns(returns)
	dd.coredata.STOCK1 = dd.coredata.STOCK1 .* 100.0
end

# ╔═╡ ac56bb3d-0732-4536-bb81-594643c31935
begin
	plot(dd, title="Drawdowns (%)", color=:red, fillcolor=:red, fillrange=0, fillalpha=0.35)
end

# ╔═╡ c61cb98d-b0ea-4bf5-a0b4-11b925b18e0d
begin
	returns.coredata[!, :Year] = map(dt -> year(dt), returns.coredata[!, :Index])
	returns.coredata[!, :Month] = map(dt -> month(dt), returns.coredata[!, :Index])
	returns.coredata[!, :Year_Month] = map(dt -> Dates.Date(year(dt), month(dt), 1), returns.coredata[!, :Index])
	returns
end

# ╔═╡ 9fbe723e-219c-48e2-b47b-cf8acde6ba01
begin
	function plot_yearly()
		dt = Date[]
		cum_return = Float64[]
		_return = CumulativeReturn{Float64}()
		grouper = dt -> year(dt)
		group_prev = 1970
		for row in Tables.rows(returns)
			group = grouper(row[:Index])
			if group != group_prev
				empty!(_return)
				group_prev = group
			end
			push!(dt, row[:Index])
			fit!(_return, row[:STOCK1])
			push!(cum_return, value(_return))
		end
		xticks = [Dates.Date(year, 1, 1) for year in years]
		#plot(dt, cum_return)
		plot(dt, cum_return, xticks=xticks, xrotation=-45, xformatter = x -> Dates.format(x, "yyyy"))
	end
	plot_yearly()
end

# ╔═╡ 812c3c39-d1e2-40f6-9ef5-08b738dae7ea
begin
	function plot_monthly()
		dt = Date[]
		cum_return = Float64[]
		_return = CumulativeReturn{Float64}()
		grouper = dt -> (year(dt), month(dt))
		group_prev = (1970, 1)
		for row in Tables.rows(returns)
			group = grouper(row[:Index])
			if group != group_prev
				empty!(_return)
				group_prev = group
			end
			push!(dt, row[:Index])
			fit!(_return, row[:STOCK1])
			push!(cum_return, value(_return))
		end
		plot(dt, cum_return)
	end
	plot_monthly()
end

# ╔═╡ 2ae89296-456b-43cc-8d95-a6e2a823dd71
begin
	function plot_yearly_bar()
		ts_yearly = combine(groupby(returns.coredata, :Year), :STOCK1 => sum)
		println(ts_yearly |> TSFrame)
		bar_width = 1.0
		year_offset = 0  # 0.5
		ts_yearly_pos = ts_yearly[ts_yearly.STOCK1_sum .>= 0, :]
		ts_yearly_neg = ts_yearly[ts_yearly.STOCK1_sum .< 0, :]
		bar(ts_yearly_pos.Year .+ year_offset , ts_yearly_pos.STOCK1_sum, color=:lightgreen, label="positive return", legend=:topright, bar_width=bar_width)
		bar!(ts_yearly_neg.Year .+ year_offset, ts_yearly_neg.STOCK1_sum, color=:red, label="negative return", bar_width=bar_width)
	end
	plot_yearly_bar()
end

# ╔═╡ d88f95a8-9a80-4930-b331-4f01771825c1
begin
	function plot_monthly_bar()
		bar_width = 1.0
		ts_monthly = combine(groupby(returns.coredata, :Year_Month), :STOCK1 => sum)
		ts_monthly_pos = ts_monthly[ts_monthly.STOCK1_sum .>= 0, :]
		ts_monthly_neg = ts_monthly[ts_monthly.STOCK1_sum .< 0, :]
		bar(ts_monthly_pos.Year_Month , ts_monthly_pos.STOCK1_sum, color=:lightgreen, label="positive ret", legend=:topright, bar_width=bar_width)
		bar!(ts_monthly_neg.Year_Month, ts_monthly_neg.STOCK1_sum, color=:red, label="negative ret", bar_width=bar_width)
	end
	plot_monthly_bar()
end

# ╔═╡ 0b5eb641-e2c0-430c-bc98-128361cf21e8
begin
	return_year_month = combine(groupby(returns.coredata, [:Year, :Month]), :STOCK1 => sum)
	
	println(return_year_month)
end

# ╔═╡ d5cc1f53-5d20-45e5-a670-477e91311bb1
return_year_month_unstacked = unstack(return_year_month, :Year, :Month, :STOCK1_sum)

# ╔═╡ fef0e57c-581b-4b41-b5fb-41c972b12fed
(return_year_month.Year, return_year_month.Month, Matrix(return_year_month_unstacked[!, Not(:Year)]))

# ╔═╡ 92e0d8c6-12ca-46b0-8910-f14dcf10ebb6
begin
	ret_monthly_max = max(abs.(return_year_month.STOCK1_sum)...) * 100.0
	ret_monthly_max = 10^ceil(log10(ret_monthly_max))
end

# ╔═╡ c2095548-0103-4ad1-b086-9744256ab9d1
begin
	function plot_heatmap()
		plt = heatmap(unique(return_year_month.Month), unique(return_year_month.Year), Matrix(return_year_month_unstacked[!, Not(:Year)]) .* 100.0, c=:redgreensplit, clims=(-ret_monthly_max, ret_monthly_max), xticks=1:12)  # :redgreensplit ou :RdYlGn_5
		for year in unique(return_year_month.Year)
			for month in unique(return_year_month.Month)
				val = return_year_month[return_year_month.Year .== year .&& return_year_month.Month .== month, :STOCK1_sum][1]
				val = @sprintf("%.1f", val * 100.0)
				annotate!(month, year, val, c=:color, annotationfontsize=8)
			end
		end
		plt
	end
	plot_heatmap()
end

# ╔═╡ 183712bb-d8f0-44b8-ade2-eac1fdb38222
begin
	function plot_spiral()
		xmin, xmax = -300, 300
		ymin, ymax = xmin, xmax		
		plt = heatmap(xlims=(xmin, xmax), ylims=(ymin, ymax), aspect_ratio=1, grid=false, axis=false)		
		R = 190.0
		for month in 1:12
			θ = (90 - month * 30.0) * π / 180.0 
			x_txt = R * cos(θ)
			y_txt = R * sin(θ)
			annotate!(x_txt, y_txt, month)
		end
		annotationfontsize = 10
		for year in year_min:2:year_max
			x_txt = 250
			y_txt = (year_max - year_min) * (year - year_min) + 10
			annotate!(x_txt, y_txt, year, annotationfontsize=annotationfontsize, annotationrotation=0)
			annotate!(x_txt, -y_txt, year, annotationfontsize=annotationfontsize, annotationrotation=0)
			annotate!(-x_txt, y_txt, year, annotationfontsize=annotationfontsize, annotationrotation=0)
			annotate!(-x_txt, -y_txt, year, annotationfontsize=annotationfontsize, annotationrotation=0)
			annotate!(y_txt, x_txt, year, annotationfontsize=annotationfontsize, annotationrotation=90)
			annotate!(-y_txt, x_txt, year, annotationfontsize=annotationfontsize, annotationrotation=90)
			annotate!(y_txt, -x_txt, year, annotationfontsize=annotationfontsize, annotationrotation=270)
			annotate!(-y_txt, -x_txt, year, annotationfontsize=annotationfontsize, annotationrotation=270)
		end
		v_x = Float64[]
		v_y = Float64[]
		for year in years
			for month in 1:12
				θ = (90 - month * 30.0) * π / 180.0
				t = year + (month - 1) / 12.0
				Ryear = (year_max - year_min) * (t - year_min) + 10
				x = Ryear * cos(θ)
				y = Ryear * sin(θ)
				val = return_year_month[return_year_month.Year .== year .&& return_year_month.Month .== month, :STOCK1_sum][1]
				val *= 100.0
				plot!([x], [y], label="", c=:grey)
				markersize = clamp(Ryear / 30.0, 2.5, 5)
				scatter!([x], [y], zcolor=val, label="", markercolor=:redgreensplit, markersize=markersize, markeralpha=0.8, legend=:bottomleft, clims=(-ret_monthly_max, ret_monthly_max))
			end
		end

		for year in years
			for month in 1:12
				for day in 1:5:30
					if (year != year_max) || (month != 12)
						θ = (90 - (month + day / 30.0) * 30.0) * π / 180.0
						t = year + (month - 1) / 12.0
						Ryear = (year_max - year_min) * (t - year_min) + 10
						x = Ryear * cos(θ)
						y = Ryear * sin(θ)
						push!(v_x, x)
						push!(v_y, y)
					end
				end
			end
		end
		plot!(v_x, v_y, label="", color=:grey)
		plt
	end
	plot_spiral()
end

# ╔═╡ Cell order:
# ╠═a1861f50-046e-11ef-348b-cb9f60ea0d1b
# ╠═accbd5bc-4976-48cf-91c1-e12b62a94edf
# ╠═da790f5a-874b-4c65-9c7d-4243d3852859
# ╠═21600f87-228d-4cd0-8f24-ec821de8ef8c
# ╠═c0fd125c-70d3-4e42-a0a5-4daff44a2c96
# ╠═b0e1d632-1b86-4259-8f28-464e0af0c3e0
# ╠═a208fb00-cfe1-46d9-9751-e9e5f423f8fb
# ╠═2d92945c-1ad5-4ef6-8c6e-1d77b23698f6
# ╠═ac56bb3d-0732-4536-bb81-594643c31935
# ╠═c61cb98d-b0ea-4bf5-a0b4-11b925b18e0d
# ╠═9fbe723e-219c-48e2-b47b-cf8acde6ba01
# ╠═812c3c39-d1e2-40f6-9ef5-08b738dae7ea
# ╠═2ae89296-456b-43cc-8d95-a6e2a823dd71
# ╠═d88f95a8-9a80-4930-b331-4f01771825c1
# ╠═0b5eb641-e2c0-430c-bc98-128361cf21e8
# ╠═d5cc1f53-5d20-45e5-a670-477e91311bb1
# ╠═fef0e57c-581b-4b41-b5fb-41c972b12fed
# ╠═92e0d8c6-12ca-46b0-8910-f14dcf10ebb6
# ╠═c2095548-0103-4ad1-b086-9744256ab9d1
# ╠═183712bb-d8f0-44b8-ade2-eac1fdb38222
