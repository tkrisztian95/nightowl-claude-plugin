---
name: goodnight
description: Save a late-night handoff summary so you can stop now and resume tomorrow. Use when the user types /goodnight, says they're going to bed, wants to wrap up the session, or asks to save progress to continue later.
---

# /goodnight — wrap up and save a handoff

The user is stopping for the night. Hunt the session down to a concise handoff so
tomorrow's session (or a fresh context) can resume with zero re-discovery.

An owl works the night shift on four instincts. Each one maps to a real step —
the bird is the mnemonic, the behavior is the value.

## Steps

### 🦉 Facial disc — gather and funnel

An owl's face is a dish that funnels scattered sound to its ears. Do the same with
the session: sweep up everything that happened and funnel it to signal.

Skim the task, what got done, what's in progress, what's still open. In a git repo,
run `git status --short` and `git log --oneline -5` to ground the summary in real
state. **Funnel, don't dump** — distill the raw output into a few sharp lines.

### 🦉 Talon grip — capture so nothing slips

Two toes forward, two back, a crushing lock. Whatever you caught tonight, grip it
hard enough that none of it leaks out overnight. Write the handoff to
`.nightowl/handoff-YYYY-MM-DD-HHMM.md` in the current project (create `.nightowl/`
if missing; use today's date and the current time). The `-HHMM` suffix keeps a
second wrap-up the same day from clobbering the first, and still sorts newest-last.
Use this shape:

```markdown
# Handoff — <YYYY-MM-DD HH:MM>

## What we were doing
<one-paragraph goal of the session>

## Done this session
- <bullet> (commit <sha> if applicable)

## In progress / where I left off
- <bullet — be specific: file:line, the exact next edit>

## Cache — prey stashed mid-bite
- <uncommitted or half-done work that isn't obvious from git: a stash, a WIP edit
  not yet saved, a branch you forgot you were on, a scratch file. What would be
  silently lost if you closed the laptop right now.>

## Pellet — dead ends, don't re-chew
- <approaches you already tried that DIDN'T work, and why. Owls cough up the
  indigestible bones so they don't swallow them twice. Save tomorrow-you from
  re-walking a path you already know is a wall.>

## Open / next steps
- [ ] <actionable next step>

## Gotchas / context to remember
- <anything non-obvious: a failing test, a decision made, a blocker>

## Resume command
<the single command or prompt to pick up tomorrow>
```

The **Cache** and **Pellet** sections are the owl's edge over a plain handoff:
Cache stops in-flight work from vanishing, Pellet stops tomorrow from repeating a
dead end. Drop either section if it'd be empty — don't pad.

### 🦉 Silent flight — leave no trace

Serrated feathers break the air so prey hears nothing. Your wrap-up should be just
as quiet: **read state and write the one file, nothing else.** Don't commit, push,
or run anything destructive. Then print the same summary in chat so the user sees
it before they close the terminal, and end with the file path.

### Sign off

One short, warm line — e.g. "Roosted. Get some rest 🌙".

## Notes

- Keep it tight. A handoff nobody reads is useless; aim for skimmable.
- Be concrete in "where I left off" — name the file and line, not "working on auth".
- Silent flight is a hard rule: no commit, push, or destructive command. Just read
  state and write the file.
- If `.nightowl/` is not git-ignored and the repo tracks it, mention the user may
  want to add `.nightowl/` to `.gitignore`.
- **Called again in the same session?** If you already wrote a handoff this
  session and nothing has changed since, don't duplicate it — say it's already
  saved and point at the existing file. If state *has* changed (new commits,
  edits, decisions, a fresh dead end worth a Pellet line), write a fresh handoff;
  the `-HHMM` in the filename keeps it from clobbering the earlier one (same-minute
  re-runs do overwrite, which is fine — the content is equivalent).
