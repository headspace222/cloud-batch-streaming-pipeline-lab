# Architecture & Design Rationale

## The Core Decision: Why Not Event Hubs, Stream Analytics, or Databricks

These are the tools most people reach for first when asked to build a "streaming"
project, and all three fail this lab's free-tier constraint for the same
underlying reason: they're billed on a resource-provisioned or consumption basis
with no always-free allowance.

- **Event Hubs**: the Basic tier has a real minimum monthly charge from the
  moment a namespace exists, independent of throughput used
- **Azure Stream Analytics**: billed per streaming-unit-hour continuously while a
  job is running, with no free grant
- **Azure Databricks**: offers a 14-day trial workspace, not an ongoing free tier
  - unsuitable for something meant to remain reproducible in a portfolio
  indefinitely, not just for a two-week evaluation window

Rather than either pay for a "proper" streaming stack or fake a streaming
architecture with something that isn't actually event-driven, this lab uses
**Storage Queues + Azure Functions (Consumption plan)** - a combination with a
genuine always-free tier (1,000,000 executions and 400,000 GB-seconds of compute
per month) that is also a legitimate real-world pattern, not a substitute
pretending to be something it isn't. Below a certain event volume, this is
frequently the actual production architecture teams use, precisely because
Event Hubs' fixed cost and operational overhead isn't justified until volume
grows past what a queue-triggered Function can comfortably handle.

## Batch Design: Azure Data Factory

### Why ADF and Not a Scripted Copy Loop

A PowerShell loop copying files on a schedule (e.g. via a Windows Task
Scheduler job or an Azure Automation runbook, as used in the cost governance lab)
would technically achieve the same file movement. Data Factory is used instead
because it's the tool actually used for this job at any real organisational
scale: pipeline monitoring, retry policies, dependency chaining between
activities, and a visual lineage of what ran when are all things ADF provides
natively that a bare script does not. Demonstrating ADF specifically is also more
directly relevant to how data engineering and ETL work is actually described in
job postings than a generic scripted alternative would be.

### Free Tier Detail

Azure's always-free service list includes a monthly allowance of low-frequency
pipeline activity executions in Data Factory. This lab's single daily Copy
Activity, run manually a handful of times during testing rather than left
running continuously, sits comfortably within that allowance. Beyond the free
allowance, additional pipeline activity runs are billed per activity execution
at a low per-run rate - worth knowing and stating honestly, rather than claiming
Data Factory is unconditionally free at any scale, which it isn't.

### Copy Activity, Not Data Flows

ADF Mapping Data Flows (for actual data transformation, not just movement)
require a Data Flow debug cluster to author and a Spark-based compute cluster to
execute - genuinely billed compute with no free tier. This lab's pipeline uses a
plain Copy Activity (data movement without transformation), which runs on ADF's
serverless Azure Integration Runtime at no additional compute cost beyond the
activity execution itself. This is a real scope boundary, not an oversight: a
production ETL pipeline doing actual transformation logic would need Data Flows
or an external compute engine (Databricks, Synapse Spark), and would need to
budget for that compute cost explicitly.

## Streaming Design: Storage Queue + Azure Function

### Why a Queue, Specifically

A Storage Queue provides at-least-once delivery with a visibility timeout -
if the Function fails to process a message, it becomes visible again for
reprocessing after the timeout expires, rather than being silently lost. This is
a meaningful reliability property, not just a convenient message-passing
mechanism, and it's worth being able to explain in exactly those terms.

### Processing Latency as the Defining Metric

The Function code explicitly calculates and logs the time between an event's
original timestamp and when it was actually processed. This is deliberate: the
single metric that distinguishes "streaming" from "batch" is latency, not the
tools involved. A batch job that happens to run every five minutes is still
batch; a queue-triggered Function that processes a message within two seconds of
arrival is genuinely event-driven, regardless of which specific Azure service
implements it. Making that latency visible in the Function's own output is the
evidence for the architectural claim this lab is making.

### A Real Constraint, Documented Honestly

Az.Storage's PowerShell module does not expose a dedicated high-level cmdlet for
sending a queue message - the simulator script has to reach into the underlying
CloudQueue object directly. This is the kind of SDK-version-dependent surface
that has broken before in this portfolio (the RBAC role definition schema in the
identity governance lab hit the same category of issue). The simulator script
documents the fallback diagnostic step directly in its own header rather than
assuming it will always work cleanly.

## What I'd Add at Enterprise Scale

- **Event Hubs**, once event volume genuinely justifies its cost and
  operational model - Functions can consume from Event Hubs using the same
  trigger pattern demonstrated here, so this lab's Function code is a reasonable
  starting point for that migration, not throwaway work
- **Azure Data Factory Data Flows or Synapse Spark** for genuine transformation
  logic beyond simple copy/move operations
- **Dead-letter queue handling** for events that repeatedly fail processing,
  rather than relying solely on the default visibility-timeout retry behaviour
- **Application Insights integration** for the Function App, giving structured,
  queryable telemetry instead of relying on Function execution logs alone
- **Managed identity authentication** between Data Factory and the storage
  account, rather than the connection-string-based auth this lab's simpler setup
  uses - consistent with the least-privilege patterns established in the
  identity governance lab