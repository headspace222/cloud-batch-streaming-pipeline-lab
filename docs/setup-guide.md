# Setup Guide

Reproduces both the batch and streaming pipelines on any free Azure subscription.

**Estimated time:** 60-75 minutes.

## Step 1 - Create Supporting Resources

```powershell
New-AzResourceGroup -Name "rg-batch-streaming-lab" -Location "uksouth" -Tag @{CostCenter="LAB001"; Owner="jane"; Environment="NonProduction"}

New-AzStorageAccount -ResourceGroupName "rg-batch-streaming-lab" -Name "<globally-unique-name>" -Location "uksouth" -SkuName "Standard_LRS" -Kind "StorageV2" -Tag @{CostCenter="LAB001"; Owner="jane"; Environment="NonProduction"}
```

```powershell
$ctx = (Get-AzStorageAccount -ResourceGroupName "rg-batch-streaming-lab" -Name "<your-storage-account-name>").Context

New-AzStorageContainer -Name "landing-zone" -Context $ctx -Permission Off
New-AzStorageContainer -Name "processed-zone" -Context $ctx -Permission Off
New-AzStorageQueue -Name "transaction-events" -Context $ctx
```

## Step 2 - Generate and Upload Batch Data

```powershell
cd C:\cloud-batch-streaming-pipeline-lab
.\batch-pipeline\generate-batch-data.ps1

Get-ChildItem "batch-pipeline\batch-dataset" | ForEach-Object {
    Set-AzStorageBlobContent -File $_.FullName -Container "landing-zone" -Blob $_.Name -Context $ctx -Force
}
```

**Evidence to capture:**
- 01-landing-zone-populated.png

## Step 3 - Create and Configure Azure Data Factory

1. Portal, Create a resource, search "Data Factory", Create
2. Resource group: rg-batch-streaming-lab, Version: V2, add tags
3. Review + create, Create, Go to resource, Launch Studio
4. Manage, Linked services, + New, Azure Blob Storage
5. Author, Datasets: LandingZoneDataset (landing-zone), ProcessedZoneDataset (processed-zone)
6. Author, Pipelines, + New pipeline, name it BatchCopyLandingToProcessed
7. Drag Copy data activity, set Source/Sink, Debug, then Publish all

**Evidence to capture:**
- 02-adf-pipeline-canvas.png
- 03-adf-pipeline-run-succeeded.png

## Step 4 - Add a Schedule Trigger

1. Add trigger, New/Edit, New, Type: Schedule, Daily
2. Save, Publish all

**Evidence to capture:**
- 04-adf-trigger-schedule.png

## Step 5 - Verify Batch Output

**Evidence to capture:**
- 05-processed-zone-output.png

## Step 6 - Attempt the Function App (Expect This to Require a Pivot)

```powershell
New-AzFunctionApp -ResourceGroupName "rg-batch-streaming-lab" -Name "<globally-unique-name>" -StorageAccountName "<your-storage-account-name>" -Runtime PowerShell -RuntimeVersion 7.4 -FunctionsVersion 4 -Location "uksouth" -OSType Windows
```

If this fails, the underlying cause is a subscription-level restriction:

1. Classic Consumption plan requires App-Service-Plan-based compute, drawing
   on regional vCPU quota. Free Trial subscriptions default to a
   non-adjustable quota of zero - confirmed across UK South, West US 2, and
   North Europe.
2. Flex Consumption is explicitly blocked outright on Free Trial subscriptions.
3. Free Trial subscriptions are explicitly ineligible for quota increase
   requests.

## Step 7 - Run the Local Event Stream Consumer

**Window 1:**
```powershell
cd C:\cloud-batch-streaming-pipeline-lab
.\streaming-pipeline\Process-EventStream-Local.ps1 -StorageAccountName "<your-storage-account-name>" -QueueName "transaction-events" -ResourceGroupName "rg-batch-streaming-lab" -PollSeconds 60
```

**Window 2:**
```powershell
cd C:\cloud-batch-streaming-pipeline-lab
.\streaming-pipeline\simulate-event-stream.ps1 -StorageAccountName "<your-storage-account-name>" -QueueName "transaction-events" -ResourceGroupName "rg-batch-streaming-lab" -EventCount 10
```

**Evidence to capture:**
- 06-event-processing-latency.png

## Step 8 - Push

```powershell
cd C:\cloud-batch-streaming-pipeline-lab
git add -A
git commit -m "Complete build with all evidence"
git push
```