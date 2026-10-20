#!/usr/bin/env bash
# Install mdview + the Vim plugin for the current user (no sudo needed).
set -euo pipefail
here=$(cd "$(dirname "$0")" && pwd)
share=$HOME/.local/share/mdview

mkdir -p "$HOME/.local/bin" "$share" "$HOME/.vim/plugin"
install -m755 "$here/mdview" "$HOME/.local/bin/mdview"
install -m644 "$here"/share/* "$share/"
install -m644 "$here/vim/mdpreview.vim" "$HOME/.vim/plugin/mdpreview.vim"
echo "installed: ~/.local/bin/mdview, $share, ~/.vim/plugin/mdpreview.vim"

# PlantUML (optional, needs java)
if [[ ! -f $share/plantuml.jar ]] && command -v java >/dev/null; then
  v=$(curl -fsSL https://api.github.com/repos/plantuml/plantuml/releases/latest | grep -m1 '"tag_name"' | cut -d'"' -f4)
  echo "downloading PlantUML $v"
  curl -fsSL -o "$share/plantuml.jar" "https://github.com/plantuml/plantuml/releases/download/$v/plantuml-${v#v}.jar"
fi

missing=()
for c in pandoc magick img2sixel python3 tmux; do
  command -v "$c" >/dev/null || missing+=("$c")
done
command -v java >/dev/null || echo "note: java not found, PlantUML blocks will show as code"
if ((${#missing[@]})); then
  echo "missing: ${missing[*]}"
  echo "  e.g. sudo apt install pandoc imagemagick libsixel-bin python3 tmux"
fi
if ! ls "$HOME"/.cache/ms-playwright/chromium_headless_shell-* >/dev/null 2>&1 &&
   ! command -v chromium >/dev/null && ! command -v google-chrome >/dev/null; then
  echo "no headless chrome found: npx playwright install chromium-headless-shell"
fi
case ":$PATH:" in *":$HOME/.local/bin:"*) ;; *) echo "add ~/.local/bin to your PATH" ;; esac
