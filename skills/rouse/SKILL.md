---
name: rouse
description: Rouse from the roost — resume where you left off by loading the latest /roost handoff. Use when the user types /rouse, says good morning, asks to pick up where they stopped, resume yesterday's work, or "what was I doing".
---

# /rouse — wake up and pick up where you left off

The counterpart to `/roost`. Load the most recent handoff, check what (if anything)
changed overnight, and tee up the next step — so the user starts the day already
oriented instead of re-reading their own code.

Same bird, dawn instincts. Three traits, three steps.

## Steps

### Night vision — see from almost nothing

Tube-shaped eyes gather every scrap of light to make a picture in near-dark. Do the
same: reconstruct a full session from one sparse handoff file.

Look in `.nightowl/` in the current project for `handoff-*.md` and pick the newest
by filename. Names are `handoff-YYYY-MM-DD-HHMM.md` (the `-HHMM` means a day can
hold more than one), and both date and time sort lexically, so the last line is the
newest:

```bash
ls -1 .nightowl/handoff-*.md 2>/dev/null | sort | tail -1
```

If none exists, say so plainly — "No handoff found in `.nightowl/`. Nothing to
resume; run /roost tonight to leave yourself one." — and stop.

Read it. Pay attention to *Where I left off*, *Cache*, *Pellet*, *Open / next
steps*, *Gotchas*, and *Resume command*. The **Cache** tells you what in-flight work
to recover; the **Pellet** tells you which approaches are already dead — don't
re-attempt them.

### 270° head swivel — scan back and forward

An owl pivots its head most of the way around without moving its body. Use both
directions:

- **Look back.** The repo may have moved since the handoff was written. In a git
  repo, check:

  ```bash
  git status --short
  git log --oneline -5
  ```

  Compare against the handoff. Call out drift explicitly: commits that landed after
  the handoff, files now dirty/clean that weren't, a branch that changed. If
  something in the handoff is now stale (e.g. "next step: finish X" but X was
  already committed), say so — don't blindly trust the note.

- **Look forward.** Recover the Cache (is that stash / WIP edit still there?) and
  confirm the Pellet's dead ends are still walls before you point at the next step.

### Asymmetric ears — pinpoint the next move

Offset ears triangulate prey to an exact spot in total dark. Land the brief on one
exact next move, not a vague direction. Keep it short, skimmable:

- **Last session:** one line — what they were doing.
- **Since then:** what changed in the repo (or "nothing — picking up clean").
- **Next up:** the top open step, made concrete (file:line, the exact edit).

Then **offer to fly** — ask if they want you to begin on the top next step (or run
the handoff's *Resume command*). Don't auto-run it — wait for go.

## Notes

- Read-only orientation. Don't edit, commit, or run anything destructive — just read
  the handoff + git state and report.
- The counterpart skill is `/roost` — that's what writes the handoff this one reads.
- If multiple handoffs exist, mention you loaded the newest and how many older ones
  are sitting in `.nightowl/`.
- Keep the brief tight. The point is a fast start, not a wall of text.
- **Called again in the same session?** You've already loaded the handoff — don't
  re-brief from scratch as if just waking up. Re-ground against the *current* state
  and give a short delta instead: what's progressed since you resumed, what's still
  next (or "nothing's changed since"). Treat the repeat as a status check, not a
  fresh start.
