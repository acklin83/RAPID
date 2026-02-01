# Mixnote ReaImGui Style Guide

Reusable dark theme design system for REAPER Lua/ReaImGui scripts, based on `mixnote_v2.lua`.

---

## Color Palette

All colors are 32-bit RGBA hex (`0xRRGGBBFF`). Reduce the alpha byte for transparency (e.g. `0x6366F140` = 25% opacity).

### Backgrounds (4-level hierarchy)

| Name        | Hex         | CSS equivalent | Usage                          |
|-------------|-------------|----------------|--------------------------------|
| `bg_body`   | `0x0F0F0FFF`| `#0f0f0f`      | Window background              |
| `bg_card`   | `0x1A1A1AFF`| `#1a1a1a`      | Cards, panels, popups          |
| `bg_input`  | `0x2A2A2AFF`| `#2a2a2a`      | Input fields, secondary buttons|
| `bg_border` | `0x3A3A3AFF`| `#3a3a3a`      | Borders, separators, hover     |

### Accent (Indigo)

| Name           | Hex         | Usage                     |
|----------------|-------------|---------------------------|
| `accent`       | `0x6366F1FF`| Primary buttons, active   |
| `accent_hover` | `0x5558E8FF`| Button hover              |
| `accent_active`| `0x4F46E5FF`| Button pressed            |
| `accent_dim`   | `0x6366F140`| Headers, subtle highlights|

### Text

| Name        | Hex         | CSS equivalent | Usage                   |
|-------------|-------------|----------------|-------------------------|
| `text`      | `0xE5E7EBFF`| `#e5e7eb`      | Primary text            |
| `text_dim`  | `0x9CA3AFFF`| `#9ca3af`      | Secondary text, metadata|
| `text_muted`| `0x6B7280FF`| `#6b7280`      | Disabled, placeholders  |

### Status Colors

| Name     | Hex         | CSS equivalent | Usage             |
|----------|-------------|----------------|-------------------|
| `green`  | `0x4ADE80FF`| `#4ade80`      | Success, resolved |
| `amber`  | `0xF59E0BFF`| `#f59e0b`      | Warning, open     |
| `red`    | `0xEF4444FF`| `#ef4444`      | Error, delete     |
| `yellow` | `0xFBBF24FF`| `#fbbf24`      | Highlight, badge  |

### Card Tints (semi-transparent overlays)

| Name          | Hex         | Usage                       |
|---------------|-------------|-----------------------------|
| `card_open`   | `0x1E233380`| Open/unresolved comment     |
| `card_solved` | `0x1A2A1A60`| Resolved comment (green)    |

---

## Theme Application

### Color Mappings (26 total)

```lua
local THEME_COLOR_COUNT = 26

local function apply_theme()
  local I = reaper.ImGui_Col_WindowBg
  -- Window
  reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_WindowBg(),       bg_body)
  reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_ChildBg(),        0x00000000)  -- transparent
  reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_PopupBg(),        bg_card)
  reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_Border(),         bg_border)
  -- Text
  reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_Text(),           text)
  reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_TextDisabled(),   text_muted)
  -- Frame (inputs, combos)
  reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_FrameBg(),        bg_input)
  reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_FrameBgHovered(), bg_border)
  reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_FrameBgActive(),  bg_border)
  -- Buttons
  reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_Button(),         accent)
  reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_ButtonHovered(),  accent_hover)
  reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_ButtonActive(),   accent_active)
  -- Headers (tree nodes, collapsing headers)
  reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_Header(),         accent_dim)
  reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_HeaderHovered(),  0x6366F160)
  reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_HeaderActive(),   0x6366F180)
  -- Tabs
  reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_Tab(),            bg_card)
  reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_TabHovered(),     accent)
  -- Scrollbar
  reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_ScrollbarBg(),    bg_body)
  reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_ScrollbarGrab(),  bg_border)
  reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_ScrollbarGrabHovered(), text_muted)
  reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_ScrollbarGrabActive(),  text_dim)
  -- Misc
  reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_Separator(),      bg_border)
  reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_CheckMark(),      accent)
  -- Title bar
  reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_TitleBg(),        bg_body)
  reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_TitleBgActive(),  bg_card)
  reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_TitleBgCollapsed(), bg_body)
end
```

### Style Variables (10 total)

```lua
local THEME_VAR_COUNT = 10

-- Inside apply_theme():
reaper.ImGui_PushStyleVar(ctx, reaper.ImGui_StyleVar_WindowPadding(),     12, 12)
reaper.ImGui_PushStyleVar(ctx, reaper.ImGui_StyleVar_FramePadding(),      8, 5)
reaper.ImGui_PushStyleVar(ctx, reaper.ImGui_StyleVar_ItemSpacing(),       8, 6)
reaper.ImGui_PushStyleVar(ctx, reaper.ImGui_StyleVar_FrameRounding(),     4)
reaper.ImGui_PushStyleVar(ctx, reaper.ImGui_StyleVar_WindowRounding(),    6)
reaper.ImGui_PushStyleVar(ctx, reaper.ImGui_StyleVar_ChildRounding(),     4)
reaper.ImGui_PushStyleVar(ctx, reaper.ImGui_StyleVar_PopupRounding(),     4)
reaper.ImGui_PushStyleVar(ctx, reaper.ImGui_StyleVar_ScrollbarRounding(), 4)
reaper.ImGui_PushStyleVar(ctx, reaper.ImGui_StyleVar_GrabRounding(),      4)
reaper.ImGui_PushStyleVar(ctx, reaper.ImGui_StyleVar_WindowBorderSize(),  0)
```

### Pop Theme

Always pop exactly the same count as pushed:

```lua
local function pop_theme()
  reaper.ImGui_PopStyleColor(ctx, THEME_COLOR_COUNT)
  reaper.ImGui_PopStyleVar(ctx, THEME_VAR_COUNT)
end
```

---

## Secondary Button Helper

For non-primary actions (Logout, Cancel, Delete, etc.), use muted button colors:

```lua
local function sec_button(label)
  reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_Button(),        bg_input)   -- 0x2A2A2AFF
  reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_ButtonHovered(), bg_border)  -- 0x3A3A3AFF
  reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_ButtonActive(),  text_muted) -- 0x6B7280FF
  local pressed = reaper.ImGui_SmallButton(ctx, label)
  reaper.ImGui_PopStyleColor(ctx, 3)
  return pressed
end
```

---

## Layout Patterns

### Right-Aligned Buttons

Use `Dummy` + `SameLine` with absolute positioning. Do **not** rely on `Dummy(width, 0) + SameLine()` — the implicit `ItemSpacing` offset causes misalignment.

```lua
-- Right-align a button within a card of width card_w
local btn_w = 48  -- measure or estimate button width
reaper.ImGui_Dummy(ctx, 1, 0)
reaper.ImGui_SameLine(ctx, card_w - 8 - btn_w)
if reaper.ImGui_SmallButton(ctx, "Reply") then ... end
```

The `- 8` accounts for the card's inner padding. Adjust to match your `WindowPadding` or `FramePadding`.

### Comment Cards with Background

Use `DrawList` rectangles behind `ChildWindow` content:

```lua
local draw_list = reaper.ImGui_GetWindowDrawList(ctx)
local cx, cy = reaper.ImGui_GetCursorScreenPos(ctx)
-- Draw card background
reaper.ImGui_DrawList_AddRectFilled(draw_list, cx, cy, cx + card_w, cy + card_h, bg_color, 6)
-- Draw left accent border (3px wide, colored by status)
reaper.ImGui_DrawList_AddRectFilled(draw_list, cx, cy, cx + 3, cy + card_h, accent_color, 6)
```

### Colored Text

```lua
reaper.ImGui_TextColored(ctx, C.green, "Resolved")
reaper.ImGui_TextColored(ctx, C.amber, "Open")
reaper.ImGui_TextColored(ctx, C.text_dim, "metadata text")
```

---

## Quick Start Template

Copy this into a new script to get the Mixnote theme:

```lua
-- Requires ReaImGui
local ctx = reaper.ImGui_CreateContext('My Script')

-- Paste the color table (C = { ... }) from above
-- Paste apply_theme() and pop_theme() from above
-- Paste sec_button() if needed

local function loop()
  apply_theme()
  local visible, open = reaper.ImGui_Begin(ctx, 'My Script', true)
  if visible then
    -- Your UI here
    reaper.ImGui_Text(ctx, "Hello Mixnote Style")
    reaper.ImGui_End(ctx)
  end
  pop_theme()
  if open then reaper.defer(loop) end
end

reaper.defer(loop)
```

---

## Design Principles

1. **4-level background hierarchy**: body → card → input → border. Each step is ~16 brightness units apart.
2. **Single accent color** (Indigo `#6366f1`) for all interactive elements.
3. **3-level text hierarchy**: primary → dim → muted. Never use pure white (`#ffffff`).
4. **Rounded corners everywhere**: 4px for small elements, 6px for windows/cards.
5. **No window borders**: `WindowBorderSize = 0`. Use background contrast instead.
6. **Status via color**: Green = good/resolved, Amber = open/warning, Red = error/delete.
