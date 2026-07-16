# monofoundry - Plugins

Plugins extend monō foundry with additional capabilities - language server support, syntax highlighting, custom tools, slash commands, and more. Plugins are distributed as tarballs from GitHub releases or direct URLs, and are managed entirely through the `monofoundry plugin` CLI command.

---

## Table of Contents

- [Overview](#overview)
- [Plugin Management](#plugin-management)
  - [Installing a Plugin](#installing-a-plugin)
  - [Listing Installed Plugins](#listing-installed-plugins)
  - [Updating a Plugin](#updating-a-plugin)
  - [Enabling and Disabling](#enabling-and-disabling)
  - [Removing a Plugin](#removing-a-plugin)
  - [Viewing Plugin Details](#viewing-plugin-details)
  - [Plugin Configuration](#plugin-configuration)
- [Installation Sources](#installation-sources)
- [Plugin IDs](#plugin-ids)
- [Storage and Configuration](#storage-and-configuration)
- [Permissions](#permissions)
- [After a Plugin Change](#after-a-plugin-change)
- [Contributed Slash Commands](#contributed-slash-commands)
- [First-Party Plugins](#first-party-plugins)
  - [LSP Plugin](#lsp-plugin)
  - [Highlight Plugin](#highlight-plugin)

---

## Overview

A plugin is a self-contained package with a `monofoundry.plugin.json` manifest that declares its name, version, entry point, permissions, and what it contributes to the runtime. The CLI downloads, validates, and installs plugins into a local store, then loads enabled plugins when a session starts.

### Runtime isolation

Plugins run in an isolated child process and communicate with the CLI over the existing IPC protocol. Windows standalone binaries re-invoke the installed executable with an internal plugin-host mode, so the Windows installation contains only `monofoundry.exe`. npm/source and Node development builds continue to use the emitted `dist/plugins/host/bootstrap.mjs` entrypoint.
||||||| Stash base

### Runtime contract

Plugins are executed in an isolated child host process. The host imports the manifest entry from the installed package directory using a file URL, so `import.meta.url`-relative asset lookup is supported.

Standalone binaries use the embedded Bun runtime for the child host; they do not guarantee a stock Node.js runtime. Plugins must not assume that a separately installed `node` executable, Node-only built-ins, or an ESM `__dirname` global exists. For portable asset lookup, use `new URL(\"./asset\", import.meta.url)` and convert it with `fileURLToPath()` when a filesystem path is required.

The manifest `moduleType` must match the plugin entry module format (`esm` or `cjs`). Node-specific runtime behavior should be treated as unsupported unless it is also supported by the Bun version embedded in the standalone release.

Plugins can contribute:

| Contribution            | Description                                                                                                           |
| ----------------------- | --------------------------------------------------------------------------------------------------------------------- |
| **Tools**               | Register new tools or override built-in ones (e.g. replace text-based `get_symbols` with LSP-backed implementations). |
| **Commands**            | Add slash commands to the REPL (e.g. `/lsp status`).                                                                  |
| **LSP**                 | Provide Language Server Protocol support for specific languages.                                                      |
| **Syntax highlighting** | Highlight code blocks and diffs in the terminal renderer.                                                             |
| **Configuration**       | Declare a configuration schema that users can set per-workspace.                                                      |

First-party plugins (published by monō ai) are marked with a `monoai` publisher ID and shown with a `(first-party)` indicator in CLI output.

---

## Plugin Management

All plugin operations use the `monofoundry plugin` command:

```
Usage: monofoundry plugin <command>

Commands:
  install <source> [--enable] [--dev]  Install a plugin from GitHub, URL, or local path
  update [id] [--version <ver>]      Update all or a specific plugin to latest (or pinned)
  list                               List installed plugins
  enable <id>                        Enable a plugin globally
  disable <id>                       Disable a plugin globally
  remove <id>                        Remove an installed plugin
  info <id>                          Show plugin details
  config <id> <key> <value>          Set a plugin config value
  config <id> clear [key]            Clear plugin config (all or single key)
  config <id> list                   List plugin config values

Sources:
  github:owner/repo@version          GitHub release tarball
  github:owner/repo@branch --dev     GitHub branch archive (dev only)
  https://github.com/owner/repo      GitHub repo URL (same as github:)
  https://.../*.tgz                  Direct tarball URL
  ./local-path --dev                 Local directory (dev only)
```

### Installing a Plugin

Install a plugin from a GitHub release:

```bash
monofoundry plugin install github:monoai-labs/mono-foundry-lsp-plugin
```

Install a specific version:

```bash
monofoundry plugin install github:monoai-labs/mono-foundry-lsp-plugin@v0.1.0
```

Install and enable in one step:

```bash
monofoundry plugin install github:monoai-labs/mono-foundry-lsp-plugin --enable
```

If `--enable` is not passed, you will be prompted to enable the plugin after installation. The install output shows the plugin's permissions, contributed tools, and SHA-256 hash for verification.

If the release tag doesn't match the manifest version, a warning is displayed:

```
⚠ Release tag v0.2.0 does not match manifest version v0.1.9
```

### Listing Installed Plugins

```bash
monofoundry plugin list
```

Output shows each plugin's ID, version, enabled/disabled status, and source:

```
Installed plugins:

  github:monoai-labs/mono-foundry-lsp-plugin v0.2.2 [enabled]
    source: github:monoai-labs/mono-foundry-lsp-plugin
```

### Updating a Plugin

Update installed plugins to their latest GitHub release:

```bash
monofoundry plugin update
```

This checks all installed GitHub-sourced plugins for available updates. If any are found, a list is shown with current → new version transitions and links to the releases page, followed by a confirmation prompt:

```
The following plugins will be updated:

  github:owner/repo  v1.0.0 → v1.2.0  https://github.com/owner/repo/releases

Update 1 plugin? [y/N]
```

Update a specific plugin:

```bash
monofoundry plugin update github:monoai-labs/mono-foundry-lsp-plugin
```

A single plugin update shows the version transition and proceeds without a confirmation prompt.

Update to a pinned version:

```bash
monofoundry plugin update github:monoai-labs/mono-foundry-lsp-plugin --version v0.2.0
```

The `--version` flag specifies a GitHub release tag to update to. It requires a plugin `<id>` — updating all plugins to a single version is not supported.

**How it works:** The update command queries the GitHub API for the latest release (or the specified tag) and compares the asset URL with the lockfile's `resolved` field. If they differ, the update proceeds by reinstalling from the new release. If they match, the plugin is already up to date and no action is taken. This is a lightweight check — one API call per plugin, no downloads needed for the check itself.

**Post-update:** If the version changes, the old version directory is cleaned up, `onEnable` is called for enabled plugins (so they can re-run setup), and you'll be prompted to restart the daemon (or notified to restart running sessions for client-only plugins).

**URL and local plugins:** Direct tarball URL and local path plugins can't be checked for updates — there's no version API to query. The command shows a notice and exits. To get a new version, reinstall with a new URL or path.

### Enabling and Disabling

Plugins can be enabled or disabled globally or per-project. Per-project settings take precedence over global settings.

Enable globally:

```bash
monofoundry plugin enable github:monoai-labs/mono-foundry-lsp-plugin
```

Disable globally:

```bash
monofoundry plugin disable github:monoai-labs/mono-foundry-lsp-plugin
```

When run inside a workspace directory (`--cwd <path>` or the current directory), enable/disable applies to that project's config instead of the global config. This lets you enable a plugin in one project without affecting others.

### Removing a Plugin

Remove a plugin entirely - deletes the installed files, lockfile entry, and disables it in config:

```bash
monofoundry plugin remove github:monoai-labs/mono-foundry-lsp-plugin
```

`uninstall` is an alias for `remove`:

```bash
monofoundry plugin uninstall github:monoai-labs/mono-foundry-lsp-plugin
```

### Viewing Plugin Details

Show detailed information about an installed plugin - manifest metadata, permissions, contributed tools, and lockfile entry:

```bash
monofoundry plugin info github:monoai-labs/mono-foundry-lsp-plugin
```

Output includes the plugin name, description, permissions, tool contributions, status, source, resolved URL, SHA-256 hash, and install timestamp.

### Plugin Configuration

Plugins can declare a configuration schema in their manifest (`contributes.configuration.schema`), allowing users to set per-plugin settings that the plugin reads at runtime. Configuration is managed through three `config` sub-commands.

#### Setting a config value

```bash
monofoundry plugin config <id> <key> <value>
```

Sets a single config key. The `<key>` supports **dot notation** for nested properties — intermediate objects are created automatically:

```bash
monofoundry plugin config github:monoai-labs/mono-foundry-lsp-plugin languages.typescript.enabled true
monofoundry plugin config github:monoai-labs/mono-foundry-lsp-plugin languages.typescript.level warn
monofoundry plugin config github:monoai-labs/mono-foundry-lsp-plugin timeout 30000
```

**Value parsing:** The `<value>` is first attempted as JSON (`JSON.parse`). If parsing succeeds, the parsed value is stored — so `true`, `42`, `null`, arrays, and objects all become their JSON equivalents. If parsing fails, the raw string is stored as-is.

```bash
# JSON values:
monofoundry plugin config my-plugin port 8080          # stored as number 8080
monofoundry plugin config my-plugin enabled true       # stored as boolean true
monofoundry plugin config my-plugin tags '["a","b"]'  # stored as array

# String fallback (not valid JSON):
monofoundry plugin config my-plugin name hello         # stored as string "hello"
```

**Schema validation:** If the plugin's manifest declares a `contributes.configuration.schema` pointing to a JSON Schema file, the full resulting config object is validated against it before writing. If validation fails, the errors are printed and the config is **not** written:

```
✗ Invalid value for languages.typescript.level
  $.languages.typescript.level: value not in enum ["off", "warn", "error"]
```

The validator supports the following JSON Schema keywords:

| Keyword            | Applies to | Description                                                                                        |
| ------------------ | ---------- | -------------------------------------------------------------------------------------------------- |
| `type`             | any        | `string`, `number`, `integer`, `boolean`, `null`, `object`, `array` (or an array of allowed types) |
| `enum`             | any        | Value must be one of the listed constants.                                                         |
| `const`            | any        | Value must equal the constant.                                                                     |
| `minimum`          | number     | Inclusive lower bound.                                                                             |
| `maximum`          | number     | Inclusive upper bound.                                                                             |
| `exclusiveMinimum` | number     | Exclusive lower bound.                                                                             |
| `exclusiveMaximum` | number     | Exclusive upper bound.                                                                             |
| `minLength`        | string     | Minimum string length.                                                                             |
| `maxLength`        | string     | Maximum string length.                                                                             |
| `pattern`          | string     | Regex the string must match.                                                                       |
| `items`            | array      | Schema that each array element must satisfy.                                                       |
| `properties`       | object     | Per-property schemas.                                                                              |
| `required`         | object     | Array of property names that must be present.                                                      |

If the plugin has no config schema declared, values are stored without validation.

#### Listing config values

```bash
monofoundry plugin config <id> list
```

Prints all currently set config keys and their values:

```
languages.typescript.enabled = true
languages.typescript.level = "warn"
timeout = 30000
```

If no config values are set, a "No config values set" message is shown.

#### Clearing config values

```bash
monofoundry plugin config <id> clear          # clear all config
monofoundry plugin config <id> clear <key>    # clear a single key (dot notation)
```

Clearing a single key uses the same dot notation as setting:

```bash
monofoundry plugin config my-plugin clear languages.typescript.enabled
```

If the key doesn't exist, a notice is printed (no error). After clearing, a restart notice is shown.

#### Storage

Plugin config is stored per-plugin at:

```
~/.monofoundry/plugins/storage/<sanitised-id>/config.json
```

The `<sanitised-id>` is the plugin ID with `/`, `\`, and `:` replaced by `__` (e.g. `github:owner/repo` becomes `github__owner__repo`). The file is a single JSON object representing the full config tree.

After any `set` or `clear` operation, the CLI prints a notice to restart running sessions for the change to take effect.

---

## Installation Sources

Plugins can be installed from three source types:

| Source                 | Syntax                                                                 | Description                                                                                                                                  |
| ---------------------- | ---------------------------------------------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------- |
| **GitHub release**     | `github:owner/repo` or `github:owner/repo@tag`                         | Downloads a tarball from the GitHub release. Defaults to the latest release.                                                                 |
| **GitHub URL**         | `https://github.com/owner/repo` or `https://github.com/owner/repo@tag` | Same as the `github:` form. Bare repo URLs are intercepted; deeper paths (e.g. `/releases/download/...`) are treated as direct tarball URLs. |
| **Direct tarball URL** | `https://example.com/path/plugin.tgz`                                  | Downloads and extracts a tarball from any HTTPS URL.                                                                                         |
| **Local path**         | `./my-plugin` or `/abs/path`                                           | Copies a local plugin directory. Requires `--dev` flag.                                                                                      |

### Dev installs

The `--dev` flag enables two additional behaviours:

- **Local path installs** - Install a plugin from a directory on your filesystem (useful during development).
- **GitHub branch archives** - Install from a branch instead of a release tag (e.g. `github:owner/repo@main --dev`).

Dev installs skip hash verification and release validation. A warning is printed:

```
⚠ Dev install - no hash verification, no release validation.
```

### GitHub API authentication

If you hit GitHub API rate limits when installing from private repos or making many requests, set the `GITHUB_TOKEN` environment variable. The installer uses it for GitHub API calls and tarball downloads.

### Tarball structure

The installer looks for the manifest (`monofoundry.plugin.json`) in three locations within the extracted tarball, tried in order:

1. Archive root
2. `package/` subdirectory
3. Single subdirectory (e.g. GitHub archive extracts to `{repo}-{ref}/`)

The tarball must contain a valid `monofoundry.plugin.json` at one of these locations.

---

## Plugin IDs

Plugin IDs are derived from the installation source and are stable across reinstalls:

| Source type | ID format            | Example                                      |
| ----------- | -------------------- | -------------------------------------------- |
| GitHub      | `github:owner/repo`  | `github:monoai-labs/mono-foundry-lsp-plugin` |
| Direct URL  | `url:hostname/path`  | `url:example.com/plugins/my-plugin.tgz`      |
| Local path  | `local:dir_basename` | `local:my-plugin`                            |

The plugin ID is the canonical key used in the lockfile, configuration, and tool registry. Use it with `enable`, `disable`, `remove`, and `info` commands.

---

## Storage and Configuration

Plugins are stored under `~/.monofoundry/plugins/`:

| Path                 | Description                                                                                          |
| -------------------- | ---------------------------------------------------------------------------------------------------- |
| `installed/`         | Installed plugin packages, organised by plugin ID and version.                                       |
| `plugin-lock.json`   | Lockfile - records each plugin's version, source, resolved URL, SHA-256 hash, and install timestamp. |
| `plugin-config.json` | Global plugin enable/disable state.                                                                  |
| `logs/`              | Per-plugin log files.                                                                                |
| `storage/`           | Per-plugin persistent storage (key-value store used by plugins at runtime).                          |
| `tools/`             | Plugin-managed tool binaries (e.g. downloaded language servers).                                     |

Per-project plugin config is stored at `~/.monofoundry/projects/<slug>/plugins.json`. Per-project settings take precedence over global settings when determining whether a plugin is enabled.

---

## Permissions

Each plugin declares a non-empty `permissions` array in its manifest. The runtime gates every capability behind the corresponding permission - if a plugin attempts to use a capability it hasn't declared, it throws an error.

| Permission                | Description                                         |
| ------------------------- | --------------------------------------------------- |
| `workspace:read`          | Read files in the workspace.                        |
| `workspace:read:external` | Read files outside the workspace.                   |
| `workspace:write`         | Write or modify files in the workspace.             |
| `process:spawn`           | Spawn child processes.                              |
| `network:localhost`       | Make network requests to localhost only.            |
| `network:external`        | Make network requests to external hosts.            |
| `config:read`             | Read plugin configuration.                          |
| `config:write`            | Write plugin configuration.                         |
| `storage:read`            | Read from plugin persistent storage.                |
| `storage:write`           | Write to plugin persistent storage.                 |
| `tool:provide:<name>`     | Provide a new tool with the given name.             |
| `tool:override:<name>`    | Override a built-in tool with the given name.       |
| `command:provide:<name>`  | Provide a slash command with the given name.        |
| `highlighter:provide`     | Provide syntax highlighting for declared languages. |
| `theme:provide`           | Provide theme(s) accessible via `/theme`.           |

The install command displays the full permissions list before enabling, so you can review what a plugin can do.

---

## After a Plugin Change

When you install, enable, disable, or remove a plugin, the CLI determines whether a restart is needed based on what the plugin contributes:

- **Daemon-targeted plugins** (tools, commands, LSP) - You'll be prompted to restart the daemon so the changes take effect.
- **Client-only plugins** (highlighters) - No daemon restart needed. You'll see a notice to restart any running sessions.

This distinction is automatic - the CLI inspects the plugin's `contributes` declarations to determine which process the plugin runs in.

---

## Contributed Slash Commands

Plugins can contribute slash commands to the interactive REPL. When a plugin declares `contributes.commands` in its manifest and registers commands via `ctx.commands.register()` during activation, those commands automatically appear in:

- **`/help` output** — listed with a `(plugin)` prefix in the description
- **Tab completion** — available alongside built-in commands when typing `/`
- **Dispatch** — handled locally when the user types the command

### Collision Handling

Built-in commands always take precedence. If a plugin contributes a command with the same name as a built-in (e.g. `/help`), the plugin command is skipped and a warning is displayed at startup.

### Error Isolation

If a plugin command handler throws an error, the error is caught and displayed to the user. It does not crash the REPL or interrupt the current session.

### Lifecycle

Plugin commands are registered at session startup when enabled plugins are loaded. Disabling or removing a plugin requires restarting the session (or daemon) for the contributed commands to disappear — there is no live unload.

---

## First-Party Plugins

monō ai maintains a set of first-party plugins under the [`monoai-labs`](https://github.com/monoai-labs) GitHub organisation. These plugins are developed alongside monō foundry and are marked with a `monoai` publisher ID.

### LSP Plugin

**Repository:** [monoai-labs/mono-foundry-lsp-plugin](https://github.com/monoai-labs/mono-foundry-lsp-plugin)

The LSP plugin adds headless Language Server Protocol support to monō foundry. It overrides the built-in code-intelligence tools with real LSP-backed implementations, so the agent gets accurate type information, go-to-definition, diagnostics, and refactoring from the actual language server running in your workspace.

#### What it does

Without this plugin, monō foundry's code-intelligence tools rely on text-based heuristics. With the LSP plugin installed, these tools are backed by a real language server:

| Tool               | LSP method                                                                |
| ------------------ | ------------------------------------------------------------------------- |
| `get_symbols`      | `textDocument/documentSymbol` and `workspace/symbol`                      |
| `hover_info`       | `textDocument/hover`                                                      |
| `code_navigation`  | Go-to-definition, references, implementations, type definitions           |
| `peek_definition`  | Definition source context with surrounding lines and hover info           |
| `get_code_actions` | `textDocument/codeAction` (list and apply quick fixes / refactorings)     |
| `rename_symbol`    | `textDocument/rename` (workspace-aware)                                   |
| `get_diagnostics`  | `textDocument/publishDiagnostics` (real compiler errors, warnings, hints) |

#### Supported languages

- **TypeScript / JavaScript** - via [`typescript-language-server`](https://github.com/typescript-language-server/typescript-language-server). The server binary is automatically downloaded and managed on first use. TypeScript is resolved from the workspace when available, falling back to a bundled version.

More languages will be added in future releases.

#### Prerequisites

- monō foundry >= 0.17.0
- Node.js >= 22

#### Install

```bash
monofoundry plugin install github:monoai-labs/mono-foundry-lsp-plugin
```

The plugin activates automatically when a `tsconfig.json` or `package.json` is detected in the workspace. No manual configuration is required for default usage.

#### Configuration

The plugin supports per-workspace configuration via monō foundry's plugin settings:

```json
{
  "languages": {
    "typescript": {
      "enabled": true,
      "rootMode": "auto"
    }
  }
}
```

| Property                        | Default  | Description                                                                                         |
| ------------------------------- | -------- | --------------------------------------------------------------------------------------------------- |
| `languages.typescript.enabled`  | `false`  | Explicitly enable TypeScript language support.                                                      |
| `languages.typescript.rootMode` | `"auto"` | How the language server root is determined. `"auto"` detects from `tsconfig.json` / `package.json`. |

#### Commands

```bash
monofoundry lsp status    # show runtime status (server, TypeScript resolution, client state)
monofoundry lsp doctor    # alias for status
```

#### How it works

On activation, the plugin spawns an LSP server. Depending on the language, any dependencies are installed on enablement into the plugin's storage directory and cached for subsequent sessions.

---

### Theme Plugin

**Repository:** [monoai-labs/mono-foundry-theme-plugin](https://github.com/monoai-labs/mono-foundry-theme-plugin)

The theme plugin provides additional pre-defined light and dark themes that can be accessed via `/theme`.

#### Install

```bash
monofoundry plugin install github:monoai-labs/mono-foundry-theme-plugin
```

---

### Highlight Plugin

**Repository:** [monoai-labs/mono-foundry-highlight-plugin](https://github.com/monoai-labs/mono-foundry-highlight-plugin)

The highlight plugin wraps [git-delta](https://github.com/dandavison/delta) as a universal syntax highlighter for the monō foundry terminal UI. It highlights both fenced code blocks and unified diffs rendered by the agent - covering every file type without needing per-language configuration.

#### What it does

- **Code blocks** - Syntax highlighting for all languages, using delta's syntax highlighting with no diff tinting. The renderer adds the indentation gutter; the plugin handles colour.
- **Diffs** - Full unified-diff highlighting with delta's default tint and syntax colouring, including file metadata headers, hunk headers, and added/removed/context lines.

The plugin registers a catch-all (`*`) highlighter that applies to every language. If another highlighter plugin is registered for a specific language (e.g. a dedicated TypeScript highlighter), that plugin takes precedence. If both a theme and a highlighter plugin are installed, the highlighter plugin takes precedence.

#### Install

```bash
monofoundry plugin install github:monoai-labs/mono-foundry-highlight-plugin
```

After enabling, the plugin downloads the `delta` binary on first use - it fetches the platform-appropriate release, verifies the SHA-256 hash, and extracts it into the plugin's storage directory. The binary is cached for subsequent sessions.

#### Configuration

The plugin ships with sensible defaults (Monokai Extended theme, dark mode, word-diff enabled, line numbers off). Configuration is managed through the plugin's config schema.

---

© monō ai Australia Pty Ltd. All rights reserved.
