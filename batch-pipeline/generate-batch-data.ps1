<#
.SYNOPSIS
    Generates sample batch data files for the Data Factory landing zone.

.DESCRIPTION
    Creates a set of daily transaction export files, standing in for the kind of
    bulk data drop a real batch pipeline would process on a schedule (e.g. an
    overnight extract from a line-of-business system).

.EXAMPLE
    .\generate-batch-data.ps1
#>

$dataDir = Join-Path $PSScriptRoot "batch-dataset"
New-Item -ItemType Directory -Force -Path $dataDir | Out-Null

Write-Host "Generating sample batch dataset in $dataDir ..." -ForegroundColor Cyan

$transactionsDay1 = @"
TransactionID,AccountID,Amount,Currency,TransactionType,Timestamp
T5001,A2001,150.00,GBP,Deposit,2026-07-01T09:15:00
T5002,A2002,45.50,GBP,Withdrawal,2026-07-01T10:22:00
T5003,A2003,2000.00,GBP,Transfer,2026-07-01T11:05:00
T5004,A2001,75.25,GBP,Deposit,2026-07-01T14:30:00
T5005,A2004,300.00,GBP,Withdrawal,2026-07-01T16:45:00
"@
$transactionsDay1 | Out-File -FilePath (Join-Path $dataDir "transactions-2026-07-01.csv") -Encoding utf8

$transactionsDay2 = @"
TransactionID,AccountID,Amount,Currency,TransactionType,Timestamp
T5006,A2002,120.00,GBP,Deposit,2026-07-02T08:50:00
T5007,A2003,60.00,GBP,Withdrawal,2026-07-02T09:40:00
T5008,A2001,500.00,GBP,Transfer,2026-07-02T13:15:00
T5009,A2004,25.75,GBP,Deposit,2026-07-02T15:20:00
"@
$transactionsDay2 | Out-File -FilePath (Join-Path $dataDir "transactions-2026-07-02.csv") -Encoding utf8

$files = Get-ChildItem -Path $dataDir
Write-Host "`nGenerated $($files.Count) batch file(s):" -ForegroundColor Green
$files | ForEach-Object { Write-Host "  $($_.Name) ($($_.Length) bytes)" }

Write-Host "`nDataset ready at $dataDir - upload to the landing-zone container before running the ADF pipeline." -ForegroundColor Cyan