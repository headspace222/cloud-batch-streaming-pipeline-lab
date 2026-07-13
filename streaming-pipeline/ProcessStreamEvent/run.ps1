# ProcessStreamEvent - Queue-triggered Azure Function
#
# Fires automatically within seconds of a new message landing on the
# transaction-events queue - this near-instant reaction is what distinguishes
# this streaming/event-driven path from the scheduled batch pipeline.

param($QueueItem, $TriggerMetadata)

Write-Host "Processing event: $QueueItem"

try {
    $event = $QueueItem | ConvertFrom-Json

    $highValueThreshold = 400
    $isHighValue = [double]$event.Amount -ge $highValueThreshold

    $processedAt = (Get-Date).ToString("o")
    $latencySeconds = ((Get-Date) - [datetime]$event.Timestamp).TotalSeconds

    Write-Host "  EventID: $($event.EventID)"
    Write-Host "  AccountID: $($event.AccountID)"
    Write-Host "  Amount: $($event.Amount) - $(if ($isHighValue) { 'FLAGGED: high-value transaction' } else { 'within normal range' })"
    Write-Host "  TransactionType: $($event.TransactionType)"
    Write-Host "  Processing latency: $([math]::Round($latencySeconds, 2)) seconds from event timestamp to processing"
    Write-Host "  Processed at: $processedAt"

} catch {
    Write-Error "Failed to process queue item: $_"
    throw
}