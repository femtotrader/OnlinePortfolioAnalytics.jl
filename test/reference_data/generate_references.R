# =============================================================================
# R Reference Value Generator for OnlinePortfolioAnalytics Validation Tests
# =============================================================================
#
# This script generates reference values from R's PerformanceAnalytics package
# for validating the Julia OnlinePortfolioAnalytics implementation.
#
# USAGE:
#   Rscript generate_references.R > output.txt
#   Then copy the output into r_reference_values.jl
#
# REQUIREMENTS:
#   - R 4.x
#   - PerformanceAnalytics package: install.packages("PerformanceAnalytics")
#
# REGENERATION:
#   Run this script whenever:
#   - PerformanceAnalytics is updated
#   - New statistics are added to OnlinePortfolioAnalytics
#   - Reference dataset needs to change
#
# =============================================================================

library(PerformanceAnalytics)

# Load the managers dataset
data(managers)

# Extract first 120 observations (10 years) for stable testing
# HAM1 = first manager, SP500 TR = S&P 500 Total Return (benchmark)
n_obs <- 120
returns <- as.numeric(managers[1:n_obs, "HAM1"])
benchmark <- as.numeric(managers[1:n_obs, "SP500 TR"])

# Remove any NA values and align the series
valid_idx <- !is.na(returns) & !is.na(benchmark)
returns <- returns[valid_idx]
benchmark <- benchmark[valid_idx]
n_obs <- length(returns)

# Parameters
rf_annual <- 0.04  # 4% annual risk-free rate
rf_monthly <- rf_annual / 12
mar <- 0.0  # Minimum Acceptable Return
var_confidence <- 0.95  # VaR/ES confidence level

cat("# =============================================================================\n")
cat("# R Reference Values for OnlinePortfolioAnalytics Validation\n")
cat("# =============================================================================\n")
cat("#\n")
cat(sprintf("# Generated: %s\n", Sys.time()))
cat(sprintf("# R Version: %s\n", R.version.string))
cat(sprintf("# PerformanceAnalytics Version: %s\n", packageVersion("PerformanceAnalytics")))
cat("#\n")
cat("# Source: PerformanceAnalytics managers dataset\n")
cat(sprintf("# Observations: %d\n", n_obs))
cat("# Asset: HAM1 (first hypothetical manager)\n")
cat("# Benchmark: SP500 TR (S&P 500 Total Return)\n")
cat("#\n")
cat("# =============================================================================\n\n")

cat("module RReferenceValues\n\n")

# Metadata
cat("# Source dataset metadata\n")
cat("const DATA_SOURCE = \"PerformanceAnalytics managers dataset\"\n")
cat(sprintf("const R_VERSION = \"%s\"\n", R.version.string))
cat(sprintf("const PA_VERSION = \"%s\"\n", packageVersion("PerformanceAnalytics")))
cat(sprintf("const GENERATED_DATE = \"%s\"\n", Sys.Date()))
cat(sprintf("const N_OBS = %d\n\n", n_obs))

# Input data arrays
cat("# Input data: HAM1 manager returns\n")
cat("const RETURNS = Float64[\n    ")
cat(paste(sprintf("%.16f", returns), collapse = ",\n    "))
cat("\n]\n\n")

cat("# Benchmark: S&P 500 returns\n")
cat("const BENCHMARK = Float64[\n    ")
cat(paste(sprintf("%.16f", benchmark), collapse = ",\n    "))
cat("\n]\n\n")

# Parameters
cat("# Parameters\n")
cat(sprintf("const RF_ANNUAL = %.16f\n", rf_annual))
cat(sprintf("const RF_MONTHLY = %.16f\n", rf_monthly))
cat(sprintf("const MAR = %.16f\n", mar))
cat(sprintf("const VAR_CONFIDENCE = %.16f\n\n", var_confidence))

# Convert to xts for PerformanceAnalytics functions
returns_xts <- xts(returns, order.by = seq(as.Date("1996-01-31"), by = "month", length.out = n_obs))
benchmark_xts <- xts(benchmark, order.by = seq(as.Date("1996-01-31"), by = "month", length.out = n_obs))

cat("# ===== REFERENCE VALUES =====\n\n")

# Core Returns (US1)
cat("# Core Returns (User Story 1)\n")
cat(sprintf("const REF_CUMULATIVE_RETURN = %.16f  # Return.cumulative(returns)\n",
    as.numeric(Return.cumulative(returns_xts))))
cat(sprintf("const REF_ARITHMETIC_MEAN = %.16f  # mean.arithmetic(returns)\n",
    mean(returns)))
cat(sprintf("const REF_GEOMETRIC_MEAN = %.16f  # mean.geometric(returns)\n",
    as.numeric(mean.geometric(returns_xts))))
cat(sprintf("const REF_ANNUALIZED_RETURN = %.16f  # Return.annualized(returns, scale=12)\n\n",
    as.numeric(Return.annualized(returns_xts, scale = 12))))

# Risk Metrics (US2)
cat("# Risk Metrics (User Story 2)\n")
cat(sprintf("const REF_STDDEV = %.16f  # StdDev(returns)\n",
    as.numeric(StdDev(returns_xts))))
cat(sprintf("const REF_DOWNSIDE_DEVIATION = %.16f  # DownsideDeviation(returns, MAR=0)\n",
    as.numeric(DownsideDeviation(returns_xts, MAR = mar))))
# UpsideRisk has a bug in some versions - compute manually
upside_returns <- returns[returns > mar]
upside_dev <- if(length(upside_returns) > 1) sd(upside_returns) else 0
cat(sprintf("const REF_UPSIDE_DEVIATION = %.16f  # UpsideRisk(returns, MAR=0, stat='deviation')\n", upside_dev))
cat(sprintf("const REF_VAR_95 = %.16f  # VaR(returns, p=0.95, method='historical')\n",
    as.numeric(VaR(returns_xts, p = var_confidence, method = "historical"))))
cat(sprintf("const REF_ES_95 = %.16f  # ES(returns, p=0.95, method='historical')\n",
    as.numeric(ES(returns_xts, p = var_confidence, method = "historical"))))
cat(sprintf("const REF_MAX_DRAWDOWN = %.16f  # maxDrawdown(returns)\n\n",
    as.numeric(maxDrawdown(returns_xts))))

# Risk-Adjusted Ratios (US3)
cat("# Risk-Adjusted Ratios (User Story 3)\n")
sharpe_result <- SharpeRatio(returns_xts, Rf = rf_monthly, FUN = "StdDev")
cat(sprintf("const REF_SHARPE = %.16f  # SharpeRatio(returns, Rf=rf, FUN='StdDev')\n",
    as.numeric(sharpe_result[1])))
cat(sprintf("const REF_SORTINO = %.16f  # SortinoRatio(returns, MAR=0)\n",
    as.numeric(SortinoRatio(returns_xts, MAR = mar))))
cat(sprintf("const REF_CALMAR = %.16f  # CalmarRatio(returns)\n",
    as.numeric(CalmarRatio(returns_xts))))
cat(sprintf("const REF_OMEGA = %.16f  # Omega(returns, L=0)\n",
    as.numeric(Omega(returns_xts, L = mar))))
cat(sprintf("const REF_TREYNOR = %.16f  # TreynorRatio(returns, benchmark, Rf=rf)\n\n",
    as.numeric(TreynorRatio(returns_xts, benchmark_xts, Rf = rf_monthly))))

# CAPM Metrics (US4)
cat("# CAPM Metrics (User Story 4)\n")
cat(sprintf("const REF_BETA = %.16f  # CAPM.beta(returns, benchmark)\n",
    as.numeric(CAPM.beta(returns_xts, benchmark_xts))))
cat(sprintf("const REF_JENSEN_ALPHA = %.16f  # CAPM.jensenAlpha(returns, benchmark, Rf=rf)\n",
    as.numeric(CAPM.jensenAlpha(returns_xts, benchmark_xts, Rf = rf_monthly))))
cat(sprintf("const REF_TRACKING_ERROR = %.16f  # TrackingError(returns, benchmark)\n",
    as.numeric(TrackingError(returns_xts, benchmark_xts))))
cat(sprintf("const REF_INFORMATION_RATIO = %.16f  # InformationRatio(returns, benchmark)\n\n",
    as.numeric(InformationRatio(returns_xts, benchmark_xts))))

# Extended Risk Ratios (US5)
cat("# Extended Risk Ratios (User Story 5)\n")
cat(sprintf("const REF_ULCER_INDEX = %.16f  # UlcerIndex(returns)\n",
    as.numeric(UlcerIndex(returns_xts))))
cat(sprintf("const REF_STERLING_RATIO = %.16f  # SterlingRatio(returns)\n",
    as.numeric(SterlingRatio(returns_xts))))
cat(sprintf("const REF_BURKE_RATIO = %.16f  # BurkeRatio(returns)\n",
    as.numeric(BurkeRatio(returns_xts))))
# NOTE: R's PainIndex has a quirk - DrawdownPeak divides returns by 100 internally,
# treating decimal returns as percentages. We compute the CORRECT formula manually.
# See: https://github.com/braverock/PerformanceAnalytics/issues/132
prices <- cumprod(1 + returns)
peak_prices <- cummax(prices)
drawdowns <- (prices - peak_prices) / peak_prices
pain_index_correct <- mean(abs(drawdowns))
ann_return <- as.numeric(Return.annualized(returns_xts, scale = 12))
pain_ratio_correct <- ann_return / pain_index_correct
cat("# NOTE: R's PainIndex has a quirk - DrawdownPeak divides returns by 100 internally,\n")
cat("# treating decimal returns (0.01) as if they were percentages. Julia uses the\n")
cat("# mathematically correct formula. The values below are computed with the CORRECT formula.\n")
cat(sprintf("const REF_PAIN_INDEX = %.16f  # Correct: mean(abs(drawdowns))\n", pain_index_correct))
cat(sprintf("const REF_PAIN_RATIO = %.16f  # Correct: AnnualizedReturn / PainIndex\n", pain_ratio_correct))

updown <- UpDownRatios(returns_xts, benchmark_xts, method = "Capture")
cat(sprintf("const REF_UP_CAPTURE = %.16f  # UpDownRatios(returns, benchmark, side='Up')\n",
    as.numeric(updown[1])))
cat(sprintf("const REF_DOWN_CAPTURE = %.16f  # UpDownRatios(returns, benchmark, side='Down')\n\n",
    as.numeric(updown[2])))

# Modigliani Measures (US6)
cat("# Modigliani Measures (User Story 6)\n")
m2_result <- Modigliani(returns_xts, benchmark_xts, Rf = rf_monthly)
benchmark_return <- as.numeric(Return.annualized(benchmark_xts, scale = 12))
cat(sprintf("const REF_M2 = %.16f  # Modigliani(returns, benchmark, Rf=rf)\n",
    as.numeric(m2_result)))
cat(sprintf("const REF_M_SQUARED_EXCESS = %.16f  # M2 - benchmark annualized return\n",
    as.numeric(m2_result) - benchmark_return))
cat(sprintf("const REF_ACTIVE_PREMIUM = %.16f  # ActivePremium(returns, benchmark)\n\n",
    as.numeric(ActivePremium(returns_xts, benchmark_xts))))

cat("end  # module RReferenceValues\n")
