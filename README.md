# gru

A fast CLI tool for rendering Markdown to ANSI-colored terminal output, powered by the [`gruff`](https://github.com/gausszhou/gruff) library.

## Install

**One-liner (Linux/macOS):**
```bash
curl -fsSL https://github.com/gausszhou/gru/releases/latest/download/install.sh | bash
```

**One-liner (Windows, PowerShell):**
```powershell
irm https://github.com/gausszhou/gru/releases/latest/download/install.ps1 | iex
```

**Go:**
```bash
go install github.com/gausszhou/gru@latest
```

Or download a prebuilt binary from the [releases page](https://github.com/gausszhou/gru/releases).

## Usage

```bash
gru README.md               # render a file
gru render README.md        # explicit subcommand
gru render -w 40 README.md  # custom wrap width
gru render -l README.md     # light theme
gru update                  # self-update to latest version
gru --version               # show version
gru --help                  # full help
```

## Commands

| Command | Description |
|---------|-------------|
| `render <file>` | Render a Markdown file to ANSI terminal output |
| `update` | Self-update `gru` to the latest GitHub release |

### Flags

| Flag | Description |
|------|-------------|
| `-w`, `--width` | Word wrap width (0 = auto-detect terminal width, default 80) |
| `-l`, `--light` | Use light background theme |

## How It Works

`gru` is a thin CLI wrapper around the [`gruff`](https://github.com/gausszhou/gruff) library. Parsing is handled by [`goldmark`](https://github.com/yuin/goldmark), and rendering emits SGR ANSI escape codes directly — no HTML, no CSS.

The `update` command fetches the latest release from GitHub, compares versions, downloads the matching platform binary, and replaces itself atomically.

## Features

- **Headings** (H1–H6) with distinct styles per level
- **Bold**, *italic*, and ***bold italic***
- `Inline code` and fenced/indented **code blocks**
- [Links](https://github.com/gausszhou/gruff) — underlined + blue with gray URL suffix
- Unordered (`-`, `*`) and ordered (`1.`) lists
- GFM tables with **UTF-8 box‑drawing borders** and automatic column width capping
- Strikethrough (`~~text~~`)
- Task lists (`- [x] done`, `- [ ] todo`)
- Dark and light themes
- ANSI-aware word wrap

## Performance

`gru` inherits the performance of the `gruff` library. Benchmark results (Ryzen 7 7435H, ~2.4 KB × 100 = ~240 KB input):

| Metric | gruff | glamour minimal | glamour standard |
|--------|-------|-----------------|------------------|
| Time/op | **~46 ms** | ~468 ms | ~2.45 s |
| Memory/op | **~39 MB** | ~86 MB | ~389 MB |

## License

MIT
