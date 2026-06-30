# Prometheus Wiki Loop

> Three small tools that turn any AI coding session — Claude Code, OpenCode,
> Codex, Claude Desktop, Kimi Desktop, Mavis/MiniMax Desktop, or a bare shell —
> into a contribution to a shared, human-readable, version-controlled
> knowledge base.

The Karpathy pattern, in shell. Plain markdown wiki, LLM-compiled, TF-IDF
searchable, no vector database. Every session closes by writing what was
learned into the wiki. The next session opens with the wiki already primed.

## What's in the box

| File | What it does | When it runs |
|---|---|---|
| `bin/kbd-close` | Universal session-close hook. Reads a summary (file, stdin JSON, or fallback), enriches it with active KBD phase context, calls `pk ingest` to compile into the wiki via the openai-proxy, appends a learning-log JSONL entry, files a skill-update candidate. Always exits 0. | End of every session (Stop hook, PreCompact hook, notify, or manual) |
| `bin/kbd-open` | Session-prime companion. Detects active KBD phase from `.kbd-orchestrator/current-waypoint.json`, reads position reminder + phase goals, runs `pk focus` on the phase, surfaces pending skill-update candidates + today's learning log. Writes a snapshot to `~/.prometheus/last-open-snapshot.txt`. | Start of every session (SessionStart hook, or manual) |
| `bin/wiki-loop-mcp` | Zero-dependency Node stdio MCP server. Exposes 7 tools (`add_to_wiki`, `prime_context`, `search_wiki`, `focus_wiki`, `list_recent_learnings`, `list_wiki_entries`, `list_pending_skill_updates`) so any MCP-capable chat tool can contribute to the wiki by natural-language prompt. | Whenever the chat tool calls a tool |

All three scripts:

- Are MIT licensed, < 500 lines each, zero non-stdlib dependencies
- Source `~/.prometheus/.env` automatically so the LLM endpoint (openai-proxy, OpenAI, Anthropic, Groq, etc.) is configurable per environment
- Always exit 0 — a hook failure never breaks the calling tool

## Install

```bash
# 1. Install the wrappers to ~/.local/bin (must be on PATH)
./scripts/install.sh

# 2. Seed the env file with your LLM endpoint
cat > ~/.prometheus/.env <<'EOF'
CLOUD_LLM_URL=https://api.openai.com/v1          # or http://localhost:8181/v1 for openai-proxy
LOCAL_LLM_URL=https://api.openai.com/v1
CLOUD_LLM_API_KEY=sk-...
PK_COMPILE_MODEL=gpt-4o-mini
PK_LINT_MODEL=gpt-4o-mini
PK_FOCUS_MODEL=gpt-4o-mini
EOF

# 3. Make sure pk is installed (from the prometheus-knowledge crate)
#    and the prometheus-knowledge MCP server is running on port 8942.
#    See: https://github.com/Prometheus-AGS/prometheus-knowledge

# 4. (Optional) Register the MCP server in your chat tool
#    Claude Desktop, Mavis/MiniMax, Kimi Code CLI, Codex:
{
  "mcpServers": {
    "wiki-loop": {
      "command": "/Users/gqadonis/.local/bin/wiki-loop-mcp"
    }
  }
}
```

That's it. From this point:

- Every Claude Code session begins with `last-open-snapshot.txt` showing your active KBD phase + focused wiki hits + pending skill-updates
- Every Claude Code session ends (or compacts) with the work written into the wiki
- Codex, OpenCode, Kimi Code, Mavis/MiniMax Desktop — same wiki, different trigger surface
- Chat surfaces (Claude Desktop, Kimi Desktop chat, Codex chat) — say "save this conversation to the wiki" and the agent calls `add_to_wiki` automatically

## The full architecture

```
┌──────────────────────────────────────────────────────────────────┐
│                  AI Tools (any of these)                          │
│                                                                   │
│   Claude Code    Codex    OpenCode    Kimi Code                   │
│       ↓           ↓          ↓           ↓                        │
│   Stop/PreCompact  notify    plugin      /kbd-close skill         │
│       ↓           ↓          ↓           ↓                        │
│   ┌──────────────────────────────────────────────────┐           │
│   │         ~/.local/bin/kbd-close (universal)        │           │
│   └──────────────────────────────────────────────────┘           │
│                            ↓                                     │
│   ┌──────────────────────────────────────────────────┐           │
│   │   Detect KBD phase + enrich + pk ingest + log    │           │
│   └──────────────────────────────────────────────────┘           │
│                            ↓                                     │
│   ┌──────────────────────────────────────────────────┐           │
│   │  ~/.prometheus/knowledge/shared/wiki/*.md        │           │
│   │  ~/.prometheus/learning-log/YYYY-MM-DD.jsonl     │           │
│   │  ~/.prometheus/skill-updates/                    │           │
│   └──────────────────────────────────────────────────┘           │
│                                                                   │
│   Chat surfaces (Claude Desktop, Kimi Desktop, Codex chat)        │
│       ↓  "save this to the wiki"                                  │
│   ┌──────────────────────────────────────────────────┐           │
│   │       ~/.local/bin/wiki-loop-mcp (MCP server)    │           │
│   │   7 tools: add_to_wiki, prime_context, ...       │           │
│   └──────────────────────────────────────────────────┘           │
└──────────────────────────────────────────────────────────────────┘
```

## What it depends on

- **bash** (for kbd-close / kbd-open)
- **node** ≥ 18 (for wiki-loop-mcp, zero deps)
- **python3** (for the JSON extraction helpers in kbd-close)
- **pk CLI** (from [prometheus-knowledge](https://github.com/Prometheus-AGS/prometheus-knowledge)) — compiled to `~/.prometheus/bin/pk` or on PATH
- **prometheus-knowledge MCP server** running on `:8942` (or override with `PK_BIN` env var)
- An **LLM endpoint** reachable by the chosen `CLOUD_LLM_URL` (default: OpenAI; works equally with the local openai-proxy on `:8181` or any OpenAI-compatible service)

## The related projects

This toolkit is one piece of the [Prometheus Fabric](https://github.com/Prometheus-AGS/prometheus-fabric), an open-source multi-repository platform for sovereign agentic AI built on [BossFang (librefang)](https://github.com/GQAdonis/librefang). Related crates:

- [`prometheus-knowledge`](https://github.com/Prometheus-AGS/prometheus-knowledge) — the Rust `pk` CLI and `pk-cherry` MCP server this toolkit calls
- [`surreal-memory-server`](https://github.com/Prometheus-AGS/surreal-memory-server) — the optional graph-memory + TaskStreams backend
- [`prometheus-skill-pack`](https://github.com/Prometheus-AGS/prometheus-skill-system) — the 280+ skill manifests and 4-layer PMPO pipeline that *uses* this toolkit for cross-session compounding
- [`prometheus-entity-management`](https://github.com/Prometheus-AGS/prometheus-entity-management) — the React entity graph that consumes the wiki as a knowledge plane

## License

MIT — see [`LICENSE`](LICENSE).