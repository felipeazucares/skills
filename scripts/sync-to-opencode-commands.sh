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

# Extracts the `description` field's full text regardless of source YAML
# style: single-line, block scalar (`|`, `|-`, `>`, `>-`), or unindicated
# plain multi-line. Joins any continuation lines with spaces into one line.
extract_description() {
  awk '
    /^description:/ {
      inline = $0
      sub(/^description: */, "", inline)
      if (inline ~ /^[|>][-+]?$/) inline = ""
      if (inline != "") { print inline; exit }
      collecting = 1
      next
    }
    collecting {
      if ($0 ~ /^[[:space:]]/) {
        line = $0
        sub(/^[[:space:]]+/, "", line)
        buf = (buf == "" ? line : buf " " line)
        next
      } else {
        print buf
        exit
      }
    }
  ' "$1"
}

for skill_md in "$SKILLS_DIR"/*/SKILL.md; do
  [[ -f "$skill_md" ]] || continue

  name=$(sed -n 's/^name: *//p' "$skill_md" | head -1)
  description=$(extract_description "$skill_md")
  [[ -z "$name" ]] && continue

  if [[ -z "$description" ]]; then
    echo "WARNING: could not extract a description for ${name}, skipping" >&2
    continue
  fi

  # Strip one layer of pre-existing surrounding quotes, then always emit our
  # own double-quoted, escaped form -- safe regardless of the source's YAML
  # style (plain, quoted, block scalar), and immune to embedded colons/quotes
  # that would otherwise be ambiguous as a bare YAML plain scalar.
  description="${description%\"}"
  description="${description#\"}"
  description="${description//\\/\\\\}"
  description="${description//\"/\\\"}"

  # Respect user-invocable: false -- author didn't want this manually triggered.
  if grep -q '^user-invocable: *false' "$skill_md"; then
    echo "Skipping ${name} (user-invocable: false)"
    continue
  fi

  cat > "$COMMANDS_DIR/${name}.md" <<CMD_EOF
---
description: "${description}"
---
Use the "${name}" skill to handle this request: \$ARGUMENTS
CMD_EOF
  echo "Generated opencode command: /${name}"
done
