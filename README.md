# skills

Portable [Claude Code](https://claude.com/claude-code) skills, agents, and commands, with a
one-way sync that replicates each Claude skill as an [opencode](https://opencode.ai) command.

This repo is meant to **be** `~/.claude/skills` — clone it directly into that path (or
symlink it there) rather than nesting it inside an existing skills directory. Claude Code
only discovers skills one level deep (`~/.claude/skills/<name>/SKILL.md`), so the extra
support directories at the root (`agents/`, `commands/`, `hooks/`, `scripts/`,
`.claude-plugin/`, and the vendored `skills/` subfolder) are simply ignored by its skill
loader and don't collide with the real, top-level skills.

## What's in here

| Path | Purpose |
|---|---|
| `<skill-name>/SKILL.md` (repo root) | Claude Code skills — one directory per skill, discovered directly. |
| `skills/<skill-name>/` | Vendored copies of a subset of these skills, kept two levels deep so Claude Code's one-level scan skips them. Used as the source for `.claude-plugin/marketplace.json`. |
| `agents/*-claude.md` | Claude Code subagents. Symlink into `~/.claude/agents/<name>.md` to install. |
| `agents/*-opencode.md` | opencode equivalents of the same subagents. Symlink into `~/.config/opencode/agents/<name>.md`. |
| `commands/*-opencode.md` | Hand-authored opencode commands (e.g. ones that route to a specific subagent via `agent:`/`subtask:`). Symlink into `~/.config/opencode/commands/<name>.md`. |
| `scripts/sync-to-opencode-commands.sh` | Generates a thin opencode command per Claude skill (see below). |
| `hooks/post-merge` | Git hook that re-runs the sync script after every `git pull`/merge. |
| `.claude-plugin/marketplace.json` | Claude Code plugin marketplace definition for a subset of skills. |

Some top-level entries are symlinks out to `~/.agents/skills/<name>` — a personal skills
source kept outside this repo. On a machine that doesn't have `~/.agents/skills/`
populated, those particular symlinks will be dangling; that's expected, not an error, and
Claude Code will just skip them.

## Setup on a new machine

1. **Clone directly as `~/.claude/skills`** (back up first if one already exists):

   ```sh
   mv ~/.claude/skills ~/.claude/skills.bak   # only if it already has content worth keeping
   git clone https://github.com/felipeazucares/skills.git ~/.claude/skills
   ```

2. **Install the Claude subagent(s)** by symlinking them into `~/.claude/agents/`:

   ```sh
   mkdir -p ~/.claude/agents
   ln -s ~/.claude/skills/agents/spec-reviewer-claude.md ~/.claude/agents/spec-reviewer.md
   ```

3. **Enable the git hook** so new/changed skills regenerate opencode commands automatically
   on every future pull:

   ```sh
   cd ~/.claude/skills
   git config core.hooksPath hooks
   ```

4. Restart Claude Code so it picks up the new skills and agent.

## Replicating skills to opencode

opencode commands are plain prompt templates — there's no deterministic tool-forcing like a
Claude skill gets, so the sync script just names the skill explicitly to give opencode's own
auto-invoke a strong nudge toward using it.

Run once after cloning (and again any time you add or edit a skill, if the git hook above
isn't enabled):

```sh
~/.claude/skills/scripts/sync-to-opencode-commands.sh
```

For every `~/.claude/skills/*/SKILL.md`, it extracts `name:` and `description:` and writes
`~/.config/opencode/commands/<name>.md`. It will:

- Skip any skill marked `user-invocable: false` in its frontmatter.
- Skip (never overwrite) any command file that's already a symlink — those are
  hand-authored commands tracked in `commands/`, not generator output.

### Hand-authored commands and agents

Some skills need more than a plain prompt nudge — e.g. `spec-review` hands off to a real
opencode subagent instead. These aren't produced by the sync script and must be linked
manually:

```sh
mkdir -p ~/.config/opencode/agents ~/.config/opencode/commands
ln -s ~/.claude/skills/agents/spec-reviewer-opencode.md ~/.config/opencode/agents/spec-reviewer.md
ln -s ~/.claude/skills/commands/spec-review-opencode.md ~/.config/opencode/commands/spec-review.md
```

Restart opencode afterwards so it picks up the new commands and agents.