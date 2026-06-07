# Image Placeholders Extension

Shows `[Img 1 - 2K]`, `[Img 2 - 3M]`, etc. in the Pi editor when pasting images from clipboard, styled with a themed background color. The actual file path is sent to the LLM on submit.

## How it works

1. **Paste** — installs a custom Pi editor component and stores each image as a private single-character marker followed by one space
2. **Display** — renders that marker as `[Img N - SIZE]` with Tokyo Night `bgVisual`, falling back to `selectedBg`
3. **Backspace** — one backspace after the auto-space removes the marker and space together, so the whole visible placeholder disappears atomically
4. **Submit** — expands markers back to real image file paths for the LLM

## Detection

An inserted text is treated as an image path if:
- File extension matches: `.png`, `.jpg`, `.jpeg`, `.gif`, `.webp`, `.bmp`, `.avif`, `.tiff`, `.tif`
- Path contains `pi-clipboard`, `/tmp/`, or `\tmp\`

## Caveats

1. **Custom editor** — replaces Pi's editor component while preserving default Pi editor handlers and shortcuts.

2. **Process-scoped counter** — numbering persists while the current Pi process is running.

3. **Only image paths** — `@file` syntax is not intercepted.

4. **Theme-dependent styling** — uses the active theme's `vars.bgVisual` value (for example, Tokyo Night's `#2d3f76`). Falls back to `selectedBg` if `bgVisual` is unavailable.
