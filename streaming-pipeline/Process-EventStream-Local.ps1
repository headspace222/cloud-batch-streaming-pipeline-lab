<#
.SYNOPSIS
    Polls the transaction-events queue and processes each message locally,
    standing in for the Azure Function that this subscription's Free Trial
    compute quota restrictions prevented from being deployed.

.DESCRIPTION
    Azure Free Trial subscriptions have a fixed, non-adjustable vCPU quota of
    zero for App-Service-Plan-based compute, and are explicitly ineligible for
    quota increases. Flex Consumption is also explicitly unavailable on Free
    Trial subscriptions. See docs/architecture.md for the full diagnostic trail.

.PARAMETER StorageAccountName
    Name of the storage account hosting the queue.

.PARAMETER QueueName
    Name of the queue to poll.

.PARAMETER ResourceGroupName
    Resource group containing the storage account.

.PARAMETER PollSeconds
    How long to keep polling before exiting. Default: 60.
#>

param(
    [Parameter(Mandatory=$true)]
    [string]$StorageAccountName,

    [Parameter(Mandatory=$true)]
    [string]$QueueName,

    [Parameter(Mandatory=$true)]
    [string]$ResourceGroupName,

    [int]$PollSeconds = 60
)

$storageAccount = Get-AzStorageAccount -ResourceGroupName $ResourceGroupName -Name $StorageAccountName
$ctx = $storageAccount.Context
$queueClient = (Get-AzStorageQueue -Name $QueueName -Context $ctx).QueueClient

Write-Host "Polling queue '$QueueName' for $PollSeconds seconds ..." -ForegroundColor Cyan

$endTime = (Get-Date).AddSeconds($PollSeconds)
$processedCount = 0

while ((Get-Date) -lt $endTime) {
    $messages = $queueClient.ReceiveMessages(32).Value

    if ($messages -and $messages.Count -gt 0) {
        foreach ($message in $messages) {
            $receivedAt = Get-Date
            $event = $message.MessageText | ConvertFrom-Json

            $highValueThreshold = 400
            $isHighValue = [double]$event.Amount -ge $highValueThreshold
            $latencySeconds = ($receivedAt - [datetime]$event.Timestamp).TotalSeconds

            $flag = if ($isHighValue) { "[FLAGGED high-value]" } else { "" }
            Write-Host "Processed: $($event.EventID) | Account: $($event.AccountID) | Amount: $($event.Amount) $flag | Latency: $([math]::Round($latencySeconds,2))s"

            $queueClient.DeleteMessage($message.MessageId, $message.PopReceipt) | Out-Null
            $processedCount++
        }
    } else {
        Start-Sleep -Milliseconds 500
    }
}

Write-Host "`nDone. $processedCount event(s) processed in this window." -ForegroundColor Green