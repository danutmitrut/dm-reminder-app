#!/bin/zsh
# Șterge programarea unui reminder (îl dezarmează).
# Folosire:
#   zsh sterge-reminder.sh <id>
#   zsh sterge-reminder.sh <id> --si-din-lista
# A doua variantă scoate și intrarea din remindere.json.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
DEST="$HOME/Remindere"
LABEL_PREFIX="com.cursant.reminder"
AGENTS="$HOME/Library/LaunchAgents"

utilizare() {
  cat <<'TXT'
Folosire:
  zsh sterge-reminder.sh <id>
  zsh sterge-reminder.sh <id> --si-din-lista

Prima formă oprește programarea, dar lasă textul în remindere.json.
A doua scoate și intrarea din listă.
TXT
}

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
  utilizare
  exit 0
fi
if [[ $# -lt 1 ]]; then
  utilizare
  exit 1
fi

if [[ "$SCRIPT_DIR" != "$DEST" ]]; then
  echo "Fișierele trebuie să fie în $DEST."
  echo "Rulează mai întâi, din pachet: zsh mac/instaleaza.sh"
  exit 1
fi

ID="$1"
SI_DIN_LISTA=0
if [[ "${2:-}" == "--si-din-lista" ]]; then
  SI_DIN_LISTA=1
fi

if [[ ! "$ID" =~ ^[a-zA-Z0-9_-]+$ ]]; then
  echo "Id invalid: $ID."
  exit 1
fi

LABEL="${LABEL_PREFIX}.${ID}"
PLIST="$AGENTS/${LABEL}.plist"
UID_NUM="$(id -u)"

launchctl bootout "gui/${UID_NUM}/${LABEL}" >/dev/null 2>&1 || true
if [[ -f "$PLIST" ]]; then
  rm -f "$PLIST"
  echo "Am scos programarea: $LABEL"
else
  echo "Nu am găsit fișierul de programare $PLIST (poate era deja șters)."
fi

if (( SI_DIN_LISTA )); then
  JSON="$DEST/remindere.json"
  if [[ ! -f "$JSON" ]]; then
    echo "Nu am găsit $JSON, deci n-am ce scoate din listă."
    exit 0
  fi
  js_escape() {
    local s=$1
    s=${s//\\/\\\\}
    s=${s//\"/\\\"}
    print -r -- "$s"
  }
  JSON_JS=$(js_escape "$JSON")
  ID_JS=$(js_escape "$ID")
  /usr/bin/osascript -l JavaScript <<JXA
ObjC.import("Foundation");
var path = "$JSON_JS";
var id = "$ID_JS";
var s = ObjC.unwrap($.NSString.stringWithContentsOfFileEncodingError(path, $.NSUTF8StringEncoding, null));
if (!s) { throw new Error("Nu pot citi remindere.json"); }
var d = JSON.parse(s);
if (d[id] === undefined) { throw new Error("ID_LIPSA"); }
delete d[id];
var out = JSON.stringify(d, null, 2) + "\n";
var ok = $.NSString.alloc.initWithString(out).writeToFileAtomicallyEncodingError(path, true, $.NSUTF8StringEncoding, null);
if (!ok) { throw new Error("Nu am putut scrie remindere.json"); }
JXA
  echo "Am scos \"$ID\" și din remindere.json."
fi

echo "Gata. Dacă vrei să te asiguri că nu mai e armat:"
echo "  launchctl print gui/$(id -u)/$LABEL"
echo "(comanda trebuie să spună că nu găsește serviciul.)"
