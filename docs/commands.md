# monofoundry - Commands & Shortcuts

This document covers every command and keyboard shortcut available in the interactive REPL.

---

## Table of Contents

- [CLI Flags](#cli-flags)
- [Slash Commands](#slash-commands)
  - [Core](#core)
  - [Conversation](#conversation)
  - [Session](#session)
  - [Files & Attachments](#files--attachments)
  - [Auth](#auth)
  - [Organisation](#organisation)
  - [Project](#project)
  - [Skills](#skills)
- [Shell Mode](#shell-mode)
- [Keyboard Shortcuts](#keyboard-shortcuts)
  - [Ctrl- Shortcuts](#ctrl--shortcuts)
  - [Navigation](#navigation)
  - [History](#history)
  - [Multi-line Input](#multi-line-input)
  - [Tab Completion](#tab-completion)
  - [Model Switching](#model-switching)

---

## CLI Flags

Flags can be passed when launching `monofoundry` from the terminal.

```
monofoundry [message]           Interactive REPL (or one-shot if message given)
monofoundry auth login          Sign in with Google or Microsoft OAuth
monofoundry auth login --apikey Sign in with an API key
monofoundry auth logout         Remove stored credentials
monofoundry auth status         Show current auth status
```

| Flag                        | Description                                          |
| --------------------------- | ---------------------------------------------------- |
| `--version`, `-v`           | Print the version and exit                           |
| `--cwd <path>`              | Set workspace root (default: current directory)      |
| `--endpoint <url>`          | Override the API endpoint                            |
| `--model <id>`              | Start the session with a specific model pre-selected |
| `--project <id\|key\|name>` | Scope the session to a workspace project             |
| `--resume <id>`             | Resume a previous conversation by ID                 |
| `--approve`                 | Require approval before applying code edits          |

---

## Slash Commands

Slash commands are available inside the interactive REPL. Type `/` to trigger tab-completion; all commands and aliases are listed. Unrecognised slash commands are treated as normal chat messages.

### Core

| Command         | Aliases  | Description                                               |
| --------------- | -------- | --------------------------------------------------------- |
| `/help`         | -        | List all available commands and shortcuts                 |
| `/quit`         | `/exit`  | Exit the REPL (saves input history first)                 |
| `/new`          | `/clear` | Start a new conversation (clears current conversation ID) |
| `/stash [text]` | -        | Stash input or open the stash picker                      |
| `/update`       | -        | Check for and apply updates to the latest version         |

#### `/help`

Prints a formatted list of every registered command, its aliases, and its description, followed by a summary of keyboard shortcuts.

```
> /help
  /approve          Toggle edit approval mode
  /attach <path>    Upload a file and attach it to your next message
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
# opens picker - select an entry to restore it to the input buffer
```

#### `/update`

Checks for any available updates.

```
> /update
Checking for updates
Update available: v0.5.0 (current: v0.4.0)
```

---

### Conversation

| Command          | Aliases  | Description                                                                                                                          |
| ---------------- | -------- | ------------------------------------------------------------------------------------------------------------------------------------ |
| `/resume [id]`   | -        | Resume the most recent conversation, or a specific one by ID                                                                         |
| `/conversations` | -        | Browse and resume local and project-linked conversations                                                                             |
| `/history`       | -        | Show recent remote conversation history (up to 10)                                                                                   |
| `/tokens`        | `/costs` | Display token usage and estimated costs for session, conversation, project, and overall - with a per-model breakdown under each tier |

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

| Command               | Aliases   | Description                                                      |
| --------------------- | --------- | ---------------------------------------------------------------- |
| `/model [id\|reset]`  | `/models` | View available models, set the active model, or reset to default |
| `/approve`            | -         | Toggle approval mode for file edits                              |
| `/clarify <msg>`      | -         | Steer the agent mid-turn                                         |
| `/nosave [msg\|/cmd]` | -         | Run a turn or command without saving to the backend              |

#### `/model [id|reset]`

- No argument: shows the current model and opens a filterable picker (sorted by frecency).
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

> **Keyboard shortcut:** Press `Alt/Opt-M` at any time to open the model picker without clearing your input — see [Model Switching](#model-switching).

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

### Files & Attachments

| Command          | Description                                                            |
| ---------------- | ---------------------------------------------------------------------- |
| `/attach <path>` | Upload a file and stage it for your next message                       |
| `/paste`         | Capture an image from the clipboard and attach it to your next message |

You can also attach files inline in any message using `@`-prefixed paths - see [@ file completion](#-file-completion) and [Inline @-path attachments](#inline--path-attachments) below.

#### `/attach <path>`

Uploads the file at `<path>` and stages it to be sent with your next message. Relative paths are resolved from the current working directory; `~/` is expanded to your home directory. The file is uploaded immediately, and a confirmation line is shown above the prompt.

Binary files (images, PDFs, Office documents, archives, etc.) are uploaded to the server. Text files are left for the agent to read directly via its file tools.

```
> /attach ./diagram.png
✓ diagram.png (42 KB)  image/png

> /attach ~/Downloads/spec.pdf
✓ spec.pdf (1.2 MB)  application/pdf
```

Multiple `/attach` calls before submitting a message will all be included together.

#### `/paste`

Captures an image from the OS clipboard (e.g. a screenshot taken with Cmd-Shift-4), writes it to a temporary file, and inserts an `@<tmp-path>` token into the input buffer. The image is uploaded when you submit the message.

```
> /paste
# if an image is in the clipboard:
Captured clipboard image → /tmp/monofoundry-clip-xxxx.png
# the @-path is inserted into the input buffer for you

# if the clipboard has no image:
No image found in the clipboard.
```

#### Inline @-path attachments

You can reference files directly in any message by prefixing the path with `@`. When you submit the message, binary files are automatically uploaded and their IDs sent to the agent. Text files are left as-is for the agent to read.

- Paths are relative to `--cwd` (default: current directory).
- `~/` is expanded to your home directory.
- Absolute paths are accepted.
- Multiple `@` references can appear in the same message.
- Duplicate paths in the same message are de-duplicated.

```
> Can you review @src/auth.ts and the design in @docs/auth-flow.png?
# auth.ts is text - the agent reads it with its tools
# auth-flow.png is binary - uploaded and sent as an attachment

> Summarise the contents of @~/Downloads/report.pdf
```

See also: [@ file completion](#-file-completion) for tab-completing paths as you type.

---

### Auth

| Command                | Description                                      |
| ---------------------- | ------------------------------------------------ |
| `/login [--microsoft]` | Sign in with Google (default) or Microsoft OAuth |
| `/logout`              | Sign out and clear stored credentials            |
| `/status`              | Show current authentication status               |

These commands mirror the `monofoundry auth` CLI subcommands but work directly from the REPL so you can re-authenticate without restarting.

> **Note:** API key login (`--apikey`) is not supported from inside the REPL. Use `monofoundry auth login --apikey` from the terminal instead.

#### `/login [--microsoft]`

Opens a browser for OAuth sign-in. Defaults to Google; pass `--microsoft` to use Microsoft.

```
> /login
Opening browser for sign-in...
Signed in as dom@monoai.co

> /login --microsoft
Opening browser for sign-in...
Signed in as dom@monoai.co
```

#### `/logout`

Clears all stored credentials from `~/.monofoundry/config.json`.

```
> /logout
Signed out.
```

#### `/status`

Shows who is currently signed in (or an error if you are not).

```
> /status
Signed in as dom@monoai.co
```

---

### Organisation

| Command                    | Aliases         | Description                                     |
| -------------------------- | --------------- | ----------------------------------------------- |
| `/org [id\|name\|default]` | `/organisation` | Switch the active organisation for this session |

#### `/org [id|name|default]`

- No argument: shows the current selection and opens a filterable picker.
- With a value: resolves and selects the matching organisation directly (by ID or display name).
- `default` / `clear` / `none` / `reset`: reverts to the account's default organisation.

Switching organisations cascades: the model cache is cleared and refreshed, any project/work-item selection is reset, and a new conversation is started (since each is homed within an org).

```
> /org
# opens picker:
  monō ai          (current)
  Acme Corp
  Use default organisation
  Cancel

> /org Acme Corp
Organisation: Acme Corp  - model cache cleared, new conversation

> /org default
Organisation: default  - model cache cleared, new conversation
```

---

### Project

| Command                                             | Description                                                     |
| --------------------------------------------------- | --------------------------------------------------------------- |
| `/project [id\|key\|name\|clear]                `   | Select (or clear) the workspace project for this session        |
| `/workitem [create <title>\|id\|key\|title\|clear]` | Select, create, or clear a work item within the current project |

#### `/project [id|key|name|clear]`

- No argument: shows the current selection and opens a filterable picker.
- With a value: resolves and selects the matching project directly (by ID, key, or name).
- `clear` / `none` / `reset`: removes the project selection.

The selection persists in `~/.monofoundry/projects/<slug>/meta.json`.

```
> /project
Current project: monō foundry - https://app.monoai.co/projects/...
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

#### `/workitem [create <title>|id|key|title|clear]`

Requires a project to be selected first.

**Sub-commands:**

- `create <title>` — Create a new work item in the current project. The title can be supplied inline (optionally quoted with `"` or `'`) or entered at a prompt if omitted. You're then prompted for an optional description (press Enter to skip). The new work item is auto-selected on success so you can start working immediately.
- `<id|key|title>` — Select an existing work item directly.
- `clear` / `none` / `reset` — Remove the current work item selection.
- No argument — Open a filterable picker of all open work items.

```
> /workitem
# opens picker:
  MONO-92  Input enhancements: stash, history search    [in-progress]
  MONO-93  Prompt stash (Ctrl-S / /stash)               [todo]
  Clear work item
  Cancel

> /workitem MONO-92
# selects by key

> /workitem create "Add dark mode toggle"
Enter an optional description (or press Enter to skip):
> Just the settings page for now

MONO-207 created (Add dark mode toggle)

> /workitem create Fix the login bug
# unquoted titles also work; description prompt follows

> /workitem clear
Work item cleared.
```

---

### Skills

| Command               | Description                                               |
| --------------------- | --------------------------------------------------------- |
| `/skills`             | List all discovered skills                                |
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
> ! ls src/
api.ts  auth.ts  commands.ts  ...
[exit 0]

> ! git status
On branch main
nothing to commit, working tree clean
[exit 0]

> ! pnpm test
# runs the test suite locally
[exit 0]
```

---

## Keyboard Shortcuts

### Ctrl- Shortcuts

| Shortcut | Action                                                                                                   |
| -------- | -------------------------------------------------------------------------------------------------------- |
| `Ctrl-C` | Interrupt - cancel the running turn, or clear the current buffer                                         |
| `Ctrl-D` | Exit the REPL - double-press to confirm (equivalent to `/quit`)                                          |
| `Ctrl-A` | Move cursor to the start of the line                                                                     |
| `Ctrl-E` | Move cursor to the end of the line                                                                       |
| `Ctrl-U` | Delete everything from the start of the line to the cursor                                               |
| `Ctrl-W` | Delete the word immediately before the cursor                                                            |
| `Ctrl-R` | Open the history search picker                                                                           |
| `Ctrl-S` | Stash / restore: stash the buffer on first press; restore (pop) on the second press with an empty buffer |
| `Ctrl-←` | Move cursor one word to the left                                                                         |
| `Ctrl-→` | Move cursor one word to the right                                                                        |

#### `Ctrl-C`

- **While the agent is generating:** aborts the current turn immediately.
- **While typing (non-empty buffer):** clears the buffer.
- **While idle (empty buffer):** arms a double-press window. Press `Ctrl-C` a second time within ~2 seconds to exit.

#### `Ctrl-R` - History search

Opens a live-filter picker over your entire input history. Start typing to narrow the list; `Enter` selects and copies the entry to the input buffer; `Escape` cancels.

```
# press Ctrl-R, then type "test"
  run failing tests
  pnpm test src/render
  fix the test snapshot
```

#### `Ctrl-S` - Stash

First press with a non-empty buffer: stashes the buffer content and clears the input (same as `/stash <buffer>`).
First press with an empty buffer (or second press): pops the most recently stashed entry back into the buffer.

```
# typing: "explain the auth flow"
# Ctrl-S → buffer cleared, "explain the auth flow" stashed
# Ctrl-S (empty buffer) → "explain the auth flow" restored
```

---

### Model Switching

| Shortcut   | Action                                                         |
| ---------- | ------------------------------------------------------------- |
| `Alt/Opt-M` | Open the model picker without clearing the input buffer       |

#### `Alt/Opt-M` - Switch model

Opens the model picker directly from the input line — no need to type `/model` and submit. The input buffer is preserved: the picker renders in the live region (temporarily hiding the input), and the buffer is restored when the picker closes, whether you select a model or cancel with `Escape`/`Ctrl-C`.

The selected model persists per project directory and takes effect on the next turn. If the agent is currently generating, the model change applies to subsequent turns — the current turn is not interrupted. The shortcut is ignored if another picker is already open.

```
# typing: "refactor the auth module to use█"
# Alt/Opt-M → picker opens, buffer hidden:
  Select model
  > Type to filter
  ▸ Claude Sonnet 4   [standard]  Anthropic
    GPT-4o             [standard]  OpenAI
    Cancel
# select a model → picker closes, buffer restored:
  ❯ refactor the auth module to use█
```

---

### Navigation

| Key                       | Action                                                  |
| ------------------------- | ------------------------------------------------------- |
| `←` / `→`                 | Move cursor one character left / right                  |
| `Home`                    | Move cursor to the start of the line (same as `Ctrl-A`) |
| `End`                     | Move cursor to the end of the line (same as `Ctrl-E`)   |
| `Alt/Opt-←` / `Alt/Opt-B` | Move cursor one word to the left                        |
| `Alt/Opt-→` / `Alt/Opt-F` | Move cursor one word to the right                       |
| `Backspace`               | Delete character before the cursor                      |
| `Delete`                  | Delete character at the cursor                          |

---

### History

| Key      | Action                                                                   |
| -------- | ------------------------------------------------------------------------ |
| `↑`      | Previous history entry (or recall the last queued message if one exists) |
| `↓`      | Next history entry                                                       |
| `Ctrl-R` | Open the live-filter history search picker                               |

History is persisted per-project at `~/.monofoundry/projects/<slug>/history`.

When multiple messages are queued (e.g. typed while the agent was running), pressing `↑` on an empty buffer recalls the most recently queued message for editing, removing it from the queue.

---

### Multi-line Input

| Key                             | Action                                                           |
| ------------------------------- | ---------------------------------------------------------------- |
| `Shift-Enter` / `Alt/Opt-Enter` | Insert a literal newline at the cursor position                  |
| `Enter`                         | Submit the message (even if it contains newlines)                |
| `↑` / `↓`                       | Move cursor up / down a visual line when the buffer has newlines |

Pasted content (bracketed paste) is automatically preserved with its original newlines intact.

```
# press Shift-Enter to build a multi-line message:
> refactor the function below to use async/await:
  <paste code here>
```

---

### Tab Completion

| Key         | Action                                                            |
| ----------- | ----------------------------------------------------------------- |
| `Tab`       | Accept ghost-text completion, or cycle to the next `@`-file match |
| `Shift-Tab` | Cycle to the previous `@`-file match                              |

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

#### Inline @-path attachments

When you submit a message containing `@`-prefixed paths, binary files (images, PDFs, Office documents, etc.) are automatically uploaded and sent as attachments. Text files are left as-is - the agent reads them using its file tools. The message text itself is not modified.

```
> Explain the architecture in @docs/overview.png and @README.md
# overview.png  → uploaded as an attachment
# README.md     → agent reads it directly (text file)
```

---

© monō ai Australia Pty Ltd. All rights reserved.
