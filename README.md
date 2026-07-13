# Batch & Streaming Data Pipeline Lab

**A dual-pattern data processing pipeline - scheduled batch ETL via Azure Data
Factory, and event-driven near-real-time processing via Storage Queues and Azure
Functions - built entirely on a free Azure subscription.**

Most real-world data platforms run both patterns side by side: a nightly (or
hourly) batch job moving and transforming bulk data, and a separate event-driven
path reacting to individual events the moment they arrive. This lab implements
both, deliberately avoiding the tools that would normally anchor a "streaming"
project (Event Hubs, Stream Analytics, Databricks) - none of which have a genuine
free tier - in favour of an architecture that's both fully reproducible for free
and a legitimate real-world pattern in its own right, not just a workaround.

## Why Not Event Hubs / Stream Analytics / Databricks

This is worth stating directly rather than leaving implicit: these are the
"obvious" tools for a streaming project, and none of them work for this lab's
constraint.

- **Event Hubs**: no always-free tier - Basic SKU has a genuine minimum monthly
  charge from the moment a namespace exists, regardless of usage
- **Stream Analytics**: billed per streaming unit-hour with no free allowance
- **Databricks**: offers a 14-day trial, not an always-free tier - unsuitable for
  a portfolio piece meant to be reproducible indefinitely

Storage Queues + Azure Functions (Consumption plan) genuinely are always-free at
this lab's scale, and this combination is a real architecture pattern used by
teams below the volume threshold where Event Hubs' cost and operational overhead
becomes worth it - not a toy substitute.

## What's Included

| Component | Purpose |
|---|---|
| [`batch-pipeline/generate-batch-data.ps1`](batch-pipeline/generate-batch-data.ps1) | Generates sample batch data files for the landing zone |
| [`batch-pipeline/adf-pipeline-definition.json`](batch-pipeline/adf-pipeline-definition.json) | Azure Data Factory pipeline definition - scheduled Copy Activity, landing zone to processed zone |
| [`streaming-pipeline/simulate-event-stream.ps1`](streaming-pipeline/simulate-event-stream.ps1) | Simulates a live event stream by pushing messages to a Storage Queue |
| [`streaming-pipeline/ProcessStreamEvent/`](streaming-pipeline/ProcessStreamEvent/) | Azure Function (Queue trigger) - processes each event as it arrives |
| [`docs/architecture.md`](docs/architecture.md) | Design rationale, cost model, and the batch-vs-streaming trade-off analysis |
| [`docs/architecture-diagram.md`](docs/architecture-diagram.md) | Visual diagram of both pipelines and the Function-to-local-consumer substitution |
| [`docs/setup-guide.md`](docs/setup-guide.md) | Full reproduction steps with screenshot evidence points |
| [`docs/screenshots/`](docs/screenshots/) | Evidence of both pipelines actually deployed and running |

## Batch vs. Streaming: The Core Distinction Demonstrated

| | Batch (Data Factory) | Streaming (Queue + Function) |
|---|---|---|
| **Trigger** | Schedule (e.g. daily) | Event arrival (each message) |
| **Latency** | Minutes to hours acceptable | Seconds |
| **Volume pattern** | Large batches, periodic | Continuous, individually small |
| **Typical real use** | Nightly reconciliation, end-of-day reporting, bulk data movement | Transaction alerts, live dashboards, fraud-pattern triggers |
| **Failure handling** | Re-run the whole pipeline | Per-message retry via queue visibility timeout |

## Cost

- **Azure Data Factory**: Azure's always-free tier includes a monthly grant of
  low-frequency pipeline activity runs, which this lab's schedule comfortably sits
  within - see docs/architecture.md for the exact allowance and what happens
  beyond it
- **Storage Queues**: negligible cost at any volume this lab generates - a few
  pence per 100,000 operations, and this lab's simulated stream is a handful of
  messages
- **Azure Functions (Consumption plan)**: always-free grant of 1,000,000
  executions and 400,000 GB-seconds of compute per month - this lab's event volume
  is nowhere close to that threshold

## Setup Guide

Full steps: [docs/setup-guide.md](docs/setup-guide.md).

## Skills Demonstrated

- **Batch ETL orchestration**: Azure Data Factory pipeline design, Copy Activity
  configuration, scheduled triggers
- **Event-driven architecture**: Storage Queue-based messaging, Azure Functions
  Queue triggers, near-real-time processing without a dedicated streaming platform
- **Architecture trade-off judgement**: choosing the right tool for data volume
  and latency requirements, rather than defaulting to the most feature-rich
  (and most expensive) option available
- **Cost-aware platform selection**: recognising which Azure services have
  genuine always-free tiers versus time-boxed trials, and designing around that
  distinction deliberately
- **PowerShell automation**: scripted data generation and event simulation for
  reproducible testing of both pipelines

## Author

Jane - Cloud & Infrastructure Engineer, AZ-104 candidate.
Companion project to the Azure RBAC & Identity Baseline Governance Lab, Cloud Cost
Governance & Tag Compliance Automation, and On-Premise to Cloud Data Migration &
Storage Design Lab.