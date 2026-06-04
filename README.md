# 🦉 nightowl

A tiny Claude Code plugin that notices when you're working late at night,
nudges you to get some sleep, and saves a handoff summary so you can stop now
and pick up tomorrow without re-discovering everything.

Four pieces:

- **`late-check` hook** (`UserPromptSubmit`) — checks the local clock on each
  prompt. Inside the late-night window it injects a one-line reminder telling
  Claude to suggest wrapping up and mention `/roost`. The tone escalates the
  later it gets (gentle → firm → urgent). Rate-limited so it nags at most once
  every 30 min.
- **`resume-check` hook** (`SessionStart`) — when a recent `/roost` handoff
  is sitting in `.nightowl/`, injects a one-line pointer so Claude reminds you
  that you can `/rouse` to resume. Surfaces once per handoff, and prunes
  stale handoffs so the folder doesn't grow forever.
- **`/roost` skill** — writes a dated handoff summary to
  `.nightowl/handoff-YYYY-MM-DD-HHMM.md` *and* prints it in chat: what you did,
  where you left off (file:line), in-flight work (**Cache**), dead ends you
  already hit (**Pellet**), open next steps, gotchas, and the command to resume.
- **`/rouse` skill** — the counterpart: loads the latest handoff,
  re-grounds it against current git state (flagging anything that changed
  overnight), recovers the Cache, respects the Pellet, and tees up the next step
  so you start oriented.

## Owl instincts

The skills aren't just owl-*named* — each step is framed as a real owl capability,
so the bird is a mnemonic for an actual best-practice. No flavor without value.

| Owl trait | What it does in the skill |
| --- | --- |
| 🦉 **Facial disc** (funnels sound to the ears) | `/roost` sweeps the whole session and funnels it to signal — distill, don't dump. |
| 🦉 **Talon grip** (two-forward-two-back crush hold) | The handoff grips exact state so nothing leaks overnight. |
| 🦉 **Cache** (owls stash uneaten prey) | A handoff section for in-flight work — a stash, a WIP edit, a forgotten branch — that git won't show and you'd silently lose. |
| 🦉 **Pellet** (owls cough up indigestible bones) | A handoff section for approaches you already tried that *didn't* work — so tomorrow-you doesn't re-chew a dead end. |
| 🦉 **Silent flight** (prey hears nothing) | `/roost` is read-only — it writes one file and disturbs nothing: no commit, no push. |
| 🦉 **Night vision** (max light in near-dark) | `/rouse` reconstructs a full session from one sparse handoff. |
| 🦉 **270° head swivel** (look behind without moving) | `/rouse` scans both ways: drift since the handoff, *and* forward to recover the Cache. |
| 🦉 **Asymmetric ears** (pinpoint prey in total dark) | The morning brief lands on one exact next move — file:line, not a vague direction. |

## Requirements

The hook and statusline are POSIX shell scripts (`bash`), so they run on
**macOS and Linux** out of the box. **Windows is not supported** — there's no
native `bash`, and no PowerShell (`.ps1`) twin is shipped. Windows users would
need WSL, Git Bash, or a port. (The `/roost` and `/rouse` skills are
just instructions to Claude and work anywhere; only the late-night hook and the
statusline owl are shell-dependent.)

## How it works

The hook reads the system clock with `date`, so it follows your machine's local
timezone — no config needed. State for throttling lives in
`$TMPDIR/nightowl-last-nag-<project>` — keyed by the current project directory,
so parallel Claude sessions in different projects each nag on their own clock
instead of sharing one machine-wide timer. The hook never blocks or fails your
prompt: on any error it exits cleanly and your request goes through.

The `/roost` summary is written under `.nightowl/` in the current project
(git-ignored by default), named `handoff-YYYY-MM-DD-HHMM.md` so a second wrap-up
the same day doesn't clobber the first. `/rouse` reads the newest
`handoff-*.md` back out of that folder. The `resume-check` hook also looks there
at session start: if the newest handoff is recent it nudges you to
`/rouse`, and it prunes handoffs older than the retention window.

## Install

### As a plugin (recommended)

This repo is its own Claude Code plugin marketplace. Add it, then install:

```
/plugin marketplace add tkrisztian95/nightowl-claude-plugin
/plugin install nightowl@nightowl
```

(`nightowl@nightowl` = the `nightowl` plugin from the `nightowl` marketplace.)
Update later with `/plugin marketplace update nightowl`.

### Manual (no marketplace)

Clone the repo somewhere, then wire up the two pieces:

```bash
git clone https://github.com/tkrisztian95/nightowl-claude-plugin.git
cd nightowl-claude-plugin
```

1. **Skills** — copy both skills so Claude can find them:

   ```bash
   cp -r skills/roost ~/.claude/skills/roost
   cp -r skills/rouse ~/.claude/skills/rouse
   ```

2. **Hooks** — add both hooks to `~/.claude/settings.json`, pointing at the
   absolute path where you cloned it:

   ```json
   {
     "hooks": {
       "UserPromptSubmit": [
         {
           "hooks": [
             {
               "type": "command",
               "command": "bash \"/absolute/path/to/nightowl-claude-plugin/hooks/late-check.sh\""
             }
           ]
         }
       ],
       "SessionStart": [
         {
           "hooks": [
             {
               "type": "command",
               "command": "bash \"/absolute/path/to/nightowl-claude-plugin/hooks/resume-check.sh\""
             }
           ]
         }
       ]
     }
   }
   ```

Restart Claude Code (or `/hooks` reload) to pick it up.

## Configuration

Override via environment variables (defaults shown):

| Var | Default | Meaning |
| --- | --- | --- |
| `NIGHTOWL_START` | `23` | Window start hour (24h). `23` = 11pm. |
| `NIGHTOWL_END` | `6` | Window end hour, exclusive. `6` = 6am. |
| `NIGHTOWL_THROTTLE_MIN` | `30` | Minimum minutes between nags. |
| `NIGHTOWL_TEMPLATE` | `hooks/reminder.tmpl` | Path to the reminder template. |
| `NIGHTOWL_FIRM_AFTER` | `2` | Hours into the night before the nudge turns *firm*. |
| `NIGHTOWL_URGENT_AFTER` | `4` | Hours into the night before the nudge turns *urgent*. |
| `NIGHTOWL_RESUME_MAX_AGE_DAYS` | `3` | `resume-check` won't surface a handoff older than this. |
| `NIGHTOWL_HANDOFF_KEEP_DAYS` | `14` | `resume-check` prunes handoffs older than this. |

Wrap-around windows work: `NIGHTOWL_START=22 NIGHTOWL_END=5` covers 10pm–5am.

**Escalating tone.** The nudge gets firmer the deeper into the night you are,
measured in hours since `NIGHTOWL_START` (wrapping midnight). With the defaults:
gentle at 11pm–12:59am, firm from 1am, urgent from 3am. `resume-check` and the
pruning it does are deterministic and never block the session — on any error it
exits cleanly.

## The reminder template

The nudge wording lives in [`hooks/reminder.tmpl`](hooks/reminder.tmpl), not in
the shell script. The hook renders it with a tiny pure-bash engine that replaces
`{{KEY}}` placeholders — `{{CLOCK}}` (the local `HH:MM`) and `{{SEVERITY}}` (the
escalation tier: `gentle`, `firm`, or `urgent`). Edit the template to change the
tone; no code change needed. The user's prompt is never read into the template,
so there's no injection surface beyond the file itself.

## Statusline owl (optional)

A 🦉 badge can appear in the status line under the Claude Code input while it's
late — a passive companion to the hook's active nudge.

**This is opt-in and manually wired.** Claude Code's `statusLine` is a single,
user-owned setting; a plugin can ship the script but cannot claim the slot for
you. (A statusLine command also doesn't receive `${CLAUDE_PLUGIN_ROOT}`, so use
an absolute path to the script.)

The script is **composable** — point it at whatever status line you already run
via `NIGHTOWL_BASE_STATUSLINE` and the owl is prepended without replacing it.

**If you have no status line yet**, add to `settings.json`:

```json
{
  "statusLine": {
    "type": "command",
    "command": "bash \"/absolute/path/to/nightowl-claude-plugin/statusline/nightowl-statusline.sh\""
  }
}
```

**If you already have one** (ruflo, caveman, a custom script), keep it by passing
it through. Set `NIGHTOWL_BASE_STATUSLINE` to your existing command and point
`statusLine` at the owl wrapper:

```json
{
  "statusLine": {
    "type": "command",
    "command": "NIGHTOWL_BASE_STATUSLINE='<your existing statusLine command>' bash \"/absolute/path/to/nightowl-claude-plugin/statusline/nightowl-statusline.sh\""
  }
}
```

The wrapper forwards Claude's session JSON (stdin) to the base command, so your
existing dashboard renders exactly as before — with the owl in front when late.
Customize the badge with `NIGHTOWL_BADGE` (default `🦉 late night · /roost`).
Window vars (`NIGHTOWL_START` / `NIGHTOWL_END`) are shared with the hook.

## Development

Lint and test (only `bash` + `shellcheck` needed — no bats):

```bash
shellcheck hooks/late-check.sh hooks/resume-check.sh statusline/nightowl-statusline.sh tests/*.sh
bash tests/late-check.test.sh
bash tests/resume-check.test.sh
bash tests/statusline.test.sh
```

The suites pin the clock via the `NIGHTOWL_FAKE_HOUR` / `NIGHTOWL_FAKE_NOW` test
seams, so window, wrap-around, and throttle logic are deterministic without
waiting for real time.
