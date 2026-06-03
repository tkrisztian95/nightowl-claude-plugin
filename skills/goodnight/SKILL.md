---
name: goodnight
description: Save a late-night handoff summary so you can stop now and resume tomorrow. Use when the user types /goodnight, says they're going to bed, wants to wrap up the session, or asks to save progress to continue later.
---

# /goodnight — wrap up and save a handoff

The user is stopping for the night. Produce a concise handoff so tomorrow's
session (or a fresh context) can resume with zero re-discovery.

## Steps

1. **Gather state.** Skim what happened this session: the task, what got done,
   what's in progress, what's still open. If in a git repo, run
   `git status --short` and `git log --oneline -5` to ground the summary in real
   state. Don't dump raw output — distill it.

2. **Write the summary file.** Save to `.nightowl/handoff-YYYY-MM-DD.md` in the
   current project (create `.nightowl/` if missing; use today's date). Use this
   shape:

   ```markdown
   # Handoff — <YYYY-MM-DD HH:MM>

   ## What we were doing
   <one-paragraph goal of the session>

   ## Done this session
   - <bullet> (commit <sha> if applicable)

   ## In progress / where I left off
   - <bullet — be specific: file:line, the exact next edit>

   ## Open / next steps
   - [ ] <actionable next step>

   ## Gotchas / context to remember
   - <anything non-obvious: a failing test, a decision made, a blocker>

   ## Resume command
   <the single command or prompt to pick up tomorrow>
   ```

3. **Print it in chat too.** Show the same summary so the user sees it before
   they close the terminal. End with the file path.

4. **Sign off.** One short, warm line — e.g. "Saved. Get some rest 🌙".

## Notes

- Keep it tight. A handoff nobody reads is useless; aim for skimmable.
- Be concrete in "where I left off" — name the file and line, not "working on auth".
- Don't commit, push, or run anything destructive. Just read state and write the file.
- If `.nightowl/` is not git-ignored and the repo tracks it, mention the user may
  want to add `.nightowl/` to `.gitignore`.
