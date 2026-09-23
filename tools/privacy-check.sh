#!/bin/bash
# privacy-check.sh — il hub è PUBBLICO: nessun nome di repo privata nei file versionati
# NÉ nella storia git — un nome committato e poi rimosso dal file resta comunque
# leggibile per sempre via git log/show (GitHub non lo dimentica). La chiave
# (night-shift/repos.key) è locale e gitignored: questo check la usa come lista nera.
# Pattern: citazione-non-presidio.
#
# v3 (nuovo ciclo 10 giri, 2026-08-22): prima scansionava solo `git ls-files` (i file
# tracciati OGGI) — un nome committato e poi tolto dal file corrente restava esposto
# per sempre nella storia, e il check diceva comunque "pulito". Aggiunta la scansione
# della storia: contenuto di ogni commit passato (pickaxe -S) e messaggi di commit
# (--grep), su TUTTI i branch (--all), non solo quello corrente.
set -uo pipefail
HERE="$(cd "$(dirname "$0")/.." && pwd)"
KEY="$HERE/night-shift/repos.key"
# v4 (2026-08-24, report dal campo su REPO-G): senza chiave il gate è CIECO — e usciva 0,
# cioè "promosso", proprio nelle sessioni cloud dove la chiave non esiste per disegno.
# Un gate che non può giudicare non dice pulito: dice degradato, e fallisce.
# (revisione 10 giri, 2026-09-23): il degradato usciva QUI, prima delle SHAPES — che il
# commento A20 sotto e la decisione di dominio del 2026-09-23 (DEBITI «Privacy fuori casa»:
# «le SHAPES girano nel repo») davano per sempre attive. Senza chiave nessuna forma di
# segreto veniva cercata. Ora: degradato dichiarato e rc=1 come prima, ma le shapes e la
# lista locale girano comunque; saltano solo i passaggi che la chiave alimenta.
RC=0
if [ -f "$KEY" ]; then
  HA_KEY=1
else
  HA_KEY=0
  echo "⛔ privacy-check: GATE DEGRADATO — repos.key assente: nomi/persone/termini della chiave NON controllati (né file, né storia git). Non è un verdetto di pulizia. Le forme di segreto e ~/.privacy-nomi si controllano comunque, qui sotto." >&2
  RC=1
fi

# giri avversari 2026-08-28 (A20): un segreto VERO non deve aspettare che repos.key
# ne conosca il nome. Le FORME generiche (prefissi di token AWS/GitHub/Anthropic/Slack,
# chiavi private PEM) si cercano sempre, su tutti i file tracciati. I file di TEST e
# l'archivio SAL citano queste forme per parlarne: esclusi per costruzione. (Revisione 10
# giri: le forme con prefisso portano il CORPO — `sk-ant-` e `github_pat_` seguiti da 20
# caratteri, come i token veri: cosi' un file che NOMINA il prefisso, come la maschera di
# night-shift/lib.sh, non e' una perdita, e nessun file intero va escluso.)
# (incidente 2026-09-23: email e telefoni VERI nei campioni BC — 39 email e 42
# numeri in 21+31 file, bonificati): le forme dei DATI DI CONTATTO entrano tra
# le shapes. Esclusi i domini tecnici (odata.media) e i placeholder (esempio).
SHAPES='sk-ant-[A-Za-z0-9_-]{20}|sk-proj-[A-Za-z0-9_-]{20}|ghp_[A-Za-z0-9]{20}|gho_[A-Za-z0-9]{20}|github_pat_[A-Za-z0-9_]{20}|AKIA[0-9A-Z]{12}|xoxb-[0-9A-Za-z-]{10}|BEGIN (RSA |EC |OPENSSH )?PRIVATE KEY|[a-zA-Z0-9._%+-]+@(yahoo|tiscali|gmail|libero|hotmail|outlook|virgilio|alice|jacer)\.[a-z]{2,}|[a-zA-Z0-9._%+-]+@pec\.[a-zA-Z0-9.-]+|\+39[ /0-9]{8,12}'
SHAPE_HIT=$( (cd "$HERE" && git ls-files -z | xargs -0 grep -lE "$SHAPES" 2>/dev/null)   | grep -vE '^tests/|SAL-ARCHIVIO\.md|repos\.key|tools/privacy-check\.sh|tools/giri-avversari\.sh' || true)
if [ -n "$SHAPE_HIT" ]; then
  echo "⛔ privacy-check: FORMA DI SEGRETO generica in:" >&2
  echo "$SHAPE_HIT" | sed 's/^/  file: /' >&2
  RC=1
fi

# scan_termine <termine> <etichetta>: FALLISCE se il termine compare nei file tracciati
# oggi, nel CONTENUTO di un commit passato (pickaxe), o nel messaggio di un commit passato.
scan_termine() {
  local termine="$1" etichetta="$2"
  [ -z "$termine" ] && return 0
  local FILES HIST MSG ALL
  FILES=$( (cd "$HERE" && git ls-files -z | xargs -0 grep -l -F "$termine" 2>/dev/null) | grep -v "repos.key" || true)
  HIST=$( (cd "$HERE" && git log --all --oneline -S"$termine" -- . 2>/dev/null) | sed 's/^/storia: /' || true)
  MSG=$( (cd "$HERE" && git log --all --oneline --grep="$termine" -F 2>/dev/null) | sed 's/^/messaggio: /' || true)
  ALL=$(printf '%s\n%s\n%s\n' "$FILES" "$HIST" "$MSG" | grep -v '^$' || true)
  if [ -n "$ALL" ]; then
    echo "⛔ $etichetta NEL REPO PUBBLICO ($termine) in:" >&2
    echo "$ALL" | head -8 >&2
    RC=1
  fi
}

# bug reale (revisione 14 lenti, 2026-08-28): `while read ... done < file` salta
# silenziosamente l'ultima riga se il file non termina con newline (comunissimo con
# editor che non lo aggiungono) — un nome sensibile su quella riga passava "pulito" per
# errore. La condizione `|| [ -n "$code" ]` cattura anche l'ultima riga senza newline
# (read fallisce a EOF ma ha comunque popolato le variabili).
[ "$HA_KEY" -eq 1 ] && while IFS='=' read -r code name || [ -n "$code" ]; do
  case "$code" in \#*|"") continue ;; esac
  base="${name##*/}"
  scan_termine "$base" "NOME PRIVATO"
  scan_termine "$name" "NOME PRIVATO"
done < "$KEY"

# v2 (giro 4/10 del ciclo precedente): anche PERSONE e TERMINI riservati — chiavi
# PERSONA=x / TERMINI=a,b,c nella stessa repos.key. La privacy non è solo il nome delle repo.
[ "$HA_KEY" -eq 1 ] && while IFS='=' read -r chiave valore || [ -n "$chiave" ]; do
  case "$chiave" in PERSONA|TERMINI) ;; *) continue ;; esac
  IFS=',' read -ra TERMINI_ARR <<<"$valore"
  for t in "${TERMINI_ARR[@]}"; do
    tt=$(echo "$t" | xargs)
    scan_termine "$tt" "TERMINE PRIVATO"
  done
done < "$KEY"

# (dominio 2026-09-23, Luca — sanitizza + guardia): anche la lista locale dei
# nomi (~/.privacy-nomi, stessa classe di repos.key: locale, gitignored) entra
# nel check. I fornitori veri nei campioni BC sono passati perche' stavano in
# QUESTA lista, che il check non leggeva. Senza il file (sessioni esterne):
# passaggio saltato col manifesteo — il gate degradato resta la regola F3.
NOMI_LOCALI="$HOME/.privacy-nomi"
if [ -s "$NOMI_LOCALI" ]; then
  # sorveglianza sui FILE CORRENTI soltanto: la storia coi nomi e' coperta
  # dalla decisione di dominio (nomi-si, accesso-no) — amnistia dichiarata,
  # non oblio. Il tripwire e' per cio' che entra ADESSO.
  while IFS= read -r n || [ -n "$n" ]; do
    case "$n" in \#*|"") continue ;; esac
    FILES_N=$( (cd "$HERE" && git ls-files -z | xargs -0 grep -l -F "$n" 2>/dev/null) | grep -v "repos.key" || true)
    if [ -n "$FILES_N" ]; then
      echo "⛔ NOME PRIVATO (lista locale) in file correnti ($n):" >&2
      echo "$FILES_N" | head -5 >&2
      RC=1
    fi
  done < "$NOMI_LOCALI"
else
  echo "privacy-check: lista locale ~/.privacy-nomi assente — passaggio saltato (gate degradato, regola F3)" >&2
fi

[ $RC -eq 0 ] && echo "privacy-check: pulito (file correnti + storia git, tutti i branch)"
exit $RC
