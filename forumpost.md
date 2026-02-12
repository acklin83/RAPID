# Forum Post Draft — REAPER Forum

## Instructions
- Post in: REAPER forum → ReaScript / JSFX / Plug-in Extensions
- Tone: casual, dev-to-dev, not marketing-speak
- Don't oversell, don't assume too much about what people need
- Core pitch: get a recording RPP into a mix template without losing template FX/sends/routing
- Multi-RPP is secondary feature, mention with real example (combining separate kick/snare/toms recordings)
- Keep it honest about what it is: a single Lua script, no magic

## Draft

**RAPID — get your recording RPP into your mix template**

Hey everyone,

I've been working on a script called **RAPID** (Recording Auto-Placement & Intelligent Dynamics) that solves a problem I kept running into: moving tracks from a recording session into a prepared mix template without losing FX, sends, routing, or automation on the template tracks.

**How it works:**
You open your mix template, run RAPID, point it at your recording .rpp, and it shows you the track list from both sides. It auto-matches tracks by name (fuzzy, so "Kick In" matches "Kick_in" etc.), you tweak what needs tweaking, hit commit, done. Your template FX chains, sends, groups — all untouched.

You can also set up aliases if your recording sessions use different naming than your template (e.g. "OH L" → "Overhead L").

**Multi-RPP mode:**
This one came out of a real need — I had separate recording sessions for kick, snare, toms, etc. and wanted them all in one mix template. Multi-RPP lets you load multiple .rpp files, each gets its own region, tempo and markers merge correctly, and you map each RPP's tracks to your template columns. Drag and drop reorder if the sequence matters.

**Normalization:**
Optional LUFS normalization with instrument profiles. You can calibrate from a reference track (e.g. "this is how loud I want my kick") and it'll match future imports to that. Segment-based measurement so it doesn't get thrown off by silence.

**Other stuff:**
- Drag & drop .rpp / audio files onto the window
- Lock tracks you don't want touched
- Duplicate slots if one template track needs multiple sources
- Editable track names inline
- Dark theme (MixnoteStyle)

Requires SWS. Optional: JS_ReaScriptAPI for multi-file dialogs.

REAPER 6.0+, single Lua script, no dependencies beyond SWS.

Would love to hear if this is useful for anyone else or if there are workflows I haven't thought of.
