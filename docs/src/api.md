# API Documentation

## Portfolio analytics

```@meta
CurrentModule = OnlinePortfolioAnalytics
```

### Modules

```@docs
OnlinePortfolioAnalytics.OnlinePortfolioAnalytics
```

### Functions

`OnlineStats.fit!`
`Base.empty!`

### Asset return

```@docs
SimpleAssetReturn
LogAssetReturn
```

### Mean return

```@docs
ArithmeticMeanReturn
GeometricMeanReturn
```

### Cumulative return

```@docs
CumulativeReturn
```

### Standard deviation

```@docs
StdDev
```

### Drawdowns

```@docs
DrawDowns
ArithmeticDrawDowns
```

### Maximum Drawdown

```@docs
AbstractMaxDrawDown
MaxDrawDown
MaxArithmeticDrawDown
```

### Statistical moments

```@docs
AssetReturnMoments
```

### Sharpe ratio

```@docs
Sharpe
```

### Sortino ratio

```@docs
Sortino
```

### Annualized return

```@docs
AnnualizedReturn
```

### Calmar ratio

```@docs
Calmar
```

### Beta

```@docs
Beta
```

### Expected return (CAPM)

```@docs
ExpectedReturn
```

### Value at Risk (VaR)

```@docs
VaR
```

### Expected Shortfall (CVaR)

```@docs
ExpectedShortfall
```

### Treynor ratio

```@docs
Treynor
```

### Information ratio

```@docs
InformationRatio
```

### Tracking error

```@docs
TrackingError
```

### Downside deviation

```@docs
DownsideDeviation
```

### Upside deviation

```@docs
UpsideDeviation
```

### Omega ratio

```@docs
Omega
```

### Jensen's Alpha

```@docs
JensenAlpha
```

### Market Capture Ratios

```@docs
UpCapture
DownCapture
UpDownCaptureRatio
```

### Extended Risk-Adjusted Ratios

```@docs
UlcerIndex
PainIndex
SterlingRatio
BurkeRatio
PainRatio
```

### Volatility & Stability Metrics

```@docs
AnnualVolatility
Stability
TailRatio
```

### Modigliani Measures

```@docs
M2
MSquaredExcess
ActivePremium
```

### Upside Potential Ratio

```@docs
UpsidePotentialRatio
```

### Rolling Window Framework

```@docs
Rolling
```

## Input types

### Asset/Benchmark return pair

```@docs
AssetBenchmarkReturn
```

## Other

```@docs
Prod
LogProd
```
