#!/bin/zsh
# Copiază fișierele de Mac în ~/Remindere/, fără să suprascrie un remindere.json existent.

set -euo pipefail

SRC="$(cd "$(dirname "$0")" && pwd)"
DEST="$HOME/Remindere"
ROOT="$(cd "$SRC/.." && pwd)"

mkdir -p "$DEST"
cp -f "$SRC/reminder.js" "$DEST/"
cp -f "$SRC/sablon.plist" "$DEST/"
cp -f "$SRC/adauga-reminder.sh" "$DEST/"
cp -f "$SRC/sterge-reminder.sh" "$DEST/"
chmod +x "$DEST/adauga-reminder.sh" "$DEST/sterge-reminder.sh"

if [[ -f "$DEST/remindere.json" ]]; then
  echo "Păstrez remindere.json existent din $DEST."
else
  cp -f "$SRC/remindere.json" "$DEST/"
fi

for doc in README.md GHID-RAPID.md INSTRUCTIUNI-PENTRU-CLAUDE.md; do
  if [[ -f "$ROOT/$doc" ]]; then
    cp -f "$ROOT/$doc" "$DEST/"
  fi
done

echo "Gata. Fișierele sunt în $DEST"
echo "Ca să adaugi un reminder, scrie titlul și textul în $DEST/remindere.json,"
echo "apoi rulează, de exemplu:"
echo "  zsh $DEST/adauga-reminder.sh pauza-ceai --saptamanal luni 11 00"
echo "Ca să vezi fereastra acum:"
echo "  /usr/bin/osascript -l JavaScript $DEST/reminder.js pauza-ceai"
