# Forum Post Draft — REAPER Forum

## Instructions
- Post in: ReaScript / JSFX / Plug-in Extensions
- Add screenshot(s)
- Link to GitHub repo + ReaPack

## Draft

**RAPID — get recording sessions into your mix template without losing anything**

If you work with a mix template — FX chains, sends, routing, groups all set up — and you keep having to manually drag stuff from recording RPPs into it, this might save you some pain.

RAPID reads your recording .rpp, shows you both track lists side by side, auto-matches by name (fuzzy — "Kick In" matches "Kick_in"), and commits everything in one go. Template tracks keep all their FX, sends, routing, groups, automation. Recording audio just lands where it belongs.

You set it up once — aliases, normalize profiles, whatever — and from then on it's: load RPP, check mappings, commit. 10 seconds for a full session import.

**Multi-RPP** — I had separate recording sessions (different days, different instruments) that all needed to go into one mix. This loads multiple .rpp files, gives each one a region, merges tempo and markers, and lets you map each RPP to your template tracks in columns. Reorder by drag and drop if the sequence matters.

**Normalization** — LUFS-based with instrument profiles. Pick a reference item that sounds right, calibrate, and it'll match everything to that level. Segment-based measurement so long silences don't throw off the reading.

**The rest:**
- Drag & drop .rpp and audio files straight onto the window
- Lock tracks you don't want touched
- Duplicate slots when one template track needs multiple sources
- Delete unused template tracks after import
- Works as import-only, normalize-only, or both together

Single Lua script, ReaImGui UI. Needs SWS. JS_ReaScriptAPI optional (multi-file picker). REAPER 6.0+.

Available on ReaPack or GitHub: [link]

Let me know if you run into issues or have use cases I haven't thought of.
