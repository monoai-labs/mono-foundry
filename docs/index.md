# monofoundry - Documentation

Welcome to the monō foundry documentation. monō foundry is a thin-client CLI for the monō ai coding agent. The agent loop, model intelligence, and projects/workspaces all run server-side; the CLI streams responses and executes tool commands in your local context.

## Guides

| Guide | Description |
|-------|-------------|
| [Commands & Shortcuts](commands.md) | Full reference for CLI flags, slash commands, keyboard shortcuts, and shell mode. |
| [Daemon Local Runtime](daemon.md) | Default daemon behaviour, lifecycle commands, troubleshooting, update handling, and direct-mode recovery. |
| [MCP Servers](mcp.md) | Configure local MCP (Model Context Protocol) servers to extend the agent with custom tools. |
| [Skills](skills.md) | Create and use reusable skill instruction sets (SKILL.md files) to guide the agent on specific tasks. |
| [Subagents](subagents.md) | How the backend spawns parallel child conversations, visual attribution, tool execution, and prompting suggestions. |
| [Files & Attachments](files.md) | Attach files to messages via `@`-paths, `/attach`, and `/paste`, with binary/text classification and upload limits. |
| [Security](security.md) | Network architecture, credential encryption, tool execution model, access control, and hardening recommendations. |

## Configuration

monō foundry uses `~/.monofoundry/` as its primary configuration directory. Credentials and settings are stored at `~/.monofoundry/config.json`. Several other config locations are automatically detected as fallbacks for compatibility with other tools and editors — see each guide for the specific paths.

| Config | Primary location | Fallbacks |
|--------|-----------------|-----------|
| Daemon discovery | `~/.monofoundry/daemon.json` | None |
| Daemon logs | `~/.monofoundry/logs/daemon.log` | None |
| MCP servers | `~/.monofoundry/mcp.json` | `~/.mcp.json`, `~/.claude/mcp.json`, `~/.vscode/settings.json`, `~/.gemini/antigravity/mcp_config.json` |
| Skills | `~/.monofoundry/skills/` | `~/.claude/skills/`, `~/.agents/skills/`, `~/.cursor/skills/`, `~/.codex/skills/`, `~/.gemini/config/skills/` |
| Agent instructions | `~/.monofoundry/MONOFOUNDRY.md` | `~/.claude/CLAUDE.md`, `~/.codex/AGENTS.md`, `~/.agents/AGENTS.md`, `~/.gemini/GEMINI.md`, `~/.cursorrules` |

Workspace-level configs (in the current project directory) always take precedence over home-level configs.

To scaffold a project-level `MONOFOUNDRY.md` with auto-detected metadata (name, scripts, frameworks, languages), use the `/init` command in the REPL — see [Commands & Shortcuts](commands.md#init).

---

© monō ai Australia Pty Ltd. All rights reserved.