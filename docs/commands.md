# monofoundry — Commands & Shortcuts

This document covers every command and keyboard shortcut available in the interactive REPL.

---

## Table of Contents

- [Slash Commands](#slash-commands)
- [Shell Mode](#shell-mode)
- [Keyboard Shortcuts](#keyboard-shortcuts)
  - [Ctrl- Shortcuts](#ctrl--shortcuts)
  - [Navigation](#navigation)
  - [History](#history)
  - [Multi-line Input](#multi-line-input)
  - [Tab Completion](#tab-completion)

---

## Slash Commands

Slash commands are available inside the interactive REPL. Type `/` to trigger tab-completion; all commands and aliases are listed. Unrecognised slash commands are treated as normal chat messages.

### Core

| Command | Aliases | Description |
|---|---|---|
| `/help` | — | List all available commands and shortcuts |
| `/quit` | `/exit` | Exit the REPL (saves input history first) |
| `/new` | `/clear` | Start a new conversation (clears current conversation ID) |
| `/stash [text]` | — | Stash input or open the stash picker |

#### `/help`

Prints a formatted list of every registered command, its aliases, and its description, followed by a summary of keyboard shortcuts.

```
> /help
  /approve          Toggle edit approval mode
  /clarify <msg>    Steer the agent mid-turn ...
  ...
  !<command>        Run a shell command locally (e.g. !ls, !git status)
  Ctrl-R            Search input history
  Ctrl-S            Stash current input (second Ctrl-S restores)
```

#### `/new` (alias `/clear`)

Clears the active conversation ID so the next message starts a fresh conversation.

```
> /new
Started new conversation.
```

#### `/quit` (alias `/exit`)

Saves input history then exits. If a conversation is active, a resume hint is printed.

```
> /quit
Tip: resume with: monofoundry --resume <id>
```

#### `/stash [text]`

A LIFO stash for text you want to set aside temporarily.

- `/stash` with no argument opens an interactive picker of all stashed entries.
- `/stash <text>` pushes `text` onto the stash immediately and shows a `[stashed]` notice.
- **Ctrl-S** (see [Keyboard Shortcuts](#ctrl--shortcuts)) is the keyboard equivalent: it stashes the current buffer contents or pops the top entry back into the buffer on the second press.

```
> /stash explain this function in detail
[stashed]

> /stash
# opens picker — select an entry to restore it to the input buffer
```

---

### Conversation

| Command | Description |
|---|---|
| `/resume [id]` | Resume the most recent conversation, or a specific one by ID |
| `/conversations` | Browse and resume local and project-linked conversations |
| `/history` | Show recent remote conversation history (up to 10) |
| `/tokens` | Display token usage for session, conversation, project, and overall — with a per-model breakdown under each tier |

#### `/resume [id]`

Without an argument, resumes the most recent conversation for the current working directory. With an ID, resumes that specific conversation.

```
> /resume
Resumed conversation: "Fix the flaky render test"
42 messages

> /resume 6a1cca6ed38548818b7c07a6
Resumed conversation: "Refactor auth module"
18 messages
```

#### `/conversations`

Opens a filterable picker listing all local conversations for the current project, as well as any backend-linked conversations when a project is selected. Selecting an entry resumes that conversation.

```
> /conversations
# interactive picker:
  Fix the flaky render test    6a1c...  13/06/2026 09:14
  Refactor auth module         6a1b...  12/06/2026 17:45  · linked
  Cancel
```

#### `/history`

Fetches and displays the 10 most recent conversations from the remote backend.

```
> /history
  1. Fix the flaky render test
  2. Refactor auth module
  3. Add token usage tracking
```

#### `/tokens`

Prints a breakdown of token consumption at every tracked scope.

```
> /tokens
Token usage
  Session        ↑ 1.2k  ↓ 567  ∑ 1.8k  (3 turns)
    Claude Opus 4.8  ↑ 800   ↓ 400  ∑ 1.2k  (2 turns)
    GPT-5.5          ↑ 434   ↓ 167  ∑ 601   (1 turn)
  Conversation       ↑ 4.9k  ↓ 1.2k ∑ 6.1k  (12 turns)
    Claude Opus 4.8  ↑ 4.9k  ↓ 1.2k ∑ 6.1k  (12 turns)
  Project            ↑ 9.0k  ↓ 2.3k ∑ 11.3k (28 turns)
    Claude Opus 4.8  ↑ 9.0k  ↓ 2.3k ∑ 11.3k (28 turns)
  Overall            ↑ 12.3k ↓ 3.5k ∑ 15.8k (41 turns)
    Claude Opus 4.8  ↑ 12.3k ↓ 3.5k ∑ 15.8k (41 turns)
```

Model rows are only shown when usage spans more than one model in a tier. They are sorted by total tokens descending.

---

### Session

| Command | Description |
|---|---|
| `/model [id\|reset]` | View available models, set the active model, or reset to default |
| `/approve` | Toggle approval mode for file edits |
| `/clarify <msg>` | Steer the agent mid-turn |
| `/nosave [msg\|/cmd]` | Run a turn or command without saving to the backend |

#### `/model [id|reset]`

- No argument: shows the current model and opens a filterable picker.
- With a model ID or display name: sets that model immediately (validated against the catalogue).
- `reset` or `default`: clears the persisted model preference and reverts to the server default.

The selection persists per project directory and is also saved to the global config as a fallback for new projects.

```
> /model
Current model: default (server-selected)
# opens picker:
  GPT-5.5             [standard]  OpenAI
  Claude Opus 4.8     [standard]  Anthropic
  Gemini 2.5 Pro      [pro]       Google
  Cancel

> /model claude-opus-4.8
Model set to: Claude Opus 4.8

> /model reset
Model reset to default.
```

#### `/approve`

Toggles approval mode. When **on**, every file-mutating tool call (`write_file`, `apply_diff`, `search_and_replace`, `delete_file`) pauses and shows a diff, waiting for you to accept, reject, or skip before the agent continues.

Equivalent to starting with the `--approve` flag.

```
> /approve
Approval mode: ON

> /approve
Approval mode: OFF
```

#### `/clarify <msg>`

Steers the running agent mid-turn by injecting a clarification at the next tool boundary. If called when the agent is idle, the message is sent as a normal turn instead.

```
# while the agent is working:
> /clarify only change the TypeScript files, leave the tests

# when idle:
> /clarify actually, use camelCase not snake_case
```

#### `/nosave [msg|/cmd]`

Enables nosave mode for the session, then optionally runs a message or another slash command. Turns run in nosave mode are not saved to the backend; local conversation history is still maintained and sent as context so the agent has continuity.

```
> /nosave
# nosave mode enabled; next message will not be saved

> /nosave summarise this file for me
# sends the message in nosave mode

> /nosave /commit
# runs the /commit skill in nosave mode
```

---

### Project

| Command | Description |
|---|---|
| `/project [id\|key\|name\|clear]` | Select (or clear) the workspace project for this session |
| `/workitem [id\|key\|title\|clear]` | Select (or clear) a work item within the current project |

#### `/project [id|key|name|clear]`

- No argument: shows the current selection and opens a filterable picker.
- With a value: resolves and selects the matching project directly (by ID, key, or name).
- `clear` / `none` / `reset`: removes the project selection.

The selection persists in `~/.monofoundry/projects/<slug>/meta.json`.

```
> /project
Current project: monō foundry — https://app.monoai.co/projects/...
# opens picker:
  monō foundry    MONO  47 open
  monō platform   PLAT  12 open
  Clear selection
  Cancel

> /project MONO
# selects project by key

> /project clear
Project selection cleared.
```

#### `/workitem [id|key|title|clear]`

Requires a project to be selected first. Opens a filterable picker of all open work items, or accepts a direct argument.

```
> /workitem
# opens picker:
  MONO-92  Input enhancements: stash, history search    [in-progress]
  MONO-93  Prompt stash (Ctrl-S / /stash)               [todo]
  Clear work item
  Cancel

> /workitem MONO-92
# selects by key

> /workitem clear
Work item cleared.
```

---

### Skills

| Command | Description |
|---|---|
| `/skills` | List all discovered skills |
| `/<skill-name> [arg]` | Run a skill as a turn, with an optional argument appended |

Skills are discovered from SKILL.md files in the workspace and your home directory. See the [Skills documentation](https://github.com/monoai-labs/mono-foundry) for the discovery paths and file format.

```
> /skills
  /commit  Format a git commit message following Dom's usual conventions

> /commit
# runs the commit skill as a full agent turn

> /commit feat: add history search
# runs the skill with the argument appended to the skill body
```

---

## Shell Mode

Any input that starts with `!` runs the rest of the line as a local shell command via `bash -c`. Output is printed above the prompt; the agent is not involved.

Timeout: 60 seconds.

```
> !ls src/
api.ts  auth.ts  commands.ts  ...
[exit 0]

> !git status
On branch main
nothing to commit, working tree clean
[exit 0]

> !pnpm test
# runs the test suite locally
[exit 0]
```

---

## Keyboard Shortcuts

### Ctrl- Shortcuts

| Shortcut | Action |
|---|---|
| `Ctrl-C` | Interrupt — cancel the running turn, or clear the current buffer |
| `Ctrl-D` | Exit the REPL (equivalent to `/quit`) |
| `Ctrl-A` | Move cursor to the start of the line |
| `Ctrl-E` | Move cursor to the end of the line |
| `Ctrl-U` | Delete everything from the start of the line to the cursor |
| `Ctrl-W` | Delete the word immediately before the cursor |
| `Ctrl-R` | Open the history search picker |
| `Ctrl-S` | Stash / restore: stash the buffer on first press; restore (pop) on the second press with an empty buffer |
| `Ctrl-←` | Move cursor one word to the left |
| `Ctrl-→` | Move cursor one word to the right |

#### `Ctrl-C`

While the agent is running: aborts the current turn. While typing: clears the buffer.

#### `Ctrl-R` — History search

Opens a live-filter picker over your entire input history. Start typing to narrow the list; `Enter` selects and copies the entry to the input buffer; `Escape` cancels.

```
# press Ctrl-R, then type "test"
  run failing tests
  pnpm test src/render
  fix the test snapshot
```

#### `Ctrl-S` — Stash

First press with a non-empty buffer: stashes the buffer content and clears the input (same as `/stash <buffer>`).
First press with an empty buffer (or second press): pops the most recently stashed entry back into the buffer.

```
# typing: "explain the auth flow"
# Ctrl-S → buffer cleared, "explain the auth flow" stashed
# Ctrl-S (empty buffer) → "explain the auth flow" restored
```

---

### Navigation

| Key | Action |
|---|---|
| `←` / `→` | Move cursor one character left / right |
| `Home` | Move cursor to the start of the line (same as `Ctrl-A`) |
| `End` | Move cursor to the end of the line (same as `Ctrl-E`) |
| `Alt-←` / `Alt-B` | Move cursor one word to the left |
| `Alt-→` / `Alt-F` | Move cursor one word to the right |
| `Backspace` | Delete character before the cursor |
| `Delete` | Delete character at the cursor |

---

### History

| Key | Action |
|---|---|
| `↑` | Previous history entry (or recall the last queued message if one exists) |
| `↓` | Next history entry |
| `Ctrl-R` | Open the live-filter history search picker |

History is persisted across sessions at `~/.monofoundry/history`.

When multiple messages are queued (e.g. typed while the agent was running), pressing `↑` on an empty buffer recalls the most recently queued message for editing, removing it from the queue.

---

### Multi-line Input

| Key | Action |
|---|---|
| `Shift-Enter` | Insert a literal newline at the cursor position |
| `Enter` | Submit the message (even if it contains newlines) |
| `↑` / `↓` | Move cursor up / down a visual line when the buffer has newlines |

Pasted content (bracketed paste) is automatically preserved with its original newlines intact.

```
# press Shift-Enter to build a multi-line message:
> refactor the function below to use async/await:
  <paste code here>
```

---

### Tab Completion

| Key | Action |
|---|---|
| `Tab` | Accept ghost-text completion, or cycle to the next `@`-file match |
| `Shift-Tab` | Cycle to the previous `@`-file match |

**Slash command completion:** When the buffer starts with `/`, pressing `Tab` completes to the longest common prefix of all matching commands. If multiple commands match, the ghost text shows the common prefix and available options are listed inline.

```
> /res<Tab>    →  /resume
> /c<Tab>      →  /c   (shows: /clarify, /clear, /conversations)
```

**`@` file completion:** Type `@` anywhere in your message to attach a file reference. As you type the path after `@`, matching files from the working directory are shown as ghost text. Completions are case-insensitive; hidden files (dotfiles) are skipped unless you explicitly type a leading `.`.

- Paths are relative to the current working directory.
- `~/` paths are expanded to your home directory.
- Directories complete with a trailing `/` so you can keep descending.
- Press `Tab` to accept the longest common prefix. If multiple files match, `Tab` and `Shift-Tab` cycle forward and backward through them.
- Multiple `@` references can appear in the same message.

```
> Summarise @src/re<Tab>   →  @src/repl.ts   (if only one match)
> Summarise @src/re<Tab>   →  @src/render/   (if a directory matches)
> Diff @src/<Tab><Tab>     →  cycles through all files under src/
> Check @~/.<Tab>          →  shows dotfiles in home directory
```

---

© monō ai Australia Pty Ltd. All rights reserved.
