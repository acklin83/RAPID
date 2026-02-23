# RAPID YouTube Script — Overview Video (~5–7 min)

**Target audience:** REAPER power users / mixing engineers
**Language:** English
**Tone:** Direct, technical, demo-driven — no hand-holding

---

## FORMAT GUIDE

> `[SCREEN]` — on-screen action / what to show
> `[CUT]` — edit cut
> **Bold** — emphasis / slightly slower delivery

---

## PART 1 — HOOK (0:00–0:35)

> `[SCREEN: REAPER project open, multiple recording tracks, empty mix template]`

You just got a multitrack recording back from the studio.
Thirty tracks. Your mix template has all the routing, FX chains, send busses — everything dialed in.
Now you have to manually drag each track into place, check the names, assign the FX,
and run through gain staging for every single channel.

Every. Single. Session.

REAPER users call this "Tuesday."

> `[SCREEN: RAPID window opens, auto-match fires, all tracks snap into place in 2 seconds]`

Or — you could let RAPID do it.

---

## PART 2 — WHAT IS RAPID (0:35–1:10)

> `[SCREEN: RAPID logo / title card, then back to UI]`

RAPID stands for **Recording Auto-Placement & Intelligent Dynamics**.
Because everything in REAPER has to be an acronym. You know the rules.

It's a single Lua script that handles three things:

- **Automated track mapping** — route recording tracks into your mix template
- **LUFS-based normalization** — instrument-specific loudness profiles
- **Multi-RPP import** — merge multiple session files into one project

No setup beyond loading a ReaScript. Everything runs inside REAPER.

> `[SCREEN: Install from ReaPack — show adding the repository URL]`

You get it via ReaPack. I'll link the repository in the description.

---

## PART 3 — TRACK MAPPING (1:10–2:50)

> `[SCREEN: RAPID window, Import mode active, source RPP loaded]`

Let's start with the core feature — **single RPP import**.

You load a recording session — either by clicking the source field or just **dragging the RPP file** onto the RAPID window.

> `[SCREEN: Drag .rpp from Finder onto RAPID window, visual hover border appears, tracks populate]`

RAPID reads all tracks from the recording session and lists them on the right.
Your mix template tracks are on the left.

> `[SCREEN: Auto-match fires, most rows fill in automatically]`

Hit **Auto-Match** — RAPID runs fuzzy matching against your template track names.
Exact matches, prefix matches, partial matches, custom aliases — it handles all of it.
Even `Kick_FINAL_v3_actually_use_this_one`. You know who you are.
Anything it can't resolve, you assign manually with a dropdown.

> `[SCREEN: Manually adjusting one dropdown, then showing Keep FX / Keep Name columns]`

Each row has per-track controls: **Keep Name**, **Keep FX**, and a normalize profile assignment.
Lock a track to protect it from being overwritten across sessions.

> `[SCREEN: Double-click a template track name — inline text field appears, rename in place]`

You can **double-click any template track name** to rename it inline — directly from RAPID,
without touching REAPER's track list.

> `[SCREEN: Shift-click or checkbox-select multiple rows, then toggle Keep FX — all change at once]`

And if you need to make the same change across multiple tracks — **select them first**.
Toggle Keep FX, swap the normalize profile, change Keep Name — applies to all selected rows at once.

> `[SCREEN: Hitting "Commit", progress bar, tracks appear in project with correct routing]`

Hit **Commit** — RAPID copies the recording tracks into your template,
preserves all FX chains, sends, routing, automation, group assignments.

The import that used to take 15 minutes takes about **three seconds**.

> `[SCREEN: Final project view with all tracks mapped correctly]`

---

## PART 4 — LUFS NORMALIZATION (2:50–4:15)

> `[SCREEN: RAPID window with Normalize mode active, profiles visible]`

Now the gain staging.

RAPID's normalization uses **instrument-specific profiles** — not a single loudness target for everything.
Your kick is measured differently than your room mics.
Your bass has a different target than your overheads.

> `[SCREEN: Profile list — Kick, Snare, Bass, Overhead, Dialogue etc.]`

Each profile defines:
- **LUFS target** — the loudness goal
- **Segment size** — how much of the item to analyze
- **Percentile** — so one loud transient doesn't throw off the whole measurement
- **Threshold** — to ignore silence between hits

> `[SCREEN: Calibration workflow — select reference item, click Calibrate, profile created]`

You build profiles from your own reference tracks using the **Calibration System**.
Load a reference item that sounds right, measure it, and RAPID locks that profile to that loudness.

> `[SCREEN: Norm column in the mapping table — profiles assigned per track]`

In the mapping table, assign a profile per track.
**Auto-match** handles this too — it uses the same alias logic as track mapping.

> `[SCREEN: Commit with normalize checked — gain values applied, meters show result]`

On commit, RAPID measures each item, calculates the gain delta,
and applies it through **Take Volume** — clean, non-destructive gain staging.
No item gain, no clip gain. Just one point of control per take.

---

## PART 5 — MULTI-RPP IMPORT (4:15–5:55)

> `[SCREEN: Multi-RPP checkbox enabled, empty queue panel]`

This is where it gets interesting for more complex workflows.

**Multi-RPP mode** lets you import several recording sessions into the same template at once —
each one placed sequentially with its own region, merged tempo map, and correct time offsets.

Think: three nights of live recording, each in its own RPP.
Or an album tracked song by song, each session separate.
Classic REAPER situation — you've got the files, you've got the template, now what?

> `[SCREEN: Drag multiple .rpp files onto RAPID window — auto-switch to Multi-RPP, queue fills]`

Drop multiple RPP files at once — RAPID detects them and **automatically switches to Multi-RPP mode**.
Each session appears in the queue. You can reorder them by drag-and-drop.

> `[SCREEN: Queue panel with 3 RPPs, measure counts visible, gap setting]`

The **gap** setting controls how many measures of silence go between each session.
RAPID calculates the exact time offset for every item, tempo marker, and region — in seconds, directly.
No beat-to-time conversion guessing.

> `[SCREEN: Multi-RPP mapping table — columns per RPP, dropdowns per row]`

The mapping table gets **one column per RPP**.
Each column has its own dropdowns — so you can map differently per session if the tracks differ.

> `[SCREEN: Auto-match all columns button — tracks snap in]`

One click auto-matches all columns at once.

> `[SCREEN: Commit — regions appear in timeline, tracks consolidated, tempo changes visible]`

On commit:
- Tempo and time-signature changes from each RPP are merged into the project timeline
- Items are consolidated per template track, aligned in lanes
- Regions are created automatically, named from the RPP filename
- If normalize is enabled, each region is measured and normalized independently

> `[SCREEN: Final multi-RPP project — 3 regions in timeline, all tracks populated]`

Three sessions. One mix template. One commit.

---

## PART 6 — OUTRO (5:55–6:20)

> `[SCREEN: RAPID window overview — all three modes visible]`

RAPID is open source, MIT licensed, and available now via ReaPack.

If you want the full documentation, the changelog, or to report a bug — links are in the description.

If this saves you time on your next session, consider leaving a comment.
And if something's broken — same place.

> `[SCREEN: Fade to black with URL: github.com/acklin83/reaper-scripts]`

---

## CUT LIST / PRODUCTION NOTES

| Segment | Content | B-roll needed |
|---|---|---|
| Hook | Problem statement | REAPER project, empty template |
| What is RAPID | Intro + install | ReaPack dialog |
| Track Mapping | Live demo | RAPID window, Finder drag |
| Normalization | Live demo | Profile list, calibration, commit |
| Multi-RPP | Live demo | Queue panel, multi-RPP table, timeline result |
| Outro | CTA | Final project overview |

**Total estimated runtime:** ~6 minutes at normal speaking pace

---

## CHAPTER MARKERS (for YouTube description)

```
0:00 The problem
0:35 What is RAPID?
1:10 Track mapping — single RPP import
2:50 LUFS normalization with profiles
4:15 Multi-RPP: merge sessions into one template
5:55 Where to get it
```
