# LUFS Calibration System — Implementation Plan

## Overview

A calibration system that allows users to create and update normalization profiles based on manually-leveled reference tracks.

**Use Case:** User has a perfectly leveled Snare track. They select it and tell RAPID: "Save this as the Snare profile." Future Snare tracks will be normalized to match the same loudness characteristics.

---

## Design Decisions

| Aspect | Decision |
|--------|----------|
| Measurement scope | Selected item only (not all items on track) |
| Offset rounding | Integer (rounded) |
| Profile modes | Update existing + Create new |
| UI location | Button in Settings → Normalization tab |
| Target Peak | Editable in dialog |
| Measurement Settings | Per-profile (not global) |
| Re-measure | Button in dialog when settings change |
| Peak/RMS profiles | Not calibratable (warning shown) |
| Dialog type | Non-modal window |

---

## Architecture Changes

### 1. Remove Global LUFS Settings

**Remove from state:**
- `settings.lufsSegmentSize`
- `settings.lufsPercentile`
- `settings.lufsSegmentThreshold`

**Remove from Settings UI:**
- Segment Size slider
- Percentile slider
- Threshold slider

**Remove from INI:**
- `[LufsSettings]` section (ignore on load for backwards compatibility)

**Add constants for defaults:**
```lua
local DEFAULT_LUFS_SEGMENT_SIZE = 10.0
local DEFAULT_LUFS_PERCENTILE = 90
local DEFAULT_LUFS_THRESHOLD = -40.0
```

### 2. Extended Profile Structure

**Current:**
```lua
{
    name = "Kick",
    offset = 18,
    defaultPeak = -6
}
```

**New:**
```lua
{
    name = "Kick",
    offset = 18,
    defaultPeak = -6,
    -- NEW: Measurement settings (optional, nil = use defaults)
    lufsSegmentSize = 10.0,    -- 5-30 seconds
    lufsPercentile = 90,       -- 80-99%
    lufsThreshold = -40.0,     -- -60 to -20 dB
}
```

### 3. New State Variables

```lua
local calibrationWindow = {
    open = false,
    itemName = "",
    measuredPeak = 0,
    measuredLUFS = 0,
    calculatedOffset = 0,
    editablePeak = 0,
    -- Measurement settings (editable in dialog)
    segmentSize = DEFAULT_LUFS_SEGMENT_SIZE,
    percentile = DEFAULT_LUFS_PERCENTILE,
    threshold = DEFAULT_LUFS_THRESHOLD,
    -- Profile selection
    selectedProfileIdx = 0,  -- 0 = "Create new"
    newProfileName = "",
    errorMsg = "",
}
```

---

## New Functions

### 1. `measureSelectedItemLoudness(segmentSize, percentile, threshold)`

Measures Peak and LUFS of the currently selected item in REAPER.

```lua
local function measureSelectedItemLoudness(segmentSize, percentile, threshold)
    -- 1. Get selected item
    local item = reaper.GetSelectedMediaItem(0, 0)
    if not item then
        return nil, "No item selected"
    end

    -- 2. Get take and source
    local take = reaper.GetActiveTake(item)
    if not take then
        return nil, "Item has no active take"
    end

    local source = reaper.GetMediaItemTake_Source(take)
    if not source then
        return nil, "Could not get audio source"
    end

    -- 3. Item boundaries
    local itemLen = reaper.GetMediaItemInfo_Value(item, "D_LENGTH")
    local takeOffset = reaper.GetMediaItemTakeInfo_Value(take, "D_STARTOFFS")

    -- 4. Measure Peak (mode 0)
    local peakNorm = reaper.CalculateNormalization(source, 0, 0, takeOffset, takeOffset + itemLen)
    local peakDB = 20 * math.log(peakNorm, 10)

    -- 5. Measure LUFS using segment-based approach (existing calcIntegratedLUFS logic)
    local lufsDB = calcIntegratedLUFS(source, takeOffset, itemLen, segmentSize, percentile, threshold)

    -- 6. Account for item gain
    local itemGain = reaper.GetMediaItemInfo_Value(item, "D_VOL")
    local itemGainDB = 20 * math.log(itemGain, 10)
    peakDB = peakDB + itemGainDB
    lufsDB = lufsDB + itemGainDB

    -- 7. Account for take gain
    local takeGain = reaper.GetMediaItemTakeInfo_Value(take, "D_VOL")
    local takeGainDB = 20 * math.log(takeGain, 10)
    peakDB = peakDB + takeGainDB
    lufsDB = lufsDB + takeGainDB

    -- 8. Get item name
    local _, itemName = reaper.GetSetMediaItemTakeInfo_String(take, "P_NAME", "", false)
    if itemName == "" then
        itemName = "Unnamed Item"
    end

    return {
        name = itemName,
        peak = peakDB,
        lufs = lufsDB,
        offset = math.floor(peakDB - lufsDB + 0.5)
    }, nil
end
```

### 2. `openCalibrationWindow()`

Opens the calibration dialog and performs initial measurement.

```lua
local function openCalibrationWindow()
    -- Initialize with defaults
    calibrationWindow.segmentSize = DEFAULT_LUFS_SEGMENT_SIZE
    calibrationWindow.percentile = DEFAULT_LUFS_PERCENTILE
    calibrationWindow.threshold = DEFAULT_LUFS_THRESHOLD
    calibrationWindow.selectedProfileIdx = 0
    calibrationWindow.newProfileName = ""
    calibrationWindow.errorMsg = ""

    -- Measure
    local result, err = measureSelectedItemLoudness(
        calibrationWindow.segmentSize,
        calibrationWindow.percentile,
        calibrationWindow.threshold
    )

    if not result then
        calibrationWindow.open = true
        calibrationWindow.errorMsg = err
        return
    end

    calibrationWindow.open = true
    calibrationWindow.itemName = result.name
    calibrationWindow.measuredPeak = result.peak
    calibrationWindow.measuredLUFS = result.lufs
    calibrationWindow.calculatedOffset = result.offset
    calibrationWindow.editablePeak = math.floor(result.peak + 0.5)
end
```

### 3. `remeasureCalibration()`

Re-measures with updated settings.

```lua
local function remeasureCalibration()
    local result, err = measureSelectedItemLoudness(
        calibrationWindow.segmentSize,
        calibrationWindow.percentile,
        calibrationWindow.threshold
    )

    if not result then
        calibrationWindow.errorMsg = err
        return
    end

    calibrationWindow.errorMsg = ""
    calibrationWindow.measuredPeak = result.peak
    calibrationWindow.measuredLUFS = result.lufs
    -- Recalculate offset based on editable peak
    calibrationWindow.calculatedOffset = math.floor(calibrationWindow.editablePeak - result.lufs + 0.5)
end
```

### 4. `saveCalibrationToProfile()`

Saves or updates the profile.

```lua
local function saveCalibrationToProfile()
    local offset = calibrationWindow.calculatedOffset
    local peak = calibrationWindow.editablePeak

    if calibrationWindow.selectedProfileIdx > 0 then
        -- Update existing profile
        local profile = normProfiles[calibrationWindow.selectedProfileIdx]
        profile.offset = offset
        profile.defaultPeak = peak
        profile.lufsSegmentSize = calibrationWindow.segmentSize
        profile.lufsPercentile = calibrationWindow.percentile
        profile.lufsThreshold = calibrationWindow.threshold
    else
        -- Create new profile
        local newName = calibrationWindow.newProfileName:match("^%s*(.-)%s*$")  -- trim
        table.insert(normProfiles, {
            name = newName,
            offset = offset,
            defaultPeak = peak,
            lufsSegmentSize = calibrationWindow.segmentSize,
            lufsPercentile = calibrationWindow.percentile,
            lufsThreshold = calibrationWindow.threshold,
        })
    end

    -- Save to INI
    saveSharedNormalizationSettings()
end
```

### 5. `drawCalibrationWindow()`

Renders the calibration dialog.

```lua
local function drawCalibrationWindow()
    if not calibrationWindow.open then return end

    local windowFlags = r.ImGui_WindowFlags_AlwaysAutoResize()
    r.ImGui_SetNextWindowPos(ctx, 400, 300, r.ImGui_Cond_FirstUseEver())

    local visible, open = r.ImGui_Begin(ctx, "Calibrate Profile", true, windowFlags)

    if visible then
        -- Error State
        if calibrationWindow.errorMsg ~= "" then
            r.ImGui_TextColored(ctx, 0xFF6666FF, calibrationWindow.errorMsg)
            r.ImGui_Spacing(ctx)
            if r.ImGui_Button(ctx, "Close") then
                calibrationWindow.open = false
            end
            r.ImGui_End(ctx)
            return
        end

        -- Item Info
        r.ImGui_Text(ctx, "Selected Item:")
        r.ImGui_SameLine(ctx)
        r.ImGui_TextColored(ctx, 0x66FF66FF, calibrationWindow.itemName)

        r.ImGui_Separator(ctx)
        r.ImGui_Spacing(ctx)

        -- Measured Values (read-only display)
        r.ImGui_Text(ctx, "Measured Values:")
        r.ImGui_Text(ctx, string.format("  Peak:  %.1f dB", calibrationWindow.measuredPeak))
        r.ImGui_Text(ctx, string.format("  LUFS:  %.1f dB", calibrationWindow.measuredLUFS))

        r.ImGui_Spacing(ctx)
        r.ImGui_Separator(ctx)
        r.ImGui_Spacing(ctx)

        -- Editable Target Peak
        r.ImGui_Text(ctx, "Target Peak (dB):")
        r.ImGui_SetNextItemWidth(ctx, 80)
        local changed, newPeak = r.ImGui_InputInt(ctx, "##targetpeak", calibrationWindow.editablePeak)
        if changed then
            calibrationWindow.editablePeak = newPeak
            calibrationWindow.calculatedOffset = math.floor(newPeak - calibrationWindow.measuredLUFS + 0.5)
        end

        r.ImGui_SameLine(ctx)
        r.ImGui_TextDisabled(ctx, string.format("(Offset: %d dB)", calibrationWindow.calculatedOffset))

        r.ImGui_Spacing(ctx)
        r.ImGui_Separator(ctx)
        r.ImGui_Spacing(ctx)

        -- Measurement Settings Section
        r.ImGui_Text(ctx, "Measurement Settings:")
        r.ImGui_Spacing(ctx)

        -- Segment Size
        r.ImGui_SetNextItemWidth(ctx, 120)
        local changed1, newSeg = r.ImGui_SliderDouble(ctx, "Segment Size (s)", calibrationWindow.segmentSize, 5.0, 30.0, "%.1f")
        if changed1 then calibrationWindow.segmentSize = newSeg end

        -- Percentile
        r.ImGui_SetNextItemWidth(ctx, 120)
        local changed2, newPct = r.ImGui_SliderInt(ctx, "Percentile (%)", calibrationWindow.percentile, 80, 99)
        if changed2 then calibrationWindow.percentile = newPct end

        -- Threshold
        r.ImGui_SetNextItemWidth(ctx, 120)
        local changed3, newThr = r.ImGui_SliderDouble(ctx, "Threshold (dB)", calibrationWindow.threshold, -60.0, -20.0, "%.0f")
        if changed3 then calibrationWindow.threshold = newThr end

        -- Re-measure button
        r.ImGui_Spacing(ctx)
        if r.ImGui_Button(ctx, "Re-measure") then
            remeasureCalibration()
        end

        r.ImGui_Spacing(ctx)
        r.ImGui_Separator(ctx)
        r.ImGui_Spacing(ctx)

        -- Profile Selection
        r.ImGui_Text(ctx, "Save to Profile:")

        -- Build dropdown items: "Create new..." + existing profiles (excluding Peak/RMS)
        r.ImGui_SetNextItemWidth(ctx, 200)
        local items = "Create new..."
        local profileIndices = {0}  -- Maps combo index to normProfiles index
        for i, p in ipairs(normProfiles) do
            if p.name ~= "Peak" and p.name ~= "RMS" then
                items = items .. "\0" .. p.name
                table.insert(profileIndices, i)
            end
        end

        local changed, newIdx = r.ImGui_Combo(ctx, "##profileselect", calibrationWindow.selectedProfileIdx, items)
        if changed then
            calibrationWindow.selectedProfileIdx = newIdx
            if newIdx > 0 and profileIndices[newIdx + 1] then
                local profile = normProfiles[profileIndices[newIdx + 1]]
                calibrationWindow.newProfileName = profile.name
                -- Load profile's measurement settings if available
                if profile.lufsSegmentSize then
                    calibrationWindow.segmentSize = profile.lufsSegmentSize
                    calibrationWindow.percentile = profile.lufsPercentile
                    calibrationWindow.threshold = profile.lufsThreshold
                end
            else
                calibrationWindow.newProfileName = ""
            end
        end

        -- New profile name input (only if "Create new" selected)
        if calibrationWindow.selectedProfileIdx == 0 then
            r.ImGui_SetNextItemWidth(ctx, 200)
            local changed, newName = r.ImGui_InputText(ctx, "##newprofilename", calibrationWindow.newProfileName)
            if changed then
                calibrationWindow.newProfileName = newName
            end
        end

        r.ImGui_Spacing(ctx)
        r.ImGui_Spacing(ctx)

        -- Buttons
        local canSave = calibrationWindow.selectedProfileIdx > 0 or
                        (calibrationWindow.newProfileName ~= "" and calibrationWindow.newProfileName:match("%S"))

        if not canSave then
            r.ImGui_BeginDisabled(ctx)
        end

        if r.ImGui_Button(ctx, "Save Profile") then
            saveCalibrationToProfile()
            calibrationWindow.open = false
        end

        if not canSave then
            r.ImGui_EndDisabled(ctx)
        end

        r.ImGui_SameLine(ctx)

        if sec_button("Cancel") then
            calibrationWindow.open = false
        end
    end

    if not open then
        calibrationWindow.open = false
    end

    r.ImGui_End(ctx)
end
```

---

## INI Format Changes

### Profile Storage (Updated)

```ini
[Profiles]
Count=10
Profile1=Peak,0,-6
Profile2=RMS,0,-12
Profile3=Kick,18,-6,10.0,90,-40.0
Profile4=Snare,18,-6,8.0,85,-35.0
```

**Format:** `Name,Offset,DefaultPeak[,SegmentSize,Percentile,Threshold]`

- Last 3 fields are optional (backwards compatible)
- If missing, use `DEFAULT_LUFS_*` constants

### Remove `[LufsSettings]` Section

- On load: ignore this section (backwards compatible)
- On save: don't write this section

---

## UI Integration

### Settings Window (Normalization Tab)

**Add button after existing buttons:**

```lua
-- Existing
if r.ImGui_Button(ctx, "+ Add Profile") then ... end
r.ImGui_SameLine(ctx)
if sec_button("Reset to Defaults") then ... end
r.ImGui_SameLine(ctx)
if r.ImGui_Button(ctx, "Save") then ... end

-- NEW
r.ImGui_SameLine(ctx)
if r.ImGui_Button(ctx, "Calibrate from Selection") then
    openCalibrationWindow()
end
```

**Remove LUFS Settings sliders** (entire section at bottom of Normalization tab)

### Main Loop

**Add after `drawSettingsWindow()`:**

```lua
drawCalibrationWindow()
```

---

## Normalization Logic Update

When normalizing a track, use profile-specific settings or defaults:

```lua
local function getProfileLufsSettings(profile)
    if profile and profile.lufsSegmentSize then
        return profile.lufsSegmentSize, profile.lufsPercentile, profile.lufsThreshold
    end
    return DEFAULT_LUFS_SEGMENT_SIZE, DEFAULT_LUFS_PERCENTILE, DEFAULT_LUFS_THRESHOLD
end
```

Update `calcIntegratedLUFS` calls to use these settings.

---

## Summary of Changes

| Component | Action |
|-----------|--------|
| State: `settings.lufs*` | Remove |
| State: `calibrationWindow` | Add |
| Constants: `DEFAULT_LUFS_*` | Add |
| Profile structure | Extend with 3 optional fields |
| `measureSelectedItemLoudness()` | Add |
| `openCalibrationWindow()` | Add |
| `remeasureCalibration()` | Add |
| `saveCalibrationToProfile()` | Add |
| `drawCalibrationWindow()` | Add |
| `getProfileLufsSettings()` | Add |
| Settings UI: LUFS sliders | Remove |
| Settings UI: Calibrate button | Add |
| Main loop | Add `drawCalibrationWindow()` call |
| INI save/load | Update profile format |
| Normalization | Use per-profile settings |

**Estimated: ~250 new lines, ~50 removed lines**

---

## Version

This feature is planned for **RAPID v2.4**.
