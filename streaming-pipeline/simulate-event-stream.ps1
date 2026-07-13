<#
.SYNOPSIS
    Simulates a live event stream by pushing transaction events onto a Storage
    Queue, one at a time with a short delay between each.

.DESCRIPTION
    Models the arrival pattern of real-time events hitting a queue as they
    happen. Uses the QueueClient object's SendMessage method (Azure.Storage.Queues
    SDK v12), confirmed as the correct property/type for current Az.Storage
    module versions.

.PARAMETER StorageAccountName
    Name of the storage account hosting the queue.

.PARAMETER QueueName
    Name of the target queue. Created if it doesn't exist.

.PARAMETER ResourceGroupName
    Resource group containing the storage account.

.PARAMETER EventCount
    Number of simulated events to send. Default: 10.
#>

param(
    [Parameter(Mandatory=$true)]
    [string]$StorageAccountName,

    [Parameter(Mandatory=$true)]
    [string]$QueueName,

    [Parameter(Mandatory=$true)]
    [string]$ResourceGroupName,

    [int]$EventCount = 10
)

$storageAccount = Get-AzStorageAccount -ResourceGroupName $ResourceGroupName -Name $StorageAccountName
$ctx = $storageAccount.Context

$queue = Get-AzStorageQueue -Name $QueueName -Context $ctx -ErrorAction SilentlyContinue
if (-not $queue) {
    Write-Host "Creating queue '$QueueName' ..." -ForegroundColor Cyan
    $queue = New-AzStorageQueue -Name $QueueName -Context $ctx
} else {
    Write-Host "Queue '$QueueName' already exists." -ForegroundColor Green
}

$accountIds = @("A2001", "A2002", "A2003", "A2004")
$transactionTypes = @("Deposit", "Withdrawal", "Transfer", "CardPayment")

Write-Host "`nSimulating $EventCount live event(s) ..." -ForegroundColor Cyan

for ($i = 1; $i -le $EventCount; $i++) {
    $event = [PSCustomObject]@{
        EventID         = "E$(Get-Random -Minimum 10000 -Maximum 99999)"
        AccountID       = $accountIds | Get-Random
        Amount          = [math]::Round((Get-Random -Minimum 5 -Maximum 500) + (Get-Random -Minimum 0 -Maximum 99) / 100, 2)
        TransactionType = $transactionTypes | Get-Random
        Timestamp       = (Get-Date).ToString("o")
    }

    $messageBody = $event | ConvertTo-Json -Compress

    $queueClient = $queue.QueueClient
    $queueClient.SendMessage($messageBody) | Out-Null

    Write-Host "  Sent: $messageBody"

    Start-Sleep -Milliseconds 800
}

Write-Host "`n$EventCount event(s) sent to queue '$QueueName'." -ForegroundColor Green