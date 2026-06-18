# Changelog

## v0.9.0 — 2026-06-18

- Local MCP server discovery and tool invocation from the CLI.
- Interactive authentication onboarding flow for first-time users.
- Per-turn and session cost reporting when model pricing is available.
- Improved exit experience with usage summary and correct prompt positioning.
- Git status tool now handles multi-repo workspaces and distinguishes intent-to-add entries.
- Bug fixes and internal improvements.

## v0.8.0 — 2026-06-16

- File upload and attachment support: drag files, paste images, or use `/attach` to include local files in conversations.
- Input history now scoped to each project directory to prevent histories from mixing across codebases.
- Bug fixes and internal improvements.

## v0.7.0 — 2026-06-15

- Improved credential security.
- Terminal command exit codes now surfaced in tool data, enabling correct distinction between command failures and tool harness failures.
- ANSI escape sequences and shell integration sequences now stripped from captured terminal output.
- Git operations and tool execution now have configurable timeouts to prevent indefinite hangs.
- Model picker now sorts by frecency for faster repeated selection.
- Bug fixes and internal improvements.

## v0.6.1 — 2026-06-15

- Fixed /model command 403 errors and doubled error messages.
- Model picker now shows model IDs alongside display names.

## v0.6.0 — 2026-06-15

- Authentication commands in the REPL: /login, /logout, /status for seamless account management without leaving the prompt.
- Organisation switching with /org command for users with multiple organisations.
- Friendly error messages on session expiry and auth failures.
- Better guidance when mistyping slash commands or running unknown auth subcommands.
- Config file corruption prevention via atomic writes.

## v0.5.0 — 2026-06-14

- Binary releases are now significantly smaller for macOS and Linux.
- Bug fixes and internal improvements.

## v0.4.1 — 2026-06-14

- Background update checking on startup, with a notice when a newer version is available, plus a `/update` command to check manually and upgrade in place.
- `/costs` added as an alias for `/tokens`.
- `/tokens` report reformatted: aligned costs, cost column before turns, right-aligned values, and per-row totals.
- `/help` output aligned into a single column, with an outdated model reference removed.
- Bug fixes and internal improvements.

## v0.4.0 — 2026-06-13

- Shell mode: prefix any input with `!` to run a local shell command without leaving the agent loop.
- Ctrl-R fuzzy history search picker with scored ranking.
- `@`-prefix file path completion in the input line.
- Prompt stash (Ctrl-S / `/stash`) to push and pop the current input buffer.
- Token usage tracking: per-turn summary, `/tokens` command with session/conversation/project/lifetime totals, and cost estimates where pricing data is available.
- Managed terminal tools: the agent can now spawn, read, write to, and kill named background processes.
- `run_task` now discovers tasks from npm/pnpm/bun/yarn scripts, `.vscode/tasks.json`, and Makefile targets.
- `get_diagnostics` now runs real checkers (tsc/tsgo, oxlint, eslint, pyright, mypy) and returns a unified diagnostic list.
- `code_runner` executes JavaScript, TypeScript, and Python snippets in isolated temporary directories. Requires Node 22+.
- Model list cached to disk with a 24-hour TTL, reducing unnecessary network calls on startup.
- `document_content`, `json_content`, `file_references`, `application_code`, and `overlay` content blocks now handled.
- Clarification confirmation line shows the delivered message text.
- Fixed Shift-Enter / Alt-Enter newline insertion, multi-line history navigation asymmetry, Ctrl-R picker layout corruption, tab-completion input drift, `@`-completion going dead, Ctrl-W WORDCHARS handling, `fd` glob search returning zero results, and inline underscore rendering.
- Bug fixes and internal improvements.

## v0.3.1 — 2026-06-12

- Windows binaries no longer report a corrupted signature
- Bug fixes and internal improvements.

## v0.3.0 — 2026-06-12

- Distributes as self-contained native binaries (macOS, Linux, Windows; x64 and ARM64).
- Installer offers to add the install directory to `PATH` via the user's shell rc file.
- Version now reported via `--version` flag, REPL banner, and `--help` header.
- Type-to-filter fuzzy search added to model, project, work-item, and conversation pickers.
- Agent plans persisted as Markdown checklists in the conversation folder.
- `/model` command scoped to organisational language models, fixing 403 errors for regular members.
- Spinner indentation and visibility gaps fixed.
- Tool receipt, approval, and clarification lines now word-wrap with hanging indent.
- Ranged file reads report the actual line range in the receipt.
- Command display truncation raised from 60 to 120 characters.
- Table layout corrected for emoji with variation selectors (U+FE0F).
- File and text search fallbacks fixed on Windows.
- Improved terminal colour palette for inline code and tool call lines.
- Bug fixes and internal improvements.
