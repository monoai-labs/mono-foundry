# Changelog

## v0.26.3 — 2026-07-24

- Live cost estimates now show bounded ranges while work is in progress.
- Known input narrows estimates, with cached and non-cached usage priced more accurately.
- Bug fixes and internal improvements.

## v0.26.2 — 2026-07-22

- Bug fixes and internal improvements.

## v0.26.1 — 2026-07-22

- More capable terminal commands with selectable shells, longer task timeouts, clearer output, and better managed-session retention.
- More reliable large-file reads, directory listings, search and replace, text edits, and Git path filtering.
- Improved daemon diagnostics, stale-instance detection, recovery, and configuration preservation.
- Bug fixes and internal improvements.

## v0.26.0 — 2026-07-20

- More capable and recoverable interactive editing, including bounded undo and redo, text recovery, improved paste handling, and more reliable Unicode navigation.
- Safer session recovery, with drafts preserved through re-authentication and stale organisation context cleared when conversations resume.
- Cleaner redirected one-shot output and more accurate terminal rendering across wide characters, wrapping, and control characters.
- Safer and more transparent file operations, including bounded large-file handling, binary-file protection, symbolic-link exclusion, and reporting for skipped search-and-replace candidates.
- More reliable cancellation, queued-input cleanup, daemon recovery, reconnects, and authentication failure handling.
- Tooling and daemon improvements, including better concurrency visibility, organisation-scoped state, and expanded regression coverage.
- Bug fixes and internal improvements.

## v0.25.4 — 2026-07-17

- Clearer terminal command receipts, output previews, and error messages.
- More reliable pasted-input handling and Unicode cursor movement.
- Improved terminal output formatting and plain-text debug output.
- Bug fixes and internal improvements.

## v0.25.3 — 2026-07-16

- Standalone plugin hosts now launch correctly.
- Bug fixes and internal improvements.

## v0.25.2 — 2026-07-16

- Standalone builds now support plugins on macOS and Linux.
- More reliable turn recovery after transient network errors.

## v0.25.1 — 2026-07-16

- More reliable standalone release builds.
- Bug fixes and internal improvements.

## v0.25.0 — 2026-07-16

- Configurable handling of messages entered during an active turn.
- Single-executable Windows standalone releases with isolated plugin support.
- More reliable session resumption, progress reporting, cumulative costs, catalogue selections, and connection recovery.
- Built-in themes and profile relocation supported in standalone use.
- Bug fixes and internal improvements.

## v0.24.2 — 2026-07-14

- Fixed a crash on load.
- More reliable daemon result delivery, standalone startup, terminal output limits, search exclusions, and prompt refresh.
- Improved pasted-input wrapping, multiline navigation, edit mismatch messages, and large-output handling.
- Stronger plugin validation, replay safety, configuration loading, and regression coverage.
- Documentation and build-process improvements.
- Bug fixes and internal improvements.

## v0.24.1 — 2026-07-14

- More reliable one-shot commands, daemon sessions, terminal resizing, and session persistence.
- Improved multiline input, paste tokens, Unicode editing, wrapping, highlighting, and idle prompt hints.
- Safer large-file handling, plugin lifecycle behaviour, attachment cleanup, and conversation history recovery.
- Better usage and cost reporting, package-manager detection, version comparisons, and model-cache resilience.
- Bug fixes and internal improvements.

## v0.24.0 — 2026-07-13

- More reliable sessions, reconnections, replay, and background work.
- Clearer usage and cost reporting, including activity from background work.
- More dependable plugin validation, lifecycle handling, and recovery.
- Improved search, file operations, interactive input, Unicode cursor movement, paste handling, and terminal rendering.
- More reliable request pacing and retry handling under service limits.
- Fixed authentication, organisation selection, session resumption, stale state, and one-shot completion issues.
- Fixed search-and-replace, file-operation, plugin, updater, and credential-handling edge cases.
- Bug fixes and internal improvements.

## v0.23.0 — 2026-07-09

- Automatic retry on rate-limit responses for initial requests, command responses, and sub-agent polling.
- Aborting a turn now cancels in-flight tools instead of letting them run to completion.
- `/resume` accepts full Studio URLs in addition to conversation IDs.
- Plugin installation is now atomic with integrity verification; updated plugins require permission consent before re-enabling; client-side load failures are surfaced.
- Auth self-healing extended: token reloaded from disk after in-flight refresh, organisation persisted immediately after login, coverage broadened to all API calls.
- Removed an unconditional five-minute approval timeout that contradicted the documented behaviour.
- Standardised reset synonyms (`clear`, `default`, `none`, `reset`) across `/model`, `/theme`, `/project`, and `/workitem`.
- Fixed markdown rendering: quadratic sentence-flush scan, escape byte leaks, link URL nesting, wrapper re-open state leak, and emphasis false positives.
- Fixed line editor: history index reset on buffer mutations, code-point cursor stepping, CJK/emoji picker width, and stale callback cleanup.
- Fixed `/star` toggle for conversations without local history and `/update` failure detection.
- Daemon stability: detached-session idle GC, SIGTERM/SIGHUP cleanup handlers, stale config detection, forceful kill escalation, session-scoped managed terminals, and WebSocket protocol fixes.
- Plugin host stability: leaked process cleanup, silent late-response dropping, and clean disconnect exit.
- Fixed version-range matching for caret and tilde operators, cross-platform path separators, and stale fallback model indication in the status bar.
- Bug fixes and internal improvements.

## v0.22.1 — 2026-07-07

- Fixed one-shot mode hanging after completion instead of exiting cleanly.

## v0.22.0 — 2026-07-07

- Terminal and task-execution tools are now gated behind approval mode; sub-agent tool calls route through the parent session's approval gate.
- Dismissing an approval prompt with Esc or Ctrl-C now skips the tool instead of accepting it; a second Esc or Ctrl-C is required to clear the input line.
- File, search, and terminal tools now enforce symlink-aware containment to the workspace root; child processes spawned during a turn have sensitive variables stripped from their environment.
- Enabling, installing, and running plugin lifecycle hooks now require explicit permission consent; MCP server spawning is gated behind workspace consent.
- Diff previews are now rendered with the active theme's colours in daemon mode and on conversation replay.
- Fixed daemon spawn races, crash-mid-turn client hangs, and managed terminal process cleanup.
- Fixed dollar-sign characters in non-regex replacement text corrupting files.
- Corrupt conversation history is now quarantined instead of erased; fixed /link and /workitem failing for work items beyond the first 100 results.
- Fixed Shift-Enter in the Kitty terminal, cursor drift from text-presentation emoji, and concurrent picker prompts overwriting each other.
- Fixed sub-agent token usage being double-counted in daemon mode.
- Bug fixes and internal improvements.

## v0.21.0 — 2026-07-05

- New slash commands for conversation management: `/star`, `/rename`, `/link`, and `/unlink` to star, rename, and link conversations to projects or work items from the REPL.
- New `--app-url` flag to override the web app URL for deep-links, auto-derived from `--endpoint` when omitted and persisted per-project; also fixes `--endpoint` leaking into the submitted message.
- Opt/Alt/Shift-Enter now inserts a newline in the quick-action picker's inline input row for multi-line text.
- Slash commands saved in input history again; token counts now format billions (B) and trillions (T) compactly.
- Fixed stream errors on turn completion caused by waiting for a terminal signal the backend never sends.
- Fixed several cost/tokens toggle (Opt-T) issues: no-op during an in-progress first turn, bounded cost range disappearing after a toggle cycle, lost streaming deltas, and a transient cost drop on the first step of a new turn.
- Fixed per-step token usage being overwritten instead of accumulated, under-counting session totals.
- /tokens now uses canonical backend cost rather than rate estimates alone; per-model breakdowns for fallback turns attribute tokens proportionally and normalise model identifiers to avoid duplicate rows.
- Spinner no longer shows during deterministic data fetches (models, projects, conversations).
- Bug fixes and internal improvements.

## v0.20.0 — 2026-07-04

- Model fallback visibility: status bar, spinner, and exit summary now show the fallback model and a per-model usage breakdown, in both direct and daemon mode.
- Authoritative backend costs are now used by default and persisted to conversation history for accurate totals on resume.
- Live cost tracking in the status bar during multi-step turns, with a bounded cost range and real-time cost/tokens toggle.
- Suppressed meaningless zero-cost rows for models with no pricing; cost toggle only activates when the session has non-zero cost.
- Code blocks now render with the current theme instead of the default.
- Exit summary on Ctrl-C/D visually separated from the end-of-turn summary.
- Bug fixes and internal improvements.

## v0.19.0 — 2026-07-03

- Token-based theming system with `/theme` command for switching, previewing, and persisting colour schemes; two bundled themes (dark and light) as editable JSON.
- Theme selection offered during first-run onboarding and applied in one-shot mode.
- Plugins can now contribute custom themes via their manifest with a dedicated permission gate.
- Plugin enable, disable, install, reinstall, and update now default to global scope; `--project` flag opts into project-scoped behaviour.
- Plugin removal now fully cleans up config entries and storage directories.
- Diff previews now render with syntax highlighting on the client side in daemon mode and with colour on conversation replay.
- All auth flows now show a green success message on completion.
- Fixed `apply_diff` prepending content instead of replacing when editing existing files with empty old text.
- Prevented temporary-directory working directories from creating orphaned project storage folders.
- Bug fixes and internal improvements.

## v0.18.1 — 2026-07-02

- Isolated plugin host: plugins run in a separate process with managed activation, health monitoring, and bounded restarts; legacy in-process execution removed.
- Plugin-contributed slash commands now appear in `/help`, tab completion, and dispatch; built-ins take precedence on conflicts.
- `plugin reinstall` command to refresh all or specific installed plugins through the hardened installer path.
- Plugin listings and info show runtime targets (client, daemon, or both) and active override conflicts.
- Plugin tool overrides resolve deterministically by priority; unregistering promotes the next best override.
- Plugin workspace edits require explicit write permissions, show diff previews, and respect the per-turn approval gate.
- Hardened plugin security: HTTPS-only downloads with size and timeout limits, archive entry validation, package integrity verification before loading, stricter manifest validation, workspace read containment, symlink escape prevention, and constrained process spawns.
- Plugin highlighter failures contained with output caps and fallback to built-in rendering.
- Fixed unrecognised `daemon` arguments producing a confusing auth error instead of a clear message.
- Bug fixes and internal improvements.

## v0.18.0 — 2026-07-01

- Syntax highlighting via plugins: plugins can declare languages they highlight, and code blocks and diff previews are styled automatically.
- `plugin update` command to update all or specific plugins to the latest release, with optional version pinning.
- `plugin config` command to set, clear, and list per-plugin configuration values with schema validation.
- Plugins can now register slash commands, spawn child processes, persist configuration, and discover workspace files via newly implemented APIs.
- Plugins can be installed via bare GitHub URLs in addition to the shorthand syntax.
- Plugin manifest schema for editor validation; manifest id field removed in favour of auto-derived identifiers.
- Capability-based language-server discovery: any plugin can declare language-server support; the CLI finds supporting plugins at runtime.
- Improved plugin install experience: permissions listed per line, interactive enable prompt, and release-tag-accurate version display.
- Bug fixes and internal improvements.

## v0.17.0 — 2026-06-30

- New plugin system: install, list, enable, disable, remove, and inspect extensions from GitHub releases, URLs, or local directories; plugins can provide or override tools and activate at daemon startup.
- `lsp enable` and `lsp doctor` commands for setting up and diagnosing language-server support in a workspace.
- Sign-in now uses a localhost OAuth redirect instead of a manual paste step; the callback page is branded and auto-closes on success.
- Daemon status shows uptime and loaded plugins; the redundant internal session row is no longer shown.
- A provisional indicator appears when a clarification is in flight during a long-running tool; slash-command tokens are now highlighted in the input line.
- Fixed cursor drift when completing file paths with non-ASCII characters, stale file completions lingering after submit, and duplicate input history entries.
- Fixed duplicate tool receipts and misaligned multiline command summaries in daemon-client mode.
- Fixed a crash when installing a local plugin from a directory with pnpm symlink farms; daemon restart now clears its own restart-required marker.
- Bug fixes and internal improvements.

## v0.16.2 — 2026-06-29

- Text search now consistently shows the requested context lines around matches.
- File search scope warning now shown on all search paths.
- Ctrl-C cancellation no longer leaves a spurious "connection ended" message in direct mode.
- Diagnostics timeout detection fixed across all supported linters and type checkers.
- Home-relative paths now expanded correctly in daemon mode.
- Rejected or skipped tools in daemon subagent sessions now render correct approval indicators.
- CJK characters and emoji no longer misalign the input line when wrapping.
- Bug fixes and internal improvements.

## v0.16.1 — 2026-06-28

- Fixed approval mode in daemon sessions: diff preview now appears before the accept/reject/skip prompt, and rejected/skipped tools show the correct indicators.
- Fixed styled text wrapping: bold, italic, and inline-code spans no longer break mid-word at the terminal margin.
- Fixed table rendering for narrow symbols (✗, ✓, ❯) that were incorrectly counted as two columns wide.
- Spinner now renders in yellow to match the active-turn prompt colour.
- Bug fixes and internal improvements.

## v0.16.0 — 2026-06-28

- Alt+U shortcut switches utility type mid-input without clearing the buffer.
- Turn duration now appears in the end-of-turn usage summary.
- Batch file read receipts list the files accessed, not just a count.
- Local project storage now resolves git worktrees and subdirectories to the main checkout, keeping conversations and history unified.
- Fixed input history corruption and lost entries under concurrent sessions.
- Managed terminal output is now properly bounded by the character cap.
- Server-side error events are now terminal in direct mode, matching daemon behaviour.
- Reconnection and approval handling are now consistent across direct and daemon modes.
- Bug fixes and internal improvements.

## v0.15.4 — 2026-06-26

- Tilde (~) in file paths now expands to the home directory across all file tools.
- Remote subagents now display correct labels and completion status instead of generic placeholder names.
- The elapsed-time timer no longer shows a stale duration after slash commands.
- Diagnostics, managed terminal, and skill listing output now include the fields agents expect.
- Removed the /history command, subsumed by /conversations studio.
- Bug fixes and internal improvements.

## v0.15.3 — 2026-06-26

- Organisation, model, and utility selections are now isolated per session, preventing concurrent sessions from overwriting each other's persisted defaults.
- Conversations now remember and restore their organisation, model, and utility context on resume.
- Projects now persist and automatically apply their preferred organisation, model, and utility on selection.
- Model catalogue cache is now per-organisation, avoiding unnecessary re-fetches when switching back to a previously visited organisation.
- Bug fixes and internal improvements.

## v0.15.2 — 2026-06-26

- Background sub-agent activity is now clearly attributed and separated from the parent session, with live aggregate status in the spinner and tool receipts that persist across resume.
- File moves now support explicit overwrite and cross-device fallback.
- Fixed dropped final stream events when a response ends without a trailing delimiter.
- Fixed staged changes being omitted from diff output by default.
- Terminal command timeouts now return partial output instead of discarding it.
- Tab completion into a directory now immediately refreshes matches with its contents.
- Deleting a non-existent file now reports a failure instead of silently succeeding.
- Daemon turns now halt immediately on server-side error events.
- Bug fixes and internal improvements.

## v0.15.1 — 2026-06-25

- Dropped files are now copied to a stable location at drop time, preventing macOS from deleting screenshots before upload; original filenames are preserved.
- Studio URLs can be pasted directly into `/conversations studio` and `/workitem` commands.
- PageUp/PageDown navigation added to the picker.
- Fixed picker jumping when scroll indicators appear or disappear.
- Bug fixes and internal improvements.

## v0.15.0 — 2026-06-25

- Daemon runtime is now the default for interactive sessions, with auto-start, idle shutdown, and graceful fallback to direct mode.
- `monofoundry daemon` and `monofoundry doctor` commands for daemon lifecycle and diagnostics.
- Platform-wide conversation discovery and resume via `/conversations studio` and `/resume <id>`.
- Status bar shows session cost by default; Meta+T toggles to token count.
- Elapsed-time timer on the spinner line during generation.
- Stale daemon detection and auto-restart, and reconnection resilience on daemon restart.
- Per-conversation model persistence and restore on resume.
- Conversation usage summary and diff previews now shown on resume.
- Two-row slash-command autocomplete for better visibility.
- Fixed multi-row history navigation, noisy prompt history, and terminal status row wrapping.
- Hardened write tools against formatter and line-ending drift.
- Bug fixes and internal improvements.

## v0.14.0 — 2026-06-23

- Improved network resilience
- Fixed `apply_diff` and `search_and_replace` tool result field mismatches that caused edits to silently no-op.
- Fixed directory listing so recursive walks no longer block the CLI and now respect `.git` and `node_modules` boundaries.
- Fixed drag-and-drop uploads to handle shell-escaped file paths correctly.
- Workspace context now builds asynchronously at startup, with a 5-second timeout fallback to keep the first response prompt.
- Model identity now uses stable server-issued identifiers with automatic migration for legacy persisted conversations.
- Placeholder hints display at startup and during idle.
- Fixed `/utility` listing utilities outside the current organisation.
- Bug fixes and internal improvements.

## v0.13.1 — 2026-06-22

- Daemon compatibility improvements.
- Server-side subagent activity now visible in CLI: banners render when backend orchestrates sub-agents.
- Code modularisation and improvements.

## v0.13.0 — 2026-06-21

- Polite re-authentication: token reload from disk, user prompt before browser opens, and cleaner one-shot abort flow.
- Text search now consistently case-insensitive, excludes build artefacts and minified files, and filters by file extension.
- Bug fixes and internal improvements.

## v0.12.2 — 2026-06-20

- Fixed model pricing visibility when API returns bare array response or cache is empty
- Fixed /clarify command silently dropping messages due to implicit 4-character tag heuristic
- Spinner now remains visible throughout all generation phases and reconnection attempts
- Input prompt colour now reflects whether input is queued during generation

## v0.12.1 — 2026-06-20

- Fix crash on Windows
- Fix quick-action picker leaving typed text in the input area
- --utility and /utility options to change the utility used by the tool
- /reset command to reset session-level settings (model, utility, save mode, approval mode) back to defaults
- Bug fixes and internal improvements

## v0.12.0 — 2026-06-19

- Automatic stream recovery on connection loss with SSE event ID tracking and exponential backoff reconnect.
- Automatic credential refresh on auth expiry with transparent OAuth re-login.
- Subagent spawning and orchestration — CLI now launches child agents concurrently with independent tool routing and visual attribution.
- Escape key now only aborts in-flight generation, preserving entered input.
- `/workitem implement <tag> | <id>` shorthand command for direct work item implementation.
- Align exit summary stats across parent and subagent tiers.
- Bug fixes and internal improvements.

## v0.11.0 - 2026-06-19

- Added external editor support (Ctrl-X Ctrl-E) for composing longer prompts.
- Added `/init` command to scaffold MONOFOUNDRY.md from project metadata.
- Added support for multiple agent instruction file formats (MONOFOUNDRY.md, CLAUDE.md, AGENTS.md, GEMINI.md, .github/copilot-instructions.md, .cursorrules) with priority fallback.
- Added comprehensive security documentation and expanded approval gate to cover code execution and file moves.
- Added documentation guides for MCP configuration, skills, files, and config directory structure.
- Fixed file path escaping in @-token completion and drag-drop for paths with spaces and internal quotes.
- Fixed Up key history navigation incorrectly entering search mode.
- Bug fixes and internal improvements.

## v0.10.0 - 2026-06-18

- Create work items directly from the REPL with `/workitem create`.
- Alt+M shortcut to switch models mid-input without losing your buffer.
- Fixed input area corruption when running `/login` or being prompted during authentication.
- Fixed Escape key to interrupt generation.
- File paths containing spaces are now correctly handled in `@`-token attachments.
- Bug fixes and internal improvements.

## v0.9.0 - 2026-06-18

- Local MCP server discovery and tool invocation from the CLI.
- Interactive authentication onboarding flow for first-time users.
- Per-turn and session cost reporting when model pricing is available.
- Improved exit experience with usage summary and correct prompt positioning.
- Git status tool now handles multi-repo workspaces and distinguishes intent-to-add entries.
- Bug fixes and internal improvements.

## v0.8.0 - 2026-06-16

- File upload and attachment support: drag files, paste images, or use `/attach` to include local files in conversations.
- Input history now scoped to each project directory to prevent histories from mixing across codebases.
- Bug fixes and internal improvements.

## v0.7.0 - 2026-06-15

- Improved credential security.
- Terminal command exit codes now surfaced in tool data, enabling correct distinction between command failures and tool harness failures.
- ANSI escape sequences and shell integration sequences now stripped from captured terminal output.
- Git operations and tool execution now have configurable timeouts to prevent indefinite hangs.
- Model picker now sorts by frecency for faster repeated selection.
- Bug fixes and internal improvements.

## v0.6.1 - 2026-06-15

- Fixed /model command 403 errors and doubled error messages.
- Model picker now shows model IDs alongside display names.

## v0.6.0 - 2026-06-15

- Authentication commands in the REPL: /login, /logout, /status for seamless account management without leaving the prompt.
- Organisation switching with /org command for users with multiple organisations.
- Friendly error messages on session expiry and auth failures.
- Better guidance when mistyping slash commands or running unknown auth subcommands.
- Config file corruption prevention via atomic writes.

## v0.5.0 - 2026-06-14

- Binary releases are now significantly smaller for macOS and Linux.
- Bug fixes and internal improvements.

## v0.4.1 - 2026-06-14

- Background update checking on startup, with a notice when a newer version is available, plus a `/update` command to check manually and upgrade in place.
- `/costs` added as an alias for `/tokens`.
- `/tokens` report reformatted: aligned costs, cost column before turns, right-aligned values, and per-row totals.
- `/help` output aligned into a single column, with an outdated model reference removed.
- Bug fixes and internal improvements.

## v0.4.0 - 2026-06-13

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

## v0.3.1 - 2026-06-12

- Windows binaries no longer report a corrupted signature
- Bug fixes and internal improvements.

## v0.3.0 - 2026-06-12

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
