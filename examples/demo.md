# mdview demo

A **real** rendered preview, right inside the terminal: *pandoc* + headless Chromium,
drawn with `sixel` graphics in a tmux pane next to Vim.

> Save the file and the preview re-renders. Scroll the preview and Vim follows.

## Features

- [x] GitHub-style dark theme
- [x] Syntax highlighting
- [x] Tables, task lists, quotes
- [x] PlantUML diagrams
- [x] Mouse wheel + arrow keys
- [ ] Your idea here

## Code

```python
from dataclasses import dataclass


@dataclass
class Preview:
    path: str
    width: int = 80

    def render(self) -> bytes:
        """Markdown -> HTML -> PNG -> sixel."""
        html = pandoc(self.path)
        return sixel(screenshot(html, self.width))
```

```bash
# open the preview from vim
:MdPreview        # or ,mp
```

## Table

| Key            | Action                 |
|----------------|------------------------|
| `j` / `k` / ↑↓ | scroll                 |
| wheel          | scroll                 |
| `h` / `l` / ←→ | pan wide pages         |
| `space` / `b`  | page down / up         |
| `g` / `G`      | top / bottom           |
| `r`            | re-render              |
| `q`            | quit                   |

## How it works

```plantuml
participant Vim
participant mdview
participant pandoc
participant Chromium
participant "Windows Terminal" as WT

Vim -> mdview : :w (file changed)
mdview -> pandoc : markdown
pandoc --> mdview : html
mdview -> Chromium : screenshot chunks
Chromium --> mdview : png
mdview -> WT : sixel (tmux passthrough)
mdview --> Vim : top line (scroll sync)
```

## Long documents

Pages are screenshotted lazily in chunks, and each chunk is encoded to sixel once.
Scrolling only slices the visible 6px sixel bands, so it stays smooth even for
files with thousands of lines.

### Section A

Lorem ipsum dolor sit amet, consectetur adipiscing elit. Integer posuere erat a
ante venenatis dapibus posuere velit aliquet.

### Section B

Maecenas sed diam eget risus varius blandit sit amet non magna. Cras mattis
consectetur purus sit amet fermentum.

### Section C

Donec ullamcorper nulla non metus auctor fringilla. Vestibulum id ligula porta
felis euismod semper.

---

*Made with Vim, tmux and too many escape sequences.*
