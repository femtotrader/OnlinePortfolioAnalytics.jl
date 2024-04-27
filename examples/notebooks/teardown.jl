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
	price_var_min = -10.0,
	price_var_step = 0.1,
	price_var_max = 10.0,
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
ts = random_data()

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
	plot(cum_returns, title="Cumulative returns", color=:green)
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
	returns.coredata[!, :Month] = map(dt -> Dates.Date(year(dt), month(dt), 1), returns.coredata[!, :Index])
end

# ╔═╡ 04894092-b9c4-42d8-87b2-b530de95736c
returns

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
# ╠═04894092-b9c4-42d8-87b2-b530de95736c
