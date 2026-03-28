-- VCA Auto-Assigner v1.0
-- Scannt alle Tracks im Projekt und weist sie VCA Masters zu
-- basierend auf konfigurierbaren Name-Keyword-Regeln.
-- Requires: ReaImGui extension

local r = reaper

-- ===== Dependency Check =====
if not r.ImGui_CreateContext then
  r.ShowMessageBox("ReaImGui is required.\nInstall via ReaPack → Extensions.", "VCA Auto-Assigner", 0)
  return
end

-- ===== ExtState Keys =====
local EXT_SECTION = "VCA_AutoAssign"
local EXT_RULES   = "rules_v1"

-- ===== ImGui Context =====
local ctx = r.ImGui_CreateContext("VCA Auto-Assigner")
local FONT_SIZE = 14

-- ===== Theme (same as RAPID) =====
local theme = {
  COLOR_COUNT = 20,
  VAR_COUNT   = 6,
  bg_body   = 0x0F0F0FFF,
  bg_card   = 0x1A1A1AFF,
  bg_input  = 0x2A2A2AFF,
  bg_border = 0x3A3A3AFF,
  accent        = 0x6366F1FF,
  accent_hover  = 0x5558E8FF,
  accent_active = 0x4F46E5FF,
  accent_dim    = 0x6366F140,
  text       = 0xE5E7EBFF,
  text_dim   = 0x9CA3AFFF,
  text_muted = 0x6B7280FF,
  green  = 0x4ADE80FF,
  amber  = 0xF59E0BFF,
  red    = 0xEF4444FF,
}

local function pushTheme()
  r.ImGui_PushStyleColor(ctx, r.ImGui_Col_WindowBg(),        theme.bg_body)
  r.ImGui_PushStyleColor(ctx, r.ImGui_Col_ChildBg(),         0x00000000)
  r.ImGui_PushStyleColor(ctx, r.ImGui_Col_PopupBg(),         theme.bg_card)
  r.ImGui_PushStyleColor(ctx, r.ImGui_Col_Border(),          theme.bg_border)
  r.ImGui_PushStyleColor(ctx, r.ImGui_Col_Text(),            theme.text)
  r.ImGui_PushStyleColor(ctx, r.ImGui_Col_TextDisabled(),    theme.text_muted)
  r.ImGui_PushStyleColor(ctx, r.ImGui_Col_FrameBg(),         theme.bg_input)
  r.ImGui_PushStyleColor(ctx, r.ImGui_Col_FrameBgHovered(),  theme.bg_border)
  r.ImGui_PushStyleColor(ctx, r.ImGui_Col_FrameBgActive(),   theme.bg_border)
  r.ImGui_PushStyleColor(ctx, r.ImGui_Col_Button(),          theme.accent)
  r.ImGui_PushStyleColor(ctx, r.ImGui_Col_ButtonHovered(),   theme.accent_hover)
  r.ImGui_PushStyleColor(ctx, r.ImGui_Col_ButtonActive(),    theme.accent_active)
  r.ImGui_PushStyleColor(ctx, r.ImGui_Col_Header(),          theme.accent_dim)
  r.ImGui_PushStyleColor(ctx, r.ImGui_Col_HeaderHovered(),   0x6366F160)
  r.ImGui_PushStyleColor(ctx, r.ImGui_Col_Separator(),       theme.bg_border)
  r.ImGui_PushStyleColor(ctx, r.ImGui_Col_CheckMark(),       theme.accent)
  r.ImGui_PushStyleColor(ctx, r.ImGui_Col_TitleBg(),         theme.bg_body)
  r.ImGui_PushStyleColor(ctx, r.ImGui_Col_TitleBgActive(),   theme.bg_card)
  r.ImGui_PushStyleColor(ctx, r.ImGui_Col_ScrollbarBg(),     theme.bg_body)
  r.ImGui_PushStyleColor(ctx, r.ImGui_Col_ScrollbarGrab(),   theme.bg_border)
  r.ImGui_PushStyleVar(ctx, r.ImGui_StyleVar_WindowPadding(),   10, 10)
  r.ImGui_PushStyleVar(ctx, r.ImGui_StyleVar_FramePadding(),     6,  3)
  r.ImGui_PushStyleVar(ctx, r.ImGui_StyleVar_ItemSpacing(),      8,  5)
  r.ImGui_PushStyleVar(ctx, r.ImGui_StyleVar_FrameRounding(),    4)
  r.ImGui_PushStyleVar(ctx, r.ImGui_StyleVar_WindowRounding(),   6)
  r.ImGui_PushStyleVar(ctx, r.ImGui_StyleVar_GrabRounding(),     4)
end

local function popTheme()
  r.ImGui_PopStyleColor(ctx, theme.COLOR_COUNT)
  r.ImGui_PopStyleVar(ctx, theme.VAR_COUNT)
end

-- ===== State =====
-- rules: list of { master = "VCA_MASTER_NAME", keywords = "Kick, Snare, Tom" }
local rules = {}
local log_lines = {}
local preview_done = false
local win_open = true

-- ===== Persistence =====
local function serializeRules()
  local parts = {}
  for _, rule in ipairs(rules) do
    -- encode as "master|keywords" with ~ as row separator
    table.insert(parts, rule.master .. "|" .. rule.keywords)
  end
  return table.concat(parts, "~")
end

local function deserializeRules(raw)
  local result = {}
  if not raw or raw == "" then return result end
  for chunk in raw:gmatch("[^~]+") do
    local master, keywords = chunk:match("^(.+)|(.*)$")
    if master then
      table.insert(result, { master = master, keywords = keywords or "" })
    end
  end
  return result
end

local function saveRules()
  r.SetExtState(EXT_SECTION, EXT_RULES, serializeRules(), true)
end

local function loadRules()
  local raw = r.GetExtState(EXT_SECTION, EXT_RULES)
  rules = deserializeRules(raw)
  if #rules == 0 then
    -- Default-Regeln als Startpunkt
    rules = {
      { master = "DRUMS VCA",   keywords = "Kick, Snare, Tom, OH, Room, HH, Hat, Ride, Cymbal" },
      { master = "GUITARS VCA", keywords = "Gtr, Guitar, Rhy, Lead, Bass" },
      { master = "VOCALS VCA",  keywords = "Vox, Vocal, BG, BGV" },
    }
  end
end

-- ===== REAPER VCA API helpers =====
-- Track VCA master: GetSetTrackGroupMembership with VCA groups
-- Group 1 = VCA master group 1, etc.
-- Actually REAPER uses TrackFX or specific VCA functions
-- Real VCA assignment: reaper.SetTrackMIDINoteName is wrong
-- Correct: r.GetSetTrackGroupMembership(track, groupname, setmask, setvalue)
-- VCA leader = group "VOLUME_VCA_LEAD", VCA follower = "VOLUME_VCA_FOLLOW"
-- We need to find the group index of the master track and assign follower to same group

local function getTrackName(track)
  local _, name = r.GetTrackName(track)
  return name or ""
end

local function getAllTracks()
  local tracks = {}
  local n = r.CountTracks(0)
  for i = 0, n - 1 do
    local t = r.GetTrack(0, i)
    tracks[i+1] = { track = t, name = getTrackName(t) }
  end
  return tracks
end

-- Find free VCA group index (1-64) not yet used as LEAD
local function findFreeVCAGroup(usedGroups)
  for i = 1, 64 do
    if not usedGroups[i] then return i end
  end
  return nil
end

-- Get which VCA lead groups a track belongs to (returns set of group indices)
local function getVCALeadGroups(track)
  local groups = {}
  for i = 1, 64 do
    local mask = (1 << (i-1))
    -- high = groups 33-64, low = groups 1-32
    if i <= 32 then
      local _, lo = r.GetSetTrackGroupMembership(track, "VOLUME_VCA_LEAD", 0, 0)
      if lo and (lo & mask) ~= 0 then groups[i] = true end
    else
      local hi, _ = r.GetSetTrackGroupMembership(track, "VOLUME_VCA_LEAD", 0, 0)
      local bit = 1 << (i-33)
      if hi and (hi & bit) ~= 0 then groups[i] = true end
    end
  end
  return groups
end

-- Assign follower track to VCA group index
local function setVCAFollow(track, groupIndex)
  if groupIndex <= 32 then
    local mask = 1 << (groupIndex - 1)
    r.GetSetTrackGroupMembership(track, "VOLUME_VCA_FOLLOW", mask, mask)
    r.GetSetTrackGroupMembership(track, "MUTE_VCA_FOLLOW", mask, mask)
  else
    -- high word groups 33-64 not directly supported via single call in older REAPER
    -- Use GetSetTrackGroupMembershipHigh if available
    if r.GetSetTrackGroupMembershipHigh then
      local bit = 1 << (groupIndex - 33)
      r.GetSetTrackGroupMembershipHigh(track, "VOLUME_VCA_FOLLOW", bit, bit)
      r.GetSetTrackGroupMembershipHigh(track, "MUTE_VCA_FOLLOW", bit, bit)
    end
  end
end

-- Set track as VCA lead in group index
local function setVCALead(track, groupIndex)
  if groupIndex <= 32 then
    local mask = 1 << (groupIndex - 1)
    r.GetSetTrackGroupMembership(track, "VOLUME_VCA_LEAD", mask, mask)
  else
    if r.GetSetTrackGroupMembershipHigh then
      local bit = 1 << (groupIndex - 33)
      r.GetSetTrackGroupMembershipHigh(track, "VOLUME_VCA_LEAD", bit, bit)
    end
  end
end

-- Get existing VCA lead group for track (first found), nil if none
local function getExistingLeadGroup(track)
  for i = 1, 32 do
    local mask = 1 << (i - 1)
    local _, lo = r.GetSetTrackGroupMembership(track, "VOLUME_VCA_LEAD", 0, 0)
    if lo and (lo & mask) ~= 0 then return i end
  end
  if r.GetSetTrackGroupMembershipHigh then
    for i = 33, 64 do
      local bit = 1 << (i - 33)
      local hi = r.GetSetTrackGroupMembershipHigh(track, "VOLUME_VCA_LEAD", 0, 0)
      if hi and (hi & bit) ~= 0 then return i end
    end
  end
  return nil
end

-- Case-insensitive partial match
local function trackMatchesKeywords(trackName, keywordsStr)
  local name_lower = trackName:lower()
  for kw in keywordsStr:gmatch("[^,]+") do
    local kw_trimmed = kw:match("^%s*(.-)%s*$"):lower()
    if kw_trimmed ~= "" and name_lower:find(kw_trimmed, 1, true) then
      return true, kw_trimmed
    end
  end
  return false, nil
end

-- ===== Core Logic =====
local function runAssign(dry_run)
  log_lines = {}
  local tracks = getAllTracks()
  local assignments = {} -- { slave_track, master_name, keyword }
  local master_map = {} -- master_name -> { track, group_index }

  -- Pass 1: find master tracks
  for _, rule in ipairs(rules) do
    local master_name_lower = rule.master:lower():match("^%s*(.-)%s*$")
    for _, t in ipairs(tracks) do
      if t.name:lower():match("^%s*(.-)%s*$") == master_name_lower then
        local existing_group = getExistingLeadGroup(t.track)
        master_map[rule.master] = { track = t.track, name = t.name, group = existing_group }
        break
      end
    end
  end

  -- Assign VCA lead groups to masters that don't have one yet
  local used_groups = {}
  for _, m in pairs(master_map) do
    if m.group then used_groups[m.group] = true end
  end
  for _, rule in ipairs(rules) do
    local m = master_map[rule.master]
    if m and not m.group then
      local g = findFreeVCAGroup(used_groups)
      if g then
        m.group = g
        used_groups[g] = true
        if not dry_run then
          setVCALead(m.track, g)
        end
        table.insert(log_lines, { text = "VCA Lead: " .. m.name .. " → Group " .. g, color = theme.amber })
      else
        table.insert(log_lines, { text = "ERROR: No free VCA group for " .. m.name, color = theme.red })
      end
    elseif not m then
      table.insert(log_lines, { text = "NOT FOUND: Master track \"" .. rule.master .. "\"", color = theme.red })
    end
  end

  -- Pass 2: match slaves
  for _, rule in ipairs(rules) do
    local m = master_map[rule.master]
    if m and m.group then
      for _, t in ipairs(tracks) do
        -- Skip master itself
        if t.track ~= m.track then
          local matched, kw = trackMatchesKeywords(t.name, rule.keywords)
          if matched then
            table.insert(assignments, { slave = t.track, slave_name = t.name, master = rule.master, keyword = kw, group = m.group })
          end
        end
      end
    end
  end

  -- Apply / preview assignments
  local assigned_count = 0
  for _, a in ipairs(assignments) do
    local prefix = dry_run and "[Preview] " or ""
    table.insert(log_lines, { text = prefix .. a.slave_name .. " → " .. a.master .. " (kw: \"" .. a.keyword .. "\")", color = theme.green })
    if not dry_run then
      setVCAFollow(a.slave, a.group)
    end
    assigned_count = assigned_count + 1
  end

  if assigned_count == 0 then
    table.insert(log_lines, { text = "No matches found.", color = theme.text_muted })
  else
    local verb = dry_run and "Would assign" or "Assigned"
    table.insert(log_lines, { text = verb .. " " .. assigned_count .. " track(s).", color = theme.text })
  end

  if not dry_run then
    r.UpdateArrange()
    r.TrackList_AdjustWindows(false)
  end

  preview_done = true
end

-- ===== GUI State =====
local WIN_W, WIN_H = 600, 560
local delete_rule_idx = nil
local new_master_buf = ""
local new_keywords_buf = ""
-- Per-rule edit buffers (populated on first render)
local rule_bufs = {} -- rule_bufs[i] = { master = buf, keywords = buf }

local function ensureRuleBuffers()
  for i = 1, #rules do
    if not rule_bufs[i] then
      rule_bufs[i] = { master = rules[i].master, keywords = rules[i].keywords }
    end
  end
  -- trim excess
  while #rule_bufs > #rules do table.remove(rule_bufs) end
end

-- ===== Main Loop =====
local function loop()
  if not win_open then return end

  pushTheme()
  r.ImGui_SetNextWindowSize(ctx, WIN_W, WIN_H, r.ImGui_Cond_FirstUseEver())
  local visible, open = r.ImGui_Begin(ctx, "VCA Auto-Assigner v1.0", true,
    r.ImGui_WindowFlags_NoCollapse())
  win_open = open

  if visible then
    ensureRuleBuffers()

    -- ── Header info ──
    r.ImGui_TextDisabled(ctx, "Definiere VCA Masters und ihre Slave-Keywords.")
    r.ImGui_Spacing(ctx)
    r.ImGui_Separator(ctx)
    r.ImGui_Spacing(ctx)

    -- ── Rules Table ──
    r.ImGui_Text(ctx, "Regeln")
    r.ImGui_Spacing(ctx)

    local tbl_flags = r.ImGui_TableFlags_BordersInnerH() | r.ImGui_TableFlags_RowBg() | r.ImGui_TableFlags_SizingStretchProp()
    if r.ImGui_BeginTable(ctx, "rules_table", 3, tbl_flags) then
      r.ImGui_TableSetupColumn(ctx, "VCA Master",  r.ImGui_TableColumnFlags_WidthStretch(), 0.28)
      r.ImGui_TableSetupColumn(ctx, "Keywords (komma-getrennt)", r.ImGui_TableColumnFlags_WidthStretch(), 0.60)
      r.ImGui_TableSetupColumn(ctx, "",             r.ImGui_TableColumnFlags_WidthFixed(), 50)
      r.ImGui_TableHeadersRow(ctx)

      for i, rule in ipairs(rules) do
        r.ImGui_TableNextRow(ctx)
        r.ImGui_TableSetColumnIndex(ctx, 0)
        r.ImGui_SetNextItemWidth(ctx, -1)
        local changed_m, new_m = r.ImGui_InputText(ctx, "##master_"..i, rule_bufs[i].master, 128)
        if changed_m then
          rule_bufs[i].master = new_m
          rules[i].master = new_m
          saveRules()
        end

        r.ImGui_TableSetColumnIndex(ctx, 1)
        r.ImGui_SetNextItemWidth(ctx, -1)
        local changed_k, new_k = r.ImGui_InputText(ctx, "##kw_"..i, rule_bufs[i].keywords, 512)
        if changed_k then
          rule_bufs[i].keywords = new_k
          rules[i].keywords = new_k
          saveRules()
        end

        r.ImGui_TableSetColumnIndex(ctx, 2)
        r.ImGui_PushStyleColor(ctx, r.ImGui_Col_Button(), 0x7F1D1DFF)
        r.ImGui_PushStyleColor(ctx, r.ImGui_Col_ButtonHovered(), 0xB91C1CFF)
        if r.ImGui_SmallButton(ctx, "Del##"..i) then
          delete_rule_idx = i
        end
        r.ImGui_PopStyleColor(ctx, 2)
      end
      r.ImGui_EndTable(ctx)
    end

    -- Apply deletion
    if delete_rule_idx then
      table.remove(rules, delete_rule_idx)
      table.remove(rule_bufs, delete_rule_idx)
      delete_rule_idx = nil
      preview_done = false
      log_lines = {}
      saveRules()
    end

    r.ImGui_Spacing(ctx)

    -- ── Add new rule ──
    r.ImGui_PushStyleColor(ctx, r.ImGui_Col_ChildBg(), theme.bg_card)
    if r.ImGui_BeginChild(ctx, "add_rule", 0, 62, true) then
      r.ImGui_Text(ctx, "Neue Regel hinzufügen:")
      r.ImGui_Spacing(ctx)
      r.ImGui_SetNextItemWidth(ctx, 160)
      local _, nm = r.ImGui_InputText(ctx, "##new_master", new_master_buf, 128)
      new_master_buf = nm
      r.ImGui_SameLine(ctx)
      r.ImGui_SetNextItemWidth(ctx, -80)
      local _, nk = r.ImGui_InputText(ctx, "##new_kw", new_keywords_buf, 512)
      new_keywords_buf = nk
      r.ImGui_SameLine(ctx)
      if r.ImGui_Button(ctx, "+ Regel") then
        local m = new_master_buf:match("^%s*(.-)%s*$")
        if m ~= "" then
          table.insert(rules, { master = m, keywords = new_keywords_buf })
          table.insert(rule_bufs, { master = m, keywords = new_keywords_buf })
          new_master_buf = ""
          new_keywords_buf = ""
          preview_done = false
          log_lines = {}
          saveRules()
        end
      end
      r.ImGui_EndChild(ctx)
    end
    r.ImGui_PopStyleColor(ctx)

    r.ImGui_Spacing(ctx)
    r.ImGui_Separator(ctx)
    r.ImGui_Spacing(ctx)

    -- ── Action Buttons ──
    local btn_w = (r.ImGui_GetContentRegionAvail(ctx) - 12) / 2
    if r.ImGui_Button(ctx, "🔍 Preview", btn_w, 32) then
      runAssign(true)
    end
    r.ImGui_SameLine(ctx)
    r.ImGui_PushStyleColor(ctx, r.ImGui_Col_Button(),        0x16A34AFF)
    r.ImGui_PushStyleColor(ctx, r.ImGui_Col_ButtonHovered(), 0x15803DFF)
    if r.ImGui_Button(ctx, "✓ Apply", btn_w, 32) then
      r.Undo_BeginBlock()
      runAssign(false)
      r.Undo_EndBlock("VCA Auto-Assign", -1)
    end
    r.ImGui_PopStyleColor(ctx, 2)

    r.ImGui_Spacing(ctx)

    -- ── Log ──
    if #log_lines > 0 then
      r.ImGui_Separator(ctx)
      r.ImGui_Spacing(ctx)
      r.ImGui_Text(ctx, preview_done and "Preview:" or "Log:")
      r.ImGui_Spacing(ctx)
      local log_h = r.ImGui_GetContentRegionAvail(ctx) - 8
      r.ImGui_PushStyleColor(ctx, r.ImGui_Col_ChildBg(), theme.bg_card)
      if r.ImGui_BeginChild(ctx, "log", 0, log_h, false) then
        for _, line in ipairs(log_lines) do
          r.ImGui_PushStyleColor(ctx, r.ImGui_Col_Text(), line.color)
          r.ImGui_TextWrapped(ctx, line.text)
          r.ImGui_PopStyleColor(ctx)
        end
        -- Auto-scroll to bottom
        if r.ImGui_GetScrollY(ctx) >= r.ImGui_GetScrollMaxY(ctx) - 20 then
          r.ImGui_SetScrollHereY(ctx, 1.0)
        end
        r.ImGui_EndChild(ctx)
      end
      r.ImGui_PopStyleColor(ctx)
    end
  end

  r.ImGui_End(ctx)
  popTheme()

  if win_open then
    r.defer(loop)
  end
end

-- ===== Init =====
loadRules()
r.defer(loop)
