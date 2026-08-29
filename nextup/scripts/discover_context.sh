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

# Kick off the GitHub lookups now, in the background — `gh auth status` and
# both list calls all start immediately (the list calls aren't gated on the
# auth check finishing first; if unauthenticated they'll just fail too, and
# their output is discarded below). This overlaps all three network
# round-trips with each other AND with the local disk/git work that follows,
# instead of paying for auth-check-then-list-call latency in sequence.
gh_available=0
gh_tmp_ok=1
issues_tmp=$(mktemp) || gh_tmp_ok=0
prs_tmp=$(mktemp) || gh_tmp_ok=0
trap 'rm -f "$issues_tmp" "$prs_tmp"' EXIT
if [ "$gh_tmp_ok" -eq 1 ] && command -v gh >/dev/null 2>&1; then
  gh_available=1
  gh auth status >/dev/null 2>&1 &
  auth_pid=$!
  # The redirection wraps the whole subshell, not just the `gh` command
  # inside it — redirecting only the inner command still leaves the
  # subshell process itself holding the script's inherited stdout open
  # for its lifetime, which can block a downstream pipe reader even after
  # this script has finished (seen when this call is never waited on, in
  # the not-authenticated branch below).
  (cd "$repo_root" && gh issue list --state open --limit 200 \
    --json number,title,labels,milestone,updatedAt,url 2>/dev/null) >"$issues_tmp" &
  issues_pid=$!
  (cd "$repo_root" && gh pr list --state open \
    --json number,title,headRefName,url 2>/dev/null) >"$prs_tmp" &
  prs_pid=$!
fi

echo
echo "=== Specification / roadmap markdown docs ==="
candidates=()
spec_dirs=()
for dir in specification docs spec design; do
  [ -d "$repo_root/$dir" ] && spec_dirs+=("$repo_root/$dir")
done
if [ "${#spec_dirs[@]}" -gt 0 ]; then
  while IFS= read -r f; do candidates+=("$f"); done < <(find "${spec_dirs[@]}" \( -type f -o -type l \) -iname "*.md" 2>/dev/null)
fi
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

gh_authed=0
if [ "$gh_available" -eq 1 ] && wait "$auth_pid"; then
  gh_authed=1
fi
# When unauthenticated, the two list calls above are left un-waited and
# un-reaped on purpose: they were fired speculatively, will fail on the
# same auth wall, and their output is discarded either way — waiting on
# them here would block this script on their latency for no benefit. The
# EXIT trap unlinking their temp files out from under a still-running
# background writer is safe (rm on an open file just defers reclaiming
# the space until the last fd closes; it can't error or corrupt data).

echo
echo "=== GitHub issues (open) ==="
if [ "$gh_tmp_ok" -eq 0 ]; then
  echo "(skipped — could not create a temp file for gh output)"
elif [ "$gh_available" -eq 0 ]; then
  echo "(gh CLI not installed)"
elif [ "$gh_authed" -eq 0 ]; then
  echo "(gh CLI not authenticated — run 'gh auth login')"
else
  if wait "$issues_pid"; then
    cat "$issues_tmp"
  else
    echo "(gh issue list failed — repo may lack a GitHub remote)"
  fi
fi

echo
echo "=== Open pull requests ==="
if [ "$gh_tmp_ok" -eq 0 ]; then
  echo "(skipped — could not create a temp file for gh output)"
elif [ "$gh_available" -eq 0 ]; then
  echo "(gh CLI not installed)"
elif [ "$gh_authed" -eq 0 ]; then
  echo "(gh CLI not authenticated — run 'gh auth login')"
else
  if wait "$prs_pid"; then
    cat "$prs_tmp"
  else
    echo "(gh pr list failed — repo may lack a GitHub remote)"
  fi
fi
