# CLAUDE.md — Project Context for Claude Code

## Project

**RAPID** (Recording Auto-Placement & Intelligent Dynamics) — a professional workflow automation tool for REAPER (DAW), written as a single Lua script.

- **Current Version:** 2.3 (February 2026)
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
- `map` — track mapping assignments (multi-slot: `map[i] = {srcIdx1, srcIdx2, ...}`)
- `normMap` — normalization profile assignments
- `keepMap` — track name preservation settings
- `fxMap` — FX copying settings per slot
- `slotNameOverride` — per-slot custom names for duplicated tracks (`slotNameOverride[mixIdx][slot]`)
- `editingDestTrack` / `editingDestBuf` — state for inline track name editing
- `selectedRows` — multi-select state (keyed by `"i_s"` format)
- `deleteUnusedMode` — 0=keep unused, 1=delete unused (persisted in INI)

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

## UI Theme (v2.2+)

- **MixnoteStyle** dark theme applied via `apply_theme()` / `pop_theme()` in the main loop
- 26 color pushes + 10 style var pushes — counts must match exactly
- `sec_button(label)` helper for secondary/non-primary action buttons
- `ctx` must be declared before theme functions (Lua upvalue binding)
- See `MixnoteStyle.md` for the full design system reference

## UI Details (v2.3+)

- **Table columns (import mode):** 10 columns — Sel, ##color (swatch), ##lock (drawn icon), Template Destinations, Recording Sources, Keep name, Keep FX, Normalize, Peak dB, x (+/- buttons)
- **Lock icon:** Drawn via `ImGui_DrawList` (filled rect body + rect shackle), not font-based — ReaImGui default font has no emoji support
- **Editable track names:** Double-click Template Destination → inline `InputText`, saves on deactivation (not just Enter)
- **Duplicate slots:** Created via "+" button, inherit normMap settings, independently renamable via `slotNameOverride`
- **Delete unused toggle:** Single checkbox, hides rows (not just dims), respects locked tracks and folders with content
- **Folder visibility:** Pre-computed `folderHasContent` via parent stack walk — folders only shown if they contain children with sources or locked children
- **Commit pipeline:** `chosenSlots[]` / `op.slotIdxs` preserve original slot indices for correct `slotNameOverride` lookup

## Important Notes

- **Do not split the file into modules** without explicit instruction
- ReaImGui calls must happen inside the deferred draw loop
- REAPER API is global (e.g., `reaper.GetTrack()`, `reaper.SetMediaItemInfo_Value()`)
- SWS functions are also global (e.g., `reaper.CF_GetSWSVersion()`)
- Chunk-based FX copying was tried and reverted (v1.4) — use native API (`TrackFX_CopyToTrack`)
- Performance-critical: track operations were optimized from 20s → 2s (v1.5 refactor)
- Import pipeline (`commitMappings()`) optimized in v2.3.1: cached chunk serialization, removed redundant `UpdateArrange()` calls, targeted peak building and media sweep to new tracks only, pre-computed normalization lookup

## Resolved Issues

**Fixed (v2.3): Imported RPP media items showed as "offline"**

- Root cause: Absolute paths in RPP chunks pointed to original location after RPP was copied elsewhere
- Solution: `tryResolveMedia()` uses progressive path suffix matching — tries direct resolve, separator variants, then progressively shorter path suffixes relative to `rppDir`
- `fixChunkMediaPaths()` escapes `%` in gsub replacement strings
- `postprocessTrackCopyRelink()` no longer early-returns when `doCopy=false` — resolves and relinks offline sources via `PCM_Source_CreateFromFile`
- Important: Do NOT hardcode subfolder names (Audio/, Media/) — users have arbitrary folder structures

## Development History Highlights

- v1.1 (Sep 2025): Initial release — basic track mapping, fuzzy matching
- v1.2 (Oct 2025): LUFS normalization added
- v1.3 (Oct 2025): Profile system, auto-match
- v1.5 (Nov 2025): Major refactor — 60% code reduction, 10x perf improvement
- v2.0 (Nov 2025): Unified workflow — merged RAPID + Little Joe, 29% line reduction
- v2.1 (Nov 2025): Auto-duplicate feature for multi-slot mapping
- v2.2 (Feb 2026): MixnoteStyle dark theme, compact UI layout, sec_button helper
- v2.3 (Feb 2026): Editable track names, duplicate slot improvements, delete unused toggle, offline media fix, DrawList lock icon, help text rewrite
- v2.3.1 (Feb 2026): Import speed optimization — cached chunks, removed redundant UI updates, targeted peak/media operations, deduplicated norm lookup

## Files

| File | Purpose |
|---|---|
| `RAPID.lua` | Entire application |
| `README.md` | User-facing documentation |
| `CHANGELOG.md` | Version history |
| `LICENSE` | MIT License |
| `CLAUDE.md` | This file — context for Claude Code |
| `MixnoteStyle.md` | UI design system (dark theme reference) |
| `roadmap.md` | Development roadmap |
| `LUFS-Calibration-Plan.md` | Implementation plan for v2.4 calibration feature |
