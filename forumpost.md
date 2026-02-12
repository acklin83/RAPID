# Forum Post Draft — REAPER Forum

## Instructions
- Post in: ReaScript / JSFX / Plug-in Extensions
- Keep it short, no marketing
- Link to GitHub repo + ReaPack

## Draft

**RAPID — Recording Auto-Placement & Intelligent Dynamics**

Made a script that gets recording tracks into a mix template. You keep your FX, sends, routing, groups, automation — everything on the template stays. Just maps recording sources to template destinations, hit commit, done.

Fuzzy name matching so "Kick In" finds "Kick_in". Custom aliases if your sessions use different naming.

**Multi-RPP:** Load multiple .rpp files into the same template. Each one gets a region, tempo/markers merge, you map per column. Had separate sessions for drums, bass, guitars — this handles that.

**Normalization:** LUFS-based, per-instrument profiles. Calibrate from a reference item and reuse. Segment-based so silence doesn't mess it up.

**Quick rundown:**
- Drag & drop .rpp / audio files onto the window
- Lock tracks, duplicate slots, inline rename
- Delete unused tracks toggle
- Works as import-only, normalize-only, or both

Single Lua script, needs SWS. JS_ReaScriptAPI optional for multi-file dialogs. REAPER 6.0+.

Install via ReaPack or grab from GitHub.

Feedback welcome — curious what workflows people would use this for.
