# Architecture

Three layers, three failure modes, three trigger surfaces.

## Layer 1 — `kbd-close` (the write)

The shell wrapper that runs at every session boundary. Always exits 0.
Reads the summary from one of three sources (file, stdin JSON, or fallback),
detects the active KBD phase, enriches the summary with phase context, and
runs the close pipeline:

1. Write summary to `~/.prometheus/last-session-summary.txt`
2. Call `pk ingest --source <tag> --scope shared` (compiles via the configured LLM)
3. Append JSONL entry to `~/.prometheus/learning-log/<today>.jsonl`
4. Invoke `propose-skill-update.sh` (writes candidates, never applies)
5. Optional `forge reflect` if `.forge/iterations/` exists

## Layer 2 — `kbd-open` (the read)

The shell wrapper that runs at session start. Always exits 0.
Detects the active KBD phase, runs `pk focus` on the phase name + goals,
and writes a snapshot to `~/.prometheus/last-open-snapshot.txt`. The
agent reads the snapshot as its first action.

## Layer 3 — `wiki-loop-mcp` (the chat surface)

Zero-dependency Node stdio MCP server. 7 tools, all shelled out to `pk`
or the wrappers. Registered in any MCP-capable chat tool (Claude Desktop,
Kimi Desktop, Mavis/MiniMax Desktop, Codex).

The MCP server is what closes the gap for tools without lifecycle hooks.
A user in Claude Desktop chat can say "save this conversation to the wiki"
and the agent calls `add_to_wiki` automatically.

## Trigger matrix

| Tool | Stop hook | SessionStart hook | MCP chat |
|---|---|---|---|
| Claude Code | ✅ Stop + PreCompact | ✅ SessionStart | n/a |
| OpenCode | via plugin tool | via plugin tool | n/a |
| Codex | via `notify` chain | n/a | n/a |
| Kimi Code | via skill invocation | via skill | n/a |
| Claude Desktop chat | n/a | n/a | ✅ wiki-loop-mcp |
| Kimi Desktop chat | n/a | n/a | ✅ wiki-loop-mcp |
| Codex chat | n/a | n/a | ✅ wiki-loop-mcp |
| Mavis / MiniMax Desktop | via skill | via skill | ✅ wiki-loop-mcp |
| Bare shell | `kbd-close <file>` | `kbd-open` | n/a |

All paths write to the same `~/.prometheus/knowledge/shared/wiki/` directory.
The wiki is the source of truth. The wrappers are just transport.

## What stops the loop from being a toy

Three structural properties, repeated for emphasis because they are load-bearing:

1. **The producer and the critic are separate models.** `learn-grade` runs through `sycophancy-correction` MCP. Self-reported fluency never closes a Feynman loop.
2. **Skill-update candidates are files, not applied changes.** `propose-skill-update.sh` writes to `~/.prometheus/skill-updates/`. A human reviews and runs `pmpo-skill-creator --update <name>` to approve. Cedar-governed by default-deny.
3. **The wiki is plain markdown.** No vector database, no black-box embeddings. Every fact traces to a `.md` file a human can read, edit, and `git blame`.

If you remove any of those three, you have a different system. You have a documentation tool, or a RAG pipeline, or a self-modifying agent. None of those are the Karpathy loop. The Karpathy loop is the system where the producer and critic are different, where self-modification is gated, and where the knowledge substrate is readable by the human it serves.