#!/usr/bin/env bash
# Smoke-tests discover_context.sh's gh-availability branches by swapping in
# stub `gh` binaries on PATH. Not wired into any CI — a fast manual re-check
# to run after touching the gh-handling logic in discover_context.sh.
set -uo pipefail

skill_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
script="$skill_dir/scripts/discover_context.sh"
target_repo="${1:-$PWD}"

fail=0

# Extracts just the lines under one "=== heading ===" (up to the next
# heading or EOF), so a check against the PR section can't pass because
# the same text happens to appear in the issues section above it.
section() {
  local heading="$1" text="$2"
  awk -v h="$heading" '
    $0 == h { flag=1; next }
    flag && /^=== / { flag=0 }
    flag { print }
  ' <<<"$text"
}

check() {
  local label="$1" expect="$2" text="$3"
  if grep -qF "$expect" <<<"$text"; then
    echo "ok   - $label"
  else
    echo "FAIL - $label (expected to find: $expect)"
    fail=1
  fi
}

stub_dir=$(mktemp -d)
trap 'rm -rf "$stub_dir"' EXIT

# gh installed but not authenticated
cat >"$stub_dir/gh" <<'EOF'
#!/usr/bin/env bash
exit 1
EOF
chmod +x "$stub_dir/gh"
out=$(PATH="$stub_dir:$PATH" bash "$script" "$target_repo")
check "unauthenticated: issues section warns" "(gh CLI not authenticated" \
  "$(section '=== GitHub issues (open) ===' "$out")"
check "unauthenticated: PR section warns too" "(gh CLI not authenticated" \
  "$(section '=== Open pull requests ===' "$out")"

# gh authenticated, but the list calls themselves fail (e.g. no GitHub remote)
cat >"$stub_dir/gh" <<'EOF'
#!/usr/bin/env bash
[ "$1" = "auth" ] && exit 0
exit 1
EOF
chmod +x "$stub_dir/gh"
out=$(PATH="$stub_dir:$PATH" bash "$script" "$target_repo")
check "authed, issue list fails: issues section says so" "(gh issue list failed" \
  "$(section '=== GitHub issues (open) ===' "$out")"
check "authed, pr list fails: PR section says so distinctly" "(gh pr list failed" \
  "$(section '=== Open pull requests ===' "$out")"

# gh authenticated and both list calls succeed — real content should reach
# each section verbatim, not a fallback message.
cat >"$stub_dir/gh" <<'EOF'
#!/usr/bin/env bash
[ "$1" = "auth" ] && exit 0
[ "$1" = "issue" ] && { echo '[{"number":1,"title":"stub issue"}]'; exit 0; }
[ "$1" = "pr" ] && { echo '[{"number":2,"title":"stub pr"}]'; exit 0; }
exit 1
EOF
chmod +x "$stub_dir/gh"
out=$(PATH="$stub_dir:$PATH" bash "$script" "$target_repo")
check "authed, issue list succeeds: real content shown" "stub issue" \
  "$(section '=== GitHub issues (open) ===' "$out")"
check "authed, pr list succeeds: real content shown" "stub pr" \
  "$(section '=== Open pull requests ===' "$out")"

exit "$fail"
