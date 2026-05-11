// Date Table
// Generates a contiguous calendar table spanning the date range found in OtelTraces.
// Relate this table to OtelTraces on: DateTable[Date] = OtelTraces[StartDate]

let
    // -------------------------------------------------------------------------
    // Derive date range from OtelTraces so the table always covers the data.
    // Falls back to today when the table is empty (List.Min/Max return null).
    // -------------------------------------------------------------------------
    Today   = Date.From(DateTime.LocalNow()),
    MinDate = List.Min(OtelTraces[StartDate]) ?? Today,
    MaxDate = List.Max(OtelTraces[StartDate]) ?? Today,

    // -------------------------------------------------------------------------
    // Generate a list of every date in the range, then convert to a table
    // -------------------------------------------------------------------------
    DayCount  = Duration.Days(MaxDate - MinDate) + 1,
    DateList  = List.Dates(MinDate, DayCount, #duration(1, 0, 0, 0)),
    DateTable = Table.FromList(DateList, Splitter.SplitByNothing(), {"Date"}),

    // -------------------------------------------------------------------------
    // Add calendar columns
    // -------------------------------------------------------------------------
    WithYear        = Table.AddColumn(DateTable, "Year",            each Date.Year([Date]),                          Int64.Type),
    WithQuarterNum  = Table.AddColumn(WithYear,        "QuarterNumber",   each Date.QuarterOfYear([Date]),                Int64.Type),
    WithQuarter     = Table.AddColumn(WithQuarterNum,  "Quarter",         each "Q" & Text.From(Date.QuarterOfYear([Date])), type text),
    WithMonthNum    = Table.AddColumn(WithQuarter,     "MonthNumber",     each Date.Month([Date]),                        Int64.Type),
    WithMonthName   = Table.AddColumn(WithMonthNum,    "MonthName",       each Date.ToText([Date], "MMMM"),               type text),
    WithMonthShort  = Table.AddColumn(WithMonthName,   "MonthNameShort",  each Date.ToText([Date], "MMM"),                type text),
    WithYearMonth   = Table.AddColumn(WithMonthShort,  "YearMonth",       each Date.Year([Date]) * 100 + Date.Month([Date]), Int64.Type),
    WithYearMonthLabel = Table.AddColumn(WithYearMonth, "YearMonthLabel", each Date.ToText([Date], "MMM yyyy"),           type text),
    WithWeekNum     = Table.AddColumn(WithYearMonthLabel, "WeekNumber",   each Date.WeekOfYear([Date]),                   Int64.Type),
    WithDayOfWeekNum = Table.AddColumn(WithWeekNum,    "DayOfWeekNumber", each Date.DayOfWeek([Date], Day.Monday) + 1,   Int64.Type),
    WithDayOfWeek   = Table.AddColumn(WithDayOfWeekNum,"DayOfWeekName",   each Date.ToText([Date], "dddd"),               type text),
    WithDayShort    = Table.AddColumn(WithDayOfWeek,   "DayOfWeekShort",  each Date.ToText([Date], "ddd"),                type text),
    WithDay         = Table.AddColumn(WithDayShort,    "Day",             each Date.Day([Date]),                          Int64.Type),
    WithIsWeekend   = Table.AddColumn(WithDay,         "IsWeekend",       each Date.DayOfWeek([Date], Day.Monday) >= 5,  type logical),

    // -------------------------------------------------------------------------
    // Set the Date column type last (after derivations)
    // -------------------------------------------------------------------------
    TypedTable = Table.TransformColumnTypes(WithIsWeekend, {{"Date", type date}})

in
    TypedTable
