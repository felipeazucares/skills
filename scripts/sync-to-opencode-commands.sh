#!/usr/bin/env zsh
# Generates a thin opencode command per Claude skill, so `/name` works in
# opencode too. opencode commands are plain prompt templates (no deterministic
# tool-forcing), so this just names the skill explicitly to make the model's
# own auto-invoke reliably pick it up -- not a guarantee, a strong nudge.
#
# Re-run after adding/editing skills. Safe to re-run (overwrites its own output).

set -euo pipefail

SKILLS_DIR="$HOME/.claude/skills"
COMMANDS_DIR="$HOME/.config/opencode/commands"

mkdir -p "$COMMANDS_DIR"

for skill_md in "$SKILLS_DIR"/*/SKILL.md; do
  [[ -f "$skill_md" ]] || continue

  name=$(sed -n 's/^name: *//p' "$skill_md" | head -1)
  description=$(sed -n 's/^description: *//p' "$skill_md" | head -1)
  [[ -z "$name" ]] && continue

  # Respect user-invocable: false -- author didn't want this manually triggered.
  if grep -q '^user-invocable: *false' "$skill_md"; then
    echo "Skipping ${name} (user-invocable: false)"
    continue
  fi

  cat > "$COMMANDS_DIR/${name}.md" <<CMD_EOF
---
description: ${description}
---
Use the "${name}" skill to handle this request: \$ARGUMENTS
CMD_EOF
  echo "Generated opencode command: /${name}"
done
