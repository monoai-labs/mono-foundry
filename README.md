# monō-foundry

A thin-client CLI for the [monō ai](https://app.monoai.co) coding agent. The agent loop, model intelligence, and projects/workspaces all run server-side; this CLI streams responses and executes tool commands in your local context.

Skills, agent instructions, and local context will all be automatically detected. This tool by default will assume all the permissions of the running user; use `/approve` if you want to approve steps, and sandbox it if you want additional protection.

## Prerequisites

- A monō ai account (Google/Microsoft SSO or an API key).

## Install

```bash
# Installs the latest release
curl -fsSL https://raw.githubusercontent.com/monoai-labs/mono-foundry/main/install.sh | bash
```

Or download the script and run it directly:

```bash
curl -fsSL -o install.sh https://raw.githubusercontent.com/monoai-labs/mono-foundry/main/install.sh
chmod +x install.sh
./install.sh            # latest release
./install.sh v0.5.0     # a specific release tag
```

To **update**, re-run the same command, or run `/update` in the CLI.

**Windows:** download `monofoundry-win32-x64.exe` or `monofoundry-win32-arm64.exe` directly from the [Releases page](https://github.com/monoai-labs/mono-foundry/releases) and add it to your `PATH`.

Verify:

```bash
monofoundry --help
```

## Authentication

```bash
monofoundry auth login              # Google OAuth (default)
monofoundry auth login --microsoft  # Microsoft OAuth
monofoundry auth login --apikey     # paste an API key (sk-... / sk_...). Note that this will disable seeing conversations in your personal conversation list
monofoundry auth status             # show current sign-in
monofoundry auth logout             # remove stored credentials
```

Credentials and settings are persisted at `~/.monofoundry/config.json`. Note that for browser-based login, you currently need to copy/paste the vscode:// redirect URL from the browser to the command line by right clicking on the "Open monō ai" link -> Copy Link Address.

## Usage

```bash
monofoundry                 # interactive REPL
monofoundry "fix the failing test in src/render"   # one-shot
```

### Options

| Flag                 | Description                                             |
| -------------------- | ------------------------------------------------------- |
| `--cwd <path>`       | Set the workspace root (default: current directory)     |
| `--model <model_id>` | Use a specific model for this session                   |
| `--approve`          | Require approval before applying code edits (REPL only) |
| `--help`, `-h`       | Show usage                                              |

`monofoundry auth login` additionally accepts `--endpoint <url>` to override the API endpoint when signing in.

### REPL commands

Inside the interactive REPL, slash commands are available:

| Command          | Description                                   |
| ---------------- | --------------------------------------------- |
| `/new`           | Start a new conversation                      |
| `/resume`        | Resume the most recent conversation           |
| `/conversations` | List all saved conversations for resumption   |
| `/history`       | Show the current conversation history         |
| `/model`         | Show or change the LLM being used             |
| `/clarify <msg>` | Steer the agent mid-turn                      |
| `/tokens`        | Display token usage stats                     |
| `/project`       | Select the workspace project for this session |
| `/workitem`      | Select a workitem for this session            |
| `/approve`       | Toggle approval mode for code edits           |
| `/init`          | Generate a MONOFOUNDRY.md for the project     |
| `/skills`        | List discovered skills                        |
| `/<skill-name>`  | Run a discovered skill as a turn              |
| `/update`        | Check for and install updates                 |
| `/help`          | Show help                                     |
| `/quit`          | Exit                                          |

### Keybindings

| Key             | Action                        |
| --------------- | ----------------------------- |
| `Ctrl-R`        | Search input history (picker) |
| `↑` / `↓`       | Navigate history              |
| `Ctrl-X Ctrl-E` | Edit prompt in `$EDITOR`      |
| `Ctrl-C`        | Interrupt / cancel            |
| `Ctrl-D`        | Exit                          |

Conversation history is stored locally under `~/.monofoundry/projects/<slug>/conversations/`.

## Docs

- [Documentation Index](docs/index.md) - high-level index of all documentation
- [Commands & Shortcuts](docs/commands.md) - full reference for slash commands, keyboard shortcuts, and shell mode
- [MCP Servers](docs/mcp.md) - configure local MCP servers to extend the agent with custom tools
- [Skills](docs/skills.md) - create and use reusable skill instruction sets
- [Files & Attachments](docs/files.md) - attach files via @-paths, /attach, and /paste
- [Security](docs/security.md) - network architecture, credential encryption, tool execution model, access control, and hardening

---

© monō ai Australia Pty Ltd. All rights reserved. Use is subject to monō ai's [legal policies](https://www.monoai.co/legal) and [terms of service](https://app.monoai.co/terms).
