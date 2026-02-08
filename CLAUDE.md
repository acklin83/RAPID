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
- `rppQueue` — array of RPP entries: `{path, name, rppText, tracks[], baseTempo, tempoMap[], markers[], lengthInMeasures, lengthInQN, maxEndTime, measureOffset, qnOffset, timeOffset}`
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
- Multi-RPP import (`commitMultiRpp()`) uses a different pipeline: API tempo → import tracks → shift/consolidate → delete unused → regions/markers → normalize (no reload)
- Tempo import via API (`SetTempoTimeSigMarker`) now has full fidelity — shape 0/1 maps perfectly to linear true/false. `SetEnvelopeStateChunk` is still used for single-RPP (copies source TEMPOENVEX directly) but NOT for multi-RPP (API markers are sufficient, envelope chunk corrupted internal state)
- Both single-RPP and multi-RPP marker/tempo import use API-based approach (no project reload needed) — undo works correctly for both
- **TEMPOENVEX PT positions are in SECONDS** (not quarter notes). Shape values: **shape=0 = gradual/linear ramp**, **shape=1 = square/instant**. This is the opposite of what the `linear` parameter in `SetTempoTimeSigMarker` suggests (`linear=true` corresponds to shape=0).
- **Lua 200 local variable limit:** Main chunk is at ~194 locals. Adding new top-level `local` variables is dangerous — consolidate into existing tables or use forward declarations (which move, not add, locals). For-loop control variables consume 3 internal slots.
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

Import multiple RPP recording session files into the same mix template. Each RPP gets its own region, with tempo/time-signature changes merged correctly. Item/region/marker positioning uses time-based offsets (seconds). Tempo envelope PT positions are in seconds.

### Architecture: Single-Pass with API Tempo

1. **API tempo** — `setTempoViaAPI()` uses `SetTempoTimeSigMarker` to write tempo markers with full shape fidelity (shape 0/1 maps perfectly to `linear` true/false). Tempo map is 100% final before any items enter the project.
2. **Import tracks** — for each template track, import all mapped RPP tracks, shift items + envelopes to correct time offsets, consolidate onto one master track
3. **Regions/markers** — created after track import, against the final tempo map

### RPP Queue

- `rppQueue[]` entries contain: path, name, rppText, tracks[], baseTempo (bpm/num/denom), tempoMap[] (all tempo points with `pt.pos` and `pt.time` in seconds), markers[], lengthInMeasures, lengthInQN, maxEndTime (seconds), measureOffset, qnOffset (for fallback buildMergedTempoSection only), timeOffset (seconds, primary for all positioning)
- `recalculateQueueOffsets()` computes `measureOffset` (for UI, using `rpp.lengthInMeasures`), `timeOffset` (seconds, for all item/region/marker/tempo positioning), and `qnOffset` (beats, for fallback `buildMergedTempoSection()` only). Time is accumulated from `maxEndTime` rounded up to measure boundary.
- Drag-and-drop reordering via ImGui `DragDropSource`/`DragDropTarget`
- JS_ReaScriptAPI multi-file dialog for loading multiple RPPs at once

### Tempo Handling

- `extractBaseTempo(rppText)` — parses `TEMPO <bpm> <num> <denom>` line
- `extractTempoMap(rppText)` — parses `TEMPO` line + `<TEMPOENVEX>` `PT` points; time signature encoded as `65536 * denom + num`
- `extractMarkersFromRpp(rppText)` — parses MARKER lines from .rpp; pairs region start+end markers (same idx) into single entries with `rgnend`
- `buildMergedTempoSection()` — FALLBACK: builds plaintext section (TEMPO line + TEMPOENVEX with all PT points offset by `timeOffset`). Only used if file-write fallback is triggered
- `applyTempoViaEnvelopeChunk()` — retained as code but NOT called in multi-RPP pipeline. Was previously used to apply tempo via `SetEnvelopeStateChunk`, but corrupted REAPER's internal beat positions. API markers now have full shape fidelity, making it unnecessary.
- `writeMultiRppTempoSection()` — FALLBACK: saves project, reads .rpp file, replaces TEMPO+TEMPOENVEX section while preserving existing MARKER lines, writes back, reloads. Only used if API tempo fails
- Gap between RPPs inherits the last tempo from the preceding RPP

### Time-Based Offset System

**Architecture:** Everything uses seconds. TEMPOENVEX PT positions are in seconds (not QN). Item/region/marker positioning uses `timeOffset` (seconds) directly. Tempo envelope PT positions are written as seconds directly (that's what REAPER expects).

**Per RPP at load:** `maxEndTime` = max(POSITION+LENGTH) in seconds. Each tempo map point's `pt.pos` IS already in seconds (from TEMPOENVEX PT). `pt.time = pt.pos` (simple assignment).

**`recalculateQueueOffsets()`** computes for each RPP:
- `timeOffset` = accumulated seconds (primary, for all positioning including tempo envelope)
- `measureOffset` = accumulated measures (for UI display, uses `rpp.lengthInMeasures`)
- `qnOffset` = accumulated beats (for fallback `buildMergedTempoSection()` only)
- Duration is rounded up to next measure boundary at base tempo before adding gap

**`setTempoViaAPI()`** sets markers using `rpp.timeOffset + pt.time` (time positions). Shape mapping: `linear = pt.shape == 0` (shape 0 = gradual = linear=true, shape 1 = square = linear=false).

**`applyTempoViaEnvelopeChunk()`** is retained as code but NOT called in the multi-RPP pipeline. It was previously used to apply tempo via `SetEnvelopeStateChunk`, but deleting API markers before chunk apply corrupted REAPER's internal beat positions (TIMELOCKMODE 2 issue). Since `setTempoViaAPI()` now maps shapes correctly, the envelope chunk is unnecessary.

**Shape values in TEMPOENVEX:**
- `shape=0` → gradual/linear ramp → API `linear=true`
- `shape=1` → square/instant → API `linear=false`

### Track Consolidation Pipeline (`commitMultiRpp()`)

```
1.  setTempoViaAPI() — set tempo markers using time positions (rpp.timeOffset + pt.time)
    Tempo map is now 100% final (API has full shape fidelity: shape 0/1 → linear true/false).
    applyTempoViaEnvelopeChunk() is NOT called — it corrupted REAPER's internal beat positions
    by deleting API markers before SetEnvelopeStateChunk (TIMELOCKMODE 2 issue).
2.  For each template track with mappings:
    a. For each RPP: sanitize chunk, fix media paths
    b. Shift POSITION + PT values in chunk text by rpp.timeOffset seconds (gsub before SetTrackStateChunk)
    c. Append POOLEDENV (after shifting — pooled envs use beat-based positions)
    d. SetTrackStateChunk (with return value check) + postprocessTrackCopyRelink
    e. Consolidate: move items + copy envelope points to first track
    e2. Align lanes: move all items to highest lane for visibility (gated on alignLanes setting)
    f. Copy FX/Sends/Groups from template track (includes GROUP_FLAGS via replaceGroupFlagsInChunk)
    g. Delete extra tracks + original template track
3. Delete unused template tracks (if enabled)
4. createMultiRppRegions() + importMultiRppMarkers() — regions/markers placed against final tempo map
5. Normalize per region (uses auto-created RPP regions)
6. Build peaks, minimize tracks
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

## Resolved Issues

**Fixed (v2.5): Multi-RPP spurious tempo markers from track envelope data (VOLENV2)**

- Root cause: `extractTempoMap()` used `rppText:find("\n>", envexStart)` to find the closing `>` of the `<TEMPOENVEX>` block. But RPP files indent the closing `>` with spaces (e.g., `  >`), so `\n>` (which requires `>` immediately after newline) never matched the real TEMPOENVEX closing tag. Instead, it matched the first unindented `>` in the file — typically the final `>` closing `<REAPER_PROJECT>` at the end. This caused the entire RPP (all tracks, all envelopes) to be parsed as part of TEMPOENVEX, extracting VOLENV2 PT values (volume multipliers like 1.0, 1.67, 0.22) as tempo points. These appeared as nonsensical 0-4 BPM tempo changes after the second RPP region.
- Fix: Changed closing tag pattern from `\n>` to `\n%s*>` to match indented closing tags. The `%s*` allows optional whitespace between newline and `>`, correctly matching RPP's indentation style.

**Fixed (v2.5): Multi-RPP offset system refactored from beat-based to time-based**

- Root cause: Beat-based offset system (`qnOffset` + `TimeMap2_beatsToTime`) had circular dependency — needed tempo map to convert beats→time, but was building the tempo map. API tempo markers disappeared during track import operations, causing `TimeMap2_beatsToTime` to return wrong values. Items shifted by 4355s instead of ~4643s (288s error).
- Fix: Complete refactor to time-based offsets. `maxEndTime` (seconds) computed from RPP items' POSITION+LENGTH. `timeOffset` accumulated in seconds (rounded up to measure boundary at base tempo + gap). Item/region/marker positioning uses `timeOffset` directly — no `TimeMap2_beatsToTime` calls. Tempo markers set via API using time positions (`SetTempoTimeSigMarker` with `timepos` parameter) with correct shape mapping (`linear = pt.shape == 0`). `qnOffset` retained only for fallback `buildMergedTempoSection()` path.

**Fixed (v2.5): Multi-RPP measures→QN lossy conversion + shape-ignoring time calculation**

- Root cause 1 (major): `recalculateQueueOffsets()` and `createMultiRppRegions()` converted `lengthInMeasures` back to QN via `lengthInMeasures * baseTempo.qnPerMeasure`, which assumes all measures have the base time signature. RPPs with internal time sig changes (e.g., 4/4 → 7/4) had wildly wrong QN offsets — e.g., Mels: 2257 measures * 4 QN = 9028 QN instead of correct ~13485 QN (4457 QN / ~1486s error at 180 BPM).
- Root cause 2 (minor): `calculateRppLengthInMeasures()` time calculation used constant-BPM formula for all segments, ignoring Shape 1 (linear ramp). Correct formula for linear ramp: `deltaTime = deltaQN * 60 * ln(bpm2/bpm1) / (bpm2 - bpm1)`. ~29s / ~72 QN error.
- Fix: `calculateRppLengthInMeasures()` now returns `(measures, totalQN)` — the exact total QN accounting for all time sig changes. Stored as `rpp.lengthInQN` in `loadRppToQueue()`. Used directly in `recalculateQueueOffsets()` and `createMultiRppRegions()` instead of lossy `measures * qnPerMeasure`. Shape-aware time integration added for linear ramps.

**Fixed (v2.5): Last tempo point shape causing unwanted transition between RPPs**

- Root cause: The last point's shape in a standalone RPP is irrelevant (REAPER ignores it). But in multi-RPP merge, the last point is no longer last — if its shape is 0 (gradual), it causes an unwanted tempo ramp to the next RPP's first tempo.
- Fix: `extractTempoMap()` now forces `shape=1` (square/instant) on the last point of every RPP, preventing unwanted transitions across RPP boundaries.

**Fixed (v2.5): extractTempoMap() multiline match + sanitizeChunk indent + SetTrackStateChunk check**

- `extractTempoMap()`: `rppText:match("<TEMPOENVEX.-\n>")` used Lua's `.-` which cannot match newlines. Fixed with `find/sub` extraction.
- `sanitizeChunk()`: Patterns like `\nAUXRECV.-\n` didn't match indented RPP lines. Fixed by adding `%s*` after `\n`.
- `commitMultiRpp()`: `SetTrackStateChunk` return value was not checked. Fixed with return value check and warning log.
- Diagnostic logging added: gsub replacement counts for POSITION and PT values.

**Fixed (v2.5): extractTempoMap() duplicate points at position 0**

- Root cause: `extractTempoMap()` always inserted a baseTempo point at pos=0 (from TEMPO line, with hardcoded shape=0 and timesig) AND then parsed all PT lines from TEMPOENVEX (including PT 0 with correct shape). This created duplicate points at position 0 for every RPP, with conflicting shape values and unnecessary timesig.
- In multi-RPP context, each RPP contributed 2 points at its offset position instead of 1, resulting in 8 points instead of 6 (for 2 RPPs), with phantom tempo changes and wrong item positions.
- Fix: baseTempo point is now only inserted as fallback when no TEMPOENVEX exists or when TEMPOENVEX has no point at pos 0. TEMPOENVEX PT lines are the authoritative source for shape values.

**Fixed (v2.5): PT line format bug in extractTempoMap() + project reload eliminated**

- Root cause: `extractTempoMap()` parsed TEMPOENVEX PT field 4 as "tension" but it is actually "timesig" (e.g., 262148 = 4/4). This caused time signature changes within an RPP to be lost, and `buildMergedTempoSection()` always wrote 4 fields (including spurious `0` tension) instead of 3 fields for points without time signature
- Fix: Removed tension from data model, field 4 now correctly parsed as optional timesig. PT lines output as 3 fields (pos/bpm/shape) or 4 fields (pos/bpm/shape/timesig)
- Project reload eliminated: Single-RPP uses `SetEnvelopeStateChunk` to copy source TEMPOENVEX directly (`importMarkersTempoPostCommit()`). Multi-RPP uses API markers only (`setTempoViaAPI()`) — envelope chunk is not needed since shape mapping is now correct.
- Undo now works correctly for marker/tempo import (entire operation in single Undo block)
- Multi-RPP retains `writeMultiRppTempoSection()` as fallback if `SetEnvelopeStateChunk` fails
- Bug fix: `setTempoViaAPI()` and `importMarkersTempoPostCommit()` had inverted `lineartempo` mapping. In TEMPOENVEX, shape=0 means gradual (linear=true in API) and shape=1 means square (linear=false). Fixed to `linear = pt.shape == 0`. Previously masked by plaintext overwrite+reload, exposed when switching to `SetEnvelopeStateChunk`.
- Bug fix: "Recalculation kick" (`SetTempoTimeSigMarker` re-set on marker 0) after `SetEnvelopeStateChunk` caused REAPER to rebuild envelope from internal markers, overriding the chunk. Removed; using `UpdateTimeline()` + `UpdateArrange()` instead.

**Fixed (v2.5): Multi-RPP marker/region duplication and wrong positions**

- Root cause 1: `extractMarkersFromRpp()` treated both region-start and region-end MARKER lines as separate entries, creating duplicate regions with `rgnend=0`
- Root cause 2: `buildMergedTempoSection()` wrote MARKER lines in wrong format (REAPER uses `MARKER idx pos "name" flags [0 colortype colorflag {GUID} 0]`, not `MARKER idx pos "name" isRegion rgnend color`)
- Root cause 3: `writeMultiRppTempoSection()` replaced everything between TEMPO and `<PROJBAY>`, deleting API-created MARKER lines
- RPP format insight: Regions use TWO MARKER lines (start with name + end without name, same index). MARKER lines come AFTER TEMPOENVEX, before `<PROJBAY>`. Flags field is a bitmask (bit 0 = isRegion). Region-end lines have shortened format: `MARKER idx pos "" flags`
- Fix: (1) `extractMarkersFromRpp()` now pairs region-end markers with start markers to set `rgnend`, skips end-markers from output. (2) `buildMergedTempoSection()` no longer writes MARKER lines — API-created markers are preserved. (3) `writeMultiRppTempoSection()` extracts and re-inserts MARKER lines when replacing TEMPO+TEMPOENVEX section

**Fixed (v2.5): TEMPOENVEX PT positions treated as QN instead of seconds + shape values inverted**

- Root cause 1 (critical): PT positions in TEMPOENVEX are in SECONDS, not quarter notes. Our code treated `pt.pos` as QN throughout — `calculateRppLengthInMeasures()` computed wrong durations (2247 vs 2714 measures for Mels), `loadRppToQueue()` had unnecessary time integration, `applyTempoViaEnvelopeChunk()` used `TimeMap2_timeToBeats` fullbeats instead of direct time, `buildMergedTempoSection()` used `qnOffset` instead of `timeOffset`.
- Root cause 2 (critical): Shape values are inverted from our assumption. shape=0 means GRADUAL/linear ramp (API `linear=true`), shape=1 means SQUARE/instant (API `linear=false`). Affected `setTempoViaAPI()`, `calculateRppLengthInMeasures()`, `applyTempoViaEnvelopeChunk()` fallback shape, `extractTempoMap()` last-point fix.
- Root cause 3: Regions and markers created BEFORE `applyTempoViaEnvelopeChunk()` were shifted by TIMELOCKMODE 2 (beat-locked) when the tempo map changed. Mels region showed 0-4350.97 instead of 0-4640.68.
- Evidence: REAPER API debug showed PT 830.27 = time=830.27s, fullbeats=2560 QN. Constant formula (shape=1): 830.27*185/60=2560 QN matches. Gradual formula (shape=0): matches for tempo ramp segments.
- Root cause 4: `applyTempoViaEnvelopeChunk()` deleted all API markers before `SetEnvelopeStateChunk`, causing beat-locked items (TIMELOCKMODE 2) to recalculate to default tempo during the gap between delete and re-set. Items shifted from 4646.92s to 4174.30s (~472s error). Additionally, the markers rebuilt from the envelope chunk had different internal beat positions than the original API markers, corrupting REAPER's measure calculations (e.g. 150 BPM marker at measure 2219 instead of 1921).
- Fix: (1) `calculateRppLengthInMeasures()` rewritten to integrate BPM over time (pt.pos=seconds), shape==0 for gradual. (2) `loadRppToQueue()` simplified: `pt.time = pt.pos`. (3) `applyTempoViaEnvelopeChunk()` writes timepos directly as PT position, fallback shape fixed to `lineartempo and 0 or 1`. (4) `setTempoViaAPI()` fixed to `linear = pt.shape == 0`. (5) `extractTempoMap()` forces shape=1 (square) on last point of every RPP. (6) `buildMergedTempoSection()` uses `timeOffset` instead of `qnOffset`. (7) `recalculateQueueOffsets()` uses `rpp.lengthInMeasures` for measure display. (8) `commitMultiRpp()` no longer calls `applyTempoViaEnvelopeChunk()` — API markers have full shape fidelity after fix (4), making the envelope chunk redundant and harmful. Regions/markers created after track import.

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
- v2.5 (Feb 2026): Multi-RPP Import — import multiple RPP files into same template, merged tempo/markers, time-based offsets (seconds), track consolidation, column-based UI, lane alignment, group flag copying, editable template track names

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
