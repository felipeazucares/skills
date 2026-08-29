#!/usr/bin/env bash
# Smoke-tests discover_context.sh's gh-availability branches by swapping in
# stub `gh` binaries on PATH. Not wired into any CI — a fast manual re-check
# to run after touching the gh-handling logic in discover_context.sh.
set -uo pipefail

skill_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
script="$skill_dir/scripts/discover_context.sh"
target_repo="${1:-$PWD}"

fail=0
check() {
  local label="$1" expect="$2" output="$3"
  if grep -qF "$expect" <<<"$output"; then
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
check "unauthenticated: issues section warns" "(gh CLI not authenticated" "$out"
check "unauthenticated: PR section warns too" "(gh CLI not authenticated" "$out"

# gh authenticated, but the list calls themselves fail (e.g. no GitHub remote)
cat >"$stub_dir/gh" <<'EOF'
#!/usr/bin/env bash
[ "$1" = "auth" ] && exit 0
exit 1
EOF
chmod +x "$stub_dir/gh"
out=$(PATH="$stub_dir:$PATH" bash "$script" "$target_repo")
check "authed, issue list fails: issues section says so" "(gh issue list failed" "$out"
check "authed, pr list fails: PR section says so distinctly" "(gh pr list failed" "$out"

exit "$fail"
