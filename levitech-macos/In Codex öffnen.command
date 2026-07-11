#!/bin/bash
#
# LEVITECH – öffnet dieses Projekt in Codex (OpenAI Codex CLI).
# Doppelklick auf diese Datei im Finder.
#
cd "$(dirname "$0")" || exit 1

echo "──────────────────────────────────────────────"
echo "  LEVITECH Workspace App  ·  Codex-Start"
echo "  Ordner: $(pwd)"
echo "──────────────────────────────────────────────"

if command -v codex >/dev/null 2>&1; then
  # Codex CLI ist installiert -> im Projektordner starten
  exec codex
else
  echo ""
  echo "  ⚠  'codex' wurde nicht gefunden."
  echo ""
  echo "  Codex CLI installieren mit:"
  echo "      npm install -g @openai/codex"
  echo "  danach diese Datei erneut per Doppelklick starten."
  echo ""
  echo "  (Fenster kann geschlossen werden.)"
  exec "$SHELL"
fi
