// GitHub Copilot Model Pricing Table
// Source: https://docs.github.com/en/copilot/reference/copilot-billing/models-and-pricing
// All prices are USD per 1,000,000 tokens. 1 AI credit = $0.01 USD.
// Fetched: 2026-05-09
//
// Columns:
//   ModelId            — matches gen_ai.request.model / gen_ai.response.model in traces
//   ModelDisplayName   — human-readable name from the pricing page
//   Provider           — OpenAI | Anthropic | Google | xAI | GitHub
//   Tier               — Lightweight | Versatile | Powerful
//   InputPricePerM     — USD per 1M input tokens
//   CacheReadPricePerM — USD per 1M cache-read tokens
//   CacheWritePricePerM— USD per 1M cache-write tokens (Anthropic only; null otherwise)
//   OutputPricePerM    — USD per 1M output tokens

let
    Rows = {
        // ── OpenAI ────────────────────────────────────────────────────────────
        [ ModelId = "gpt-4.1",          ModelDisplayName = "GPT-4.1",          Provider = "OpenAI",   Tier = "Versatile",    InputPricePerM = 2.00,  CacheReadPricePerM = 0.500,  CacheWritePricePerM = null,  OutputPricePerM = 8.00  ],
        [ ModelId = "gpt-5-mini",        ModelDisplayName = "GPT-5 mini",       Provider = "OpenAI",   Tier = "Lightweight",  InputPricePerM = 0.25,  CacheReadPricePerM = 0.025,  CacheWritePricePerM = null,  OutputPricePerM = 2.00  ],
        [ ModelId = "gpt-5.2",          ModelDisplayName = "GPT-5.2",          Provider = "OpenAI",   Tier = "Versatile",    InputPricePerM = 1.75,  CacheReadPricePerM = 0.175,  CacheWritePricePerM = null,  OutputPricePerM = 14.00 ],
        [ ModelId = "gpt-5.2-codex",    ModelDisplayName = "GPT-5.2-Codex",   Provider = "OpenAI",   Tier = "Powerful",     InputPricePerM = 1.75,  CacheReadPricePerM = 0.175,  CacheWritePricePerM = null,  OutputPricePerM = 14.00 ],
        [ ModelId = "gpt-5.3-codex",    ModelDisplayName = "GPT-5.3-Codex",   Provider = "OpenAI",   Tier = "Powerful",     InputPricePerM = 1.75,  CacheReadPricePerM = 0.175,  CacheWritePricePerM = null,  OutputPricePerM = 14.00 ],
        [ ModelId = "gpt-5.4",          ModelDisplayName = "GPT-5.4",          Provider = "OpenAI",   Tier = "Versatile",    InputPricePerM = 2.50,  CacheReadPricePerM = 0.250,  CacheWritePricePerM = null,  OutputPricePerM = 15.00 ],
        [ ModelId = "gpt-5.4-mini",     ModelDisplayName = "GPT-5.4 mini",     Provider = "OpenAI",   Tier = "Lightweight",  InputPricePerM = 0.75,  CacheReadPricePerM = 0.075,  CacheWritePricePerM = null,  OutputPricePerM = 4.50  ],
        [ ModelId = "gpt-5.4-nano",     ModelDisplayName = "GPT-5.4 nano",     Provider = "OpenAI",   Tier = "Lightweight",  InputPricePerM = 0.20,  CacheReadPricePerM = 0.020,  CacheWritePricePerM = null,  OutputPricePerM = 1.25  ],
        [ ModelId = "gpt-5.5",          ModelDisplayName = "GPT-5.5",          Provider = "OpenAI",   Tier = "Powerful",     InputPricePerM = 5.00,  CacheReadPricePerM = 0.500,  CacheWritePricePerM = null,  OutputPricePerM = 30.00 ],

        // ── Anthropic ─────────────────────────────────────────────────────────
        // Anthropic has an additional CacheWritePricePerM column
        [ ModelId = "claude-haiku-4-5",  ModelDisplayName = "Claude Haiku 4.5", Provider = "Anthropic", Tier = "Versatile", InputPricePerM = 1.00, CacheReadPricePerM = 0.10, CacheWritePricePerM = 1.25, OutputPricePerM = 5.00  ],
        [ ModelId = "claude-sonnet-4",   ModelDisplayName = "Claude Sonnet 4",  Provider = "Anthropic", Tier = "Versatile", InputPricePerM = 3.00, CacheReadPricePerM = 0.30, CacheWritePricePerM = 3.75, OutputPricePerM = 15.00 ],
        [ ModelId = "claude-sonnet-4-5", ModelDisplayName = "Claude Sonnet 4.5",Provider = "Anthropic", Tier = "Versatile", InputPricePerM = 3.00, CacheReadPricePerM = 0.30, CacheWritePricePerM = 3.75, OutputPricePerM = 15.00 ],
        [ ModelId = "claude-sonnet-4-6", ModelDisplayName = "Claude Sonnet 4.6",Provider = "Anthropic", Tier = "Versatile", InputPricePerM = 3.00, CacheReadPricePerM = 0.30, CacheWritePricePerM = 3.75, OutputPricePerM = 15.00 ],
        [ ModelId = "claude-opus-4-5",   ModelDisplayName = "Claude Opus 4.5",  Provider = "Anthropic", Tier = "Powerful",  InputPricePerM = 5.00, CacheReadPricePerM = 0.50, CacheWritePricePerM = 6.25, OutputPricePerM = 25.00 ],
        [ ModelId = "claude-opus-4-6",   ModelDisplayName = "Claude Opus 4.6",  Provider = "Anthropic", Tier = "Powerful",  InputPricePerM = 5.00, CacheReadPricePerM = 0.50, CacheWritePricePerM = 6.25, OutputPricePerM = 25.00 ],
        [ ModelId = "claude-opus-4-7",   ModelDisplayName = "Claude Opus 4.7",  Provider = "Anthropic", Tier = "Powerful",  InputPricePerM = 5.00, CacheReadPricePerM = 0.50, CacheWritePricePerM = 6.25, OutputPricePerM = 25.00 ],

        // ── Google ────────────────────────────────────────────────────────────
        [ ModelId = "gemini-2.5-pro",   ModelDisplayName = "Gemini 2.5 Pro",   Provider = "Google",   Tier = "Powerful",     InputPricePerM = 1.25, CacheReadPricePerM = 0.125, CacheWritePricePerM = null, OutputPricePerM = 10.00 ],
        [ ModelId = "gemini-3-flash",   ModelDisplayName = "Gemini 3 Flash",   Provider = "Google",   Tier = "Lightweight",  InputPricePerM = 0.50, CacheReadPricePerM = 0.050, CacheWritePricePerM = null, OutputPricePerM = 3.00  ],
        [ ModelId = "gemini-3.1-pro",   ModelDisplayName = "Gemini 3.1 Pro",   Provider = "Google",   Tier = "Powerful",     InputPricePerM = 2.00, CacheReadPricePerM = 0.200, CacheWritePricePerM = null, OutputPricePerM = 12.00 ],

        // ── xAI ───────────────────────────────────────────────────────────────
        [ ModelId = "grok-code-fast-1", ModelDisplayName = "Grok Code Fast 1", Provider = "xAI",      Tier = "Lightweight",  InputPricePerM = 0.20, CacheReadPricePerM = 0.020, CacheWritePricePerM = null, OutputPricePerM = 1.50  ],

        // ── Fine-tuned (GitHub) ───────────────────────────────────────────────
        [ ModelId = "raptor-mini",      ModelDisplayName = "Raptor mini",      Provider = "GitHub",   Tier = "Versatile",    InputPricePerM = 0.25, CacheReadPricePerM = 0.025, CacheWritePricePerM = null, OutputPricePerM = 2.00  ],
        [ ModelId = "goldeneye",        ModelDisplayName = "Goldeneye",        Provider = "GitHub",   Tier = "Powerful",     InputPricePerM = 1.25, CacheReadPricePerM = 0.125, CacheWritePricePerM = null, OutputPricePerM = 10.00 ]
    },

    PricingTable = Table.FromRecords(Rows),

    // Add derived columns: AI Credits per 1M tokens (1 credit = $0.01)
    WithCredits = Table.AddColumn(
        Table.AddColumn(
            Table.AddColumn(
                Table.AddColumn(PricingTable,
                    "InputCreditsPerM",      each [InputPricePerM]      * 100, type number),
                "CacheReadCreditsPerM",  each [CacheReadPricePerM]  * 100, type number),
            "CacheWriteCreditsPerM", each if [CacheWritePricePerM] = null then null else [CacheWritePricePerM] * 100, type number),
        "OutputCreditsPerM",     each [OutputPricePerM]     * 100, type number),

    TypedTable = Table.TransformColumnTypes(
        WithCredits,
        {
            {"ModelId",              type text},
            {"ModelDisplayName",     type text},
            {"Provider",             type text},
            {"Tier",                 type text},
            {"InputPricePerM",       type number},
            {"CacheReadPricePerM",   type number},
            {"CacheWritePricePerM",  type number},
            {"OutputPricePerM",      type number},
            {"InputCreditsPerM",     type number},
            {"CacheReadCreditsPerM", type number},
            {"CacheWriteCreditsPerM",type number},
            {"OutputCreditsPerM",    type number}
        }
    )

in
    TypedTable
