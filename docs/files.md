# monofoundry - Files & Attachments

Attach files to your messages so the agent can see images, PDFs, and other binary content. Text files are left for the agent to read directly with its file tools.

---

## Table of Contents

- [Overview](#overview)
- [Inline @-Path Attachments](#inline--path-attachments)
- [/attach Command](#attach-command)
- [/paste Command](#paste-command)
- [Binary vs Text Classification](#binary-vs-text-classification)
  - [Known Binary Extensions](#known-binary-extensions)
  - [Content Sniffing](#content-sniffing)
- [Upload Limits](#upload-limits)
- [Clipboard Image Support](#clipboard-image-support)
- [Tab Completion](#tab-completion)

---

## Overview

There are three ways to attach files to a message:

1. **Inline `@`-paths** — type `@path/to/file` directly in your message. Binary files are uploaded automatically when you submit; text files are left as-is for the agent to read.
2. **`/attach <path>`** — upload a file explicitly and stage it for your next message.
3. **`/paste`** — capture an image from your clipboard and insert it as an `@`-path token.

In all cases, binary files are uploaded to the server and their file IDs are sent to the agent. Text files are never uploaded — the agent reads them directly using its file tools (`read_file`, `batch_read_files`, etc.). The message text itself is never modified; only file IDs are attached.

---

## Inline @-Path Attachments

Reference files directly in any message by prefixing the path with `@`. When you submit the message, binary files are automatically uploaded and their IDs sent to the agent. Text files are left as-is.

### Syntax

- `@path/to/file` — relative to the current working directory.
- `@~/path/to/file` — expanded from your home directory.
- `@/absolute/path/to/file` — absolute path.
- `@"path with spaces"` — quoted path (double quotes are stripped before resolving).

### Rules

- An `@` must be at the start of the message or preceded by whitespace (so email addresses like `user@host` are not matched).
- Multiple `@` references can appear in the same message.
- Duplicate paths in the same message are de-duplicated.
- The message text is never modified — only file IDs are returned and sent alongside the message.

### Examples

```
> Can you review @src/auth.ts and the design in @docs/auth-flow.png?
# auth.ts is text — the agent reads it with its file tools
# auth-flow.png is binary — uploaded and sent as an attachment

> Summarise the contents of @~/Downloads/report.pdf

> Check the config in @"src/my project/config.yaml"
```

---

## /attach Command

Uploads a file and stages it to be sent with your next message. The file is uploaded immediately and a confirmation line is shown above the prompt.

```
> /attach ./diagram.png
✓ diagram.png (42 KB)  image/png

> /attach ~/Downloads/spec.pdf
✓ spec.pdf (1.2 MB)  application/pdf
```

Multiple `/attach` calls before submitting a message will all be included together. Paths are relative to the current working directory; `~/` is expanded to your home directory.

---

## /paste Command

Captures an image from the OS clipboard (e.g. a screenshot taken with Cmd-Shift-4 on macOS), writes it to a temporary file, and inserts an `@<tmp-path>` token into the input buffer. The image is uploaded when you submit the message.

```
> /paste
# if an image is in the clipboard:
Captured clipboard image → /tmp/monofoundry-clip-xxxx.png
# the @-path is inserted into the input buffer for you

# if the clipboard has no image:
No image found in the clipboard.
```

See [Clipboard Image Support](#clipboard-image-support) for platform-specific details.

---

## Binary vs Text Classification

Every referenced file is classified as **binary** (upload), **text** (leave for the agent), or **skip** (missing, directory, or unreadable). Classification uses a two-stage approach:

### Known Binary Extensions

A fast-path checks the file extension against a list of known binary types. If the extension matches, the file is classified as binary without reading any content.

| Category | Extensions |
|----------|-----------|
| Images | `.png`, `.jpg`, `.jpeg`, `.gif`, `.webp`, `.bmp`, `.ico`, `.tiff`, `.heic` |
| Documents | `.pdf`, `.doc`, `.docx`, `.xls`, `.xlsx`, `.ppt`, `.pptx` |
| Archives | `.zip`, `.gz`, `.tar`, `.7z`, `.rar` |
| Media | `.mp3`, `.wav`, `.ogg`, `.mp4`, `.mov`, `.avi` |
| Fonts | `.woff`, `.woff2`, `.ttf`, `.otf` |
| Binaries | `.bin`, `.exe`, `.dll`, `.so`, `.dylib`, `.wasm` |

### Content Sniffing

If the extension doesn't match the fast-path list, the first 8 KB of the file is read and inspected:

- A **NUL byte** (`\x00`) anywhere in the sample is a definitive binary marker.
- Otherwise, the ratio of non-text control bytes is calculated. If more than 30% of the sample bytes are non-text (excluding tab, newline, carriage return, form feed, printable ASCII, and high-bit characters), the file is classified as binary.
- Empty files are treated as text (and skipped during upload).

This catches files with no extension or unexpected extensions (e.g. a binary file with a `.txt` name).

---

## Upload Limits

| Limit | Value |
|-------|-------|
| Maximum file size | **20 MB** (20,971,520 bytes) |
| Empty files | Rejected (cannot upload a 0-byte file) |

Files exceeding the 20 MB limit will fail with an error message. The MIME type is resolved from the file extension; unrecognised extensions fall back to `application/octet-stream`.

---

## Clipboard Image Support

The `/paste` command reads an image from the OS clipboard as a PNG. Support varies by platform:

| Platform | Method | Fallback |
|----------|--------|----------|
| **macOS** | `pngpaste` command | AppleScript (`osascript`) — writes the clipboard's PNG data to a temp file |
| **Linux** | `xclip` | `wl-paste` (Wayland) |
| **Windows** | Not supported | — |

If no image is found in the clipboard, or no supported tool is available, `/paste` prints `No image found in the clipboard.` and does not error.

To install `pngpaste` on macOS:

```bash
brew install pngpaste
```

To install `xclip` on Linux:

```bash
# Debian/Ubuntu
sudo apt install xclip

# Fedora
sudo dnf install xclip
```

---

## Tab Completion

When typing `@` in the input buffer, file completions from the working directory appear as ghost text. This works for all attachment methods:

- Type `@` followed by a partial path to see matching files.
- Completions are case-insensitive.
- Hidden files (dotfiles) are skipped unless you explicitly type a leading `.`.
- Directories complete with a trailing `/` so you can keep descending.
- Press `Tab` to accept the longest common prefix. If multiple files match, `Tab` and `Shift-Tab` cycle forward and backward through them.
- `~/` paths are expanded to your home directory.

```
> Summarise @src/re<Tab>   →  @src/repl.ts   (if only one match)
> Summarise @src/re<Tab>   →  @src/render/   (if a directory matches)
> Diff @src/<Tab><Tab>     →  cycles through all files under src/
> Check @~/.<Tab>          →  shows dotfiles in home directory
```

See also: [Commands & Shortcuts](commands.md) for the full `@`-path completion reference.

---

© monō ai Australia Pty Ltd. All rights reserved.