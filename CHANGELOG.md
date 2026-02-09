# CHANGELOG

Version history for RAPID.

---

## v2.6 (February 2026)

**Drag & Drop File Import:**
- Drag `.rpp` and audio files directly from OS file manager onto the RAPID window
- Auto-classification by extension: `.rpp` files go to import, audio files (`.wav`, `.aif`, `.mp3`, `.flac`, etc.) added as sources
- Multiple `.rpp` files in a single drop auto-switch to Multi-RPP mode and load into queue
- Visual hover feedback with indigo accent border during drag
- No JS_ReaScriptAPI dependency — uses native ReaImGui `AcceptDragDropPayloadFiles`

**Auto-Match Improvements:**
- Auto-matching triggers automatically after import/drop (both single and multi-RPP)
- Fixed: multi-RPP auto-matching after import was incorrectly calling single-RPP matcher

**Architecture:**
- Drop handler logic inline in `loop()` to avoid Lua 200 local variable limit
- `AUDIO_EXTENSIONS` table constant for file type classification
- Entire main window wrapped in `BeginChild("##dropzone")` as drop target

---

## v2.5 (February 2026)

**Multi-RPP Import:**
- Import multiple RPP files into the same mix template
- Drag-and-drop reordering of RPP queue
- Per-RPP regions created automatically (named from filename)
- Tempo/time-signature changes merged from all RPPs (full fidelity via plaintext import)
- Markers imported with correct measure offsets
- Configurable gap between RPPs (in measures, default: 2)
- JS_ReaScriptAPI multi-file dialog support for loading multiple RPPs at once

**Multi-RPP Track Handling:**
- Column-based UI: one dropdown column per loaded RPP, horizontal scrolling for many RPPs
- Per-column and all-columns auto-matching
- Track consolidation: import all RPP tracks → shift items + envelopes to measure offset → merge onto single master track
- FX/Sends/routing copied from template to consolidated tracks
- Normalization per region uses auto-created RPP regions

**Architecture:**
- Two-phase tempo: API tempo for positioning, plaintext overwrite for full fidelity (API loses Shape/Tension)
- All calculations measure-based (not time-based — time is unreliable with changing tempos)
- `commitMultiRpp()` pipeline: API tempo → regions → markers → track import/shift/consolidate → normalize → plaintext tempo → reload
- New state: `multiRppMode`, `rppQueue`, `multiMap`, `multiNormMap`, `multiRppSettings`
- ~1,300 new lines of code

---

## v2.4 (February 2026)

**LUFS Calibration System:**
- New "Calibrate from Selection" button in Settings → Normalization tab
- Select a perfectly leveled item in REAPER, click to measure Peak + LUFS
- Create new profiles or update existing ones from reference tracks
- Per-profile LUFS measurement settings (segment size, percentile, threshold)
- Calibration window with editable target peak and re-measure functionality

**Normalization Improvements:**
- Calibration now correctly accounts for both Item Gain and Take Volume when measuring
- Normalization resets both Item Gain and Take Volume to 0dB before processing
- All normalization applied via Take Volume only (cleaner gain staging)
- Peak/RMS measurement uses AudioAccessor for accurate item-level measurement

**Bug Fixes:**
- Fixed mode switching: tracks now properly reload when toggling Import/Normalize checkboxes

**Architecture Changes:**
- LUFS settings moved from global to per-profile storage
- Extended INI profile format: `Name,Offset,Peak[,SegSize,Pct,Threshold]`
- Removed global LUFS sliders from Settings UI (now profile-specific)
- Backwards compatible: profiles without custom settings use defaults (10s, 90%, -40dB)

---

## v2.3.1 (February 2026)

**Performance:**
- Cached `GetTrackStateChunk` in duplicate loop (eliminates 2×(N-1) serializations per mapped track)
- Removed 7 redundant `UpdateArrange()` calls inside normalization loops (already within `PreventUIRefresh`)
- Wrapped post-commit minimize-all-tracks loop in `PreventUIRefresh` block
- Peak building now targets only newly created tracks instead of scanning entire project
- Pre-computed normalization lookup table (single O(N×M) pass instead of two)
- Media copy/relink sweep scoped to newly created tracks instead of all project items

---

## v2.3 (February 2026)

**New Features:**
- Editable template track names (double-click to rename)
- Duplicate slot renaming (independent from original track)
- Duplicate slots inherit normalization settings automatically
- Delete unused toggle (single checkbox replaces radio buttons)
- Unused tracks hidden when "Delete unused" is active
- Improved media path resolution for imported RPP files
- Offline media auto-relinking via progressive path suffix matching

**UI Improvements:**
- MixnoteStyle dark theme refinements
- Separate color swatch and lock columns with lock icon header
- Consistent button styling (sec_button for all secondary actions)
- Right-aligned Commit/Close buttons
- Renamed options: "Import to new lane", "Normalize per region"
- Removed obsolete buttons (Reload Mix Targets, Clear list, Show all RPP tracks)
- Removed bulk action row (use multi-select instead)
- Rewritten help text (removed broken characters, documented all v2.3 features)

**Bug Fixes:**
- Fixed offline media items when importing RPP tracks from different locations
- Fixed duplicate slot deletion losing original track assignment
- Fixed folder visibility logic in delete unused mode
- Fixed slot name override on commit for duplicated tracks

---

## v2.2 (February 2026)

- MixnoteStyle dark theme (26 color + 10 style variable pushes)
- Compact UI layout
- sec_button() helper for secondary action buttons
- Visual refinements throughout

---

## v2.1 (November 27, 2025)

**Auto-Duplicate Feature:**
- Automatically creates duplicate template tracks when multiple recording sources match to the same template track
- Multi-slot mapping with independent Keep Name/FX settings per slot
- Track naming: "Track 2" instead of "Track (2)"

**Improvements:**
- Improved group copying reliability
- Better FX preservation options per slot
- Streamlined UI layout
- Group flags properly copied to duplicate tracks
- FX copying works reliably via native API
- Lane creation and activation stability improvements

---

## v2.0-dev261125c (November 26, 2025)

**MAJOR UPDATE - Unified Workflow:**
- Merged RAPID and standalone normalization into one script
- Mode Selection system (Import + Normalize checkboxes)
- Three workflows in one tool
- Conditional UI based on active modes

**New Features:**
- Normalize-Only Mode (full standalone normalization)
- Mode persistence (saves/restores your preference)
- Clickable column headers (toggle all)
- Drag-to-toggle for all checkboxes (paint mode)
- Lock column (protected tracks)
- Multi-select batch editing
- Separate drag states per checkbox type

**Code Quality:**
- Removed 668 lines of obsolete code
- Streamlined from 8076 total lines to 5900 lines (29% reduction)
- Unified configuration system
- Better separation of concerns

---

## v1.5-dev261125b (November 26, 2025)

- Multi-select system for batch row editing
- Drag-over-checkboxes selection (REAPER-style)
- Shift+Click range selection
- Separate Lock column with color swatch
- Keep FX per-slot functionality

---

## v1.5-dev261125 (November 25, 2025)

- Keep Source FX checkbox per slot
- Manual Marker/Region/Tempo import button
- Script auto-close after marker import
- Improved UI layout

---

## v1.5-dev251125 (November 25, 2025)

**MAJOR REFACTOR:**
- 60% code reduction (~5,096 to ~2,000 lines)
- 10x performance improvement (20s → 2s for 20 tracks)
- Complete code reorganization
- Optimized track operations

---

## v1.5-dev171125 (November 17, 2025)

- LUFS Segment Threshold feature
- Filters out quiet segments during measurement
- Prevents silence from affecting normalization
- Default: -40 LUFS threshold

---

## v1.5-dev161125 (November 16, 2025)

- Shared normalization configuration system
- Configurable LUFS settings
- Segment size (5-30s)
- Percentile (80-99%)
- Settings window with tabs

---

## v1.5 (November 2025)

- Fixed FX copying using native API (TrackFX_CopyToTrack)
- Reverted from chunk-based approach
- Reliable FX chain copying
- No bracket escaping issues

---

## v1.4 (November 2025)

- FAILED: Chunk-based FX copying approach
- Nested bracket issues
- Reverted in v1.5

---

## v1.3 (October 2025)

- Profile system introduced
- Auto-match profiles feature
- Instrument-specific LUFS offsets
- Profile aliases

---

## v1.2 (October 2025)

- LUFS normalization added
- Segment-based measurement
- Percentile filtering
- Integration with track mapping

---

## v1.1 (September 2025)

- Initial public release
- Basic track mapping
- Fuzzy matching
- Track aliases
- Template workflow

---

**Developed by Frank**
