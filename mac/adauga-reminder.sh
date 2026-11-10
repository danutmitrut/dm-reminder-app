#!/bin/zsh
# Adaugă (sau actualizează) programarea unui reminder deja prezent în remindere.json.
# Folosire:
#   zsh adauga-reminder.sh <id> --saptamanal <zi> <ora> [minut]
#   zsh adauga-reminder.sh <id> --zilnic <ora> [minut]
#   zsh adauga-reminder.sh <id> --o-data <YYYY-MM-DD> <ora> [minut]
# Ziua poate fi: luni, marți, miercuri, joi, vineri, sâmbătă, duminică
# (și fără diacritice). Ora poate fi 18 30 sau 18:30.
# launchd pe Mac: 0 = duminică, 1 = luni, ... 6 = sâmbătă.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
DEST="$HOME/Remindere"
LABEL_PREFIX="com.cursant.reminder"
AGENTS="$HOME/Library/LaunchAgents"

utilizare() {
  cat <<'TXT'
Folosire:
  zsh adauga-reminder.sh <id> --saptamanal <zi> <ora> [minut]
  zsh adauga-reminder.sh <id> --zilnic <ora> [minut]
  zsh adauga-reminder.sh <id> --o-data <YYYY-MM-DD> <ora> [minut]

Exemple:
  zsh adauga-reminder.sh pauza-ceai --saptamanal luni 11 00
  zsh adauga-reminder.sh pauza-ceai --zilnic 11:00
  zsh adauga-reminder.sh pauza-ceai --o-data 2026-11-15 11 00

Reminderul (titlu și text) trebuie să existe deja în ~/Remindere/remindere.json.
Rulează mai întâi: zsh instaleaza.sh
TXT
}

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
  utilizare
  exit 0
fi
if [[ $# -lt 2 ]]; then
  utilizare
  exit 1
fi

if [[ "$SCRIPT_DIR" != "$DEST" ]]; then
  echo "Fișierele trebuie să fie în $DEST."
  echo "Rulează mai întâi, din pachet: zsh mac/instaleaza.sh"
  exit 1
fi

ID="$1"
shift

if [[ ! "$ID" =~ ^[a-zA-Z0-9_-]+$ ]]; then
  echo "Id invalid: $ID. Folosește doar litere, cifre, cratimă și underscore."
  exit 1
fi

JSON="$DEST/remindere.json"
SCRIPT="$DEST/reminder.js"
if [[ ! -f "$JSON" || ! -f "$SCRIPT" ]]; then
  echo "Lipsesc $JSON sau $SCRIPT. Rulează mai întâi instaleaza.sh."
  exit 1
fi

xml_escape() {
  local s=$1
  s=${s//&/&amp;}
  s=${s//</&lt;}
  s=${s//>/&gt;}
  s=${s//\"/&quot;}
  print -r -- "$s"
}

# Evităm Python: trecem calea prin JXA, cu ghilimele escape-uite.
js_escape() {
  local s=$1
  s=${s//\\/\\\\}
  s=${s//\"/\\\"}
  print -r -- "$s"
}

JSON_JS=$(js_escape "$JSON")
ID_JS=$(js_escape "$ID")

if ! /usr/bin/osascript -l JavaScript <<JXA
ObjC.import("Foundation");
var path = "$JSON_JS";
var id = "$ID_JS";
var s = ObjC.unwrap($.NSString.stringWithContentsOfFileEncodingError(path, $.NSUTF8StringEncoding, null));
if (!s) { throw new Error("Nu pot citi remindere.json"); }
var d = JSON.parse(s);
var r = d[id];
if (!r) { throw new Error("ID_LIPSA"); }
if (!r.titlu || !r.text) { throw new Error("CAMPURI_LIPSA"); }
JXA
then
  echo "Nu am găsit reminderul \"$ID\" în $JSON, sau îi lipsesc câmpurile titlu și text."
  echo "Adaugă mai întâi intrarea în remindere.json, apoi rulează din nou acest script."
  exit 1
fi

MOD=""
ZI_NUM=""
ZI_NUME=""
AN=""
LUNA=""
ZI_LUNA=""
ORA=""
MINUT=""
CAND=""
O_DATA="false"

norm_zi() {
  local z=${1:l}
  z=${z//ă/a}
  z=${z//â/a}
  z=${z//î/i}
  z=${z//ș/s}
  z=${z//ş/s}
  z=${z//ț/t}
  z=${z//ţ/t}
  case "$z" in
    duminica|sunday|0|7) print 0; print -r -- "duminică" ;;
    luni|monday|1)       print 1; print -r -- "luni" ;;
    marti|tuesday|2)     print 2; print -r -- "marți" ;;
    miercuri|wednesday|3) print 3; print -r -- "miercuri" ;;
    joi|thursday|4)      print 4; print -r -- "joi" ;;
    vineri|friday|5)     print 5; print -r -- "vineri" ;;
    sambata|saturday|6)  print 6; print -r -- "sâmbătă" ;;
    *) return 1 ;;
  esac
}

parse_ora() {
  local a="${1:-}" b="${2:-}"
  if [[ "$a" == *:* ]]; then
    ORA="${a%%:*}"
    MINUT="${a##*:}"
  else
    ORA="$a"
    MINUT="${b:-0}"
  fi
  ORA=${ORA##0}
  MINUT=${MINUT##0}
  [[ -z "$ORA" ]] && ORA=0
  [[ -z "$MINUT" ]] && MINUT=0
  if ! [[ "$ORA" =~ ^[0-9]+$ && "$MINUT" =~ ^[0-9]+$ ]]; then
    echo "Ora sau minutul nu sunt numere: $a $b"
    exit 1
  fi
  if (( ORA < 0 || ORA > 23 || MINUT < 0 || MINUT > 59 )); then
    echo "Ora trebuie să fie între 0 și 23, minutul între 0 și 59."
    exit 1
  fi
}

fmt2() {
  printf '%02d' "$1"
}

case "${1:-}" in
  --saptamanal)
    MOD="saptamanal"
    shift
    if [[ $# -lt 2 ]]; then utilizare; exit 1; fi
    if ! zi_out=$(norm_zi "$1"); then
      echo "Zi necunoscută: $1"
      exit 1
    fi
    ZI_NUM=$(print -r -- "$zi_out" | sed -n '1p')
    ZI_NUME=$(print -r -- "$zi_out" | sed -n '2p')
    shift
    parse_ora "${1:-}" "${2:-}"
    CAND="$ZI_NUME $(fmt2 $ORA):$(fmt2 $MINUT), săptămânal"
    ;;
  --zilnic)
    MOD="zilnic"
    shift
    if [[ $# -lt 1 ]]; then utilizare; exit 1; fi
    parse_ora "${1:-}" "${2:-}"
    CAND="$(fmt2 $ORA):$(fmt2 $MINUT), zilnic"
    ;;
  --o-data)
    MOD="o-data"
    O_DATA="true"
    shift
    if [[ $# -lt 2 ]]; then utilizare; exit 1; fi
    DATA="$1"
    shift
    if [[ ! "$DATA" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}$ ]]; then
      echo "Data trebuie să fie de forma YYYY-MM-DD, de exemplu 2026-11-15."
      exit 1
    fi
    AN="${DATA%%-*}"
    rest="${DATA#*-}"
    LUNA="${rest%%-*}"
    ZI_LUNA="${rest#*-}"
    LUNA=$((10#$LUNA))
    ZI_LUNA=$((10#$ZI_LUNA))
    if (( LUNA < 1 || LUNA > 12 || ZI_LUNA < 1 || ZI_LUNA > 31 )); then
      echo "Luna sau ziua sunt în afara intervalului."
      exit 1
    fi
    parse_ora "${1:-}" "${2:-}"
    CAND="$DATA $(fmt2 $ORA):$(fmt2 $MINUT), o dată"
    ;;
  *)
    echo "Lipsește modul: --saptamanal, --zilnic sau --o-data."
    utilizare
    exit 1
    ;;
esac

# Actualizează câmpul cand (și o_data) în JSON, fără Python.
CAND_JS=$(js_escape "$CAND")
/usr/bin/osascript -l JavaScript <<JXA
ObjC.import("Foundation");
var path = "$JSON_JS";
var id = "$ID_JS";
var cand = "$CAND_JS";
var oData = $O_DATA;
var s = ObjC.unwrap($.NSString.stringWithContentsOfFileEncodingError(path, $.NSUTF8StringEncoding, null));
var d = JSON.parse(s);
d[id].cand = cand;
if (oData) { d[id].o_data = true; } else { delete d[id].o_data; delete d[id].tip; }
var out = JSON.stringify(d, null, 2) + "\n";
var ok = $.NSString.alloc.initWithString(out).writeToFileAtomicallyEncodingError(path, true, $.NSUTF8StringEncoding, null);
if (!ok) { throw new Error("Nu am putut scrie remindere.json"); }
JXA

# Construiește intervalul din șablon.
if [[ "$MOD" == "saptamanal" ]]; then
  INTERVAL=$(cat <<XML
<dict>
    <key>Weekday</key>
    <integer>${ZI_NUM}</integer>
    <key>Hour</key>
    <integer>${ORA}</integer>
    <key>Minute</key>
    <integer>${MINUT}</integer>
  </dict>
XML
)
elif [[ "$MOD" == "zilnic" ]]; then
  INTERVAL=$(cat <<XML
<dict>
    <key>Hour</key>
    <integer>${ORA}</integer>
    <key>Minute</key>
    <integer>${MINUT}</integer>
  </dict>
XML
)
else
  INTERVAL=$(cat <<XML
<dict>
    <key>Month</key>
    <integer>${LUNA}</integer>
    <key>Day</key>
    <integer>${ZI_LUNA}</integer>
    <key>Hour</key>
    <integer>${ORA}</integer>
    <key>Minute</key>
    <integer>${MINUT}</integer>
  </dict>
XML
)
fi

LABEL="${LABEL_PREFIX}.${ID}"
PLIST="$AGENTS/${LABEL}.plist"
mkdir -p "$AGENTS"

LABEL_X=$(xml_escape "$LABEL")
CALE_X=$(xml_escape "$SCRIPT")
ID_X=$(xml_escape "$ID")
ERR_X=$(xml_escape "$DEST/err.log")
OUT_X=$(xml_escape "$DEST/out.log")

# Înlocuiri în șablon. Folosim un delimitator rar, ca să nu stricăm căile.
sablon=$(cat "$SCRIPT_DIR/sablon.plist")
sablon=${sablon//__LABEL__/$LABEL_X}
sablon=${sablon//__CALE_SCRIPT__/$CALE_X}
sablon=${sablon//__ID__/$ID_X}
sablon=${sablon//__CALE_ERR__/$ERR_X}
sablon=${sablon//__CALE_OUT__/$OUT_X}
# INTERVAL poate conține newline: îl înlocuim prin python-free cu awk.
tmp="${TMPDIR:-/tmp}/sablon-reminder-$$.plist"
print -r -- "$sablon" > "$tmp"
# awk pentru blocul multi-linie
awk -v interval="$INTERVAL" '{
  if ($0 ~ /__INTERVAL__/) { print interval; next }
  print
}' "$tmp" > "$PLIST"
rm -f "$tmp"

UID_NUM="$(id -u)"
# Dacă e deja armat, îl descărcăm întâi, apoi îl încărcăm din nou.
launchctl bootout "gui/${UID_NUM}/${LABEL}" >/dev/null 2>&1 || true
if ! launchctl bootstrap "gui/${UID_NUM}" "$PLIST"; then
  echo "Nu am putut arma reminderul. Verifică $PLIST și mesajul de mai sus."
  exit 1
fi
launchctl enable "gui/${UID_NUM}/${LABEL}" >/dev/null 2>&1 || true

echo "Reminderul \"$ID\" este armat: $CAND"
echo "Etichetă: $LABEL"
echo "Programare: $PLIST"
echo "Pentru a-l vedea acum, fără să aștepți ora:"
echo "  /usr/bin/osascript -l JavaScript \"$SCRIPT\" $ID"
