var documenterSearchIndex = {"docs":
[{"location":"api/#API-Documentation","page":"API","title":"API Documentation","text":"","category":"section"},{"location":"api/#Portfolio-analytics","page":"API","title":"Portfolio analytics","text":"","category":"section"},{"location":"api/","page":"API","title":"API","text":"CurrentModule = OnlinePortfolioAnalytics","category":"page"},{"location":"api/#Modules","page":"API","title":"Modules","text":"","category":"section"},{"location":"api/","page":"API","title":"API","text":"OnlinePortfolioAnalytics.OnlinePortfolioAnalytics","category":"page"},{"location":"api/#OnlinePortfolioAnalytics.OnlinePortfolioAnalytics","page":"API","title":"OnlinePortfolioAnalytics.OnlinePortfolioAnalytics","text":"OnlinePortfolioAnalytics module aims to provide users with functionality for performing quantitative portfolio analytics via online algorithms.\n\n\n\nMIT License\n\nCopyright (c) 2024 FemtoTrader <femto.trader@gmail.com>\n\nPermission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the \"Software\"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:\n\nThe above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.\n\nTHE SOFTWARE IS PROVIDED \"AS IS\", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.\n\n\n\n\n\n","category":"module"},{"location":"api/#Asset-return","page":"API","title":"Asset return","text":"","category":"section"},{"location":"api/","page":"API","title":"API","text":"SimpleAssetReturn\nLogAssetReturn","category":"page"},{"location":"api/#OnlinePortfolioAnalytics.SimpleAssetReturn","page":"API","title":"OnlinePortfolioAnalytics.SimpleAssetReturn","text":"mutable struct SimpleAssetReturn{T} <: OnlinePortfolioAnalytics.AssetReturn{T}\n\nSimpleAssetReturn{T}(; period::Int = 1)\n\nThe SimpleAssetReturn implements asset return (simple method) calculations.\n\nParameters\n\nperiod\n\nUsage\n\nFeed SimpleAssetReturn one observation at a time\n\njulia> using OnlinePortfolioAnalytics\n\njulia> ret = SimpleAssetReturn{Float64}()\nSimpleAssetReturn: n=0 | value=missing\n\njulia> fit!(ret, 10.0)\nSimpleAssetReturn: n=1 | value=missing\n\njulia> fit!(ret, 11.0)\nSimpleAssetReturn: n=2 | value=0.1\n\njulia> value(ret)\n0.1\n\n\n\n\n\n","category":"type"},{"location":"api/#OnlinePortfolioAnalytics.LogAssetReturn","page":"API","title":"OnlinePortfolioAnalytics.LogAssetReturn","text":"mutable struct LogAssetReturn{T} <: OnlinePortfolioAnalytics.AssetReturn{T}\n\nLogAssetReturn{T}(; period::Int = 1)\n\nThe LogAssetReturn implements asset return (natural log method) calculations.\n\nParameters\n\nperiod\n\nUsage\n\nFeed LogAssetReturn one observation at a time\n\njulia> using OnlinePortfolioAnalytics\n\njulia> ret = LogAssetReturn{Float64}()\nLogAssetReturn: n=0 | value=missing\n\njulia> fit!(ret, 10.0)\nLogAssetReturn: n=1 | value=missing\n\njulia> fit!(ret, 11.0)\nLogAssetReturn: n=2 | value=0.0953102\n\njulia> value(ret)\n0.09531017980432493\n\n\n\n\n\n","category":"type"},{"location":"api/#Mean-return","page":"API","title":"Mean return","text":"","category":"section"},{"location":"api/","page":"API","title":"API","text":"ArithmeticMeanReturn\nGeometricMeanReturn","category":"page"},{"location":"api/#OnlinePortfolioAnalytics.ArithmeticMeanReturn","page":"API","title":"OnlinePortfolioAnalytics.ArithmeticMeanReturn","text":"mutable struct ArithmeticMeanReturn{T} <: OnlinePortfolioAnalytics.AbstractMeanReturn{T}\n\nArithmeticMeanReturn{T}()\n\nThe ArithmeticMeanReturn type implements arithmetic mean returns calculations.\n\n\n\n\n\n","category":"type"},{"location":"api/#OnlinePortfolioAnalytics.GeometricMeanReturn","page":"API","title":"OnlinePortfolioAnalytics.GeometricMeanReturn","text":"mutable struct GeometricMeanReturn{T} <: OnlinePortfolioAnalytics.AbstractMeanReturn{T}\n\nGeometricMeanReturn{T}()\n\nThe GeometricMeanReturn type implements geometric mean returns calculations.\n\n\n\n\n\n","category":"type"},{"location":"api/#Cumulative-return","page":"API","title":"Cumulative return","text":"","category":"section"},{"location":"api/","page":"API","title":"API","text":"CumulativeReturn","category":"page"},{"location":"api/#OnlinePortfolioAnalytics.CumulativeReturn","page":"API","title":"OnlinePortfolioAnalytics.CumulativeReturn","text":"mutable struct CumulativeReturn{T} <: OnlinePortfolioAnalytics.PortfolioAnalyticsSingleOutput{T}\n\nCumulativeReturn{T}()\n\nThe CumulativeReturn type implements cumulative return calculations.\n\n\n\n\n\n","category":"type"},{"location":"api/#Standard-deviation","page":"API","title":"Standard deviation","text":"","category":"section"},{"location":"api/","page":"API","title":"API","text":"StdDev","category":"page"},{"location":"api/#OnlinePortfolioAnalytics.StdDev","page":"API","title":"OnlinePortfolioAnalytics.StdDev","text":"mutable struct StdDev{T} <: OnlinePortfolioAnalytics.PortfolioAnalyticsSingleOutput{T}\n\nStdDev{T}()\n\nThe StdDev type implements standard deviation calculations.\n\n\n\n\n\n","category":"type"},{"location":"api/#Drawdowns","page":"API","title":"Drawdowns","text":"","category":"section"},{"location":"api/","page":"API","title":"API","text":"DrawDowns\nArithmeticDrawDowns","category":"page"},{"location":"api/#OnlinePortfolioAnalytics.DrawDowns","page":"API","title":"OnlinePortfolioAnalytics.DrawDowns","text":"mutable struct DrawDowns{T} <: OnlinePortfolioAnalytics.AbstractDrawDowns{T}\n\nDrawDowns{T}()\n\nThe DrawDowns type implements drawdowns calculations (geometric method).\n\n\n\n\n\n","category":"type"},{"location":"api/#OnlinePortfolioAnalytics.ArithmeticDrawDowns","page":"API","title":"OnlinePortfolioAnalytics.ArithmeticDrawDowns","text":"mutable struct ArithmeticDrawDowns{T} <: OnlinePortfolioAnalytics.AbstractDrawDowns{T}\n\nArithmeticDrawDowns{T}()\n\nThe ArithmeticDrawDowns type implements drawdowns calculations (arithmetic method).\n\n\n\n\n\n","category":"type"},{"location":"api/#Statistical-moments","page":"API","title":"Statistical moments","text":"","category":"section"},{"location":"api/","page":"API","title":"API","text":"AssetReturnMoments","category":"page"},{"location":"api/#OnlinePortfolioAnalytics.AssetReturnMoments","page":"API","title":"OnlinePortfolioAnalytics.AssetReturnMoments","text":"mutable struct AssetReturnMoments{T} <: OnlinePortfolioAnalytics.PortfolioAnalyticsMultiOutput{T}\n\nAssetReturnMoments{T}()\n\nThe AssetReturnMoments type implements 4 first statistical moments (mean, std, skewness, kurtosis) calculations.\n\n\n\n\n\n","category":"type"},{"location":"api/#Sharpe-ratio","page":"API","title":"Sharpe ratio","text":"","category":"section"},{"location":"api/","page":"API","title":"API","text":"Sharpe","category":"page"},{"location":"api/#OnlinePortfolioAnalytics.Sharpe","page":"API","title":"OnlinePortfolioAnalytics.Sharpe","text":"mutable struct Sharpe{T} <: OnlinePortfolioAnalytics.PortfolioAnalyticsSingleOutput{T}\n\nSharpe{T}(; period=252, risk_free=0)\n\nThe Sharpe type implements sharpe ratio calculations.\n\nParameters\n\nperiod: default is 252. Daily (252), Hourly (252*6.5), Minutely(252*6.5*60) etc...\nrisk_free: default is 0. Constant risk-free return throughout the period.\n\n\n\n\n\n","category":"type"},{"location":"api/#Sortino-ratio","page":"API","title":"Sortino ratio","text":"","category":"section"},{"location":"api/","page":"API","title":"API","text":"Sortino","category":"page"},{"location":"api/#OnlinePortfolioAnalytics.Sortino","page":"API","title":"OnlinePortfolioAnalytics.Sortino","text":"mutable struct Sortino{T} <: OnlinePortfolioAnalytics.PortfolioAnalyticsSingleOutput{T}\n\nSortino{T}(; period=252, risk_free=0)\n\nThe Sortino type implements Sortino ratio calculations.\n\nParameters\n\nperiod: default is 252. Daily (252), Hourly (252*6.5), Minutely(252*6.5*60) etc...\nrisk_free: default is 0. Constant risk-free return throughout the period.\n\n\n\n\n\n","category":"type"},{"location":"api/#Other","page":"API","title":"Other","text":"","category":"section"},{"location":"api/","page":"API","title":"API","text":"Prod","category":"page"},{"location":"api/#OnlinePortfolioAnalytics.Prod","page":"API","title":"OnlinePortfolioAnalytics.Prod","text":"Prod(T::Type = Float64)\n\nTrack the overall product.\n\n\n\n\n\n","category":"type"},{"location":"usage/#Usage","page":"Usage","title":"Usage","text":"","category":"section"},{"location":"usage/#Feeding-a-portfolio-analytics-one-observation-at-a-time","page":"Usage","title":"Feeding a portfolio analytics one observation at a time","text":"","category":"section"},{"location":"usage/","page":"Usage","title":"Usage","text":"A portfolio analytics object can be feeded using fit! function.\nIt's feeded one observation at a time.","category":"page"},{"location":"usage/#Showing-sample-data","page":"Usage","title":"Showing sample data","text":"","category":"section"},{"location":"usage/","page":"Usage","title":"Usage","text":"Some sample data are provided for testing purpose.","category":"page"},{"location":"usage/","page":"Usage","title":"Usage","text":"julia> using OnlinePortfolioAnalytics\njulia> using OnlinePortfolioAnalytics.SampleData: dates, TSLA, NFLX, MSFT, weights\n\njulia> dates\nDates.Date(\"2020-12-31\"):Dates.Month(1):Dates.Date(\"2021-12-31\")\n\njulia> TSLA\n13-element Vector{Float64}:\n 235.22\n 264.51\n 225.16\n 222.64\n 236.48\n 208.4\n 226.56\n 229.06\n 245.24\n 258.49\n 371.33\n 381.58\n 352.26\n\njulia> NFLX\n13-element Vector{Float64}:\n 540.73\n 532.39\n 538.85\n 521.66\n 513.47\n 502.81\n 528.21\n 517.57\n 569.19\n 610.34\n 690.31\n 641.9\n 602.44\n\njulia> MSFT\n13-element Vector{Float64}:\n 222.42\n 231.96\n 232.38\n 235.77\n 252.18\n 249.68\n 270.9\n 284.91\n 301.88\n 281.92\n 331.62\n 330.59\n 336.32\n\njulia> weights\n3-element Vector{Float64}:\n 0.4\n 0.4\n 0.2","category":"page"},{"location":"usage/#Calculate-returns-(from-TSLA-prices)","page":"Usage","title":"Calculate returns (from TSLA prices)","text":"","category":"section"},{"location":"usage/","page":"Usage","title":"Usage","text":"julia> stat = SimpleAssetReturn{Float64}()\nSimpleAssetReturn: n=0 | value=missing\n\njulia> fit!(stat, 235.22)\nSimpleAssetReturn: n=1 | value=missing\n\njulia> fit!(stat, 264.51)\nSimpleAssetReturn: n=2 | value=0.124522\n\njulia> value(stat)\n0.12452172434316806","category":"page"},{"location":"usage/#Calculate-returns-(natural-log-method)","page":"Usage","title":"Calculate returns (natural log method)","text":"","category":"section"},{"location":"usage/","page":"Usage","title":"Usage","text":"julia> stat = LogAssetReturn{Float64}()\nLogAssetReturn: n=0 | value=missing\n\njulia> fit!(stat, 235.22)\nLogAssetReturn: n=1 | value=missing\n\njulia> fit!(stat, 264.51)\nLogAssetReturn: n=2 | value=0.117358","category":"page"},{"location":"usage/#Others","page":"Usage","title":"Others","text":"","category":"section"},{"location":"usage/","page":"Usage","title":"Usage","text":"See API usage","category":"page"},{"location":"usage/#Portfolio-analytics-with-Tables.jl-compatible-sources","page":"Usage","title":"Portfolio analytics with Tables.jl compatible sources","text":"","category":"section"},{"location":"usage/","page":"Usage","title":"Usage","text":"Here is an example showing how to use OnlinePortfolioAnalytics with Tables.jl compatible sources.","category":"page"},{"location":"usage/#Sample-data","page":"Usage","title":"Sample data","text":"","category":"section"},{"location":"usage/","page":"Usage","title":"Usage","text":"julia> using TSFrames\n\njulia> prices_ts = TSFrame([TSLA NFLX MSFT], dates, colnames = [:TSLA, :NFLX, :MSFT])\n13×3 TSFrame with Date Index\n Index       TSLA     NFLX     MSFT\n Date        Float64  Float64  Float64\n───────────────────────────────────────\n 2020-12-31   235.22   540.73   222.42\n 2021-01-31   264.51   532.39   231.96\n 2021-02-28   225.16   538.85   232.38\n 2021-03-31   222.64   521.66   235.77\n 2021-04-30   236.48   513.47   252.18\n 2021-05-31   208.4    502.81   249.68\n 2021-06-30   226.56   528.21   270.9\n 2021-07-31   229.06   517.57   284.91\n 2021-08-31   245.24   569.19   301.88\n 2021-09-30   258.49   610.34   281.92\n 2021-10-31   371.33   690.31   331.62\n 2021-11-30   381.58   641.9    330.59\n 2021-12-31   352.26   602.44   336.3","category":"page"},{"location":"usage/#Returns","page":"Usage","title":"Returns","text":"","category":"section"},{"location":"usage/","page":"Usage","title":"Usage","text":"julia> returns = SimpleAssetReturn(prices_ts)\n13×3 TSFrame with Date Index\n Index       TSLA             MSFT              NFLX\n Date        Float64?         Float64?          Float64?\n────────────────────────────────────────────────────────────────\n 2020-12-31  missing          missing           missing\n 2021-01-31        0.124522         0.0428918        -0.0154236\n 2021-02-28       -0.148766         0.00181066        0.012134\n 2021-03-31       -0.011192         0.0145882        -0.0319013\n 2021-04-30        0.0621631        0.0696017        -0.0156999\n 2021-05-31       -0.118742        -0.00991355       -0.0207607\n 2021-06-30        0.0871401        0.0849888         0.0505161\n 2021-07-31        0.0110346        0.0517165        -0.0201435\n 2021-08-31        0.0706365        0.0595627         0.0997353\n 2021-09-30        0.0540287       -0.066119          0.0722957\n 2021-10-31        0.436535         0.176291          0.131025\n 2021-11-30        0.0276035       -0.00310596       -0.0701279\n 2021-12-31       -0.0768384        0.0173326        -0.0614737","category":"page"},{"location":"usage/#Remove-missing-from-returns","page":"Usage","title":"Remove missing from returns","text":"","category":"section"},{"location":"usage/","page":"Usage","title":"Usage","text":"julia> using DataFrames\n\njulia> returns = dropmissing(returns.coredata) |> TSFrame\n12×3 TSFrame with Date Index\n Index       TSLA        MSFT         NFLX\n Date        Float64     Float64      Float64\n─────────────────────────────────────────────────\n 2021-01-31   0.124522    0.0428918   -0.0154236\n 2021-02-28  -0.148766    0.00181066   0.012134\n 2021-03-31  -0.011192    0.0145882   -0.0319013\n 2021-04-30   0.0621631   0.0696017   -0.0156999\n 2021-05-31  -0.118742   -0.00991355  -0.0207607\n 2021-06-30   0.0871401   0.0849888    0.0505161\n 2021-07-31   0.0110346   0.0517165   -0.0201435\n 2021-08-31   0.0706365   0.0595627    0.0997353\n 2021-09-30   0.0540287  -0.066119     0.0722957\n 2021-10-31   0.436535    0.176291     0.131025\n 2021-11-30   0.0276035  -0.00310596  -0.0701279\n 2021-12-31  -0.0768384   0.0173326   -0.0614737","category":"page"},{"location":"usage/#Calculate-standard-deviation-of-returns","page":"Usage","title":"Calculate standard deviation of returns","text":"","category":"section"},{"location":"usage/","page":"Usage","title":"Usage","text":"julia> stddev = StdDev(returns)\n12×3 TSFrame with Date Index\n Index       TSLA       MSFT       NFLX\n Date        Float64    Float64    Float64\n─────────────────────────────────────────────\n 2021-01-31  1.0        1.0        1.0\n 2021-02-28  0.193243   0.0290488  0.0194861\n 2021-03-31  0.136645   0.0210239  0.0222487\n 2021-04-30  0.117541   0.0302594  0.0182741\n 2021-05-31  0.116225   0.0322773  0.016229\n 2021-06-30  0.11253    0.0381779  0.0301918\n 2021-07-31  0.102823   0.0354894  0.0282681\n 2021-08-31  0.0983386  0.0338512  0.0456038\n 2021-09-30  0.0931719  0.047328   0.0478437\n 2021-10-31  0.159765   0.064804   0.0582396\n 2021-11-30  0.15182    0.0630003  0.0624165\n 2021-12-31  0.149608   0.0603753  0.0637211","category":"page"},{"location":"usage/#Calculate-arithmetic-mean-returns","page":"Usage","title":"Calculate arithmetic mean returns","text":"","category":"section"},{"location":"usage/","page":"Usage","title":"Usage","text":"julia> amr = ArithmeticMeanReturn(returns)\n12×3 TSFrame with Date Index\n Index       TSLA          MSFT       NFLX\n Date        Float64       Float64    Float64\n──────────────────────────────────────────────────\n 2021-01-31   0.124522     0.0428918  -0.0154236\n 2021-02-28  -0.012122     0.0223512  -0.00164482\n 2021-03-31  -0.011812     0.0197636  -0.0117303\n 2021-04-30   0.00668179   0.0322231  -0.0127227\n 2021-05-31  -0.0184029    0.0237958  -0.0143303\n 2021-06-30  -0.000812376  0.0339946  -0.00352257\n 2021-07-31   0.00088005   0.0365263  -0.00589699\n 2021-08-31   0.00959961   0.0394058   0.00730705\n 2021-09-30   0.0145362    0.0276809   0.014528\n 2021-10-31   0.0567361    0.0425419   0.0261777\n 2021-11-30   0.0540877    0.0383921   0.0174227\n 2021-12-31   0.0431772    0.0366371   0.010848","category":"page"},{"location":"usage/#Calculate-geometric-mean-returns","page":"Usage","title":"Calculate geometric mean returns","text":"","category":"section"},{"location":"usage/","page":"Usage","title":"Usage","text":"julia> gmr = GeometricMeanReturn(returns)\n12×3 TSFrame with Date Index\n Index       TSLA         MSFT       NFLX\n Date        Float64      Float64    Float64\n─────────────────────────────────────────────────\n 2021-01-31   0.124522    0.0428918  -0.0154236\n 2021-02-28  -0.0216179   0.0221449  -0.0017399\n 2021-03-31  -0.0181549   0.0196197  -0.0118967\n 2021-04-30   0.00133649  0.0318919  -0.0128489\n 2021-05-31  -0.0239216   0.0233919  -0.0144363\n 2021-06-30  -0.0062324   0.0334097  -0.00389675\n 2021-07-31  -0.00378386  0.0360053  -0.0062341\n 2021-08-31   0.00522813  0.0389211   0.00643238\n 2021-09-30   0.0105369   0.0266895   0.013546\n 2021-10-31   0.0467153   0.0407506   0.0247227\n 2021-11-30   0.0449633   0.0366852   0.0157142\n 2021-12-31   0.0342267   0.0350585   0.00904634","category":"page"},{"location":"usage/#Calculate-asset-log-returns-from-prices","page":"Usage","title":"Calculate asset log returns from prices","text":"","category":"section"},{"location":"usage/","page":"Usage","title":"Usage","text":"julia> log_returns = LogAssetReturn(prices_ts)\n13×3 TSFrame with Date Index\n Index       TSLA             MSFT              NFLX\n Date        Float64?         Float64?          Float64?\n────────────────────────────────────────────────────────────────\n 2020-12-31  missing          missing           missing\n 2021-01-31        0.117358         0.0419975        -0.0155438\n 2021-02-28       -0.161068         0.00180902        0.0120609\n 2021-03-31       -0.0112551        0.0144828        -0.0324212\n 2021-04-30        0.0603075        0.0672864        -0.0158244\n 2021-05-31       -0.126404        -0.00996302       -0.0209792\n 2021-06-30        0.0835505        0.0815697         0.0492816\n 2021-07-31        0.0109742        0.0504236        -0.0203492\n 2021-08-31        0.0682533        0.0578562         0.0950695\n 2021-09-30        0.0526197       -0.0684062         0.0698019\n 2021-10-31        0.362234         0.162366          0.123125\n 2021-11-30        0.0272294       -0.0031108        -0.0727082\n 2021-12-31       -0.079951         0.0171842        -0.0634445","category":"page"},{"location":"usage/#Calculate-cumulative-returns","page":"Usage","title":"Calculate cumulative returns","text":"","category":"section"},{"location":"usage/","page":"Usage","title":"Usage","text":"julia> cum_returns = CumulativeReturn(returns)\n12×3 TSFrame with Date Index\n Index       TSLA      MSFT     NFLX\n Date        Float64   Float64  Float64\n─────────────────────────────────────────\n 2021-01-31  1.12452   1.04289  0.984576\n 2021-02-28  0.957232  1.04478  0.996523\n 2021-03-31  0.946518  1.06002  0.964733\n 2021-04-30  1.00536   1.1338   0.949587\n 2021-05-31  0.885979  1.12256  0.929873\n 2021-06-30  0.963183  1.21797  0.976846\n 2021-07-31  0.973812  1.28095  0.957169\n 2021-08-31  1.0426    1.35725  1.05263\n 2021-09-30  1.09893   1.26751  1.12873\n 2021-10-31  1.57865   1.49096  1.27663\n 2021-11-30  1.62223   1.48633  1.1871\n 2021-12-31  1.49758   1.51209  1.11412","category":"page"},{"location":"usage/#Calculate-Drawdowns","page":"Usage","title":"Calculate Drawdowns","text":"","category":"section"},{"location":"usage/","page":"Usage","title":"Usage","text":"julia> dd = DrawDowns(returns)\n12×3 TSFrame with Date Index\n Index       TSLA        MSFT         NFLX\n Date        Float64     Float64      Float64\n─────────────────────────────────────────────────\n 2021-01-31   0.0         0.0          0.0\n 2021-02-28  -0.148766    0.0          0.0\n 2021-03-31  -0.158293    0.0         -0.0319013\n 2021-04-30  -0.10597     0.0         -0.0471003\n 2021-05-31  -0.212128   -0.00991355  -0.0668832\n 2021-06-30  -0.143473    0.0         -0.0197458\n 2021-07-31  -0.134021    0.0         -0.0394915\n 2021-08-31  -0.0728517   0.0          0.0\n 2021-09-30  -0.0227591  -0.066119     0.0\n 2021-10-31   0.0         0.0          0.0\n 2021-11-30   0.0        -0.00310596  -0.0701279\n 2021-12-31  -0.0768384   0.0         -0.127291","category":"page"},{"location":"usage/#Calculate-Drawdowns-(Arithmetic-method)","page":"Usage","title":"Calculate Drawdowns (Arithmetic method)","text":"","category":"section"},{"location":"usage/","page":"Usage","title":"Usage","text":"julia> arith_dd = ArithmeticDrawDowns(returns)\n12×3 TSFrame with Date Index\n Index       TSLA        MSFT         NFLX\n Date        Float64     Float64      Float64\n─────────────────────────────────────────────────\n 2021-01-31   0.0         0.0          0.0\n 2021-02-28  -0.132292    0.0          0.0\n 2021-03-31  -0.142245    0.0         -0.0320066\n 2021-04-30  -0.0869655   0.0         -0.0477583\n 2021-05-31  -0.192558   -0.00878166  -0.0685875\n 2021-06-30  -0.115068    0.0         -0.0179047\n 2021-07-31  -0.105255    0.0         -0.0381146\n 2021-08-31  -0.0424401   0.0          0.0\n 2021-09-30   0.0        -0.0502712    0.0\n 2021-10-31   0.0         0.0          0.0\n 2021-11-30   0.0        -0.00217898  -0.0555787\n 2021-12-31  -0.0481756   0.0         -0.104299","category":"page"},{"location":"usage/#Calculate-statistical-moments-of-returns","page":"Usage","title":"Calculate statistical moments of returns","text":"","category":"section"},{"location":"usage/","page":"Usage","title":"Usage","text":"julia> moments = AssetReturnMoments(returns)\n12×3 TSFrame with Date Index\n Index       TSLA                               MSFT                               NFLX\n Date        Any                                Any                                Any\n─────────────────────────────────────────────────────────────────────────────────────────────────────────────────────\n 2021-01-31  (mean = 0.124522, std = NaN, ske…  (mean = 0.0428918, std = NaN, sk…  (mean = -0.0154236, std = NaN, s…\n 2021-02-28  (mean = -0.012122, std = 0.19324…  (mean = 0.0223512, std = 0.02904…  (mean = -0.00164482, std = 0.019…\n 2021-03-31  (mean = -0.011812, std = 0.13664…  (mean = 0.0197636, std = 0.02102…  (mean = -0.0117303, std = 0.0222…\n 2021-04-30  (mean = 0.00668179, std = 0.1175…  (mean = 0.0322231, std = 0.03025…  (mean = -0.0127227, std = 0.0182…\n 2021-05-31  (mean = -0.0184029, std = 0.1162…  (mean = 0.0237958, std = 0.03227…  (mean = -0.0143303, std = 0.0162…\n 2021-06-30  (mean = -0.000812376, std = 0.11…  (mean = 0.0339946, std = 0.03817…  (mean = -0.00352257, std = 0.030…\n 2021-07-31  (mean = 0.00088005, std = 0.1028…  (mean = 0.0365263, std = 0.03548…  (mean = -0.00589699, std = 0.028…\n 2021-08-31  (mean = 0.00959961, std = 0.0983…  (mean = 0.0394058, std = 0.03385…  (mean = 0.00730705, std = 0.0456…\n 2021-09-30  (mean = 0.0145362, std = 0.09317…  (mean = 0.0276809, std = 0.04732…  (mean = 0.014528, std = 0.047843…\n 2021-10-31  (mean = 0.0567361, std = 0.15976…  (mean = 0.0425419, std = 0.06480…  (mean = 0.0261777, std = 0.05823…\n 2021-11-30  (mean = 0.0540877, std = 0.15182…  (mean = 0.0383921, std = 0.06300…  (mean = 0.0174227, std = 0.06241…\n 2021-12-31  (mean = 0.0431772, std = 0.14960…  (mean = 0.0366371, std = 0.06037…  (mean = 0.010848, std = 0.063721…","category":"page"},{"location":"usage/#Calculate-Sharpe-ratio-(from-returns)","page":"Usage","title":"Calculate Sharpe ratio (from returns)","text":"","category":"section"},{"location":"usage/","page":"Usage","title":"Usage","text":"julia> sharpe = Sharpe(returns, period = 1)\n12×3 TSFrame with Date Index\n Index       TSLA         MSFT       NFLX\n Date        Float64      Float64    Float64\n────────────────────────────────────────────────\n 2021-01-31   0.124522    0.0428918  -0.0154236\n 2021-02-28  -0.062729    0.769438   -0.0844096\n 2021-03-31  -0.086443    0.940052   -0.527235\n 2021-04-30   0.0568464   1.0649     -0.696214\n 2021-05-31  -0.158339    0.73723    -0.883007\n 2021-06-30  -0.00721917  0.890425   -0.116673\n 2021-07-31   0.00855887  1.02922    -0.208609\n 2021-08-31   0.0976179   1.16409     0.160229\n 2021-09-30   0.156015    0.584873    0.303656\n 2021-10-31   0.355123    0.65647     0.449484\n 2021-11-30   0.356261    0.609396    0.279136\n 2021-12-31   0.288602    0.606824    0.170242","category":"page"},{"location":"usage/#Calculate-Sortino-ratio-(from-returns)","page":"Usage","title":"Calculate Sortino ratio (from returns)","text":"","category":"section"},{"location":"usage/","page":"Usage","title":"Usage","text":"julia> sortino = Sortino(returns)\n12×3 TSFrame with Date Index\n Index       TSLA       MSFT       NFLX\n Date        Float64    Float64    Float64\n───────────────────────────────────────────────\n 2021-01-31   1.97672    0.680887   -0.244842\n 2021-02-28  -0.19243    0.354815   -0.0261106\n 2021-03-31  -1.92754    0.313737  -15.9819\n 2021-04-30   1.09037    0.511526  -21.4069\n 2021-05-31  -4.03861    0.377746  -29.527\n 2021-06-30  -0.17828    0.539648   -7.25811\n 2021-07-31   0.193132   0.579837  -14.0099\n 2021-08-31   2.10669    0.625548   17.3599\n 2021-09-30   3.19005   11.0565     34.5153\n 2021-10-31  12.4511    16.9924     62.1925\n 2021-11-30  11.8698    17.6228     13.163\n 2021-12-31  11.4992    16.8173      7.56288","category":"page"},{"location":"#OnlinePortfolioAnalytics.jl","page":"Home","title":"OnlinePortfolioAnalytics.jl","text":"","category":"section"},{"location":"","page":"Home","title":"Home","text":"This project aims to provide users with functionality for performing quantitative portfolio analytics via online algorithms.","category":"page"},{"location":"","page":"Home","title":"Home","text":"It depends especially on OnlineStatsBase.jl.","category":"page"},{"location":"","page":"Home","title":"Home","text":"It's inspired by the following projects:","category":"page"},{"location":"","page":"Home","title":"Home","text":"Julia\nPortfolioAnalytics.jl\nR\nPerformanceAnalytics\nPortfolioAnalytics\nPython\npyfolio\nempyrical","category":"page"},{"location":"#Installation","page":"Home","title":"Installation","text":"","category":"section"},{"location":"","page":"Home","title":"Home","text":"Open Julia command line interface. ","category":"page"},{"location":"","page":"Home","title":"Home","text":"Type ] dev https://github.com/femtotrader/OnlinePortfolioAnalytics.jl/","category":"page"},{"location":"#Usage","page":"Home","title":"Usage","text":"","category":"section"},{"location":"","page":"Home","title":"Home","text":"See unit tests","category":"page"},{"location":"","page":"Home","title":"Home","text":"🚧 This software is under construction. API can have breaking changes.","category":"page"},{"location":"#Contents","page":"Home","title":"Contents","text":"","category":"section"},{"location":"","page":"Home","title":"Home","text":"Pages = [\n    \"index.md\",\n    \"usage.md\",\n    \"api.md\"\n]","category":"page"}]
}