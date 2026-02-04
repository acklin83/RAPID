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
- `multiRppSettings` — `{enabled=false, gapInMeasures=2, createRegions=true, importMarkers=true}`
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
- Multi-RPP import (`commitMultiRpp()`) uses a different pipeline: API tempo → import all tracks → shift/consolidate → plaintext tempo overwrite → reload
- Tempo import via API loses Shape/Tension — used only for positioning; plaintext overwrite at end restores full fidelity
- All multi-RPP calculations are measure-based, not time-based (time is unreliable with changing tempos)
- **Lua 200 local variable limit:** Main chunk is at ~195 locals. Adding new top-level `local` variables is dangerous — consolidate into existing tables or use forward declarations (which move, not add, locals). For-loop control variables consume 3 internal slots.
- **Forward declarations:** 8 functions (`sanitizeChunk`, `fixChunkMediaPaths`, `postprocessTrackCopyRelink`, `copyFX`, `cloneSends`, `rewireReceives`, `copyTrackControls`, `shiftTrackItemsBy`) are forward-declared before `commitMultiRpp` because they're defined later in the file. Their definitions use `X = function(...)` assignment form (not `local function`).

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
- `buildMergedTempoSection()` — builds complete plaintext section (TEMPO line + MARKER lines + TEMPOENVEX with all PT points from all RPPs, offset by `qnOffset`)
- `writeMultiRppTempoSection()` — saves project, reads .rpp file, replaces section between first `TEMPO` line and `<PROJBAY>`, writes back, reloads
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
   d. SetTrackStateChunk + postprocessTrackCopyRelink
   e. Consolidate: move items + copy envelope points to first track
   f. Copy FX/Sends from template track
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
- **Settings row:** Gap (measures), Create regions, Import Markers + Tempo Map checkboxes
- **Column-based mapping table:** One dropdown column per loaded RPP, horizontal scrolling (`ScrollX`) for many RPPs
- **Auto-match:** Per-column and all-columns auto-matching via `multiRppAutoMatchColumn()` / `multiRppAutoMatchAll()` — uses same `calculateMatchScore` logic as single-RPP (exact/prefix/first-word/contains/fuzzy)
- **Normalize match:** "Match" button in normalize column + included in "Match All" — uses `autoMatchProfilesMulti()` with alias + fuzzy matching

### Known Limitations (MVP)

- Send Envelopes and Pooled Automation items are not explicitly shifted (deferred to future version)
- Pooled automation is copied as-is (works because it's pooled by reference)

## OPEN BUG: Multi-RPP Item Positioning + Region Length (v2.5)

**Status:** Unresolved — needs debugging in the next session.

### Symptom

When importing 2 RPPs (tested with "250927 Kulti" in 4/4 and "Pre Pro EP 2024" with tempo changes):

1. **Items from RPP 2 are NOT shifted** — items like "03-Kik In-untitled.mp3" and "03-Kik In-Pre Pro EP 2024.mp3" appear at their original RPP-internal positions (starting at 0) instead of being offset to the RPP 2 region. Items at higher positions in RPP 2 (like "-01.mp3" items around measure 387) appear there by coincidence (their original position in RPP 2), NOT because they were shifted.
2. **Region 2 is too short** — "Pre Pro EP 2024" region shows ~130 measures instead of 622 in the original RPP. Region 1 "Kulti" appears correct.
3. **Regions START at correct positions** — the offset calculation (`qnOffset`) and region creation work. Only the LENGTH of RPP 2's region and the item POSITIONS are wrong.

### What has been tried (and failed)

1. **Chunk-based POSITION shifting** (current approach): Instead of shifting items via API (`shiftTrackItemsBy`) after `SetTrackStateChunk`, positions are now shifted directly in the chunk text via gsub BEFORE `SetTrackStateChunk`. Pattern: `(\n%s*POSITION%s+)([%d%.%-]+)`. The `%s*` was added to handle RPP indentation (lines like `\n      POSITION 10.5`). **Still doesn't work** — items remain unshifted.

2. **`calculateRppLengthInMeasures` rewrite**: Replaced simple `maxEndTime * (bpm/60)` with full tempo map walk (converts time→beats→measures through each tempo segment). Also replaced the `<ITEM.-\n>` gmatch (which failed on indented RPP text because `\n>` only matches unindented closing brackets) with line-by-line POSITION/LENGTH scanning. **Region 2 is still too short** — suggests the tempo map walk or item scanning may still have issues.

3. **`setTempoViaAPI` beatpos parameter**: Changed from converting beats→time per marker (`TimeMap2_beatsToTime` + timepos) to passing `beatpos` directly (`timepos=-1, measurepos=-1, beatpos=QN`). Regions are created correctly after this, so tempo markers are being set. **But this change hasn't been verified independently** — might need to revert to timepos approach if beatpos doesn't work reliably in all REAPER versions.

### Investigation plan for next session

**Priority 1: Debug the gsub POSITION shifting**
- Add `log()` calls to verify `mp.offset` is non-zero for RPP 2
- Log the count of gsub replacements: `local count; chunk, count = chunk:gsub(...); log("shifted "..count.." positions")`
- If count is 0: dump first 500 chars of chunk to log to see actual format (indentation, line endings)
- If count > 0 but items still unshifted: check if `SetTrackStateChunk` silently fails (check return value)

**Priority 2: Debug region length calculation**
- Log `maxEndTime` from `calculateRppLengthInMeasures` for RPP 2 to verify item scanning finds all items
- Log tempo map segment count and total measures calculation
- Compare against manual item count in the RPP file

**Priority 3: Verify setTempoViaAPI**
- Check if reverting to `timepos` approach (with `TimeMap2_beatsToTime` conversion) fixes anything
- The cascading conversion should work correctly when markers are added in order (each marker only affects tempo after its position)

### Key code locations

- Chunk POSITION shifting: `commitMultiRpp()` step 4b (~line 2708)
- `calculateRppLengthInMeasures()`: ~line 1871
- `setTempoViaAPI()`: ~line 2328
- `recalculateQueueOffsets()`: ~line 2055
- `createMultiRppRegions()`: ~line 2418
- `extractTrackChunks()`: ~line 1325 (how chunks are stored — preserves RPP indentation)
- `sanitizeChunk()`: ~line 3620 (note: its `\n` patterns also lack `%s*` but this doesn't matter because properties are later set via API)

### RPP chunk indentation context

RPP files are indented (2 spaces per nesting level). `extractTrackChunks()` preserves original indentation. Inside a track chunk, item POSITION lines look like `\n      POSITION 10.5` (6+ spaces). Any gsub pattern matching chunk content MUST use `%s*` between `\n` and the keyword. `sanitizeChunk()` patterns (`\nI_FOLDERDEPTH`, `\nRECARM`, etc.) lack `%s*` but this is harmless because those properties are set later via REAPER API.

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
- v2.4 (Feb 2026): LUFS Calibration System — measure reference items to create/update profiles, per-profile LUFS settings, gain reset before normalization
- v2.5 (Feb 2026): Multi-RPP Import — import multiple RPP files into same template, merged tempo/markers, measure-based offsets, track consolidation, column-based UI

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
