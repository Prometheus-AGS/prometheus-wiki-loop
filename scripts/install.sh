#!/usr/bin/env bash
# install.sh — install kbd-close, kbd-open, and wiki-loop-mcp to ~/.local/bin
# and set up the ~/.prometheus directory tree expected by the wrappers.
#
# Re-run safely — idempotent.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BIN_DIR="${HOME}/.local/bin"
PROM_DIR="${HOME}/.prometheus"

echo "🔧 Installing prometheus-wiki-loop"
echo "  bin dir:    $BIN_DIR"
echo "  prom dir:   $PROM_DIR"
echo ""

mkdir -p "$BIN_DIR"
mkdir -p "$PROM_DIR"/{logs,knowledge,learning-log,skill-updates,bin}

# Copy binaries (use install to set exec bit atomically)
install -m 0755 "$REPO_ROOT/bin/kbd-close"      "$BIN_DIR/kbd-close"
install -m 0755 "$REPO_ROOT/bin/kbd-open"       "$BIN_DIR/kbd-open"
install -m 0755 "$REPO_ROOT/bin/wiki-loop-mcp"  "$BIN_DIR/wiki-loop-mcp"

echo "  ✅ installed: $BIN_DIR/{kbd-close,kbd-open,wiki-loop-mcp}"

# Smoke test — wrappers should print help / no-op cleanly
echo ""
echo "🧪 smoke test"
if "$BIN_DIR/kbd-close" </dev/null >/dev/null 2>&1; then
  echo "  ✅ kbd-close exits 0 on empty stdin"
else
  echo "  ⚠️  kbd-close returned non-zero (probably missing pk — see README)"
fi

if "$BIN_DIR/kbd-open" </dev/null >/dev/null 2>&1; then
  echo "  ✅ kbd-open exits 0 on empty stdin"
else
  echo "  ⚠️  kbd-open returned non-zero (probably missing pk — see README)"
fi

# Check the env file
ENV_FILE="$PROM_DIR/.env"
if [ ! -f "$ENV_FILE" ]; then
  cat > "$ENV_FILE" <<'EOF'
# Prometheus Wiki Loop — LLM endpoint configuration.
# Edit this file to point at your preferred LLM. Defaults below assume OpenAI.
CLOUD_LLM_URL=https://api.openai.com/v1
LOCAL_LLM_URL=https://api.openai.com/v1
CLOUD_LLM_API_KEY=replace-me
PK_COMPILE_MODEL=gpt-4o-mini
PK_LINT_MODEL=gpt-4o-mini
PK_FOCUS_MODEL=gpt-4o-mini
EOF
  echo ""
  echo "  📝 wrote $ENV_FILE with OpenAI defaults — set CLOUD_LLM_API_KEY before using"
fi

echo ""
echo "✨ done. next steps:"
echo "   1. set CLOUD_LLM_API_KEY in $ENV_FILE (or wire to openai-proxy)"
echo "   2. install pk CLI from https://github.com/Prometheus-AGS/prometheus-knowledge"
echo "   3. run 'kbd-close <some-file.md>' or invoke /kbd-close from your AI tool"