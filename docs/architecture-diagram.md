# Architecture Diagram

```mermaid
flowchart TB
    subgraph Batch["Batch Pipeline - Scheduled ETL"]
        direction TB
        B1[generate-batch-data.ps1] --> B2[(landing-zone Blob Container)]
        B2 --> B3{Azure Data Factory BatchCopyLandingToProcessed}
        B4[Daily Schedule Trigger] -.triggers.-> B3
        B3 --> B5[(processed-zone Blob Container)]
    end

    subgraph Streaming["Streaming Pipeline - Event-Driven"]
        direction TB
        S1[simulate-event-stream.ps1] --> S2[(transaction-events Storage Queue)]
        S2 --> S3[Process-EventStream-Local.ps1 Polling Consumer]
        S3 --> S4[Parsed and Flagged Event Output]
        S3 -.deletes processed message.-> S2
    end

    subgraph Substitution["Why Local, Not Azure Function"]
        direction TB
        X1[ProcessStreamEvent - Originally Designed Function] -.blocked by.-> X2[Free Trial: Consumption plan vCPU quota = 0, non-adjustable]
        X1 -.blocked by.-> X3[Free Trial: Flex Consumption explicitly unsupported]
        X2 --> X4[Pivot: run consumer locally instead of on Azure compute]
        X3 --> X4
        X4 -.same processing logic.-> S3
    end

    style Batch fill:#e8f4fd,stroke:#1a73e8
    style Streaming fill:#e6f4ea,stroke:#188038
    style Substitution fill:#fef7e0,stroke:#f9ab00
```

## Reading This Diagram

**Batch (top-left, blue):** a schedule trigger fires the Data Factory pipeline
daily, copying whatever files have landed in landing-zone into
processed-zone. Latency of minutes-to-hours is acceptable here - the whole
point is periodic, bulk movement, not immediacy.

**Streaming (top-right, green):** each event is sent individually to a Storage
Queue the moment it "happens" (simulated), and a polling consumer picks it up
and processes it within seconds - the defining characteristic that separates
this from the batch path is latency, not the specific tooling.

**Substitution (bottom, amber):** documents why the streaming consumer runs
locally rather than as a deployed Azure Function - a genuine, diagnosed
subscription restriction (Free Trial compute quota), not a design preference.
The original Function code is retained in the repo and would replace the
local consumer with no logic changes on a subscription without this
restriction.