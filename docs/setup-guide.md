# Setup Guide

Reproduces both the batch and streaming pipelines on any free Azure subscription.

**Estimated time:** 60-75 minutes - this is the most involved of the four labs in
this portfolio, since Data Factory Studio and Function App deployment both
involve more portal work than pure PowerShell/CLI-driven labs.

## Step 1 - Create Supporting Resources

```powershell
New-AzResourceGroup -Name "rg-batch-streaming-lab" -Location "uksouth" -Tag @{CostCenter="LAB001"; Owner="jane"; Environment="NonProduction"}

New-AzStorageAccount -ResourceGroupName "rg-batch-streaming-lab" -Name "<globally-unique-name>" -Location "uksouth" -SkuName "Standard_LRS" -Kind "StorageV2" -Tag @{CostCenter="LAB001"; Owner="jane"; Environment="NonProduction"}
```

Create the two containers the batch pipeline needs, and the queue the streaming
pipeline needs:

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
- 01-landing-zone-populated.png - Portal, storage account, Containers,
  landing-zone, showing the uploaded batch files

## Step 3 - Create and Configure Azure Data Factory

1. Portal, Create a resource, search "Data Factory", Create
2. Resource group: rg-batch-streaming-lab, Name: something globally unique,
   Version: V2, add the same tags used elsewhere in this lab
3. Review + create, Create
4. Once deployed, Go to resource, Launch Studio

**In Data Factory Studio:**

5. Manage (toolbox icon), Linked services, + New, Azure Blob
   Storage, connect it to your storage account
6. Author, Datasets, + New dataset, create two: one pointing at
   landing-zone (source), one pointing at processed-zone (sink), both using
   the linked service from step 5
7. Author, Pipelines, + New pipeline, name it
   BatchCopyLandingToProcessed
8. Drag a Copy data activity onto the canvas, set its Source to the
   landing-zone dataset, Sink to the processed-zone dataset
9. Debug to test it runs correctly, then Publish all

**Evidence to capture:**
- 02-adf-pipeline-canvas.png - the pipeline canvas showing the Copy activity
  configured
- 03-adf-pipeline-run-succeeded.png - the pipeline run output showing
  Succeeded status

## Step 4 - Add a Schedule Trigger

1. Still in the pipeline view, Add trigger, New/Edit, New
2. Type: Schedule, recurrence: Daily, pick a time
3. Save, then Publish all again

**Evidence to capture:**
- 04-adf-trigger-schedule.png - the trigger configuration

## Step 5 - Verify Batch Output

1. Portal, storage account, Containers, processed-zone
2. Confirm the files copied from landing-zone are present

**Evidence to capture:**
- 05-processed-zone-output.png - the processed-zone container showing the
  copied files

## Step 6 - Create the Function App

```powershell
New-AzFunctionApp -ResourceGroupName "rg-batch-streaming-lab" -Name "<globally-unique-name>" -StorageAccountName "<your-storage-account-name>" -Runtime PowerShell -RuntimeVersion 7.4 -FunctionsVersion 4 -Location "uksouth" -OSType Windows
```

**Evidence to capture:**
- 06-function-app-created.png - the created Function App's Overview page

## Step 7 - Deploy the Queue-Triggered Function

The simplest path for a lab this size is authoring directly in the portal:

1. Function App, Functions, + Create
2. Development environment: Develop in portal
3. Template: Azure Queue Storage trigger
4. Name: ProcessStreamEvent, Queue name: transaction-events, Storage account
   connection: select your storage account
5. Create
6. In the function's Code + Test view, replace the default code with the
   contents of streaming-pipeline/ProcessStreamEvent/run.ps1
7. Save

**Evidence to capture:**
- 07-function-code-deployed.png - the Code + Test view showing the deployed
  function code

## Step 8 - Simulate the Event Stream

```powershell
.\streaming-pipeline\simulate-event-stream.ps1 -StorageAccountName "<your-storage-account-name>" -QueueName "transaction-events" -ResourceGroupName "rg-batch-streaming-lab" -EventCount 10
```

While this runs, watch the Function's live log stream in the portal (Function,
Monitor, or Code + Test, Logs panel at the bottom) to see each event
processed within seconds of being sent.

**Evidence to capture:**
- 08-event-simulation-output.png - terminal output showing events sent
- 09-function-execution-log.png - the Function's live log output showing each
  event processed, including the calculated processing latency

## Step 9 - Push

```powershell
cd C:\cloud-batch-streaming-pipeline-lab
git init
git add -A
git commit -m "Initial build: batch ADF pipeline and streaming queue/Function pipeline"
git branch -M main
git remote add origin https://github.com/headspace222/cloud-batch-streaming-pipeline-lab.git
git push -u origin main
```