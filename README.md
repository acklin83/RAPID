# RAPID v2.6.2 - Recording Auto-Placement & Intelligent Dynamics

A professional workflow tool for REAPER that combines automated track mapping with intelligent LUFS-based normalization.

---

## THREE WORKFLOWS IN ONE

**1. IMPORT MODE (Single RPP)**
- Map recording tracks to your mix template
- Preserves all FX, sends, routing, automation
- Perfect for recurring workflows (podcasts, live recordings, etc.)

**2. MULTI-RPP IMPORT**
- Import multiple RPP session files into the same template
- Automatic regions, merged tempo/markers, configurable gap
- Drag-and-drop reorder, column-based mapping UI

**3. NORMALIZE MODE**
- Standalone LUFS normalization for existing tracks
- No import needed - works on current project
- Quick loudness standardization

**4. IMPORT + NORMALIZE (Full Workflow)**
- Complete automation: import, map, and normalize
- One-click solution for production workflows
- Professional gain staging in seconds

---

## MODE SELECTION

At the top of the window, you'll find two checkboxes:

- ☑ Import ☑ Normalize → Full RAPID workflow
- ☑ Import ☐ Normalize → Import & mapping only
- ☐ Import ☑ Normalize → Normalize-only mode

(At least one mode must be active)

Your mode selection is saved and restored automatically.

---

## KEY FEATURES

**Intelligent Track Matching**
- Fuzzy matching handles typos and variations
- Custom aliases for your workflow
- Exact, contains, and similarity-based matching

**Drag & Drop Import (NEW in v2.6)**
- Drag `.rpp` and audio files from OS file manager onto the RAPID window
- Auto-classification: `.rpp` → import, audio → add as sources
- Multiple `.rpp` files auto-switch to Multi-RPP mode
- Auto-matching triggers after drop

**Multi-RPP Import**
- Import multiple RPP files into one template project
- Automatic regions per RPP (named from filename)
- Full tempo/time-signature merging (time-based)
- Configurable gap between RPPs (in measures)
- Drag-and-drop queue reordering
- Column-based mapping with per-RPP dropdowns

**LUFS-Based Normalization**
- Instrument-specific profiles (Kick, Snare, Bass, etc.)
- Segment-based measurement with percentile filtering
- Threshold to ignore silent sections
- Calibration System - Create profiles from reference tracks

**Workflow Efficiency**
- Multi-select rows for batch editing
- Drag-to-toggle checkboxes (paint mode)
- Click column headers to toggle all
- Protected tracks (lock feature)

**Professional Tools**
- Process per region (multi-song sessions)
- Create on new Fixed Item Lane (A/B comparison)
- Delete gaps between regions
- Copy or keep source FX

---

## GETTING STARTED

See the built-in Help window (Help button in RAPID) for:
- **Import Mode** tab - Detailed import workflow
- **Normalize Mode** tab - Normalization workflow  
- **Normalization** tab - LUFS profile system details
- **Tips & Tricks** tab - Advanced features
- **Changelog** tab - Version history

---

## REQUIREMENTS

**Essential:**
- REAPER 6.0 or later
- ReaImGui extension (install via ReaPack)

**Recommended:**
- SWS Extension (for full functionality)
- JS_ReaScriptAPI (for multi-file import and multi-RPP file dialog)

---

## INSTALLATION

1. Download `RAPID.lua` from Releases
2. Copy to your REAPER Scripts folder:
   - Windows: `%APPDATA%\REAPER\Scripts\`
   - macOS: `~/Library/Application Support/REAPER/Scripts/`
   - Linux: `~/.config/REAPER/Scripts/`
3. In REAPER: Actions → Show action list → Load ReaScript
4. Select `RAPID.lua`

---

## VERSION

Current Version: **2.6.2**
Last Updated: February 2026

---

## CREDITS

Developed by Frank  
REAPER Lua scripting  
ReaImGui interface  
SWS Extension integration

Special thanks to the REAPER community for feedback and testing.

---

## SUPPORT

For support or feature requests, check the REAPER forums.

---

## LICENSE

MIT License - See LICENSE file for details
