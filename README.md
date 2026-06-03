# 🦉 nightowl

A tiny Claude Code plugin that notices when you're working past midnight,
nudges you to get some sleep, and saves a handoff summary so you can stop now
and pick up tomorrow without re-discovering everything.

Two pieces:

- **`late-check` hook** (`UserPromptSubmit`) — checks the local clock on each
  prompt. Inside the late-night window it injects a one-line reminder telling
  Claude to gently suggest wrapping up and mention `/goodnight`. Rate-limited so
  it nags at most once every 30 min.
- **`/goodnight` skill** — writes a dated handoff summary to
  `.nightowl/handoff-YYYY-MM-DD.md` *and* prints it in chat: what you did, where
  you left off (file:line), open next steps, gotchas, and the command to resume.

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

1. **Skill** — copy the skill so Claude can find it:

   ```bash
   cp -r skills/goodnight ~/.claude/skills/goodnight
   ```

2. **Hook** — add the hook to `~/.claude/settings.json`, pointing at the
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
       ]
     }
   }
   ```

Restart Claude Code (or `/hooks` reload) to pick it up.

## Configuration

Override via environment variables (defaults shown):

| Var | Default | Meaning |
| --- | --- | --- |
| `NIGHTOWL_START` | `0` | Window start hour (24h). `0` = midnight. |
| `NIGHTOWL_END` | `6` | Window end hour, exclusive. `6` = 6am. |
| `NIGHTOWL_THROTTLE_MIN` | `30` | Minimum minutes between nags. |

Wrap-around windows work: `NIGHTOWL_START=22 NIGHTOWL_END=5` covers 10pm–5am.

## How it works

The hook reads the system clock with `date`, so it follows your machine's local
timezone — no config needed. State for throttling lives in
`$TMPDIR/nightowl-last-nag` (just a timestamp). The hook never blocks or fails
your prompt: on any error it exits cleanly and your request goes through.

The `/goodnight` summary is written under `.nightowl/` in the current project,
which is git-ignored by default.
