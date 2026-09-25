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
# (2026-09-25, settimo ventaglio, V4 R2): il locale si SCEGLIE fra quelli installati, come in tools/pre-commit.sh, e non
# si eredita. In C `grep -i` non ripiega le maiuscole accentate: «ZANETTÒ» passava qui e il pre-commit lo fermava. Qui
# vince sempre l'UTF-8 (un LC_ALL=C del chiamante indeboliva il controllo senza dirlo); senza, lo si dichiara.
UTF_LOCALE=$(locale -a 2>/dev/null | grep -iE '^(en_US|C)\.(utf8|UTF-8)$' | head -1)
if [ -n "$UTF_LOCALE" ]; then export LANG="$UTF_LOCALE" LC_ALL="$UTF_LOCALE"
else echo "⚠ privacy-check: nessun locale UTF-8 installato — le maiuscole accentate non si ripiegano (controllo nomi DEGRADATO)" >&2; fi
KEY="$HERE/night-shift/repos.key"
# v4 (2026-08-24, report dal campo su REPO-G): senza chiave il gate è CIECO — e usciva 0,
# cioè "promosso", proprio nelle sessioni cloud dove la chiave non esiste per disegno.
# Un gate che non può giudicare non dice pulito: dice degradato, e fallisce.
# (revisione 10 giri, 2026-09-23): il degradato usciva QUI, prima delle SHAPES — che il
# commento A20 sotto e la decisione di dominio del 2026-09-23 (DEBITI «Privacy fuori casa»:
# «le SHAPES girano nel repo») davano per sempre attive. Senza chiave nessuna forma di
# segreto veniva cercata. Ora: degradato dichiarato e rc=1 come prima, ma le shapes e la
# lista locale girano comunque; saltano solo i passaggi che la chiave alimenta.
# rifila <testo>: toglie gli spazi in testa e in coda. (2026-09-24, sesto ventaglio, S3 R1): era `xargs`, che su
# un apostrofo («Dell'Orto») esce in errore e non stampa niente — il termine vuoto valeva «pulito», e un leak
# vero di un nome con l'apice passava con rc 0.
rifila() { local t="$1"; t="${t#"${t%%[![:space:]]*}"}"; printf '%s' "${t%"${t##*[![:space:]]}"}"; }

# nomi_locali <lista>: i nomi della lista locale, uno per riga — la regola UNICA di cosa e' un nome (2026-09-25,
# settimo ventaglio, V1 R1). Anche l'ultima riga senza a capo (revisione 14 lenti, 2026-08-28), mai le righe «#»
# o vuote, spazi rifilati. La usa questo check e, via --elenca-nomi, il pre-commit: prima il pre-commit leggeva
# la lista con regole sue, saltava l'ultima riga e prendeva un «#» per un nome.
nomi_locali() {
  local n
  while IFS= read -r n || [ -n "$n" ]; do
    n=$(rifila "$n")
    case "$n" in \#*|"") continue ;; esac
    printf '%s\n' "$n"
  done < "$1"
}
# --elenca-nomi <lista>: stampa i nomi (per chi li confronta in memoria, mai per stamparli) ed esce.
if [ "${1:-}" = "--elenca-nomi" ]; then
  [ -f "${2:-}" ] || exit 0
  nomi_locali "$2"; exit 0
fi

RC=0
if [ -f "$KEY" ]; then
  HA_KEY=1
elif [ ! -d "$HERE/night-shift" ]; then
  # (2026-09-25, D6, risposta delegata): un satellite (nessuna cartella night-shift/) non ha mai una repos.key, che e'
  # dell'hub: la sua assenza qui non e' un degrado. Si controllano le forme di segreto e la lista locale dei nomi.
  HA_KEY=0
  echo "privacy-check: satellite (nessuna night-shift/): repos.key e' dell'hub — qui le forme di segreto e ~/.privacy-nomi (D6)" >&2
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
# (2026-09-23, notte dei giri, T5#3): le credenziali di QUESTO parco — Google OAuth (clasp, cioe' la
# produzione: ya29., 1//0, GOCSPX-), la password dentro un URL, la chiave Zhipu nuda.
SHAPES='sk-ant-[A-Za-z0-9_-]{20}|sk-proj-[A-Za-z0-9_-]{20}|ghp_[A-Za-z0-9]{20}|gho_[A-Za-z0-9]{20}|github_pat_[A-Za-z0-9_]{20}|AKIA[0-9A-Z]{12}|xoxb-[0-9A-Za-z-]{10}|BEGIN (RSA |EC |OPENSSH )?PRIVATE KEY|[a-zA-Z0-9._%+-]+@(yahoo|tiscali|gmail|libero|hotmail|outlook|virgilio|alice|jacer)\.[a-z]{2,}|[a-zA-Z0-9._%+-]+@pec\.[a-zA-Z0-9.-]+|\+39[ /0-9]{8,12}|ya29\.[A-Za-z0-9_-]{20}|1//0[A-Za-z0-9_-]{20}|GOCSPX-[A-Za-z0-9_-]{20}|://[^/[:space:]:@]+:[^/[:space:]@]{6,}@|[0-9a-f]{32}\.[A-Za-z0-9]{16}'
SHAPE_HIT=$( (cd "$HERE" && git ls-files -z | xargs -0 grep -lE "$SHAPES" 2>/dev/null)   | grep -vE 'SAL-ARCHIVIO\.md|repos\.key|tools/privacy-check\.sh|tools/giri-avversari\.sh' || true)   # (2026-09-24, Q5 R5): tests/ non piu' escluso — i banchi compongono le forme a runtime (E-007)
if [ -n "$SHAPE_HIT" ]; then
  echo "⛔ privacy-check: FORMA DI SEGRETO generica in:" >&2
  echo "$SHAPE_HIT" | sed 's/^/  file: /' >&2
  RC=1
fi

# (2026-09-24, quarto ventaglio, Q5 R2, caso A2): le forme si cercavano solo nei file di OGGI — un token
# committato e tolto nel commit dopo restava nella storia sull'hub pubblico, e qui «pulito». Le forme di
# CREDENZIALE (non i dati di contatto: la storia e' amnistiata per i dati di business, DEBITI.md) si cercano
# anche nella storia. Si dicono commit e oggetto, mai il valore. Misurato sull'hub: 5 s, zero commit.
# Ogni alternativa sta anche in SHAPES (lo pretende tests/test-privacy.sh).
SHAPES_CREDENZIALI='sk-ant-[A-Za-z0-9_-]{20}|sk-proj-[A-Za-z0-9_-]{20}|ghp_[A-Za-z0-9]{20}|gho_[A-Za-z0-9]{20}|github_pat_[A-Za-z0-9_]{20}|AKIA[0-9A-Z]{12}|xoxb-[0-9A-Za-z-]{10}|BEGIN (RSA |EC |OPENSSH )?PRIVATE KEY|ya29\.[A-Za-z0-9_-]{20}|1//0[A-Za-z0-9_-]{20}|GOCSPX-[A-Za-z0-9_-]{20}|://[^/[:space:]:@]+:[^/[:space:]@]{6,}@|[0-9a-f]{32}\.[A-Za-z0-9]{16}'
CRED_STORIA=$( (cd "$HERE" && git log --all --format='%h %s' -G"$SHAPES_CREDENZIALI" -- . ':!tests/' ':!tools/privacy-check.sh' ':!tools/giri-avversari.sh' ':!SAL-ARCHIVIO.md' ':!**/repos.key' 2>/dev/null) || true)
if [ -n "$CRED_STORIA" ]; then
  echo "⛔ privacy-check: forma di CREDENZIALE nella STORIA git (il valore non si stampa: la chiave va ruotata; riscrivere la storia lo decide Luca):" >&2
  echo "$CRED_STORIA" | cut -c1-90 | sed 's/^/  commit /' >&2
  RC=1
fi


# (2026-09-23, notte dei giri, T5#4): l'uscita di questo check finisce nell'issue «[banco]» del repo
# PUBBLICO (banco-passaggio.sh -> night-shift.sh). Stampava il termine che proteggeva. Ora ne stampa
# l'impronta (CLAUDE.md «Mask, don't omit»): chi ha la chiave la riconosce, il lettore pubblico no.
# Il testo si maschera con TUTTI i termini noti, non solo con quello cercato: il nome di un file
# puo' essere a sua volta un termine protetto.
TERMINI_NOTI=()
if [ "$HA_KEY" -eq 1 ]; then
  while IFS='=' read -r k v || [ -n "$k" ]; do
    case "$k" in \#*|"") continue ;; PERSONA|TERMINI) IFS=',' read -ra PEZZI <<<"$v"; for t in "${PEZZI[@]}"; do TERMINI_NOTI+=("$(rifila "$t")"); done ;; *) TERMINI_NOTI+=("$v" "${v##*/}") ;; esac
  done < "$KEY"
fi
[ -s "$HOME/.privacy-nomi" ] && while IFS= read -r n || [ -n "$n" ]; do
  case "$n" in \#*|"") ;; *) TERMINI_NOTI+=("$n") ;; esac
done < "$HOME/.privacy-nomi"
# maschera <testo>: il testo con ogni termine noto sostituito dalla sua impronta (i piu' lunghi prima,
# cosi' «org/app» non viene spezzato dalla maschera di «app»)
maschera() {
  local testo="$1" t imp
  while IFS= read -r t; do
    [ -z "$t" ] && continue
    imp=$(printf '%s' "$t" | { shasum -a 256 2>/dev/null || sha256sum; } | cut -c1-8)
    testo="${testo//"$t"/«termine $imp · ${#t} caratteri»}"
  done < <(for t in "${TERMINI_NOTI[@]+"${TERMINI_NOTI[@]}"}"; do printf '%d\t%s\n' "${#t}" "$t"; done | sort -rn | cut -f2-)
  printf '%s\n' "$testo"
}

# scan_termine <termine> <etichetta>: FALLISCE se il termine compare nei file tracciati
# oggi, nel CONTENUTO di un commit passato (pickaxe), o nel messaggio di un commit passato.
scan_termine() {
  local termine="$1" etichetta="$2"
  [ -z "$termine" ] && return 0
  local FILES HIST MSG ALL
  # (2026-09-24, Q5 R5): -i — il nome in MAIUSCOLO passava qui e non nel pre-commit (che e' -i)
  FILES=$( (cd "$HERE" && git ls-files -z | xargs -0 grep -l -i -F "$termine" 2>/dev/null) | grep -v "repos.key" || true)
  HIST=$( (cd "$HERE" && git log --all --oneline -S"$termine" -- . 2>/dev/null) | sed 's/^/storia: /' || true)
  MSG=$( (cd "$HERE" && git log --all --oneline --grep="$termine" -F 2>/dev/null) | sed 's/^/messaggio: /' || true)
  ALL=$(printf '%s\n%s\n%s\n' "$FILES" "$HIST" "$MSG" | grep -v '^$' || true)
  if [ -n "$ALL" ]; then
    maschera "⛔ $etichetta NEL REPO PUBBLICO ($termine) in:" >&2
    maschera "$(head -8 <<<"$ALL")" >&2
    RC=1
  fi
}

# bug reale (revisione 14 lenti, 2026-08-28): `while read ... done < file` salta
# silenziosamente l'ultima riga se il file non termina con newline (comunissimo con
# editor che non lo aggiungono) — un nome sensibile su quella riga passava "pulito" per
# errore. La condizione `|| [ -n "$code" ]` cattura anche l'ultima riga senza newline
# (read fallisce a EOF ma ha comunque popolato le variabili).
[ "$HA_KEY" -eq 1 ] && while IFS='=' read -r code name || [ -n "$code" ]; do
  case "$code" in \#*|""|PERSONA|TERMINI) continue ;; esac   # persone e termini: il ciclo sotto
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
    tt=$(rifila "$t")
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
  while IFS= read -r n; do
    FILES_N=$( (cd "$HERE" && git ls-files -z | xargs -0 grep -l -i -F -- "$n" 2>/dev/null) | grep -v "repos.key" || true)
    if [ -n "$FILES_N" ]; then
      maschera "⛔ NOME PRIVATO (lista locale) in file correnti ($n):" >&2
      maschera "$(head -5 <<<"$FILES_N")" >&2
      RC=1
    fi
  done < <(nomi_locali "$NOMI_LOCALI")
else
  echo "privacy-check: lista locale ~/.privacy-nomi assente — passaggio saltato (gate degradato, regola F3)" >&2
fi

[ $RC -eq 0 ] && echo "privacy-check: pulito (file correnti + storia git, tutti i branch)"
exit $RC
