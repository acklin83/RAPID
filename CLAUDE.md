# CLAUDE.md — Project Context for Claude Code

## Project

**RAPID** (Recording Auto-Placement & Intelligent Dynamics) — a professional workflow automation tool for REAPER (DAW), written as a single Lua script.

- **Current Version:** 2.1 (November 2025)
- **Developer:** Frank
- **License:** MIT

## Tech Stack

- **Language:** Lua
- **Platform:** REAPER 6.0+ (Digital Audio Workstation)
- **GUI:** ReaImGui (ImGui wrapper for REAPER)
- **Required Extensions:** SWS Extension
- **Optional:** JS_ReaScriptAPI (multi-file import dialogs)

## Architecture

- **Monolithic single-file script:** `RAPID.lua` (~6,600 lines)
- No build step — script is loaded directly into REAPER via Actions → Load ReaScript
- No automated tests — testing is manual inside REAPER
- Config is persisted via INI files and REAPER ExtState

### Code Structure (RAPID.lua)

| Section | Lines (approx.) | Purpose |
|---|---|---|
| Init & Constants | 1–150 | Version, defaults, profiles, aliases |
| Persistence | 211–687 | saveIni/loadIni, protected tracks, session recovery |
| File Operations | 751–895 | Path handling, media resolution, cross-platform |
| Track & Project | 917–1300 | RPP parsing, chunk extraction, track manipulation |
| Matching & Suggestion | 1027–1845 | Fuzzy matching, aliases, auto-suggest, profile matching |
| Audio Processing | 2730–3150 | LUFS calculation, normalization, gain staging |
| Track Operations | 2446–2630 | FX copying, sends, groups, lanes |
| Main Workflow | 3518+ | commitMappings() — executes import/normalize |
| UI Rendering | 3986–5161 | drawUI_body(), Settings, Help windows |
| Entry Point | 6541–6633 | Dependency check, config load, event loop |

### Key Data Structures

- `recSources` — recording tracks from source RPP
- `mixTargets` — template tracks in current project
- `map` — track mapping assignments
- `normMap` — normalization profile assignments
- `keepMap` — track name preservation settings
- `fxMap` — FX copying settings per slot

## Three Workflows

1. **Import Mode** — map recording tracks to mix template (preserves FX, sends, routing, automation)
2. **Normalize Mode** — standalone LUFS normalization on existing tracks
3. **Full Workflow** — import + mapping + normalization in one pass

## Code Conventions

- Functions: `camelCase` (e.g., `baseSimilarity()`, `findAliasTarget()`, `commitMappings()`)
- Variables: `camelCase`
- UI functions prefixed with `draw` (e.g., `drawUI_body()`, `drawSettingsWindow()`)
- Inline comments in English
- No external module system — all code in one file

## Important Notes

- **Do not split the file into modules** without explicit instruction
- ReaImGui calls must happen inside the deferred draw loop
- REAPER API is global (e.g., `reaper.GetTrack()`, `reaper.SetMediaItemInfo_Value()`)
- SWS functions are also global (e.g., `reaper.CF_GetSWSVersion()`)
- Chunk-based FX copying was tried and reverted (v1.4) — use native API (`TrackFX_CopyToTrack`)
- Performance-critical: track operations were optimized from 20s → 2s (v1.5 refactor)

## Development History Highlights

- v1.1 (Sep 2025): Initial release — basic track mapping, fuzzy matching
- v1.2 (Oct 2025): LUFS normalization added
- v1.3 (Oct 2025): Profile system, auto-match
- v1.5 (Nov 2025): Major refactor — 60% code reduction, 10x perf improvement
- v2.0 (Nov 2025): Unified workflow — merged RAPID + Little Joe, 29% line reduction
- v2.1 (Nov 2025): Auto-duplicate feature for multi-slot mapping

## Files

| File | Purpose |
|---|---|
| `RAPID.lua` | Entire application |
| `README.md` | User-facing documentation |
| `CHANGELOG.md` | Version history |
| `LICENSE` | MIT License |
| `CLAUDE.md` | This file — context for Claude Code |
