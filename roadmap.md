# RAPID Roadmap

---

## Priority 0: Drag & Drop File Import (v2.6)

Drag `.rpp` files and audio files (`.wav`, `.aif`, `.flac`, `.mp3`, etc.) directly from the OS file manager onto the RAPID main window to load them — no dialog needed. Subtle GUI hint communicates the feature without cluttering the interface.

### Technical Foundation

ReaImGui supports native OS file drops via `AcceptDragDropPayloadFiles` / `GetDragDropPayloadFile` inside a `BeginDragDropTarget` / `EndDragDropTarget` block on the main window. No JS_ReaScriptAPI dependency — works with base ReaImGui.

### 0.1 File Classification & Drop Handler

- [ ] Add `AUDIO_EXTENSIONS` lookup table (`wav`, `aif`, `aiff`, `mp3`, `flac`, `ogg`, `opus`, `wma`, `m4a`) in constants section (~line 100)
- [ ] Implement `classifyDroppedFile(path)` — returns `"rpp"`, `"audio"`, or `nil` based on extension
- [ ] Implement `handleDroppedFiles(files)` (~line 1743, after `clearRecList`):
  - Separate files into RPP list and audio list
  - **RPP handling:**
    - Multi-RPP mode active → `loadRppToQueue(path)` for each RPP
    - Single-RPP mode, 1 RPP → `loadRecRPP(path)`
    - Single-RPP mode, multiple RPPs → auto-switch to Multi-RPP, load all into queue
  - **Audio handling:** append to `recSources[]` as `{src="file", name=..., file=...}` (same as `loadRecFiles()`)
  - **Mixed drops (RPP + audio):** load RPPs first, then audio files
  - After loading: trigger `applyLastMap()` + auto-match (same post-load logic as existing buttons)
  - Unknown file types: silently ignored

### 0.2 Drop Target on Main Window

- [ ] Add drop target in `loop()` (after `drawUI_body()`, before `r.ImGui_End(ctx)`):
  ```lua
  if r.ImGui_BeginDragDropTarget(ctx) then
      local rv, count = r.ImGui_AcceptDragDropPayloadFiles(ctx)
      if rv then
          local files = {}
          for i = 0, count - 1 do
              local ok, fn = r.ImGui_GetDragDropPayloadFile(ctx, i)
              if ok then files[#files + 1] = fn end
          end
          if #files > 0 then handleDroppedFiles(files) end
      end
      r.ImGui_EndDragDropTarget(ctx)
  end
  ```
- [ ] Entire window acts as drop zone — no special child widget needed

### 0.3 Visual Drop Feedback (hover highlight)

- [ ] While files hover over window: draw subtle accent border via DrawList
  - `ImGui_DrawList_AddRect` with `theme.accent_dim`, 6px rounding, 2px thickness
  - Only visible during active drag — disappears on drop or leave

### 0.4 Subtle GUI Hints

Three low-key text hints in `theme.text_muted` that indicate drag & drop is available:

- [ ] **Single-RPP, no RPP loaded yet** (~line 6218): add `"or drag & drop .rpp / audio files here"` below toolbar
- [ ] **Multi-RPP, empty queue** (~line 6231): same hint text below the "Add .RPP" toolbar
- [ ] **Table placeholder** (~line 6994): change existing `"(load .RPP or files)"` to `"(load or drop .rpp / audio files)"`

### 0.5 Edge Cases

- [ ] Multiple RPPs dropped in single-RPP mode → auto-enable Multi-RPP, load all into queue
- [ ] Mixed RPP + audio drop → RPPs first, then audio
- [ ] Unknown extensions → silently skip
- [ ] REAPER running as admin on Windows → OS blocks drag & drop (known OS limitation, no fix possible)

### Implementation Notes

- **No new top-level `local` variables** — `AUDIO_EXTENSIONS` goes in constants block, functions are defined at function scope or consolidated into existing tables
- **~75 lines total** — minimal footprint
- **No JS_ReaScriptAPI dependency** — `AcceptDragDropPayloadFiles` is native ReaImGui
- **Lua 200 local limit safe** — all additions are either table entries or function-scope locals

---

## Priority 0 (DONE): Multi-RPP Import (v2.5)

~~Import multiple RPP recording session files into the same mix template with merged tempo, regions, and track consolidation.~~

- [x] RPP queue with drag-and-drop reordering
- [x] Tempo extraction: `extractBaseTempo()`, `extractTempoMap()`, `extractMarkersFromRpp()`
- [x] Measure-based offset calculation (`recalculateQueueOffsets()`)
- [x] Two-phase tempo: API for positioning + plaintext overwrite for full fidelity
- [x] Merged tempo section builder (`buildMergedTempoSection()`, `writeMultiRppTempoSection()`)
- [x] Track consolidation: import → shift items/envelopes → merge onto master track
- [x] Per-RPP region creation and marker import with offsets
- [x] Column-based UI with per-RPP dropdowns and horizontal scrolling
- [x] Per-column and all-columns auto-matching
- [x] Multi-RPP commit pipeline (`commitMultiRpp()`)
- [x] Normalization per region using auto-created RPP regions
- [x] JS_ReaScriptAPI multi-file dialog
- [x] INI persistence for multi-RPP settings

---

## Priority 0.5: LUFS Calibration System (DONE in v2.4)

~~Create and update normalization profiles by measuring manually-leveled reference tracks.~~

**Full specification:** See `LUFS-Calibration-Plan.md`

### 0.1 Architecture Changes
- [x] Remove global LUFS settings (`settings.lufsSegmentSize`, etc.)
- [x] Add `DEFAULT_LUFS_*` constants
- [x] Extend profile structure with optional measurement settings
- [x] Add `calibrationWindow` state

### 0.2 Measurement Functions
- [x] Implement `measureSelectedItemLoudness(segmentSize, percentile, threshold)`
- [x] Implement `getProfileLufsSettings(profile)` helper

### 0.3 Calibration Window
- [x] Implement `openCalibrationWindow()`
- [x] Implement `remeasureCalibration()`
- [x] Implement `drawCalibrationWindow()` (non-modal)
- [x] Implement `saveCalibrationToProfile()`

### 0.4 UI Integration
- [x] Add "Calibrate from Selection" button to Settings → Normalization tab
- [x] Remove LUFS settings sliders from Settings window
- [x] Add `drawCalibrationWindow()` call to main loop

### 0.5 Persistence
- [x] Update INI format: `Profile=Name,Offset,Peak[,SegSize,Pct,Thresh]`
- [x] Update `saveSharedNormalizationSettings()` for new format
- [x] Update `loadSharedNormalizationSettings()` with backwards compatibility

### 0.6 Normalization Update
- [x] Update normalization logic to use per-profile measurement settings
- [x] Fallback to defaults when profile has no settings

---

## Priority 1: Import Speed Optimization (DONE in v2.3.1)

~~Optimize the `commitMappings()` import pipeline for faster execution.~~

- [x] Cache `firstNew` chunk once before the per-duplicate loop
- [x] Remove redundant `UpdateArrange()` calls inside per-track normalization loops
- [x] Targeted peak building (only new items)
- [x] Deduplicate normalization lookup
- [x] Scope `sweepProjectCopyRelink` to new tracks only

---

# UI Redesign (MixnoteStyle)

Redesign of RAPID's UI based on the Mixnote ReaImGui Style Guide (`MixnoteStyle.md`).

---

## Goal

Replace RAPID's current default ImGui styling with the Mixnote dark theme design system. This gives RAPID a modern, consistent, professional look that matches the Mixnote visual language.

---

## Phase 1: Theme Integration

### 1.1 Add Color Palette & Theme Functions
- [ ] Add Mixnote color constants to RAPID.lua (bg_body, bg_card, bg_input, bg_border, accent, text hierarchy, status colors)
- [ ] Implement `apply_theme()` with all 26 color mappings
- [ ] Implement `pop_theme()` with matching pop counts
- [ ] Add 10 style variables (padding, rounding, spacing, border)

### 1.2 Apply Theme to Main Loop
- [ ] Wrap the existing draw loop with `apply_theme()` / `pop_theme()`
- [ ] Verify `THEME_COLOR_COUNT` and `THEME_VAR_COUNT` match push/pop counts exactly
- [ ] Test that all windows (main, settings, help) inherit the theme

---

## Phase 2: Component Restyling

### 2.1 Buttons
- [ ] Primary action buttons (Commit, Import, Normalize) use accent color (already via theme)
- [ ] Implement `sec_button()` helper for secondary actions (Cancel, Reset, Close)
- [ ] Replace all non-primary `SmallButton` / `Button` calls with `sec_button()` where appropriate

### 2.2 Track Mapping Table
- [ ] Table rows: use `bg_card` as row background
- [ ] Alternating rows: use `bg_card` / `bg_body` for visual separation
- [ ] Selected rows: accent_dim highlight
- [ ] Locked rows: subtle status color indicator (left border or tint)

### 2.3 Input Fields & Dropdowns
- [ ] FrameBg → `bg_input`, hover → `bg_border` (handled by theme)
- [ ] Verify combo boxes, text inputs, and sliders look correct with new colors

### 2.4 Headers & Separators
- [ ] Section headers: accent_dim background
- [ ] Separators: `bg_border` color
- [ ] Mode selection area (Import/Normalize checkboxes): visually distinct card-style panel

### 2.5 Settings & Help Windows
- [ ] Popup background → `bg_card`
- [ ] Tab styling: inactive = `bg_card`, hovered = accent
- [ ] Text hierarchy: primary labels = `text`, descriptions = `text_dim`, disabled = `text_muted`

---

## Phase 3: Layout Refinements

### 3.1 Spacing & Padding
- [ ] WindowPadding 12×12, FramePadding 8×5, ItemSpacing 8×6 (from style guide)
- [ ] Review all manual spacing/offsets for compatibility with new padding values

### 3.2 Rounded Corners
- [ ] 4px rounding on frames, children, popups, scrollbars, grabs
- [ ] 6px rounding on windows
- [ ] No window borders (`WindowBorderSize = 0`)

### 3.3 Right-Aligned Elements
- [ ] Review button alignment in toolbars — use Dummy+SameLine pattern from style guide
- [ ] Ensure Commit button and mode toggles are properly aligned

---

## Phase 4: Status & Feedback Colors

### 4.1 Track Status Indicators
- [ ] Matched tracks: `green` text or indicator
- [ ] Unmatched/missing tracks: `amber` or `red`
- [ ] Normalization complete: `green` checkmark
- [ ] Normalization error: `red` indicator

### 4.2 Profile Badges
- [ ] Normalize profile labels: colored with `text_dim` or subtle accent
- [ ] Auto-matched profiles: visual distinction from manual assignments

---

## Phase 5: Card-Based Layout (Optional / Future)

### 5.1 Track Cards
- [ ] Explore replacing flat table rows with card-style elements using DrawList rectangles
- [ ] Left accent border per card (3px, colored by match status)
- [ ] Card background tints for different states (open/resolved pattern from MixnoteStyle)

### 5.2 Dashboard Header
- [ ] Mode selection as styled card panel
- [ ] Source file info in a card with `bg_card` background
- [ ] Statistics (matched/unmatched count) with status colors

---

## Design Principles (from MixnoteStyle)

1. **4-level background hierarchy**: body → card → input → border (~16 brightness steps)
2. **Single accent color**: Indigo `#6366f1` for all interactive elements
3. **3-level text hierarchy**: primary → dim → muted (never pure white)
4. **Rounded corners everywhere**: 4px small, 6px windows
5. **No window borders**: contrast through background levels
6. **Status via color**: green = success, amber = warning, red = error

---

## Notes

- All changes happen inside `RAPID.lua` (monolithic script)
- Theme must be applied/popped symmetrically every frame
- Existing functionality must not be affected — this is purely visual
- Test in REAPER after each phase to verify no ImGui stack errors
