---
name: goodmorning
description: Resume where you left off by loading the latest /goodnight handoff. Use when the user types /goodmorning, says good morning, asks to pick up where they stopped, resume yesterday's work, or "what was I doing".
---

# /goodmorning — pick up where you left off

The counterpart to `/goodnight`. Load the most recent handoff, check what (if
anything) changed overnight, and tee up the next step — so the user starts the
day already oriented instead of re-reading their own code.

## Steps

1. **Find the latest handoff.** Look in `.nightowl/` in the current project for
   `handoff-*.md` and pick the newest by filename. Names are
   `handoff-YYYY-MM-DD-HHMM.md` (the `-HHMM` means a day can hold more than one),
   and both date and time sort lexically, so the last line is the newest:

   ```bash
   ls -1 .nightowl/handoff-*.md 2>/dev/null | sort | tail -1
   ```

   If none exists, say so plainly — "No handoff found in `.nightowl/`. Nothing to
   resume; start `/goodnight` tonight to leave yourself one." — and stop.

2. **Read it.** Load that file. Pay attention to *Where I left off*, *Open / next
   steps*, *Gotchas*, and *Resume command*.

3. **Re-ground against reality.** The repo may have moved since the handoff was
   written. In a git repo, check:

   ```bash
   git status --short
   git log --oneline -5
   ```

   Compare against the handoff. Call out drift explicitly: commits that landed
   after the handoff, files now dirty/clean that weren't, a branch that changed.
   If something in the handoff is now stale (e.g. "next step: finish X" but X was
   already committed), say so — don't blindly trust the note.

4. **Brief the user.** Short, skimmable:
   - **Last session:** one line — what they were doing.
   - **Since then:** what changed in the repo (or "nothing — picking up clean").
   - **Next up:** the top open step, made concrete (file:line, the exact edit).

5. **Offer to start.** End by asking if they want you to begin on the top next
   step (or run the handoff's *Resume command*). Don't auto-run it — wait for go.

## Notes

- Read-only orientation. Don't edit, commit, or run anything destructive — just
  read the handoff + git state and report.
- If multiple handoffs exist, mention you loaded the newest and how many older
  ones are sitting in `.nightowl/`.
- Keep the brief tight. The point is a fast start, not a wall of text.
