param(
    [string]$InputPath = "data\quarter_trigger_input.csv",
    [string]$OutFile = ""
)

function To-Decimal {
    param($Value)
    if ($null -eq $Value -or "$Value".Trim() -eq "") { return $null }
    return [decimal]::Parse("$Value", [Globalization.CultureInfo]::InvariantCulture)
}

function Add-Score {
    param([int]$Score, [string[]]$Reasons, [int]$Delta, [string]$Reason)
    return @{
        Score = $Score + $Delta
        Reasons = @($Reasons + $Reason)
    }
}

function Format-Number {
    param($Value, [int]$Digits = 2)
    if ($null -eq $Value) { return "NA" }
    return ([math]::Round([double]$Value, $Digits)).ToString("N$Digits")
}

if (!(Test-Path $InputPath)) {
    throw "Input CSV not found: $InputPath"
}

$rows = Import-Csv -Path $InputPath -Encoding UTF8
$results = @()

foreach ($row in $rows) {
    $lastYearProfit = To-Decimal $row.last_year_net_profit
    $revenueYoy = To-Decimal $row.current_quarter_revenue_yoy_pct
    $qProfit = To-Decimal $row.current_quarter_net_profit
    $profitYoy = To-Decimal $row.current_quarter_net_profit_yoy_pct
    $deductedProfit = To-Decimal $row.current_quarter_deducted_net_profit
    $cashFlow = To-Decimal $row.current_quarter_operating_cash_flow
    $priorQ2Profit = To-Decimal $row.prior_year_q2_net_profit
    $structuralScore = To-Decimal $row.structural_driver_score
    $researchScore = To-Decimal $row.research_signal_score
    $oneOffRisk = To-Decimal $row.one_off_risk_score

    $annualizedProfit = $null
    $annualizedVsLastYear = $null
    if ($qProfit -ne $null -and $lastYearProfit -ne $null -and $lastYearProfit -ne 0) {
        $annualizedProfit = $qProfit * 4
        $annualizedVsLastYear = ($annualizedProfit / $lastYearProfit) * 100
    }

    $profitRevenueSpread = $null
    if ($profitYoy -ne $null -and $revenueYoy -ne $null) {
        $profitRevenueSpread = $profitYoy - $revenueYoy
    }

    $deductedQuality = $null
    if ($deductedProfit -ne $null -and $qProfit -ne $null -and $qProfit -ne 0) {
        $deductedQuality = ($deductedProfit / $qProfit) * 100
    }

    $cashConversion = $null
    if ($cashFlow -ne $null -and $qProfit -ne $null -and $qProfit -ne 0) {
        $cashConversion = ($cashFlow / $qProfit) * 100
    }

    $sameProfitQ2Yoy = $null
    if ($qProfit -ne $null -and $priorQ2Profit -ne $null -and $priorQ2Profit -ne 0) {
        $sameProfitQ2Yoy = (($qProfit / $priorQ2Profit) - 1) * 100
    }

    $score = 0
    $reasons = @()

    if ($annualizedVsLastYear -ne $null) {
        if ($annualizedVsLastYear -ge 120) {
            $r = Add-Score $score $reasons 3 ("Annualized quarterly profit reaches " + (Format-Number $annualizedVsLastYear 1) + "% of last-year profit")
            $score = $r.Score; $reasons = $r.Reasons
        } elseif ($annualizedVsLastYear -ge 105) {
            $r = Add-Score $score $reasons 2 ("Annualized quarterly profit exceeds last-year profit: " + (Format-Number $annualizedVsLastYear 1) + "%")
            $score = $r.Score; $reasons = $r.Reasons
        } elseif ($annualizedVsLastYear -ge 95) {
            $r = Add-Score $score $reasons 1 ("Annualized quarterly profit is close to last-year profit: " + (Format-Number $annualizedVsLastYear 1) + "%")
            $score = $r.Score; $reasons = $r.Reasons
        }
    }

    if ($profitYoy -ne $null) {
        if ($profitYoy -ge 80) {
            $r = Add-Score $score $reasons 3 ("Net profit YoY is very strong: " + (Format-Number $profitYoy 1) + "%")
            $score = $r.Score; $reasons = $r.Reasons
        } elseif ($profitYoy -ge 50) {
            $r = Add-Score $score $reasons 2 ("Net profit YoY is strong: " + (Format-Number $profitYoy 1) + "%")
            $score = $r.Score; $reasons = $r.Reasons
        } elseif ($profitYoy -ge 30) {
            $r = Add-Score $score $reasons 1 ("Net profit YoY growth: " + (Format-Number $profitYoy 1) + "%")
            $score = $r.Score; $reasons = $r.Reasons
        }
    }

    if ($profitRevenueSpread -ne $null) {
        if ($profitRevenueSpread -ge 25) {
            $r = Add-Score $score $reasons 2 ("Profit growth is far above revenue growth; spread " + (Format-Number $profitRevenueSpread 1) + "ppt")
            $score = $r.Score; $reasons = $r.Reasons
        } elseif ($profitRevenueSpread -ge 8) {
            $r = Add-Score $score $reasons 1 ("Profit growth is above revenue growth; spread " + (Format-Number $profitRevenueSpread 1) + "ppt")
            $score = $r.Score; $reasons = $r.Reasons
        }
    }

    if ($deductedQuality -ne $null) {
        if ($deductedQuality -ge 90) {
            $r = Add-Score $score $reasons 2 ("Adjusted net profit quality is high: " + (Format-Number $deductedQuality 1) + "%")
            $score = $r.Score; $reasons = $r.Reasons
        } elseif ($deductedQuality -ge 75) {
            $r = Add-Score $score $reasons 1 ("Adjusted net profit quality: " + (Format-Number $deductedQuality 1) + "%")
            $score = $r.Score; $reasons = $r.Reasons
        } else {
            $r = Add-Score $score $reasons -1 "Adjusted profit quality is low; check one-off gains"
            $score = $r.Score; $reasons = $r.Reasons
        }
    }

    if ($cashConversion -ne $null) {
        if ($cashConversion -ge 70) {
            $r = Add-Score $score $reasons 1 ("Operating cash flow / net profit: " + (Format-Number $cashConversion 1) + "%")
            $score = $r.Score; $reasons = $r.Reasons
        } elseif ($cashConversion -lt 30) {
            $r = Add-Score $score $reasons -1 ("Operating cash flow / net profit is low: " + (Format-Number $cashConversion 1) + "%; check inventory, receivables, and stocking")
            $score = $r.Score; $reasons = $r.Reasons
        }
    }

    if ($structuralScore -ne $null -and $structuralScore -gt 0) {
        $r = Add-Score $score $reasons ([int]$structuralScore) ("Structural driver score +" + [int]$structuralScore)
        $score = $r.Score; $reasons = $r.Reasons
    }

    if ($researchScore -ne $null -and $researchScore -gt 0) {
        $r = Add-Score $score $reasons ([int]$researchScore) ("Research/IR signal score +" + [int]$researchScore)
        $score = $r.Score; $reasons = $r.Reasons
    }

    if ($oneOffRisk -ne $null -and $oneOffRisk -gt 0) {
        $r = Add-Score $score $reasons (-1 * [int]$oneOffRisk) ("One-off/cycle/cost risk -" + [int]$oneOffRisk)
        $score = $r.Score; $reasons = $r.Reasons
    }

    $action = "No action"
    if ($score -ge 11) {
        $action = "Strong trigger: recalculate full-year EPS now"
    } elseif ($score -ge 8) {
        $action = "Medium trigger: high-priority watch"
    } elseif ($score -ge 5) {
        $action = "Weak trigger: wait for next confirmation"
    }

    $results += [PSCustomObject]@{
        Ticker = $row.ticker
        Name = $row.name
        Period = $row.period
        Score = $score
        Action = $action
        AnnualizedProfit = Format-Number $annualizedProfit 2
        AnnualizedVsLastYearPct = Format-Number $annualizedVsLastYear 1
        ProfitRevenueSpreadPct = Format-Number $profitRevenueSpread 1
        DeductedQualityPct = Format-Number $deductedQuality 1
        CashConversionPct = Format-Number $cashConversion 1
        SameProfitQ2YoyPct = Format-Number $sameProfitQ2Yoy 1
        Reasons = ($reasons -join " | ")
        Notes = $row.notes
        Source = $row.source_url
    }
}

$lines = @()
$lines += "# Quarter Trigger System Output"
$lines += ""
$lines += "Input: $InputPath"
$lines += "Generated at: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
$lines += ""
$lines += "| Company | Period | Score | Action | Annualized profit | Annualized / last year | Profit-revenue spread | Adjusted profit quality | Cash conversion | Q2 YoY if same profit |"
$lines += "|---|---|---:|---|---:|---:|---:|---:|---:|---:|"
foreach ($result in $results) {
    $lines += "| $($result.Name) | $($result.Period) | $($result.Score) | $($result.Action) | $($result.AnnualizedProfit) | $($result.AnnualizedVsLastYearPct)% | $($result.ProfitRevenueSpreadPct)ppt | $($result.DeductedQualityPct)% | $($result.CashConversionPct)% | $($result.SameProfitQ2YoyPct)% |"
}

$lines += ""
$lines += "## Trigger Reasons"
$lines += ""
foreach ($result in $results) {
    $lines += "### $($result.Name) $($result.Period)"
    $lines += ""
    $lines += "- Action: $($result.Action)"
    $lines += "- Reasons: $($result.Reasons)"
    $lines += "- Notes: $($result.Notes)"
    $lines += "- Source: $($result.Source)"
    $lines += ""
}

$output = $lines -join [Environment]::NewLine

if ($OutFile -ne "") {
    $dir = Split-Path -Parent $OutFile
    if ($dir -ne "" -and !(Test-Path $dir)) {
        New-Item -ItemType Directory -Force -Path $dir | Out-Null
    }
    Set-Content -Path $OutFile -Value $output -Encoding UTF8
}

Write-Output $output
