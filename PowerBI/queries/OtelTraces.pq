// Power Query M-Code to parse VS Code OpenTelemetry JSONL trace files
// Usage: In Power BI Desktop, use "Blank Query" and paste this code into the Advanced Editor

let
    // -------------------------------------------------------------------------
    // CONFIGURATION — set the DataFolder parameter in Manage Parameters
    // -------------------------------------------------------------------------
    TraceFolder = DataFolder,

    // -------------------------------------------------------------------------
    // Load all *.json files in the folder and combine their lines
    // -------------------------------------------------------------------------
    Source = Folder.Files(TraceFolder),
    JsonFiles = Table.SelectRows(Source, each Text.EndsWith([Name], ".json")),
    FileContents = Table.AddColumn(JsonFiles, "Lines", each Lines.FromBinary([Content], null, null, 65001)),
    AllLines = Table.ExpandListColumn(Table.SelectColumns(FileContents, {"Name", "Lines"}), "Lines"),
    NonEmptyLines = Table.SelectRows(AllLines, each [Lines] <> "" and [Lines] <> null),

    // -------------------------------------------------------------------------
    // Parse each JSONL line as JSON
    // -------------------------------------------------------------------------
    ParsedLines = Table.AddColumn(NonEmptyLines, "Json", each Json.Document([Lines]), type record),

    // -------------------------------------------------------------------------
    // Expand resourceSpans (one record per export batch)
    // -------------------------------------------------------------------------
    ResourceSpansList = Table.AddColumn(ParsedLines, "resourceSpans", each [Json][resourceSpans], type list),
    ExpandedResourceSpans = Table.ExpandListColumn(ResourceSpansList, "resourceSpans"),

    // -------------------------------------------------------------------------
    // Extract resource-level attributes (service.name, service.version, session.id)
    // -------------------------------------------------------------------------
    WithResourceAttrs = Table.AddColumn(
        ExpandedResourceSpans,
        "ResourceAttributes",
        each
            let
                attrs = [resourceSpans][resource][attributes],
                asRecord = List.Accumulate(
                    attrs,
                    [],
                    (state, attr) =>
                        Record.AddField(state, attr[key], Record.FieldOrDefault(attr[value], "stringValue",
                            Record.FieldOrDefault(attr[value], "intValue",
                            Record.FieldOrDefault(attr[value], "doubleValue",
                            Record.FieldOrDefault(attr[value], "boolValue", null)))))
                )
            in
                asRecord
    ),
    WithServiceName    = Table.AddColumn(WithResourceAttrs, "service.name",    each Record.FieldOrDefault([ResourceAttributes], "service.name",    null)),
    WithServiceVersion = Table.AddColumn(WithServiceName,   "service.version", each Record.FieldOrDefault([ResourceAttributes], "service.version", null)),
    WithSessionId      = Table.AddColumn(WithServiceVersion,"session.id",      each Record.FieldOrDefault([ResourceAttributes], "session.id",      null)),

    // -------------------------------------------------------------------------
    // Expand scopeSpans
    // -------------------------------------------------------------------------
    WithScopeSpans = Table.AddColumn(WithSessionId, "scopeSpans", each [resourceSpans][scopeSpans], type list),
    ExpandedScopeSpans = Table.ExpandListColumn(WithScopeSpans, "scopeSpans"),
    WithScopeName = Table.AddColumn(ExpandedScopeSpans, "scope.name", each [scopeSpans][scope][name], type text),

    // -------------------------------------------------------------------------
    // Expand individual spans
    // -------------------------------------------------------------------------
    WithSpansList = Table.AddColumn(WithScopeName, "spans", each [scopeSpans][spans], type list),
    ExpandedSpans = Table.ExpandListColumn(WithSpansList, "spans"),

    // -------------------------------------------------------------------------
    // Pull span-level fields
    // -------------------------------------------------------------------------
    WithSpanFields = Table.AddColumn(
        ExpandedSpans,
        "SpanRecord",
        each
            let
                s = [spans],
                // Helper: resolve typed OTel value
                ResolveValue = (v as record) =>
                    if Record.HasFields(v, "stringValue") then v[stringValue]
                    else if Record.HasFields(v, "intValue")    then v[intValue]
                    else if Record.HasFields(v, "doubleValue") then v[doubleValue]
                    else if Record.HasFields(v, "boolValue")   then v[boolValue]
                    else null,

                // Flatten span attributes into a record
                AttrList = if Record.HasFields(s, "attributes") then s[attributes] else {},
                AttrsRecord = List.Accumulate(
                    AttrList,
                    [],
                    (state, attr) => Record.AddField(state, attr[key], ResolveValue(attr[value]))
                ),

                // Timestamps: OTel uses nanoseconds since epoch (parsed as Text by Power Query)
                StartNano  = if Record.HasFields(s, "startTimeUnixNano") then Number.From(s[startTimeUnixNano]) else null,
                EndNano    = if Record.HasFields(s, "endTimeUnixNano")   then Number.From(s[endTimeUnixNano])   else null,
                // Convert nanoseconds → DateTime
                NanoToDateTime = (nano) =>
                    if nano = null then null
                    else #datetime(1970,1,1,0,0,0) + #duration(0, 0, 0, nano / 1e9),

                DurationMs =
                    if StartNano <> null and EndNano <> null
                    then (EndNano - StartNano) / 1e6
                    else null
            in
                [
                    traceId      = Record.FieldOrDefault(s, "traceId",      null),
                    spanId       = Record.FieldOrDefault(s, "spanId",       null),
                    parentSpanId = Record.FieldOrDefault(s, "parentSpanId", null),
                    name         = Record.FieldOrDefault(s, "name",         null),
                    kind         = Record.FieldOrDefault(s, "kind",         null),
                    startTime    = NanoToDateTime(StartNano),
                    endTime      = NanoToDateTime(EndNano),
                    durationMs   = DurationMs,
                    attributes   = AttrsRecord,

                    // Common Copilot / GenAI attributes (null when absent)
                    operation    = Record.FieldOrDefault(AttrsRecord, "gen_ai.operation.name",            null),
                    model        = Record.FieldOrDefault(AttrsRecord, "gen_ai.request.model",             null),
                    inputTokens  = Record.FieldOrDefault(AttrsRecord, "gen_ai.usage.input_tokens",        null),
                    outputTokens = Record.FieldOrDefault(AttrsRecord, "gen_ai.usage.output_tokens",       null),
                    cacheReadTokens     = Record.FieldOrDefault(AttrsRecord, "gen_ai.usage.cache_read.input_tokens",     null),
                    cacheCreationTokens = Record.FieldOrDefault(AttrsRecord, "gen_ai.usage.cache_creation.input_tokens", null),
                    responseModel= Record.FieldOrDefault(AttrsRecord, "gen_ai.response.model",            null),
                    agentName    = Record.FieldOrDefault(AttrsRecord, "gen_ai.agent.name",                null),
                    toolName     = Record.FieldOrDefault(AttrsRecord, "gen_ai.tool.name",                 null),
                    ttft         = Record.FieldOrDefault(AttrsRecord, "copilot_chat.time_to_first_token", null),
                    chatSessionId= Record.FieldOrDefault(AttrsRecord, "copilot_chat.chat_session_id",     null)
                ]
    ),

    // -------------------------------------------------------------------------
    // Expand SpanRecord columns into the final table
    // -------------------------------------------------------------------------
    ExpandedSpanRecord = Table.ExpandRecordColumn(
        WithSpanFields,
        "SpanRecord",
        {
            "traceId", "spanId", "parentSpanId", "name", "kind",
            "startTime", "endTime", "durationMs",
            "operation", "model", "inputTokens", "outputTokens",
            "cacheReadTokens", "cacheCreationTokens", "responseModel",
            "agentName", "toolName", "ttft", "chatSessionId",
            "attributes"
        }
    ),

    // -------------------------------------------------------------------------
    // Keep only the columns that are useful for analysis
    // -------------------------------------------------------------------------
    FinalTable = Table.SelectColumns(
        ExpandedSpanRecord,
        {
            "service.name", "service.version", "session.id", "scope.name",
            "traceId", "spanId", "parentSpanId", "name", "kind",
            "startTime", "endTime", "durationMs",
            "operation", "model", "responseModel", "agentName", "toolName",
            "inputTokens", "outputTokens", "cacheReadTokens", "cacheCreationTokens",
            "ttft", "chatSessionId",
            "attributes"   // full attribute record — expand further as needed
        }
    ),

    // -------------------------------------------------------------------------
    // Add StartDate (date only) for relating to the Date table
    // -------------------------------------------------------------------------
    WithStartDate = Table.AddColumn(FinalTable, "StartDate", each Date.From([startTime]), type date),

    // -------------------------------------------------------------------------
    // Set column types
    // -------------------------------------------------------------------------
    TypedTable = Table.TransformColumnTypes(
        WithStartDate,
        {
            {"startTime",    type datetime},
            {"endTime",      type datetime},
            {"durationMs",   type number},
            {"inputTokens",  Int64.Type},
            {"outputTokens", Int64.Type},
            {"cacheReadTokens",     Int64.Type},
            {"cacheCreationTokens", Int64.Type},
            {"ttft",         Int64.Type},
            {"kind",         Int64.Type}
        }
    )

in
    TypedTable
