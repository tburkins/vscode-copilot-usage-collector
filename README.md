# GitHub Copilot Usage Analytics

Visualize GitHub Copilot AI token usage and estimated cost in Power BI by collecting OpenTelemetry traces from VS Code and loading them into a pre-built data model.

---

## How it works

```
VS Code (GitHub Copilot)
        │  OTLP/gRPC  (port 4317)
        ▼
OpenTelemetry Collector  ──►  data/traces.json
        │
        └── Power BI reads the JSON folder
              OtelTraces  ──►  DateTable  (date relationship)
              OtelTraces  ──►  ModelPricing  (model relationship)
                                    │
                                    └── DAX measures calculate cost
```

---

## Prerequisites

| Tool | Notes |
|---|---|
| [Docker Desktop](https://www.docker.com/products/docker-desktop/) | Runs the OTel Collector |
| [Power BI Desktop](https://powerbi.microsoft.com/desktop/) | Opens the `.pbix` report |
| VS Code with GitHub Copilot | Source of the telemetry |

---

## Step 1 — Start the OpenTelemetry Collector

The collector receives OTLP traces from VS Code and writes them as newline-delimited JSON to the `data/` folder.

```powershell
# From the repo root
.\Start-OtelCollector.ps1
```

This runs the `otel/opentelemetry-collector-contrib` Docker image with:
- **Port 4317** — OTLP gRPC receiver
- **Port 4318** — OTLP HTTP receiver
- `otel-collector.yaml` mounted as the collector config
- `data/` mounted as the output folder

The collector config (`otel-collector.yaml`) batches spans every 5 seconds and writes them to `/data/traces.json`, rotating at 100 MB or 1 day.

> To stop the collector: `docker stop otel-parquet`

---

## Step 2 — Configure VS Code to send telemetry

Enable OpenTelemetry export in your VS Code `settings.json`:

```json
{
  "github.copilot.advanced.openTelemetry.otlpGrpcEndpoint": "http://localhost:4317"
}
```

Use Copilot as normal. Trace data will accumulate in `data/traces.json`.

---

## Step 3 — Open the Power BI report

1. Open `Copilot Usage.pbix` in Power BI Desktop.
2. Go to **Home → Transform Data → Manage Parameters**.
3. Set the **`DataFolder`** parameter to the absolute path of the `data/` folder on your machine, e.g. `C:\Users\you\otel\data`.
4. Set the **`TimeZoneOffsetHours`** parameter to your UTC offset so that timestamps display in local time (e.g. `-5` for UTC−5 Eastern Standard, `-7` for UTC−7 Mountain Standard, `1` for CET). Fractional offsets are supported (e.g. `5.5` for India UTC+5:30). This is a fixed offset and does **not** auto-adjust for daylight saving time.
5. Click **Home → Refresh** to load your traces.

---

## Power Query tables

### `OtelTraces` — [PowerBI/queries/OtelTraces.pq](PowerBI/queries/OtelTraces.pq)

Reads all `*.json` files from `DataFolder`, parses each newline-delimited JSON record, unpacks the OTLP `resourceSpans → scopeSpans → spans` hierarchy, and flattens span attributes into typed columns.

| Column | Type | Description |
|---|---|---|
| `service.name` | text | VS Code extension name |
| `service.version` | text | Extension version |
| `session.id` | text | VS Code session identifier |
| `traceId` / `spanId` / `parentSpanId` | text | OTLP span identifiers |
| `name` | text | Span name (operation label) |
| `startTime` / `endTime` | datetime | UTC timestamps (converted from nanoseconds) |
| `durationMs` | number | Span duration in milliseconds |
| `operation` | text | `gen_ai.operation.name` |
| `model` | text | Requested model (`gen_ai.request.model`) |
| `responseModel` | text | Actual model used in the response |
| `inputTokens` | integer | Input token count |
| `outputTokens` | integer | Output token count |
| `cacheReadTokens` | integer | Cache-read input tokens (prompt cache hits) |
| `cacheCreationTokens` | integer | Cache-write input tokens (Anthropic only) |
| `agentName` | text | Copilot agent name |
| `toolName` | text | Tool invoked (if any) |
| `ttft` | integer | Time to first token (ms) |
| `chatSessionId` | text | Chat session identifier |
| `StartDate` | date | Date portion of `startTime` — used to relate to `DateTable` |

### `DateTable` — [PowerBI/queries/DateTable.pq](PowerBI/queries/DateTable.pq)

Generates a contiguous calendar table spanning the min/max `StartDate` values in `OtelTraces`. Mark this table as a **Date Table** (right-click in the Fields pane → "Mark as date table" → select `Date`) to enable DAX time intelligence.

**Relationship:** `DateTable[Date]` → `OtelTraces[StartDate]` (one-to-many)

| Column | Example | Notes |
|---|---|---|
| `Date` | 5/10/2026 | Primary key — relate to `OtelTraces[StartDate]` |
| `Year` | 2026 | |
| `Quarter` / `QuarterNumber` | Q2 / 2 | |
| `MonthName` / `MonthNameShort` | May / May | |
| `MonthNumber` | 5 | |
| `YearMonth` | 202605 | Integer sort key for month slicers |
| `YearMonthLabel` | May 2026 | Human-readable month label |
| `WeekNumber` | 19 | ISO-style week of year |
| `DayOfWeekName` / `DayOfWeekShort` | Saturday / Sat | |
| `DayOfWeekNumber` | 6 | Monday = 1, Sunday = 7 |
| `Day` | 10 | Day of month |
| `IsWeekend` | true | |

### `ModelPricing` — [PowerBI/queries/ModelPricing.pq](PowerBI/queries/ModelPricing.pq)

A static lookup table of GitHub Copilot model pricing sourced from the [GitHub Copilot billing documentation](https://docs.github.com/en/copilot/reference/copilot-billing/models-and-pricing). Prices are USD per 1 million tokens.

**Relationship:** `ModelPricing[ModelId]` → `OtelTraces[model]` (one-to-many)

| Column | Description |
|---|---|
| `ModelId` | Matches `gen_ai.request.model` in traces |
| `ModelDisplayName` | Human-readable model name |
| `Provider` | OpenAI, Anthropic, Google, xAI, GitHub |
| `Tier` | Lightweight, Versatile, or Powerful |
| `InputPricePerM` | USD per 1M input tokens |
| `CacheReadPricePerM` | USD per 1M cache-read tokens |
| `CacheWritePricePerM` | USD per 1M cache-write tokens (Anthropic only; null otherwise) |
| `OutputPricePerM` | USD per 1M output tokens |
| `*CreditsPerM` | Derived columns — AI credits per 1M tokens (1 credit = $0.01) |

> To update pricing, edit the `Rows` list in `ModelPricing.pq` and refresh the report.

---

## DAX measures

All measures live in the `OtelTraces` table. Cost is calculated by joining token counts to the `ModelPricing` lookup via `RELATED()`.

### `Input Cost ($)` — [PowerBI/dax/Input Cost.dax](PowerBI/dax/Input%20Cost.dax)
```dax
Input Cost ($) =
SUMX(
    OtelTraces,
    DIVIDE(OtelTraces[inputTokens], 1000000) *
    RELATED(ModelPricing[InputPricePerM])
)
```
Sums `(inputTokens / 1,000,000) × InputPricePerM` across all rows in the current filter context.

### `Cache Read Cost ($)` — [PowerBI/dax/Cache Read Cost.dax](PowerBI/dax/Cache%20Read%20Cost.dax)
```dax
Cache Read Cost ($) =
SUMX(
    OtelTraces,
    DIVIDE(OtelTraces[cacheReadTokens], 1000000) *
    RELATED(ModelPricing[CacheReadPricePerM])
)
```
Cost of prompt cache hits (tokens served from the model's KV cache at a reduced rate).

### `Cache Write Cost ($)` — [PowerBI/dax/Cache Write Cost.dax](PowerBI/dax/Cache%20Write%20Cost.dax)
```dax
Cache Write Cost ($) =
SUMX(
    OtelTraces,
    DIVIDE(OtelTraces[cacheCreationTokens], 1000000) *
    COALESCE(RELATED(ModelPricing[CacheWritePricePerM]), 0)
)
```
Cost of writing tokens into the prompt cache. Uses `COALESCE(..., 0)` so non-Anthropic models (where `CacheWritePricePerM` is null) contribute $0.

### `Output Cost ($)` — [PowerBI/dax/Output Cost.dax](PowerBI/dax/Output%20Cost.dax)
```dax
Output Cost ($) =
SUMX(
    OtelTraces,
    DIVIDE(OtelTraces[outputTokens], 1000000) *
    RELATED(ModelPricing[OutputPricePerM])
)
```
Cost of generated (completion) tokens.

### `Total Cost ($)` — [PowerBI/dax/Total Cost.dax](PowerBI/dax/Total%20Cost.dax)
```dax
Total Cost ($) =
[Input Cost ($)] + [Cache Read Cost ($)] + [Cache Write Cost ($)] + [Output Cost ($)]
```
Sum of all four cost components. Use this measure on report visuals.

---

## Updating the report

### Adding a new model
Edit the `Rows` list in [PowerBI/queries/ModelPricing.pq](PowerBI/queries/ModelPricing.pq) and add a record following the existing pattern, then refresh.

### Changing the data folder
Go to **Home → Transform Data → Manage Parameters** and update the `DataFolder` value. No query edits needed.

### Changing the time zone
Go to **Home → Transform Data → Manage Parameters** and update the `TimeZoneOffsetHours` value. Use your UTC offset as a decimal number (e.g. `-5`, `1`, `5.5`). The offset is applied as a fixed shift to all `startTime` and `endTime` values and does not account for daylight saving time.

### Adding new span attributes
In `OtelTraces.pq`, add a field to the record returned inside `WithSpanFields`, then add the column name to both the `ExpandedSpanRecord` column list and the `FinalTable` column list.

---

## Repository structure

```
otel-collector.yaml        # OTel Collector configuration
Start-OtelCollector.ps1    # Script to start the collector via Docker
data/
  traces.json              # Collector output (git-ignored in production)
PowerBI/
  Copilot Usage.pbix       # Power BI report file
  queries/
    OtelTraces.pq          # Power Query — parses trace JSON
    DateTable.pq           # Power Query — calendar dimension table
    ModelPricing.pq        # Power Query — model pricing lookup
  dax/
    Input Cost.dax         # Measure — cost of input tokens
    Cache Read Cost.dax    # Measure — cost of cache-read tokens
    Cache Write Cost.dax   # Measure — cost of cache-write tokens (Anthropic only)
    Output Cost.dax        # Measure — cost of output (completion) tokens
    Total Cost.dax         # Measure — sum of all four cost measures
```
