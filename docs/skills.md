# monofoundry - Skills

Skills are reusable instruction sets that tell the agent how to approach a specific task. They are discovered from `SKILL.md` files in your workspace and home directory, and surfaced to the agent as invocable instructions and to the REPL as slash commands.

---

## Table of Contents

- [Overview](#overview)
- [Discovery Paths](#discovery-paths)
- [SKILL.md File Format](#skillmd-file-format)
  - [Frontmatter Fields](#frontmatter-fields)
  - [File Naming Conventions](#file-naming-conventions)
  - [Block Scalars](#block-scalars)
- [How Skills Are Surfaced](#how-skills-are-surfaced)
- [Name Collisions](#name-collisions)
- [Symlinked Skill Directories](#symlinked-skill-directories)
- [Examples](#examples)

---

## Overview

A skill is a markdown file with optional YAML frontmatter. The frontmatter declares metadata (name, description, tools, tags); the body contains the instructions the agent follows when the skill is invoked.

Skills are discovered from a fixed set of directories in your workspace and home directory. Discovery is stateless — skills are re-scanned on demand, not watched. This fits the thin-client model: no background processes, no cached state to invalidate.

When a skill is invoked (via the agent's `invoke_skill` tool or the `/<skill-name>` REPL command), the skill's instruction body is loaded and executed as a full agent turn. An optional argument can be appended to the skill body.

---

## Discovery Paths

The CLI scans skill directories in a fixed order. **The first directory to produce a skill with a given name wins** — if two directories both contain a skill called `"commit"`, the one earlier in the list takes precedence. Workspace directories are scanned before home directories, so project-level skills override user-level ones.

### Workspace directories

| # | Path | Source label |
|---|------|-------------|
| 1 | `.monofoundry/skills/` | monofoundry |
| 2 | `.claude/skills/` | claude |
| 3 | `.agents/skills/` | agents |
| 4 | `.cursor/skills/` | cursor |
| 5 | `.codex/skills/` | codex |
| 6 | `.github/skills/` | github |

### Home directories

| # | Path | Source label |
|---|------|-------------|
| 7 | `~/.monofoundry/skills/` | monofoundry |
| 8 | `~/.claude/skills/` | claude |
| 9 | `~/.agents/skills/` | agents |
| 10 | `~/.cursor/skills/` | cursor |
| 11 | `~/.codex/skills/` | codex |
| 12 | `~/.gemini/config/skills/` | antigravity |

`~/.monofoundry/skills/` is the primary home-level skills directory. The remaining paths are automatically detected as fallbacks for compatibility with Claude Code, OpenAI Codex, Cursor, GitHub Copilot, and Antigravity.

The **source label** indicates which ecosystem a skill was discovered from. It is surfaced in the `/skills` listing and in the workspace context sent to the agent.

---

## SKILL.md File Format

A skill file is markdown with optional YAML frontmatter delimited by `---`:

```markdown
---
name: commit
description: Format a git commit message following conventional commits
tools:
  - run_terminal
  - read_file
tags:
  - git
  - version-control
trigger: manual
context: workspace
---

Skill Instructions

Write a commit message for the staged changes...
```

If no frontmatter is present, the entire file is treated as the instruction body and the skill name falls back to the directory name.

### Frontmatter Fields

| Field | Type | Default | Description |
|-------|------|---------|-------------|
| `name` | `string` | Directory name | The skill name. Used for the `/<skill-name>` command and the `invoke_skill` tool. |
| `description` | `string` | `"Skill: <name>"` | A short description shown in `/skills` listings and the workspace context. |
| `tools` | `string[]` | `[]` | Tools the skill expects to use. Informational — does not restrict the agent's available tools. |
| `context` | `string` | `"main"` | Context hint for the skill (e.g. `"workspace"`, `"main"`). |
| `trigger` | `string` | `"manual"` | How the skill is triggered. `manual` skills are invoked explicitly. |
| `tags` | `string[]` | `[]` | Free-form tags for categorisation. |

Unknown frontmatter keys are silently ignored.

### File Naming Conventions

Each skill directory is scanned for skill files using two conventions, tried in order:

1. **`<dir>/SKILL.md`** — the standard convention (preferred).
2. **`<dir>/<name>.md`** — a fallback where the filename matches the directory name (e.g. `office/office.md`).

If `SKILL.md` exists and is readable, it is used. Otherwise, the fallback `<name>.md` is tried.

Additionally, standalone files named `SKILL.md`, `AGENTS.md`, or `CLAUDE.md` (case-insensitive) are recognised as skill files directly within a skills directory. In this case, the skill name falls back to the parent directory name.

**Examples of discovered paths** (assuming `~/.claude/skills/` is the skills directory):

| Path | Skill name (if no frontmatter `name`) |
|------|--------------------------------------|
| `~/.claude/skills/commit/SKILL.md` | `commit` |
| `~/.claude/skills/office/office.md` | `office` |
| `~/.claude/skills/commit/CLAUDE.md` | `commit` |

### Block Scalars

The frontmatter parser supports YAML block scalars for multi-line values:

- **`|` (literal)** — preserves newlines.
- **`>` (folded)** — folds newlines into spaces.

```yaml
---
name: deploy
description: |
  Deploy the application to production.
  Run the full deployment checklist first.
tags:
  - deploy
  - production
---
```

Inline arrays (`[a, b]`) and block lists (`- item`) are both supported for array fields.

---

## How Skills Are Surfaced

Skills are surfaced in three ways:

### 1. Agent tools

The agent has access to two tools for working with skills:

- **`list_skills`** — returns all discovered skills with their metadata.
- **`invoke_skill`** — loads a skill's instruction body and returns it to the agent. The agent then follows those instructions for the current task. Passing `"none"` or `"deactivate"` clears any active skill.

### 2. Workspace context

Discovered skills are included in the workspace context sent to the agent at the start of each turn. Each skill is listed with its name, description (first line), and source label, along with a note to use the `invoke_skill` tool.

### 3. REPL slash commands

- **`/skills`** — lists all discovered skills with their slash command names and descriptions.
- **`/<skill-name> [arg]`** — runs a skill as a full agent turn. The skill body is loaded and sent as the turn's message. An optional argument is appended to the skill body.

Skill names are slugified into command names: lowercase, non-alphanumeric characters replaced with hyphens, leading/trailing hyphens stripped. For example, `"Commit Msg"` becomes `/commit-msg`.

---

## Name Collisions

If two skills share the same name (after frontmatter resolution or directory-name fallback), **the first one discovered wins**. Discovery order follows the [Discovery Paths](#discovery-paths) table — workspace directories before home directories, and within each scope, in the listed order.

For REPL slash commands, built-in commands take precedence over skill commands on name collision. If a skill would produce a command name that already exists as a built-in (e.g. `/help`), the skill command is not registered.

---

## Symlinked Skill Directories

Skill directories are often symlinked from a dotfiles repository. The CLI follows symlinks: if a directory entry is a symbolic link, it is resolved and scanned as a directory (or file) accordingly. Dangling symlinks are silently skipped.

---

## Examples

### Basic skill

`~/.monofoundry/skills/commit/SKILL.md`:

```markdown
---
name: commit
description: Format a git commit message following conventional commits
tools:
  - run_terminal
  - read_file
tags:
  - git
---

Write a conventional commit message for the currently staged changes.

1. Run `git diff --cached` to see what's staged.
2. Write a commit message with a type prefix (feat, fix, docs, refactor, etc.).
3. Keep the subject line under 72 characters.
4. Add a body if the change needs explanation.
```

Invoke it:

```
> /commit
# runs the skill as a full agent turn

> /commit feat: add history search
# runs the skill with the argument appended to the body
```

### Skill with a folded description

`<workspace>/.claude/skills/deploy/SKILL.md`:

```markdown
---
name: deploy
description: >
  Deploy the application to production using the standard
  deployment pipeline. Run the full pre-deployment checklist
  first, then promote the build.
tags:
  - deploy
  - production
trigger: manual
---

Follow the deployment checklist...
```

### Skill without frontmatter

`<workspace>/.monofoundry/skills/notes/SKILL.md`:

```markdown
Take notes on the current discussion. Summarise key decisions,
action items, and open questions in a structured format.
```

This skill is discovered with the name `notes` (from the directory name) and the description `Skill: notes` (auto-generated).

---

© monō ai Australia Pty Ltd. All rights reserved.