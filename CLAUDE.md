# CLAUDE.md — Project Context for Claude Code

## Project

**RAPID** (Recording Auto-Placement & Intelligent Dynamics) — a professional workflow automation tool for REAPER (DAW), written as a single Lua script.

- **Current Version:** 2.5 (February 2026)
- **Developer:** Frank
- **License:** MIT

## Tech Stack

- **Language:** Lua
- **Platform:** REAPER 6.0+ (Digital Audio Workstation)
- **GUI:** ReaImGui (ImGui wrapper for REAPER)
- **Required Extensions:** SWS Extension
- **Optional:** JS_ReaScriptAPI (multi-file import dialogs)

## Architecture

- **Monolithic single-file script:** `RAPID.lua` (~8,500 lines)
- No build step — script is loaded directly into REAPER via Actions → Load ReaScript
- No automated tests — testing is manual inside REAPER
- Config is persisted via INI files and REAPER ExtState

### Code Structure (RAPID.lua)

| Section | Lines (approx.) | Purpose |
|---|---|---|
| Init & Constants | 1–150 | Version, defaults, profiles, aliases |
| State Variables | 200–320 | All runtime state incl. multi-RPP variables |
| Persistence | 330–850 | saveIni/loadIni, protected tracks, session recovery |
| File Operations | 900–1050 | Path handling, media resolution, cross-platform |
| Track & Project | 1050–1400 | RPP parsing, chunk extraction, track manipulation |
| Matching & Suggestion | 1400–1750 | Fuzzy matching, aliases, auto-suggest, profile matching |
| Multi-RPP Core | 1757–2200 | RPP queue, tempo extraction, merged tempo section, plaintext write |
| Multi-RPP Track Ops | 2203–2430 | Shift envelopes, move items, consolidate tracks, auto-match |
| Multi-RPP Commit | 2431–2700 | commitMultiRpp() — full multi-RPP pipeline |
| Audio Processing | 2730–3500 | LUFS calculation, normalization, gain staging |
| Track Operations | 3500–3700 | FX copying, sends, groups, lanes |
| Main Workflow (Single) | 4943+ | commitMappings() — single-RPP import/normalize |
| UI Rendering | 5464–7450 | drawUI_body(), Settings, Help windows |
| Entry Point | 8458–8555 | Dependency check, config load, event loop |

### Key Data Structures

- `recPath` — source RPP paths: `.rpp` (file path), `.dir` (directory), `.regionCount` (region count)
- `recSources` — recording tracks from source RPP
- `mixTargets` — template tracks in current project
- `map` — track mapping assignments (multi-slot: `map[i] = {srcIdx1, srcIdx2, ...}`)
- `normMap` — normalization profile assignments
- `keepMap` — track name preservation settings
- `fxMap` — FX copying settings per slot
- `editState` — inline editing: `.track` (edit key), `.buf` (InputText buffer), `.slotNames[i][s]` (custom names for duplicate slots)
- `uiFlags` — UI booleans: `.settings`, `.help`, `.close`, `.winInit`
- `dragState` — drag-to-toggle: `.sel`, `.lock`, `.keepName`, `.keepFX`, `.lastClicked`
- `selectedRows` — multi-select state (keyed by `"i_s"` format)
- `deleteUnusedMode` — 0=keep unused, 1=delete unused (persisted in INI)
- `calibrationWindow` — state for LUFS calibration popup (v2.4+)
- `normProfiles` — array of profiles with optional per-profile LUFS settings (segmentSize, percentile, threshold)
- `multiRppSettings` — `{enabled=false, gapInMeasures=2, createRegions=true, importMarkers=true, alignLanes=true}`
- `rppQueue` — array of RPP entries: `{path, name, rppText, tracks[], baseTempo, tempoMap[], markers[], lengthInMeasures, measureOffset, qnOffset}`
- `multiMap` — mapping: `multiMap[mixIdx][rppIdx] = trackIdxInRpp` (0 = unmapped)
- `multiNormMap` — normalization per template track: `multiNormMap[mixIdx] = {profile, targetPeak}`
- `trackCache` — weak caches: `.kids` (folder has children), `.color` (effective track color)
- `nameCache` — weak cache for track names

## Four Workflows

1. **Import Mode (Single RPP)** — map recording tracks to mix template (preserves FX, sends, routing, automation)
2. **Import Mode (Multi-RPP)** — import multiple RPP files into the same template with merged tempo, regions, and track consolidation (v2.5+)
3. **Normalize Mode** — standalone LUFS normalization on existing tracks
4. **Full Workflow** — import + mapping + normalization in one pass (works with both single and multi-RPP)

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

- **Table columns (single-RPP import mode):** 10 columns — Sel, ##color (swatch), ##lock (drawn icon), Template Destinations, Recording Sources, Keep name, Keep FX, Normalize, Peak dB, x (+/- buttons)
- **Table columns (multi-RPP import mode):** Lock, ##color (swatch), Template Destinations, [one column per RPP with dropdowns], Normalize, Peak dB — horizontal scrolling for many RPPs, dropdowns dim already-assigned tracks with `[-> target]` annotation
- **Lock icon:** Drawn via `ImGui_DrawList` (filled rect body + rect shackle), not font-based — ReaImGui default font has no emoji support
- **Editable track names:** Double-click Template Destination → inline `InputText`, saves on deactivation (not just Enter). Works in both single-RPP and multi-RPP mode.
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
- Multi-RPP import (`commitMultiRpp()`) uses a different pipeline: API tempo → import all tracks → shift/consolidate → plaintext tempo overwrite → reload
- Tempo import via API loses Shape/Tension — used only for positioning; plaintext overwrite at end restores full fidelity
- All multi-RPP calculations are measure-based, not time-based (time is unreliable with changing tempos)
- **Lua 200 local variable limit:** Main chunk is at ~195 locals. Adding new top-level `local` variables is dangerous — consolidate into existing tables or use forward declarations (which move, not add, locals). For-loop control variables consume 3 internal slots.
- **Forward declarations:** 9 functions (`sanitizeChunk`, `fixChunkMediaPaths`, `postprocessTrackCopyRelink`, `copyFX`, `cloneSends`, `rewireReceives`, `copyTrackControls`, `shiftTrackItemsBy`, `replaceGroupFlagsInChunk`) are forward-declared before `commitMultiRpp` because they're defined later in the file. Their definitions use `X = function(...)` assignment form (not `local function`).

## Normalization System (v2.4+)

- **Gain Reset:** Before normalizing, both Item Gain (`D_VOL` on item) and Take Volume (`D_VOL` on take) are reset to 0dB
- **Normalization via Take Volume:** All gain adjustments applied through Take Volume only (cleaner gain staging)
- **AudioAccessor for Peak/RMS:** Uses `CreateTakeAudioAccessor` to measure actual item content (not source file)
- **LUFS via CalculateNormalization:** Uses REAPER's native API with segment-based percentile measurement
- **Per-profile LUFS settings:** Each profile can have custom segmentSize, percentile, threshold (stored in INI)
- **Calibration workflow:** Select reference item → measure Peak+LUFS → create/update profile

## Multi-RPP Import System (v2.5+)

### Concept

Import multiple RPP recording session files into the same mix template. Each RPP gets its own region, with tempo/time-signature changes merged correctly. All calculations are measure-based (not time-based) because time doesn't work reliably with changing tempos.

### Architecture: Single-Pass with Two-Phase Tempo

1. **API tempo first** — `setTempoViaAPI()` uses `SetTempoTimeSigMarker` to write tempo markers so REAPER can calculate correct positions for track import
2. **Import tracks** — for each template track, import all mapped RPP tracks, shift items + envelopes to correct measure offsets, consolidate onto one master track
3. **Plaintext tempo overwrite** — `writeMultiRppTempoSection()` replaces the entire tempo section in the saved .rpp file with full-fidelity plaintext (API loses Shape/Tension parameters), then reloads

### RPP Queue

- `rppQueue[]` entries contain: path, name, rppText, tracks[], baseTempo (bpm/num/denom), tempoMap[] (all tempo points), markers[], lengthInMeasures, measureOffset, qnOffset
- `recalculateQueueOffsets()` computes both `measureOffset` (for UI) and `qnOffset` (QN position for all beat/time calculations, accumulated correctly across RPPs with different time signatures)
- Drag-and-drop reordering via ImGui `DragDropSource`/`DragDropTarget`
- JS_ReaScriptAPI multi-file dialog for loading multiple RPPs at once

### Tempo Handling

- `extractBaseTempo(rppText)` — parses `TEMPO <bpm> <num> <denom>` line
- `extractTempoMap(rppText)` — parses `TEMPO` line + `<TEMPOENVEX>` `PT` points; time signature encoded as `65536 * denom + num`
- `extractMarkersFromRpp(rppText)` — parses MARKER lines from .rpp; pairs region start+end markers (same idx) into single entries with `rgnend`
- `buildMergedTempoSection()` — builds plaintext section (TEMPO line + TEMPOENVEX with all PT points from all RPPs, offset by `qnOffset`). Does NOT write MARKER lines — those are created via API and preserved from the saved .rpp
- `writeMultiRppTempoSection()` — saves project, reads .rpp file, replaces TEMPO+TEMPOENVEX section while preserving existing MARKER lines (between TEMPOENVEX end and `<PROJBAY>`), writes back, reloads
- Gap between RPPs inherits the last tempo from the preceding RPP

### Beat Offset Calculation (qnOffset)

**Critical:** Converting measure offsets to beat positions (quarter notes) requires accounting for time signatures. A measure in 6/8 has 3 QN (`6 * 4/8`), not 6. And each RPP may have a different time signature, so the global offset must accumulate QN from all preceding RPPs.

Formula per measure: `qnPerMeasure = num * (4 / denom)`

`recalculateQueueOffsets()` computes both `measureOffset` (for UI display) and `qnOffset` (for all beat/time calculations). All code that converts measure positions to beats MUST use `rpp.qnOffset`, never `rpp.measureOffset * (rpp.baseTempo.num or 4)`.

After `setTempoViaAPI()` runs, REAPER's `TimeMap2_beatsToTime(0, qnOffset)` gives accurate time positions.

### Track Consolidation Pipeline (`commitMultiRpp()`)

```
1. setTempoViaAPI() — set tempo markers for correct positioning (uses beatpos parameter)
2. createMultiRppRegions() — one region per RPP (gated on createRegions setting)
3. importMultiRppMarkers() — markers with measure offsets (gated on importMarkers setting)
4. For each template track with mappings:
   a. For each RPP: sanitize chunk, fix media paths
   b. Shift POSITION + PT values in chunk text (gsub before SetTrackStateChunk)
   c. Append POOLEDENV (after shifting — pooled envs use beat-based positions)
   d. SetTrackStateChunk (with return value check) + postprocessTrackCopyRelink
   e. Consolidate: move items + copy envelope points to first track
   e2. Align lanes: move all items to highest lane for visibility (gated on alignLanes setting)
   f. Copy FX/Sends/Groups from template track (includes GROUP_FLAGS via replaceGroupFlagsInChunk)
   g. Delete extra tracks + original template track
5. Delete unused template tracks (if enabled)
6. Normalize per region (uses auto-created RPP regions)
7. Build peaks, minimize tracks
8. writeMultiRppTempoSection() + reload (ONLY if importMarkers enabled)
```

### Key Helper Functions

- `shiftTrackEnvelopesBy(tr, delta)` — shifts all envelope points on a track by time delta
- `moveItemsToTrack(srcTrack, destTrack)` — moves all media items between tracks via `MoveMediaItemToTrack`
- `copyEnvelopePointsToTrack(srcTrack, destTrack)` — merges envelope points by matching envelope names
- `autoMatchProfilesMulti()` — auto-matches normalize profiles to template tracks in multi-RPP mode (same alias + fuzzy logic as single-RPP `autoMatchProfiles`)

### Multi-RPP UI

- **Toggle:** "Multi-RPP" checkbox in toolbar enables/disables multi-RPP mode
- **Queue panel:** CollapsingHeader showing loaded RPPs with drag-drop reorder, editable names, measure info, remove buttons
- **Settings row:** Gap (measures), Create regions, Import Markers + Tempo Map, Align lanes checkboxes
- **Column-based mapping table:** One dropdown column per loaded RPP, horizontal scrolling (`ScrollX`) for many RPPs
- **Auto-match:** Per-column and all-columns auto-matching via `multiRppAutoMatchColumn()` / `multiRppAutoMatchAll()` — uses same `calculateMatchScore` logic as single-RPP (exact/prefix/first-word/contains/fuzzy)
- **Normalize match:** "Match" button in normalize column + included in "Match All" — uses `autoMatchProfilesMulti()` with alias + fuzzy matching

### Known Limitations (MVP)

- Send Envelopes and Pooled Automation items are not explicitly shifted (deferred to future version)
- Pooled automation is copied as-is (works because it's pooled by reference)

## FIXED BUG: Multi-RPP Item Positioning + Region Length (v2.5)

**Status:** Fixed — needs manual testing in REAPER to confirm.

### Root Causes Found

1. **`extractTempoMap()` line 1794**: `rppText:match("<TEMPOENVEX.-\n>")` used Lua's `.-` which cannot match newlines. Multi-line TEMPOENVEX blocks were never extracted, so only base tempo was returned. This caused `calculateRppLengthInMeasures()` to use the fallback constant-BPM formula, producing wrong lengths for RPPs with tempo changes. **Fixed** by replacing with `find/sub` extraction.

2. **`sanitizeChunk()` lines 3679-3688**: Patterns like `\nAUXRECV.-\n` didn't match indented RPP lines (e.g., `\n    AUXRECV ...`). Stale AUXRECV/HWOUT entries referencing non-existent tracks could cause `SetTrackStateChunk` to silently fail. **Fixed** by adding `%s*` after `\n` in all patterns.

3. **`commitMultiRpp()` line 2745**: `SetTrackStateChunk` return value was not checked, hiding failures. **Fixed** with return value check and warning log.

4. **Diagnostic logging added**: gsub replacement counts for POSITION and PT values are now logged to help verify shifting works correctly.

## Resolved Issues

**Fixed (v2.5): Multi-RPP marker/region duplication and wrong positions**

- Root cause 1: `extractMarkersFromRpp()` treated both region-start and region-end MARKER lines as separate entries, creating duplicate regions with `rgnend=0`
- Root cause 2: `buildMergedTempoSection()` wrote MARKER lines in wrong format (REAPER uses `MARKER idx pos "name" flags [0 colortype colorflag {GUID} 0]`, not `MARKER idx pos "name" isRegion rgnend color`)
- Root cause 3: `writeMultiRppTempoSection()` replaced everything between TEMPO and `<PROJBAY>`, deleting API-created MARKER lines
- RPP format insight: Regions use TWO MARKER lines (start with name + end without name, same index). MARKER lines come AFTER TEMPOENVEX, before `<PROJBAY>`. Flags field is a bitmask (bit 0 = isRegion). Region-end lines have shortened format: `MARKER idx pos "" flags`
- Fix: (1) `extractMarkersFromRpp()` now pairs region-end markers with start markers to set `rgnend`, skips end-markers from output. (2) `buildMergedTempoSection()` no longer writes MARKER lines — API-created markers are preserved. (3) `writeMultiRppTempoSection()` extracts and re-inserts MARKER lines when replacing TEMPO+TEMPOENVEX section

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
- v2.4 (Feb 2026): LUFS Calibration System — measure reference items to create/update profiles, per-profile LUFS settings, gain reset before normalization
- v2.5 (Feb 2026): Multi-RPP Import — import multiple RPP files into same template, merged tempo/markers, measure-based offsets, track consolidation, column-based UI, lane alignment, group flag copying, editable template track names

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
