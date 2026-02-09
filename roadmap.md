# RAPID Roadmap

**Current Version:** 2.6.1 (February 2026)

All planned features have been implemented. This file documents what was delivered.

---

## Completed

### v2.6.1 — Live Template Sync
- Auto-detect template track changes (add/remove/rename) during runtime
- Smart rebuild preserving all existing mappings via name-based matching
- Throttled fingerprint check (~2x/sec), negligible performance cost

### v2.6 — Drag & Drop File Import
- Drag `.rpp` and audio files from OS file manager onto main window
- Auto-classification by extension, visual hover feedback
- Multiple RPPs in single mode auto-switches to Multi-RPP
- Auto-match on drop

### v2.5 — Multi-RPP Import
- Import multiple RPP recording sessions into same mix template
- Merged tempo/time-signature with time-based offset system (seconds)
- Track consolidation, per-RPP regions, marker import
- Column-based UI with per-RPP dropdowns and horizontal scrolling
- API-based tempo import with full shape fidelity

### v2.4 — LUFS Calibration System
- Measure reference items to create/update normalization profiles
- Per-profile LUFS settings (segmentSize, percentile, threshold)
- Gain reset before normalization (Item Gain + Take Volume → 0 dB)

### v2.3.1 — Import Speed Optimization
- Cached chunk serialization, removed redundant `UpdateArrange()` calls
- Targeted peak building and media sweep to new tracks only

### v2.3 — Editable Track Names & UI Polish
- Double-click to rename template tracks inline
- Duplicate slot improvements, delete unused toggle
- Offline media fix, DrawList lock icon

### v2.2 — MixnoteStyle UI Redesign
- Dark theme with 26 color pushes + 10 style var pushes
- `apply_theme()` / `pop_theme()` system
- `sec_button()` helper for secondary actions
- Full component restyling (table, buttons, inputs, headers, settings/help)

### v2.1 — Auto-Duplicate
- Multi-slot mapping with automatic track duplication

### v2.0 — Unified Workflow
- Merged RAPID + Little Joe into single tool
- 29% line reduction

### v1.5 — Major Refactor
- 60% code reduction, 10x performance improvement

### v1.3 — Profile System
- Normalization profiles, auto-match

### v1.2 — LUFS Normalization
- Integrated LUFS-based normalization

### v1.1 — Initial Release (Sep 2025)
- Basic track mapping, fuzzy matching
