# monofoundry - MCP Servers

Configure local MCP (Model Context Protocol) servers to extend the agent with custom tools. The agent can discover, list, and call tools exposed by any stdio-based MCP server you configure.

---

## Table of Contents

- [Overview](#overview)
- [Config File Locations](#config-file-locations)
- [Config Formats](#config-formats)
  - [servers (recommended)](#servers-recommended)
  - [mcpServers (legacy)](#mcpservers-legacy)
  - [VS Code settings.json](#vs-code-settingsjson)
- [Server Configuration](#server-configuration)
- [Transport](#transport)
- [Lifecycle](#lifecycle)
- [Approval Mode](#approval-mode)
- [JSONC Support](#jsonc-support)
- [Examples](#examples)

---

## Overview

MCP servers are local processes that expose tools via the Model Context Protocol. The CLI discovers server configurations from a set of well-known config files, connects to servers on demand, and exposes their tools to the agent. The agent can then call those tools as part of its normal workflow.

Two tools are registered for the agent:

- **`list_mcp_servers`** — discovers and lists all configured servers with their status, transport, and available tools.
- **`call_mcp_tool`** — calls a specific tool on a specific server, passing arguments through.

Servers are discovered from config files in your workspace and home directory. Discovery is stateless and re-run on demand — no file watchers, no background processes until a tool is actually called.

---

## Config File Locations

The CLI scans config files in a fixed order. **The first file to define a server name wins** — if two files both define a server called `"my-server"`, the one earlier in the list takes precedence. Workspace configs are scanned before home configs, so project-level settings override user-level ones.

| # | Location | Format | Scope |
|---|----------|--------|-------|
| 1 | `<workspace>/.mcp.json` | `servers` | Workspace |
| 2 | `<workspace>/.claude/mcp.json` | `servers` | Workspace |
| 3 | `<workspace>/.vscode/mcp.json` | `servers` | Workspace |
| 4 | `~/.monofoundry/mcp.json` | `servers` | Home |
| 5 | `~/.mcp.json` | `servers` | Home |
| 6 | `~/.claude/mcp.json` | `servers` | Home |
| 7 | `~/.vscode/settings.json` | `vscodeSettings` | Home |
| 8 | `~/.gemini/antigravity/mcp_config.json` | `mcpServers` | Home |

`~/.monofoundry/mcp.json` is the primary home-level config location. The remaining paths are automatically detected as fallbacks for compatibility with other tools and editors (VS Code, Claude Code, Antigravity, etc.).

---

## Config Formats

Three config-file formats are recognised. The format is determined by the file's location (see the table above), not by its content.

### servers (recommended)

Used by `.mcp.json`, `.claude/mcp.json`, and `~/.monofoundry/mcp.json`. This is the VS Code native format.

```json
{
  "servers": {
    "filesystem": {
      "type": "stdio",
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-filesystem", "/Users/me/projects"],
      "env": {}
    },
    "github": {
      "type": "stdio",
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-github"],
      "env": {
        "GITHUB_PERSONAL_ACCESS_TOKEN": "ghp_xxxxxxxxxxxx"
      }
    }
  }
}
```

### mcpServers (legacy)

Used by `~/.gemini/antigravity/mcp_config.json`. This is the Antigravity legacy format. It uses `serverUrl` instead of `url` and `disabled` instead of `enabled`.

```json
{
  "mcpServers": {
    "my-server": {
      "command": "npx",
      "args": ["-y", "@some/mcp-server"],
      "env": {
        "API_KEY": "xxx"
      },
      "disabled": false
    }
  }
}
```

### VS Code settings.json

Used by `~/.vscode/settings.json`. Servers are nested under the `"mcp.servers"` key.

```json
{
  "mcp.servers": {
    "my-server": {
      "type": "stdio",
      "command": "npx",
      "args": ["-y", "@some/mcp-server"]
    }
  }
}
```

---

## Server Configuration

Each server entry supports the following fields:

| Field | Type | Description |
|-------|------|-------------|
| `type` | `"stdio"` \| `"sse"` | Transport type. Auto-detected: `"sse"` if `url`/`serverUrl` is present, otherwise `"stdio"`. See [Transport](#transport). |
| `command` | `string` | The executable to spawn (e.g. `"npx"`, `"node"`, `"python"`). |
| `args` | `string[]` | Arguments passed to the command. |
| `env` | `Record<string, string>` | Environment variables, merged with the current process environment. Config values override existing ones. |
| `cwd` | `string` | Working directory for the spawned process. Resolved relative to the config file's directory. Defaults to the config file's directory. |
| `url` | `string` | Server URL for SSE transport (`serverUrl` in the legacy format). **SSE is not supported** — see [Transport](#transport). |
| `enabled` | `boolean` | Whether the server is enabled. Defaults to `true`. Set to `false` to disable. (Legacy format uses `disabled: true` instead.) |

> **Note:** On Windows, the `command` is spawned with `shell: true` so that `npx` and similar wrappers resolve correctly.

---

## Transport

Only **stdio** transport is supported. The CLI spawns the server process, communicates over stdin/stdout using JSON-RPC 2.0, and performs the standard MCP `initialize` handshake (protocol version `2024-11-05`).

SSE transport is **not** supported. If a server config specifies `type: "sse"` or includes a `url`/`serverUrl`, the server will appear in listings with an error status (`"SSE transport not supported"`) and tool calls will fail.

---

## Lifecycle

- **Discovery** is stateless and re-run every time `list_mcp_servers` or `call_mcp_tool` is invoked. No background scanning or file watchers.
- **Connection is lazy.** Servers are not started when the CLI launches. A server process is spawned only when the agent first calls a tool on that server (auto-connect).
- **Tools are cached.** After connecting, the server's tool list (`tools/list`) is cached for the duration of the session.
- **Per-request timeout.** Each JSON-RPC request has a 30-second timeout. If a server doesn't respond in time, the request fails with a timeout error.
- **Cleanup on exit.** All spawned server processes are killed when the CLI exits. Servers are also `unref`'d so they don't prevent the CLI from exiting cleanly.

If a server fails to connect, the error message includes the command and arguments to help diagnose the issue (e.g. missing executable, wrong path, server crash on startup).

---

## Approval Mode

`call_mcp_tool` is classified as a **mutating tool**. When approval mode is enabled (`--approve` flag or `/approve` command), the CLI shows a summary of the server name and tool name before executing the call, and prompts you to accept, reject, or skip.

Even when approval mode is off, a brief summary of the MCP tool call is displayed before execution.

---

## JSONC Support

All config files support **JSONC** (JSON with Comments). You can include `//` line comments and trailing commas — they are stripped before parsing. If strict JSON parsing fails, the CLI falls back to JSONC parsing automatically.

```jsonc
{
  "servers": {
    // Filesystem access for the current project
    "filesystem": {
      "type": "stdio",
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-filesystem", "./src"],
    }
  }
}
```

---

## Examples

### Filesystem server (workspace-level)

Create `<workspace>/.mcp.json`:

```json
{
  "servers": {
    "filesystem": {
      "type": "stdio",
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-filesystem", "/Users/me/projects"]
    }
  }
}
```

### GitHub server with environment variables (home-level)

Create `~/.monofoundry/mcp.json`:

```json
{
  "servers": {
    "github": {
      "type": "stdio",
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-github"],
      "env": {
        "GITHUB_PERSONAL_ACCESS_TOKEN": "ghp_xxxxxxxxxxxx"
      }
    }
  }
}
```

### Custom local server with a working directory

```json
{
  "servers": {
    "my-tool": {
      "type": "stdio",
      "command": "node",
      "args": ["./mcp-server.js"],
      "cwd": "./tools",
      "env": {
        "DEBUG": "true"
      }
    }
  }
}
```

### Disabling a server

```json
{
  "servers": {
    "legacy-tool": {
      "type": "stdio",
      "command": "python",
      "args": ["-m", "old_mcp_server"],
      "enabled": false
    }
  }
}
```

---

© monō ai Australia Pty Ltd. All rights reserved.