# monofoundry - Security

An overview of the security properties of the monō foundry CLI - its network architecture, credential handling, tool execution model, and the access controls that govern what the agent can see and do.

---

## Table of Contents

- [Overview](#overview)
- [Network Architecture](#network-architecture)
  - [Backend and Local Daemon Endpoints](#backend-and-local-daemon-endpoints)
  - [Complete List of Network Endpoints](#complete-list-of-network-endpoints)
  - [No Outbound Calls from Tool Execution](#no-outbound-calls-from-tool-execution)
- [Credential Storage & Encryption at Rest](#credential-storage--encryption-at-rest)
  - [Threat Model](#threat-model)
  - [Encryption Design](#encryption-design)
  - [File Permissions](#file-permissions)
  - [Atomic Writes](#atomic-writes)
- [Agent Loop & Tool Execution](#agent-loop--tool-execution)
  - [Server-Side Orchestration](#server-side-orchestration)
  - [Fixed Tool Registry](#fixed-tool-registry)
  - [Local Execution with User Permissions](#local-execution-with-user-permissions)
  - [Tool Watchdog](#tool-watchdog)
- [Approval Mode](#approval-mode)
- [Access Control](#access-control)
  - [Role-Based Access Control](#role-based-access-control)
  - [Organisation Scoping](#organisation-scoping)
  - [Project & Work Item Scoping](#project--work-item-scoping)
- [User-Scoped Connections](#user-scoped-connections)
  - [Local MCP Servers](#local-mcp-servers)
  - [Platform Connections](#platform-connections)
- [Web Search & SafeLinks](#web-search--safelinks)
- [OAuth Authentication Flow](#oauth-authentication-flow)
- [No Telemetry or Analytics](#no-telemetry-or-analytics)
- [Data Minimisation](#data-minimisation)
- [Hardening Recommendations](#hardening-recommendations)

---

## Overview

monō foundry is a **thin client**. The agent loop, model intelligence, tool selection, and orchestration all run server-side on the monō ai backend. The CLI's job is to stream responses, execute tool commands locally, and post the results back. This architecture has security implications that flow through every aspect of the tool:

- The CLI does not choose which tools to run - the backend does.
- The CLI does not perform web searches, call third-party APIs, or make arbitrary network requests - the backend handles external lookups.
- The CLI's network footprint is small and predictable: one backend endpoint for Core communication, a loopback daemon connection for the default local runtime, plus optional GitHub calls for update checks and installs.
- Credentials stored on disk are encrypted with a key that is not in the source code and not in the config file.

---

## Network Architecture

### Backend and Local Daemon Endpoints

All Core agent communication - streaming responses, tool command dispatch, tool result posting, file uploads, model listing, conversation/project/work-item queries - goes to a single backend endpoint. The default is `https://core.monoai.co`, set at login time and stored in the local config. It can be overridden with `--endpoint <url>`.

The Studio web app URL (used for deep-links to projects, work items, and conversations) defaults to `https://app.monoai.co`. It can be overridden with `--app-url <url>`. If `--app-url` is omitted while `--endpoint` is provided, the app URL is derived by swapping the `app`↔`core` subdomain prefix (e.g. `core-staging.monoai.co` → `app-staging.monoai.co`). Derivation only succeeds for hostnames ending in `monoai.co` or `sprnt.ai`; otherwise an error is raised. Both `--endpoint` and `--app-url` are persisted per-project at `~/.monofoundry/projects/<slug>/config.json` so they are remembered on subsequent runs in that project.

By default, interactive and one-shot CLI sessions connect to a local monofoundry daemon over loopback. The daemon is the local runtime host: it owns the Core stream, executes local tools, and relays events back to the CLI client. It binds to `127.0.0.1`, requires a bearer token from `~/.monofoundry/daemon.json`, and is not exposed as a remote service.

The CLI **never** makes HTTP requests to arbitrary hosts as part of its core function. There is no general-purpose HTTP client, no plugin download mechanism, and no way for the agent to instruct the CLI to call an arbitrary URL. The only network calls the CLI makes are to the configured backend endpoint, loopback daemon endpoint, update endpoints, and OAuth callback endpoint listed below.

### Complete List of Network Endpoints

| Endpoint | Protocol | When | Purpose |
|----------|----------|------|---------|
| `core.monoai.co` (default, configurable) | HTTPS | Every turn | Agent streaming, tool dispatch, file uploads, auth verification, model/conversation/project queries |
| `api.github.com` | HTTPS | `/update` command or startup check (24h cache) | Check for new releases |
| `raw.githubusercontent.com` | HTTPS | Only when an update is installed | Download the install script |
| `app.monoai.co` (default, configurable via `--app-url`) | HTTPS | When deep-links are opened (in the user's browser, not from the CLI process) | Studio project/work-item/conversation links |
| OAuth provider (Google/Microsoft) | HTTPS | Only during `auth login` (opened in the user's browser) | SSO sign-in |
| `127.0.0.1` (localhost) | HTTP/SSE/WebSocket | Default daemon-client mode | Local daemon transport for interactive, one-shot, and IDE bridge sessions |
| `127.0.0.1` (localhost) | HTTP | Only during `auth login` | Ephemeral callback server to capture the OAuth token |

No other outbound network connections are made by the CLI itself.

### No Outbound Calls from Tool Execution

The tools the CLI executes locally - file operations, terminal commands, search, git, code runner, diagnostics - do not make network calls. The code runner, for example, writes code to a local temp directory and runs it with the local interpreter (Node, Python, tsx); it does not connect to a remote sandbox service. File uploads go to the backend endpoint, not to any third-party storage.

The one exception is **local MCP servers**, which are user-configured external processes. See [User-Scoped Connections](#user-scoped-connections) below.

---

## Credential Storage & Encryption at Rest

### Threat Model

The encryption design protects against a specific threat: the config file (or the entire `~/.monofoundry/` directory) being **accidentally synced or leaked** - for example, picked up by iCloud, Dropbox, or a backup - and then read on another machine. An attacker who already has access to the originating machine is explicitly out of scope (they can reproduce the decryption key), and knowledge of the source code alone must not be sufficient to decrypt.

### Encryption Design

The authentication token is encrypted at rest using **AES-256-GCM** with a key derived via **scrypt** (per-file random salt). The key is derived from a secret that lives **outside** the config file and is **not** in the source code:

- **`MONOFOUNDRY_PASSPHRASE`** environment variable, if set (portable across machines, e.g. CI), or
- An **OS machine identifier** (macOS `IOPlatformUUID`, Linux `/etc/machine-id`, Windows `MachineGuid`).

A synced-away config file therefore yields only ciphertext plus public source code - no usable key. On the originating machine, the key is reconstructible, which is acceptable per the threat model.

The on-disk token is stored as a self-describing encrypted envelope (`{v, alg, kdf, src, salt, iv, tag, data}`) that records the algorithm, KDF, key source, and all cryptographic parameters. Legacy plaintext tokens (from before encryption was added) are automatically upgraded on the next save.

Only the `token` field is encrypted. Other config fields (endpoint, user info, org ID, login method) remain readable for debuggability.

### File Permissions

The config directory (`~/.monofoundry/`) is hardened to `0700` (owner-only access) and the config file to `0600` (owner-only read/write). Permission hardening is best-effort and is a no-op on Windows.

### Atomic Writes

Config writes are atomic: content is written to a temp file, permissions are set, and the temp file is renamed over the target. A reader (or a crash) never observes a half-written config file.

---

## Agent Loop & Tool Execution

### Server-Side Orchestration

The backend decides which tools to run. In direct mode, the CLI sends the user's message (plus workspace context) to the backend, receives a stream of SSE events, and when the backend sends an `ide_automation_command` event naming a tool, the CLI executes it locally and posts the result back. In default daemon mode, the local daemon owns that same Core stream and tool round-trip, while the foreground CLI attaches to the daemon over loopback. The CLI and daemon **never** choose tools themselves - they are passive executors of the backend's decisions.

This means the agent's intelligence, including decisions about which files to read, which commands to run, and which edits to make, all happen server-side under the backend's access control and safety policies.

### Fixed Tool Registry

The set of tools the CLI can execute is **fixed at build time** - defined in the tool registry and compiled into the binary. The agent cannot instruct the CLI to run arbitrary executables or access capabilities outside the registry. The available tools are:

| Category | Tools |
|----------|-------|
| File operations | `read_file`, `write_file`, `apply_diff`, `batch_read_files`, `list_directory`, `create_directory`, `delete_file`, `move_file` |
| Search | `search_files`, `search_text`, `search_and_replace` |
| Terminal | `run_terminal`, `spawn_terminal`, `read_terminal`, `write_terminal`, `kill_terminal`, `list_terminals` |
| Tasks | `run_task` |
| Code execution | `code_runner` (local temp directory, no remote sandbox) |
| Git | `get_git_status`, `get_recent_changes`, `get_file_diff` |
| Workspace | `get_workspace_info`, `open_file`, `get_open_editors` |
| Skills | `list_skills`, `invoke_skill` |
| Diagnostics | `get_diagnostics` |
| MCP | `list_mcp_servers`, `call_mcp_tool` |

The tool list is advertised to the backend as part of the workspace context, so the agent knows what is available. Unknown tool names return an error without executing.

### Local Execution with User Permissions

All tools execute locally with the permissions of the user running the CLI. The CLI does not escalate privileges, run as a different user, or execute code in a remote sandbox. Terminal commands run in the user's shell; file operations use the user's filesystem permissions; git commands use the user's git configuration.

This means the CLI's filesystem and process access is exactly what the running user has - no more, no less. See [Hardening Recommendations](#hardening-recommendations) for guidance on limiting this.

### Tool Watchdog

Every tool execution is wrapped in a 60-second watchdog. A tool that never resolves (e.g. a spawned process that silently hangs) returns an error result rather than wedging the entire turn. The underlying process may still be alive after the watchdog fires - per-tool timeouts handle cleanup at the tool level.

---

## Approval Mode

The CLI provides an approval gate for mutating operations. When enabled (`--approve` flag or `/approve` command in the REPL), the following tools are intercepted before execution:

- `write_file` — create or overwrite files
- `apply_diff` — apply targeted edits to files
- `search_and_replace` — multi-file text replacement
- `delete_file` — delete files or directories
- `move_file` — move or rename files (can overwrite the destination)
- `call_mcp_tool` — call a tool on a local MCP server
- `code_runner` — execute code or shell commands (including a `bash -c` fallback mode)

For each intercepted tool, the CLI:

1. **Renders a coloured diff preview** of the proposed change (or a summary for non-diff operations like `search_and_replace`, `call_mcp_tool`, `code_runner`, and `move_file`). This preview is **always shown**, even when approval mode is off - so you always see what is about to change before it happens. For `code_runner`, the preview distinguishes between code execution (showing the language and code) and shell command fallback mode (labelled explicitly).
2. **Prompts the user** to accept, skip, or reject with guidance (when approval mode is on).

If you reject with guidance, your message is sent back to the agent as a command error, so the agent adapts its approach. If you skip, the tool is silently skipped and generation continues.

> **Note:** Approval mode is only available in the interactive REPL. In one-shot mode (`monofoundry "message"`), the diff preview is still rendered but no prompt is presented.

> **Design note:** Terminal tools (`run_terminal`, `spawn_terminal`, `write_terminal`, `kill_terminal`) and `run_task` are **not** gated by approval mode. This is deliberate: terminal tools are expected to execute commands as part of normal agent operation (build, test, lint, git), and gating every command would make approval mode impractical. The `code_runner` tool is gated because its shell command fallback mode can execute arbitrary commands without the user expecting terminal-level access from a "code execution" tool.

---

## Access Control

### Role-Based Access Control

The monō ai platform enforces **role-based access control (RBAC)** server-side. Every API call the CLI makes is authenticated and authorised by the backend. The CLI itself does not implement access control - it simply presents the user's credentials and the backend determines what they can see and do.

This means:

- The agent can only access projects, work items, conversations, models, and connections that the authenticated user has permission to access.
- Organisation administrators control what each user or role can do via the platform's permission system.
- The CLI cannot bypass these controls - it has no way to access resources the backend does not authorise.

### Organisation Scoping

The CLI sends an `X-Organisation-Context` header with every API call, identifying the active organisation. This scopes all queries - models, conversations, projects, work items - to the user's membership in that organisation. Users can belong to multiple organisations and switch between them; the active organisation determines the scope of everything the agent can access.

### Project & Work Item Scoping

A session can be scoped to a specific project and work item (`--project` flag, `/project` and `/workitem` commands). When set, the agent's context is linked to that project/work item on the backend, and conversations are associated with it. This provides an additional layer of scoping - the agent operates within the context of a specific work item, not the user's entire accessible surface.

---

## User-Scoped Connections

### Local MCP Servers

Users can extend the agent with their own tools by configuring local MCP (Model Context Protocol) servers. These are **local processes** that the CLI spawns on demand (stdio transport only) and exposes to the agent. See the [MCP Servers guide](mcp.md) for configuration details.

MCP servers are user-configured and run with the user's permissions. They can make their own network calls to whatever services they are designed to reach - but this is entirely under the user's control. The CLI does not configure, contact, or trust any MCP server by default. MCP tool calls are classified as mutating operations and are subject to [approval mode](#approval-mode) when enabled.

### Platform Connections

The monō ai backend provides a rich set of platform-level connections to external services and data sources (search providers, knowledge bases, APIs, etc.). These connections are managed server-side and are subject to the platform's RBAC - users only see and can use connections their organisation has enabled and their role permits. The CLI does not directly contact these services; the backend mediates all access.

Users can also add their own scoped connections through the platform, extending the agent's reach to additional services while remaining under the backend's access control and audit logging.

---

## Web Search & SafeLinks

Web searches, URL fetches, and other external lookups performed by the agent are carried out **by the backend**, not by the CLI. The CLI never makes web search requests, fetches arbitrary URLs, or contacts external hosts on behalf of the agent.

The backend's external lookups are protected by a **SafeLinks** service that screens target hosts against threat intelligence before any request is made. Potentially malicious hosts are detected and blocked, preventing the agent from being directed to compromise infrastructure via prompt injection or other attack vectors.

This design means:

- The CLI's network surface remains minimal - it does not need to implement URL screening, threat detection, or content filtering locally.
- All external lookups are centralised, logged, and subject to the platform's security policies.
- An attacker who attempts to direct the agent to a malicious URL (e.g. via a prompt injection in a file or web page) is stopped at the backend, before any request reaches the target.

---

## OAuth Authentication Flow

The CLI supports two authentication methods:

- **API key** (`sk-` or `sk_` prefix) - sent in an `X-API-Key` header.
- **OAuth** (Google or Microsoft SSO) - the token is sent in an `Authorization: Bearer` header.

During OAuth login, the CLI:

1. Opens the user's default browser to the monō ai backend's OAuth endpoint (which redirects to Google/Microsoft).
2. Starts an ephemeral HTTP server on `127.0.0.1` (localhost only, random port) to capture the callback token.
3. Accepts the token from either the localhost callback or a manually pasted redirect URL (for headless environments).
4. Closes the localhost server immediately after receiving the token (or after a 5-minute timeout).

The CLI never handles the user's Google/Microsoft credentials directly - the browser-based OAuth flow is mediated by the backend. The localhost server binds only to `127.0.0.1` and is not accessible from other machines.

---

## No Telemetry or Analytics

The CLI does not collect, transmit, or store analytics, usage telemetry, or tracking data. It does not phone home, beacon, or report usage statistics to any server. The only data sent to the backend is what is required for the agent to function:

- The user's message and conversation history.
- Workspace context (OS, detected frameworks, git status, available tools, skills, project instructions).
- Tool command results (output of local tool execution).
- File uploads (binary attachments the user explicitly attaches).

In daemon-default mode, a local daemon may continue running between turns so future CLI/IDE sessions can attach quickly and share one local runtime. It listens only on loopback, requires a bearer token, writes discovery to `~/.monofoundry/daemon.json`, and writes logs to `~/.monofoundry/logs/daemon.log`. Use `monofoundry daemon stop` to stop it, or `--direct` / `--no-daemon` to bypass it for a session.

---

## Data Minimisation

The CLI sends only what is needed for the agent to operate:

| What is sent | When | What is NOT sent |
|--------------|------|------------------|
| User message + conversation history | Every turn | Arbitrary file contents (only files the agent explicitly reads via tools) |
| Workspace context (OS, frameworks, git status, tool list, skills, instructions) | Start of each conversation | Full directory listings, file contents, or environment variables |
| Tool execution results | When a tool is run | Shell history, system logs, or other user activity |
| Binary file uploads | When the user explicitly attaches a file | Text files are never uploaded - the agent reads them locally |

Text files are never uploaded to the backend. When you reference a text file (via `@`-path or when the agent reads it with `read_file`), the contents are sent as part of the tool result, not as a pre-emptive upload. Binary files (images, PDFs, etc.) are uploaded only when explicitly attached, with a 20 MB limit.

---

## Hardening Recommendations

The CLI operates with the permissions of the running user. For additional protection, consider the following:

| Measure | How | Benefit |
|---------|-----|--------|
| **Approval mode** | `monofoundry --approve` or `/approve` in the REPL | Review and reject mutating tool calls before they execute |
| **Sandboxed execution** | Run the CLI inside a container, VM, or restricted user account | Limit filesystem and process access to a contained environment |
| **Dedicated workspace** | Point `--cwd` at a specific project directory, not your home directory | Limit the agent's filesystem access to the project scope |
| **Passphrase-based encryption** | Set `MONOFOUNDRY_PASSPHRASE` in the environment | Make credentials non-decryptable without the passphrase, even on the originating machine |
| **Network egress filtering** | Allowlist `core.monoai.co` (and GitHub endpoints for updates) plus loopback daemon traffic in your firewall | Enforce the expected network model at the network level |
| **MCP server review** | Audit any MCP server configs before adding them | MCP servers run with your permissions and can make their own network calls |

---

© monō ai Australia Pty Ltd. All rights reserved. Use is subject to monō ai's [legal policies](https://www.monoai.co/legal) and [terms of service](https://app.monoai.co/terms).
