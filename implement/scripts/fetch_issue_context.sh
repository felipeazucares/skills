#!/usr/bin/env bash
# Discovers everything the `implement` skill needs about one GitHub issue:
# the issue itself, whether work on it is already in flight, and which
# repo docs/conventions bear on it. Read-only — prints a manifest, touches
# nothing (does not create branches, does not modify git state).
set -uo pipefail

issue_number="${1:?usage: fetch_issue_context.sh <issue-number> [repo-root]}"
start_dir="${2:-$PWD}"

repo_root="$(git -C "$start_dir" rev-parse --show-toplevel 2>/dev/null || echo "$start_dir")"

echo "=== Issue #$issue_number ==="
if command -v gh >/dev/null 2>&1; then
  if gh auth status >/dev/null 2>&1; then
    (cd "$repo_root" && gh issue view "$issue_number" \
      --json number,title,body,state,labels,milestone,url,comments 2>&1) \
      || echo "(could not fetch issue #$issue_number — check the number and that this repo has a GitHub remote)"
  else
    echo "(gh CLI not authenticated — run 'gh auth login')"
  fi
else
  echo "(gh CLI not installed)"
fi

echo
echo "=== Git state ==="
if git -C "$repo_root" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  echo "branch: $(git -C "$repo_root" branch --show-current)"
  echo "status (dirty working tree? review before branching):"
  git -C "$repo_root" status --short
else
  echo "(not a git repo)"
fi

echo
echo "=== Existing branches referencing #$issue_number ==="
git -C "$repo_root" branch -a 2>/dev/null | grep -i "$issue_number" || echo "(none found)"

echo
echo "=== PRs (any state) referencing #$issue_number ==="
if command -v gh >/dev/null 2>&1 && gh auth status >/dev/null 2>&1; then
  (cd "$repo_root" && gh pr list --state all --search "$issue_number in:title,body" \
    --json number,title,headRefName,state,url 2>/dev/null) \
    || echo "(none found, or gh unavailable)"
else
  echo "(gh unavailable)"
fi

echo
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

echo
echo "=== Spec/design docs mentioning #$issue_number ==="
grep -rIl -e "#$issue_number\b" -e "issue $issue_number\b" \
  "$repo_root"/specification "$repo_root"/docs "$repo_root"/spec "$repo_root"/design 2>/dev/null \
  | sort -u || true
echo "(if empty: no doc explicitly references this issue number by name — match it to a doc by title/topic instead)"

echo
echo "=== All specification/roadmap markdown docs (for conventions + topic matching) ==="
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
