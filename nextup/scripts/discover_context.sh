#!/usr/bin/env bash
# Discovers planning-context sources for the next-task-planner skill:
# CLAUDE.md, specification/roadmap markdown docs, git state, and open
# GitHub issues/PRs. Read-only — prints a manifest, touches nothing.
set -uo pipefail

start_dir="${1:-$PWD}"

echo "=== CLAUDE.md ==="
d="$start_dir"
found_claude=""
while :; do
  if [ -f "$d/CLAUDE.md" ]; then
    echo "$d/CLAUDE.md"
    found_claude="$d/CLAUDE.md"
    break
  fi
  if [ -e "$d/.git" ] || [ "$d" = "/" ]; then
    break
  fi
  d=$(dirname "$d")
done
[ -z "$found_claude" ] && echo "(none found)"

repo_root="$d"
[ -e "$repo_root/.git" ] || repo_root="$start_dir"

echo
echo "=== Specification / roadmap markdown docs ==="
candidates=()
for dir in specification docs spec design; do
  if [ -d "$repo_root/$dir" ]; then
    while IFS= read -r f; do candidates+=("$f"); done < <(find "$repo_root/$dir" -iname "*.md" 2>/dev/null)
  fi
done
for f in PROGRESS.md ROADMAP.md TODO.md DESIGN.md CONSTITUTION.md CODEBASE_ASSESSMENT.md REQUIREMENTS.md BACKLOG.md; do
  [ -f "$repo_root/$f" ] && candidates+=("$repo_root/$f")
done
if [ "${#candidates[@]}" -eq 0 ]; then
  echo "(none found)"
else
  printf '%s\n' "${candidates[@]}" | sort -u
fi

echo
echo "=== Git state ==="
if git -C "$repo_root" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  echo "branch: $(git -C "$repo_root" branch --show-current)"
  echo "status:"
  git -C "$repo_root" status --short
  echo "recent commits:"
  git -C "$repo_root" log --oneline -10
else
  echo "(not a git repo)"
fi

echo
echo "=== GitHub issues (open) ==="
if command -v gh >/dev/null 2>&1; then
  if gh auth status >/dev/null 2>&1; then
    (cd "$repo_root" && gh issue list --state open --limit 200 \
      --json number,title,labels,milestone,updatedAt,url 2>/dev/null) \
      || echo "(gh issue list failed — repo may lack a GitHub remote)"
  else
    echo "(gh CLI not authenticated — run 'gh auth login')"
  fi
else
  echo "(gh CLI not installed)"
fi

echo
echo "=== Open pull requests ==="
if command -v gh >/dev/null 2>&1 && gh auth status >/dev/null 2>&1; then
  (cd "$repo_root" && gh pr list --state open --json number,title,headRefName,url 2>/dev/null) \
    || echo "(none, or gh unavailable)"
fi
