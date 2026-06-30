#!/usr/bin/env bash
# smoke-test.sh — verify the three wrappers are present, executable, and respond.

set -uo pipefail

PASS=0
FAIL=0

check() {
  local desc="$1"; shift
  if "$@" >/dev/null 2>&1; then
    echo "  ✅ $desc"
    PASS=$((PASS + 1))
  else
    echo "  ❌ $desc"
    FAIL=$((FAIL + 1))
  fi
}

echo "🧪 prometheus-wiki-loop smoke test"
echo ""

# --- binaries ---
echo "binaries"
check "kbd-close is executable"      test -x ~/.local/bin/kbd-close
check "kbd-open is executable"       test -x ~/.local/bin/kbd-open
check "wiki-loop-mcp is executable"  test -x ~/.local/bin/wiki-loop-mcp

# --- kbd-close smoke ---
echo ""
echo "kbd-close"
check "kbd-close: empty stdin -> exit 0"        bash -c '~/.local/bin/kbd-close </dev/null'
check "kbd-close: file arg -> exit 0"           bash -c 'echo x > /tmp/kbd-test.txt && ~/.local/bin/kbd-close /tmp/kbd-test.txt'
check "kbd-close: pipe text -> exit 0"          bash -c 'echo hi | ~/.local/bin/kbd-close'

# --- kbd-open smoke ---
echo ""
echo "kbd-open"
check "kbd-open: empty stdin -> exit 0"         bash -c '~/.local/bin/kbd-open </dev/null'

# --- wiki-loop-mcp smoke ---
echo ""
echo "wiki-loop-mcp"
RESP="$(printf '%s\n%s\n' \
  '{"jsonrpc":"2.0","id":1,"method":"initialize","params":{"protocolVersion":"2024-11-05","capabilities":{},"clientInfo":{"name":"smoke","version":"0"}}}' \
  '{"jsonrpc":"2.0","id":2,"method":"tools/list"}' \
  | wiki-loop-mcp 2>/dev/null)"

# Count individual tool names in the tools/list response.
# Expected tools: add_to_wiki, prime_context, search_wiki, focus_wiki,
# list_recent_learnings, list_wiki_entries, list_pending_skill_updates.
EXPECTED=7
HITS=0
for tool in add_to_wiki prime_context search_wiki focus_wiki list_recent_learnings list_wiki_entries list_pending_skill_updates; do
  if echo "$RESP" | grep -q "\"name\":\"$tool\""; then
    HITS=$((HITS + 1))
  fi
done

if [ "$HITS" -eq "$EXPECTED" ]; then
  echo "  ✅ wiki-loop-mcp: tools/list returned all $EXPECTED tools ($HITS/$EXPECTED)"
  PASS=$((PASS + 1))
else
  echo "  ❌ wiki-loop-mcp: tools/list returned $HITS/$EXPECTED tools"
  FAIL=$((FAIL + 1))
fi

echo ""
echo "===================================="
echo "  $PASS passed, $FAIL failed"
echo "===================================="
[ "$FAIL" -eq 0 ]