# monofoundry - Subagents

Subagents are independent child conversations that the backend can spawn mid-turn to work on a task in parallel with the main agent. They run concurrently on the CLI surface - the parent turn is not blocked while children execute - and their output is visually attributed with a gutter prefix so you can tell parent and child apart.

---

## Table of Contents

- [Overview](#overview)
- [How It Works](#how-it-works)
- [Visual Attribution](#visual-attribution)
- [Lifecycle](#lifecycle)
- [Tool Execution](#tool-execution)
- [Persistence & Resume](#persistence--resume)
- [Prompting Suggestions](#prompting-suggestions)
- [Limitations & Constraints](#limitations--constraints)

---

## Overview

The monō foundry CLI is a thin client: the agent loop and model intelligence live server-side. Subagents extend this model - the backend's orchestrator decides when to spawn a child conversation, and emits a `subagent_spawn` event on the parent's generate stream. The CLI receives this event and launches a second loop for the child that executes independently of the parent.

Key properties:

- **Concurrent (fire-and-forget).** The parent stream continues processing while children run. The parent does not wait for a child to finish before handling the next event.
- **Independent conversations.** Each child has its own hidden Core conversation server-side.
- **Same local tool surface.** Children execute IDE tool commands locally via the same registry as the parent.
- **No grandchildren.** A child cannot spawn its own subagents.

---

## Visual Attribution

Child output is visually distinguished from parent output so you can follow both streams:

- **Gutter prefix.** All child output lines are prefixed with ` |` (two spaces, a dimmed pipe, a space).
- **Banners.** A start and finish banner are written to the parent sink (not indented) so they stand out:

  ```
    ▸ subagent [a3f2] started: Research the auth flow and summarise token refresh...
    | <child output lines here>
    ▸ subagent [a3f2] finished
  ```

  The tag (`a3f2` in this example) provies a short distinguishing label when multiple children run concurrently.

---

## Lifecycle

| Phase            | Behaviour                                                                                                                                                  |
| ---------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **Spawn**        | The backend emits `subagent_spawn` on the parent stream.                                                                                                   |
| **Running**      | The child consumes its own SSE stream, renders output through the child sink, and executes tool commands locally. The parent stream continues in parallel. |
| **Completion**   | When the child stream ends (`done`/`complete`), the child prints its finish banner and resolves.                                                           |
| **Turn end**     | The parent awaits all in-flight children before the turn is considered complete.                                                                           |
| **Cancellation** | Ctrl-C / SIGINT propagates to children through the shared `AbortSignal`. An aborted child exits cleanly without an error message.                          |

If a child crashes unexpectedly, a safety net prevents that failure from propagating to the parent.

---

## Tool Execution

Children use the same local tool registry as the parent. Every tool available to the parent is available to a child, including file operations, terminal commands, search, git, and MCP tools.

### Auto-accept for mutations

Mutating tools (`write_file`, `apply_diff`, `search_and_replace`, `delete_file`, `move_file`, `call_mcp_tool`, `code_runner`) are **auto-accepted** in subagents — the diff preview is still rendered for visibility, but no interactive approval prompt is shown. This is because children run in the background and cannot block on user input.

If you have approval mode enabled (`--approve` or `/approve`), it applies to the **parent** turn only. Subagent mutations are not gated.

### Command response routing

Each tool command's result is POSTed back via `sendCommandResponse` on the child's own `commandId`. The wire contract relies on command IDs being globally unique across parent and child streams - if this assumption ever breaks, `childSid`/`conversationId` correlation would be needed on the POST.

---

## Persistence & Resume

Subagent transcripts are **not** written to the local conversation store. The child has its own hidden Core conversation server-side; the CLI does not persist child messages, tool calls, or plans locally.

For `/resume` fidelity, a lightweight `subagent_spawn` marker is pushed into the parent's `assistantToolCalls` array, recording the child's request and `childSid`. This means that when you resume a conversation that involved subagents, you will see that a subagent was spawned and what it was asked to do, but not its full transcript.

---

## Prompting Suggestions

Subagent spawning is orchestrated by the backend - you do not directly control when children are launched. However, you can structure your requests to encourage effective parallel work and get the most out of subagents when they appear.

### Encourage parallel decomposition

When your request naturally decomposes into independent subtasks, the orchestrator is more likely to spawn children for them. Frame requests that have clear, separable components:

```
Research the authentication flow in src/auth/ and draft a README section
explaining token refresh. At the same time, audit src/api.ts for any
unhandled error paths and list them.
```

Two independent tasks (research + audit) are good candidates for parallel subagents. A single tightly-coupled task is not.

### Be explicit about scope

Children receive their own workspace context but do not inherit the parent's in-progress reasoning. Give enough context in your request that a subtask is self-contained:

```
In the src/render/ directory, find all files that import from ~/render/ansi
and check whether any use escape codes outside the SGR family. The renderer
contract requires SGR-only output - flag any violations.
```

### Expect concurrent output

When subagents are running, you will see interleaved output: parent text, then gutter-prefixed child lines (`| ...`), then more parent text. Each child is tagged with a 4-character label in its banners (e.g. `[a3f2]`) so you can distinguish multiple children. You do not need to wait for children to finish - the parent continues working.

### Know that mutations are auto-accepted

Subagents do not prompt for approval on mutating tools. If a child needs to write files or run commands, it will do so without asking. If you are working in a sensitive area and want full control over mutations, be aware that subagent changes will not be gated by `--approve`.

### Use Ctrl-C to cancel everything

Ctrl-C / SIGINT cancels the parent turn and all in-flight children simultaneously via the shared abort signal. There is no way to cancel a single child independently from the CLI.

### Keep subtasks focused

Children are lightweight loops without the full persistence and approval machinery of the parent. They are best suited for focused, well-bounded tasks - research, analysis, drafting, code review - rather than long-running multi-step implementations that require interactive steering.

---

## Limitations & Constraints

| Constraint                      | Detail                                                                                                                              |
| ------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------- |
| **No grandchildren**            | A child cannot spawn its own subagents. `subagent_spawn` events on a child stream are ignored.                                      |
| **No local persistence**        | Child transcripts are not saved to the local conversation store. Only a spawn marker is recorded in the parent's tool-call history. |
| **No interactive approval**     | Mutating tools are auto-accepted in children. The diff preview is shown but no accept/reject/skip prompt.                           |
| **No independent cancellation** | Ctrl-C cancels the parent and all children together. Individual children cannot be cancelled from the CLI.                          |
| **No child spinner**            | The parent owns the spinner line. Child status feedback comes through text output and tool-run summaries only.                      |
| **Server-side orchestration**   | The CLI does not decide when to spawn subagents - the backend orchestrator does. The CLI cannot request a subagent directly.        |

---

© monō ai Australia Pty Ltd. All rights reserved.
