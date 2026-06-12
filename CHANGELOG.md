# Changelog

All notable changes to monofoundry are documented here.

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
