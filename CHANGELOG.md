# CHANGELOG

Version history for RAPID.

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
