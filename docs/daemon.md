# monofoundry - Daemon local runtime

monō foundry uses a local daemon as the default runtime for both interactive REPL sessions and one-shot CLI turns. The CLI you type into is still the frontend; the daemon hosts the local control loop, Core stream, local tool execution, subagent lifecycle, and bridge/session state.

The daemon is local-only. It binds to loopback, authenticates clients with a bearer token, and stores its discovery record and logs under `~/.monofoundry/`.

---

## Table of Contents

- [Default behaviour](#default-behaviour)
- [Lifecycle commands](#lifecycle-commands)
- [REPL commands](#repl-commands)
- [Direct and recovery mode](#direct-and-recovery-mode)
- [Multiple CLI clients](#multiple-cli-clients)
- [Explicit daemon diagnostics](#explicit-daemon-diagnostics)
- [Files and locations](#files-and-locations)
- [Updates and stale daemons](#updates-and-stale-daemons)
- [Troubleshooting](#troubleshooting)
- [Security notes](#security-notes)

---

## Default behaviour

Normal usage routes through the daemon by default:

```bash
monofoundry
monofoundry "fix the failing test in src/render"
```

On startup, the CLI checks daemon discovery metadata and daemon health. If a ready daemon is available, the CLI attaches to it by creating an explicit cwd-aware daemon session. If not, the CLI starts one in the background when daemon support is bundled for the current install.

CLI auto-started daemons receive a default idle shutdown window of five minutes. Once no clients are attached and no session is streaming, the daemon exits after that window. Explicit daemon starts (`monofoundry daemon start` or `monofoundry daemon`) remain opt-in for idle shutdown and continue to run until stopped unless `--idle-ms` or `SPIRE_IDLE_SHUTDOWN_MS` is supplied.

Default daemon mode is intentionally recoverable: if daemon startup or readiness fails before a turn begins, the CLI can fall back to direct mode and run the turn without the daemon. Explicit daemon mode behaves differently; see [Explicit daemon diagnostics](#explicit-daemon-diagnostics).

## Lifecycle commands

Use the top-level daemon commands to inspect and manage the local runtime:

```bash
monofoundry daemon status
monofoundry daemon start
monofoundry daemon stop
monofoundry daemon restart
monofoundry daemon logs [--lines n]
monofoundry doctor
```

| Command                               | Description                                                                                               |
| ------------------------------------- | --------------------------------------------------------------------------------------------------------- |
| `monofoundry daemon status`           | Show discovery, readiness, pid, port, version, protocol, boot id, log path, and cwd-aware sessions for the discovered daemon. |
| `monofoundry daemon start`            | Start the daemon in the background, or report the existing ready daemon.                                  |
| `monofoundry daemon stop`             | Request shutdown for the discovered daemon.                                                               |
| `monofoundry daemon restart`          | Stop the discovered daemon, wait briefly, then start a fresh daemon.                                      |
| `monofoundry daemon logs [--lines n]` | Print recent daemon log lines; defaults to the last 100 lines.                                            |
| `monofoundry doctor`                  | Run local diagnostics covering discovery, readiness, version compatibility, logs, and config health.      |

## REPL commands

Inside the interactive REPL, daemon diagnostics are also available without leaving the session:

| Command            | Description                                                             |
| ------------------ | ----------------------------------------------------------------------- |
| `/daemon status`   | Show daemon status using the same status path as the top-level command. |
| `/daemon logs [n]` | Show recent daemon logs.                                                |
| `/doctor`          | Run local monofoundry diagnostics.                                      |

These commands are safe during a turn, so they can be used while investigating a stuck or degraded daemon session.

## Direct and recovery mode

Use direct mode when you need to bypass the daemon for recovery, debugging, or comparison:

```bash
monofoundry --direct
monofoundry --no-daemon
MONOFOUNDRY_NO_DAEMON=1 monofoundry
```

Direct mode runs the CLI against Core without attaching to or starting the daemon. It remains the escape hatch for urgent work if the daemon is unhealthy.

## Multiple CLI clients and cwds

One daemon process can host multiple CLI or IDE frontends at the same time. Each new CLI REPL or one-shot daemon-client run creates a distinct logical daemon session id (`sid`) and attaches it with an immutable canonical cwd plus workspace folder metadata.

Session isolation rules:

- cwd belongs to the daemon session, not the daemon process;
- output for sid A is delivered only to sid A's frontend channel;
- input and abort/control for sid A only affect sid A's `DaemonSession`;
- daemon-local tools execute with sid A's cwd;
- relayed tool requests carry sid A's cwd and workspace folders;
- relayed tool and approval responses are matched by sid plus request id/command id;
- reconnects resume only the replay buffer for the reconnecting sid;
- reattaching the same sid with a different cwd is rejected;
- a duplicate physical connection for the same sid replaces only that sid's channel.

A `/resume` conversation id is not the same as a daemon sid. Resuming a conversation in a new CLI creates a new daemon sid, while reconnecting an existing CLI process reuses its current sid and `Last-Event-ID` replay position.

Subagent child sessions are owned by their parent daemon sid. Their output is still tagged with the child sid for attribution, but it is delivered through the owning frontend session. Child sessions inherit the parent's workspace context unless a future explicit cross-workspace subagent feature is designed.

Reference VS Code compatibility remains at the daemon boundary. Reference-style VS Code clients can still connect with the primary session and `SPIRE_WORKSPACE_FOLDERS`; the daemon normalises that into the same session workspace model used by CLI clients.

## Explicit daemon diagnostics

For daemon-specific debugging, force daemon-client mode:

```bash
monofoundry --daemon-client
monofoundry --daemon-client --daemon-port 43123 --daemon-token "$TOKEN"
monofoundry --daemon-client --daemon-url http://127.0.0.1:43123 --daemon-token "$TOKEN"
```

Environment variable equivalents are also supported:

| Variable                      | Purpose                                                                |
| ----------------------------- | ---------------------------------------------------------------------- |
| `MONOFOUNDRY_DAEMON_CLIENT=1` | Force daemon-client mode.                                              |
| `MONOFOUNDRY_DAEMON_URL`      | Daemon base URL.                                                       |
| `MONOFOUNDRY_DAEMON_PORT`     | Shorthand for `http://127.0.0.1:<port>`.                               |
| `MONOFOUNDRY_DAEMON_TOKEN`    | Bearer token for daemon-client auth.                                   |
| `MONOFOUNDRY_DAEMON_IDLE_MS`  | Idle shutdown window for CLI auto-started daemons; use `0` to disable. |

Explicit daemon mode fails closed on startup, readiness, protocol, auth, or version mismatch errors. Use it when you want daemon problems to be surfaced rather than silently recovered by direct fallback.

## Files and locations

| File                                            | Purpose                                                                                                         |
| ----------------------------------------------- | --------------------------------------------------------------------------------------------------------------- |
| `~/.monofoundry/daemon.json`                    | Discovery metadata for the current daemon, including URL, token, pid, version, protocol, boot id, and log path. |
| `~/.monofoundry/logs/daemon.log`                | Daemon NDJSON logs.                                                                                             |
| `~/.monofoundry/config.json`                    | Auth credentials and user settings.                                                                             |
| `~/.monofoundry/projects/<slug>/conversations/` | Local conversation history.                                                                                     |

Avoid editing `daemon.json` manually unless diagnostics direct you to remove stale discovery data.

## Updates and stale daemons

A running daemon keeps executing the code it was started with. After updating monofoundry, a daemon may therefore be older than the newly launched CLI.

The CLI checks daemon version metadata during attach:

- In default daemon mode, an idle stale daemon is restarted automatically.
- If the stale daemon has active sessions and remains protocol-compatible, the CLI warns and continues; restart it when work finishes.
- In explicit `--daemon-client` mode, version mismatch fails closed with a clear restart message.
- `monofoundry daemon status` and `monofoundry doctor` report stale daemon versions and recommend `monofoundry daemon restart`.

## Troubleshooting

| Symptom                               | First checks                                      | Recovery                                                                               |
| ------------------------------------- | ------------------------------------------------- | -------------------------------------------------------------------------------------- |
| Daemon unavailable or unreachable     | `monofoundry doctor`, `monofoundry daemon status` | Run `monofoundry daemon restart`; use `--direct` for urgent work.                      |
| Auth required or expired              | `monofoundry auth status`, `monofoundry doctor`   | Run `monofoundry auth login`, then retry or restart the daemon if it remains degraded. |
| Bridge unavailable                    | `monofoundry doctor`, daemon logs                 | Restart the daemon; use direct mode for CLI-only recovery.                             |
| Version mismatch or stale daemon      | `monofoundry daemon status`, `monofoundry doctor` | Wait for active sessions to finish, then run `monofoundry daemon restart`.             |
| Stale discovery, socket, or port data | Status, doctor, logs                              | Run `monofoundry daemon stop`; remove stale discovery only if directed; start again.   |
| Wrong cwd or sid attach rejection     | `monofoundry daemon status`, daemon logs          | Start a fresh CLI session for the new cwd; do not reuse an old sid across directories. |
| Tool routing or timeout failures      | Daemon logs and doctor output                     | Retry the turn, restart the daemon if repeated, or use direct mode for urgent work.    |

## Security notes

The daemon listens only on loopback and requires the bearer token from the discovery record. It does not expose a remote network service.

Tools still execute locally with the permissions of the user running monofoundry. The daemon changes where the local runtime is hosted, not what permissions local tools have. Use `--approve` for interactive edit approval and use OS-level sandboxing or a restricted user account when you need stronger isolation.

See [Security](security.md) for the full security model.

---

© monō ai Australia Pty Ltd. All rights reserved.
