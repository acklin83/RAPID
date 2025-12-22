# CHANGELOG

Version history for RAPID.

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
