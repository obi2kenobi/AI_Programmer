#!/bin/bash
# lib.sh — funzioni condivise del sistema (sourced, non eseguito).
# default_branch(): il branch di default della repo, MAI hardcoded (review 2026-08-21 §2.2:
# tre script assumevano "main" — una repo con "master" rompeva i flussi in silenzio).
default_branch() {
  local dir="$1"
  local ref
  ref=$(git -C "$dir" symbolic-ref refs/remotes/origin/HEAD 2>/dev/null) && {
    echo "${ref#refs/remotes/origin/}"; return 0
  }
  local ghb
  # bug reale (revisione 14 lenti, 2026-08-28): la query jq leggeva `.name` invece di
  # `.defaultBranchRef.name` — con `--json defaultBranchRef` l'oggetto è
  # {"defaultBranchRef":{"name":...}}, quindi `.name` valeva sempre "null" (comando gh
  # riuscito, solo la query sbagliata) e il chiamante non vedeva MAI l'avviso di fallback,
  # perché "&&" scattava comunque con la stringa letterale "null". Verificato con jq sullo
  # stesso schema prima e dopo il fix.
  ghb=$(gh repo view -R "$(git -C "$dir" remote get-url origin 2>/dev/null | sed 's|.*github.com[:/]||; s|\.git$||')" \
    --json defaultBranchRef -q .defaultBranchRef.name 2>/dev/null) && [ -n "$ghb" ] && [ "$ghb" != "null" ] && { echo "$ghb"; return 0; }
  echo "main" # fallback finale: CHIAMANTE deve avvisare che è un'assunzione
  return 1
}

# mtime(): l'epoch di ultima modifica di un file, portabile (test del sistema completo
# 2026-09-20, D22): `stat -f %m` e' BSD/macOS, su Linux non esiste e il fallback `|| echo 0`
# faceva risultare ogni lock e ogni cooldown «scaduto» (eta' = adesso - 0). Stampa 0 e
# torna 1 se il file non c'e': il chiamante decide.
mtime() {
  local f="$1" t
  t=$(stat -f %m "$f" 2>/dev/null) || t=$(stat -c %Y "$f" 2>/dev/null) || { echo 0; return 1; }
  echo "$t"
}

# rotate_log_if_big(): ruota un log oltre soglia (default 10MB) — una sola generazione
# (file → file.1, sovrascrivendo un .1 precedente: non serve di più per un log locale
# di debug, non un archivio). Debito aperto dal 2026-08-21 ("nessun limite raggiunto");
# night-shift.log e morning-gate.log crescono senza limite da allora.
rotate_log_if_big() {
  local file="$1" soglia_mb="${2:-10}"
  [ -f "$file" ] || return 0
  local size_bytes
  size_bytes=$(wc -c < "$file" 2>/dev/null) || return 0
  local soglia_bytes=$((soglia_mb * 1024 * 1024))
  if [ "$size_bytes" -ge "$soglia_bytes" ]; then
    mv -f "$file" "$file.1"
    : > "$file"
  fi
}

# run_guarded(): esegue un comando con watchdog (i secondi) — l'asimmetria trovata dalla
# review §3 (.night-verify senza timeout fermava il gate per sempre) non torna.
#
# bug reale, alta severità (dogfooding, set 2 "capacità di progettare", 2026-08-22):
# `kill "$wdg"` uccideva solo il SUBSHELL bash che eseguiva "sleep $secs; kill ...", non
# il processo "sleep" che quel subshell aveva generato come figlio — il "sleep" orfano
# restava vivo, e dentro una command substitution ($(...), esattamente come lo chiama
# morning-gate.sh) il descrittore stdout ereditato dal "sleep" orfano teneva la pipe
# APERTA finché il sonno non finiva DA SOLO. Risultato: ogni comando .night-verify (e il
# banco avversariale) impiegava SEMPRE l'intera durata del watchdog (120s in produzione)
# per restituire il risultato, anche se il comando reale finiva in millisecondi —
# verificato dal vivo con `time`: 10.0s esatti per un `run_guarded 10 bash -c "true"`.
# Primo tentativo di fix (`exec sleep` nel subshell watchdog) si è rivelato SBAGLIATO
# alla verifica dal vivo: un secondo subshell non può fare `wait` su un job che non è
# figlio SUO (è figlio del chiamante) — bash lo rifiuta ("not a child of this shell"),
# quindi il killer non uccideva mai il comando davvero bloccato, silenziosamente. Fix
# vero: nessun subshell "figlio di un figlio" — un poll con `kill -0` nel chiamante
# stesso, che possiede sia il comando che il tempo trascorso. Portabile su bash 3.2
# (nessun `wait -n`, non disponibile prima di bash 4.3/5.1 — questo repo ha altrove
# vincoli espliciti di compatibilità con la bash 3.2 di macOS).
# (revisione 10 giri, 2026-09-23): il poll qui sopra mandava TERM al solo figlio diretto e
# restituiva l'rc del comando — un nipote che tiene aperta la pipe (bash -c 'sleep …' dentro
# $(…)) teneva il chiamante per l'intera durata, e un comando che ignora TERM tornava VERDE
# dopo la sua durata intera (riprodotti in tests/test-lib.sh). La cura esisteva gia' in
# llm/_timeout.sh (kill del GRUPPO, KILL dopo 5s, 124 a timeout): run_guarded la usa.
_LIB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
declare -F ai_timeout >/dev/null 2>&1 || source "$_LIB_DIR/../llm/_timeout.sh"
run_guarded() {
  local secs="$1"; shift
  ai_timeout "$secs" "$@"
}

# ambiente_turno: una riga per il log — la bash, il ramo di ai_timeout, la sandbox (2026-09-23, notte dei
# giri, T3#6). Il turno gira sul Mac, i banchi su Linux: senza questa riga le differenze fra i due
# (il ramo perl del timeout, la sandbox) non si misurano dal log.
ambiente_turno() {
  local sb="ASSENTE (esecuzioni senza sandbox; il censore rinvia)"
  command -v sandbox-exec >/dev/null 2>&1 && sb="sandbox-exec"
  echo "ambiente: bash $BASH_VERSION · timeout: $(ai_timeout_ramo) · sandbox: $sb"
}

# gate_allowlist_ok(): TRUE solo se OGNI segmento del comando (split consapevole delle
# virgolette su && || ; |) inizia con uno strumento che NON PUÒ eseguire codice via argomenti.
# Decisione di Luca 2026-08-21 (opzione c): niente interpreti general-purpose — bash -c,
# python3 -c, awk system(), sed /e, npm run bypassavano il controllo sul primo token
# (verificato dal vivo da dev-critic, vedi DEBITI.md). Il banco smentisce con grep/cat/git.
gate_allowlist_ok() {
  python3 - "$1" <<'PY'
import sys, re
cmd = sys.argv[1]
# bug reale, ALTA (revisione 14 lenti, 2026-08-28): il controllo guardava solo il PRIMO
# TOKEN di ogni segmento — non riconosceva una sostituzione di comando ANNIDATA dentro un
# segmento già ammesso. `echo $(python3 -c "...")` superava l'allowlist (primo token=echo,
# ammesso) ma la sostituzione faceva comunque girare python3 -c con codice arbitrario dentro
# la sandbox seatbelt (che nega solo rete/scritture, non la lettura). Riprodotto dal vivo.
# Rifiuto conservativo: qualunque sostituzione di comando o processo, ovunque compaia nella
# stringa (anche dentro virgolette singole — non vale la pena distinguere, è un banco
# avversariale, non un interprete shell general-purpose).
if "$(" in cmd or "`" in cmd or "<(" in cmd or ">(" in cmd:
    sys.exit(1)
# le sole redirezioni ammesse: verso /dev/null e 2>&1 (non scrivono niente) — tolte PRIMA del
# controllo sulle redirezioni in split_operators (revisione 10 giri)
cmd = re.sub(r"(?<![\w&])[12]?>>?\s*/dev/null", " ", cmd).replace("2>&1", " ")
# split consapevole delle virgolette: gli operatori DENTRO stringhe citate non separano
# (chiude anche il falso positivo documentato in DEBITI: grep -c "a;b" file)
# (revisione 10 giri, 2026-09-23): anche `&` singolo separa (il comando dopo girava in
# background senza esame) e una redirezione `>` FUORI dalle virgolette rifiuta tutto (il
# banco e' in sola lettura: `grep x f > out` scriveva). Dentro le virgolette restano dati.
def split_operators(c):
    out, buf, q = [], [], None
    i = 0
    while i < len(c):
        ch = c[i]
        if q:
            buf.append(ch)
            if ch == q: q = None
        elif ch in "\"'":
            q = ch; buf.append(ch)
        elif c[i:i+2] in ("&&", "||"):
            out.append("".join(buf)); buf = []; i += 2; continue
        elif ch == ">":
            sys.exit(1)
        elif ch in ";|&":
            out.append("".join(buf)); buf = []
        else:
            buf.append(ch)
        i += 1
    out.append("".join(buf))
    return out

# (2026-09-23, notte dei giri, T5#2): l'allowlist guardava QUALE strumento gira, non COSA legge —
# `cat ~/.git-credentials`, `echo $ZHIPUAI_API_KEY`, `cat /proc/self/environ` passavano, e agente.sh
# poteva scriverne il contenuto in un file che il `git add -A` del turno spinge. Il confine e' il
# progetto: un `$` fuori dagli apici singoli (espansione), un argomento che inizia con / o ~ (anche
# dopo `--opzione=`), un `..` come cartella — si rifiuta. `HEAD~1..HEAD` resta ammesso.
def fuori_dagli_apici_singoli(c):
    q = None
    for ch in c:
        if q:
            if ch == q: q = None
        elif ch in "\"'":
            q = ch
        if ch == "$" and q != "'":
            return True
    return False
if fuori_dagli_apici_singoli(cmd):
    sys.exit(1)
def fuori_dal_progetto(tok):
    t = tok.strip("\"'")
    for v in (t, t.split("=", 1)[1] if "=" in t else ""):
        v = v.strip("\"'")
        if v.startswith(("/", "~")) or re.search(r"(^|/)\.\.(/|$)", v):
            return True
    return False

ALLOWED = {"grep","cat","diff","wc","head","tail","ls","test","jq","echo","git"}
GIT_RO = {"diff","log","show","grep","status","rev-parse","ls-files","blame"}
for seg in split_operators(cmd):
    seg = seg.strip()
    if not seg:
        continue
    # token grezzo senza shlex (shlex esploderebbe su sintassi shell complessa):
    tokens = seg.split()
    if not tokens:
        continue
    if tokens[0] not in ALLOWED:
        sys.exit(1)
    if any(fuori_dal_progetto(t) for t in tokens[1:]):
        sys.exit(1)
    if tokens[0] == "git":
        sub = tokens[1] if len(tokens) > 1 else ""
        if sub not in GIT_RO:
            sys.exit(1)
        # (revisione 10 giri): le opzioni che fanno ESEGUIRE (git grep -O<prog>,
        # --open-files-in-pager, --ext-diff, --textconv) o SCRIVERE (--output) un sottocomando
        # di sola lettura — riprodotto: `git grep -O'echo X' …` eseguiva echo.
        # (2026-09-23, giro A6 della notte): riprodotte due vie ancora aperte — le opzioni corte
        # RAGGRUPPATE (`-iO'cmd'` esegue cmd) e le lunghe ABBREVIATE (`--open-files=cmd`: git
        # accetta ogni prefisso non ambiguo). Ora: un gruppo corto che contiene O si rifiuta, e
        # una lunga che e' l'inizio di un'opzione pericolosa si rifiuta.
        PERICOLOSE = ("open-files-in-pager", "output", "ext-diff", "textconv")
        for t in tokens[2:]:
            if t.startswith("--"):
                nome = t[2:].split("=", 1)[0]
                if nome and any(p.startswith(nome) for p in PERICOLOSE):
                    sys.exit(1)
            elif t.startswith("-") and "O" in t.split("=", 1)[0]:
                sys.exit(1)
sys.exit(0)
PY
}

# mask_secrets(): maschera segreti nell'output del banco avversariale prima che finisca
# nel report (pattern segreto-come-impronta). Copre due forme, non una lista esaustiva
# di forme di segreto (quello richiederebbe un rilevatore per-forma come segreti-parco.js,
# fuori scope qui — annotato in DEBITI.md):
#   1. "parola-chiave=valore" o "parola-chiave: valore" (secret/token/password/key)
#   2. "Authorization: Bearer/Basic/Token <valore>" — trovato scoperto con dogfooding
#      (nuovo ciclo 10 giri, 2026-08-22): un comando che stampa un header HTTP con un
#      Bearer token passava INTERO, perché "Authorization" non contiene nessuna delle
#      parole chiave della forma 1.
# (revisione 10 giri, 2026-09-23): il formato e' quello della regola vincolante di CLAUDE.md
# («Mask, don't omit») e del pattern — «segreto <impronta> · N caratteri», non piu'
# ***MASCHERATO***: chi legge vede che c'era un segreto, quanto era lungo, e se due righe
# portano lo STESSO (impronta = primi 8 hex di sha256). Forma 3 nuova: i token NUDI con
# prefisso noto (ghp_, github_pat_, sk-ant-, xoxb-, AKIA...) — prima passavano interi se
# nessuna parola chiave li precedeva. Una maschera gia' messa («...) non si rimaschera.
# (2026-09-23, notte dei giri, T5#3): anche le credenziali di QUESTO parco — Google OAuth, cioe'
# clasp e la produzione (ya29., 1//0, GOCSPX-), la chiave Zhipu nuda (<32 hex>.<segreto>), PASSWD,
# e la password dentro un URL (fra «utente:» e la chiocciola dell'host). Prima passavano intere.
mask_secrets() {
  python3 -c '
import sys, re, hashlib
def imp(v):
    return "«segreto %s · %d caratteri»" % (hashlib.sha256(v.encode("utf-8", "surrogateescape")).hexdigest()[:8], len(v))
AUTH = re.compile(r"(Authorization[=: ]+(?:Bearer|Basic|Token)[= ]+)([^\s,\"«][^\s,\"]*)", re.I)
# (revisione 10 giri): anche la chiave e il valore fra virgolette — JSON e X="y" (\x27 = apostrofo:
# questo codice vive fra apici singoli di bash)
KW = re.compile(r"((?:secret|token|passwd|password|key)[a-z_]*[\"\x27]?\s*[=:]\s*[\"\x27]?|(?:secret|token|passwd|password|key)[a-z_]* )([^\s,\"\x27«][^\s,\"\x27]*)", re.I)
NUDI = re.compile(r"(?:ghp_|gho_|github_pat_|sk-ant-|sk-proj-|xox[bp]-|AKIA|ya29\.|1//0|GOCSPX-)[A-Za-z0-9_-]{12,}|[0-9a-f]{32}\.[A-Za-z0-9]{16,}")
URL = re.compile(r"(://[^/\s:@\"\x27]+:)([^/\s@\"\x27«]{6,})(@)")
for raw in sys.stdin.buffer:
    l = raw.decode("utf-8", "surrogateescape")
    l = AUTH.sub(lambda m: m.group(1) + imp(m.group(2)), l)
    l = KW.sub(lambda m: m.group(1) + imp(m.group(2)), l)
    l = NUDI.sub(lambda m: imp(m.group(0)), l)
    l = URL.sub(lambda m: m.group(1) + imp(m.group(2)) + m.group(3), l)
    sys.stdout.buffer.write(l.encode("utf-8", "surrogateescape"))
    sys.stdout.buffer.flush()
' || echo "⛔ mask_secrets: la maschera e' MORTA (python) — output SOPPRESSO, non mostrato per sicurezza: e' un rosso, non un silenzio"
}

# candidata_censore(): dal JSON di `gh pr list --json number,headRefName,isDraft,title` (stdin)
# il numero della prima PR che il censore ACCETTA — bozza, branch night/*, titolo `caccia:`:
# gli stessi predicati delle guardie di night-shift/revisore.sh. (Revisione 10 giri,
# 2026-09-23): il turno prendeva la prima bozza night/* qualunque; con una PR di issue in
# testa il censore rispondeva «non mio» a ogni ciclo e le caccia dietro non passavano mai.
candidata_censore() {
  jq -r '[.[] | select(.isDraft == true and (.headRefName | startswith("night/")) and ((.title // "") | startswith("caccia:")))][0].number // empty' 2>/dev/null
}

# rami_da_scopare <ora-epoch> <soglia-ore> <file-rami> <file-pr>: i rami remoti che la scopa
# del turno puo' cancellare. <file-rami>: «nome<TAB>epoch dell'ultimo commit» per riga;
# <file-pr>: «head<TAB>stato» (OPEN|MERGED|CLOSED) per riga. Regole (decisione di Luca
# 2026-09-23 «un ramo fuso non serve a niente», con le guardie che il codice non aveva):
#  - mai main, mai un ramo con una PR APERTA (anche se un'altra PR sullo stesso nome e' fusa);
#  - PR fusa/chiusa → si cancella;
#  - nessuna PR → si cancella solo oltre la soglia (48h): prima la soglia era nel commento
#    e un ramo spinto un minuto prima della sua PR spariva al ciclo dopo.
# (Revisione 10 giri, 2026-09-23.)
rami_da_scopare() {
  python3 - "$1" "$2" "$3" "$4" <<'PY'
import sys
ora, soglia = int(sys.argv[1]), int(sys.argv[2]) * 3600
rami = {}
for l in open(sys.argv[3]):
    p = l.rstrip("\n").split("\t")
    if len(p) == 2 and p[0] and p[1].isdigit():
        rami[p[0]] = int(p[1])
stati = {}
for l in open(sys.argv[4]):
    p = l.rstrip("\n").split("\t")
    if len(p) == 2 and p[0]:
        stati.setdefault(p[0], set()).add(p[1])
for nome, eta in rami.items():
    if nome == "main" or "OPEN" in stati.get(nome, set()):
        continue
    if stati.get(nome, set()) & {"MERGED", "CLOSED"}:
        print(nome)
    elif nome not in stati and ora - eta > soglia:
        print(nome)
PY
}

# repo_code(): i codici anonimi sono stati ritirati (dominio, Luca 2026-09-23:
# il mapping non era mai stato alimentato e i nomi possono comparire — resta
# proibito l'ACCESSO). La funzione resta per i chiamatori: restituisce il nome.
repo_code() {
  echo "$1"
}

# forme_prima_del_push <dir> <base>: il cancello fra commit e push (2026-09-23, notte dei giri, T5#3).
# lente_pr gira DOPO il push: sull'hub pubblico un segreto nel diff era gia' su GitHub quando la
# lente lo vedeva. Qui lo strato 1 della lente (le forme di segreto, deterministico, niente cervello)
# su <base>...HEAD: rc 0 = il push puo' partire; altrimenti stampa il rapporto (valori mascherati) e
# rc != 0 — anche DEGRADATA (diff illeggibile) ferma il push: nel dubbio, niente esce.
forme_prima_del_push() {
  local rap rc
  rap=$(LENTE_SOLO_FORME=1 bash "$(dirname "${BASH_SOURCE[0]}")/../tools/lente-sicurezza.sh" "$1" "$2" HEAD 2>/dev/null); rc=$?
  [ $rc -eq 0 ] && return 0
  echo "⛔ forme di segreto nel diff ($2...HEAD): push NON eseguito — $(tail -1 <<<"$rap")"
  grep '^- ' <<<"$rap" | head -5
  return 1
}

# lente_pr <dir> <base> <head> <url-pr>: la lente sicurezza (dev-critic §2bis) su una PR appena
# creata dalla notte — decisione di Luca, D2 2026-09-23: automatica su TUTTE le PR notturne. Il
# rapporto (valori gia' mascherati da tools/lente-sicurezza.sh) diventa un commento della PR;
# la riga di sintesi va a stdout per il log del chiamante. Non blocca la creazione: chi delibera
# (il censore, il giorno) legge il verdetto — il censore la rilancia da se' prima di fondere.
lente_pr() {
  local dir="$1" base="$2" head="$3" url="$4" rap
  case "$url" in https://*) ;; *) echo "lente sicurezza: nessuna PR da guardare ('$url') — salto dichiarato"; return 0 ;; esac
  rap=$(bash "$(dirname "${BASH_SOURCE[0]}")/../tools/lente-sicurezza.sh" "$dir" "$base" "$head" 2>/dev/null)
  if (cd "$dir" && gh pr comment "$url" --body "$rap") >/dev/null 2>&1; then
    echo "lente sicurezza su $url: $(tail -1 <<<"$rap") (rapporto nel commento della PR)"
  else
    echo "lente sicurezza su $url: $(tail -1 <<<"$rap") — ⚠ commento NON pubblicato sulla PR"
  fi
}

# candidata_parere <dir-stato>: dal JSON di `gh pr list --json number,headRefName,isDraft,title,headRefOid`
# (stdin) il numero della prima PR di ISSUE (bozza, branch night/issue-*) senza parere gia' dato su
# quel commit — decisione di Luca, D10 2026-09-23: «b», il censore giudica le PR delle issue e lascia
# un parere, mai la fusione. Il parere dato vive in <dir-stato>/parere-<numero>-<commit> (lo scrive
# night-shift/revisore.sh): senza questo filtro la stessa PR tornerebbe al censore a ogni ciclo.
candidata_parere() {
  local stato="$1" n oid
  while IFS=$'\t' read -r n oid; do
    [ -n "$n" ] || continue
    [ -f "$stato/parere-$n-$oid" ] && continue
    echo "$n"; return 0
  done < <(jq -r '.[] | select(.isDraft == true and (.headRefName | startswith("night/issue-"))) | [.number, .headRefOid] | @tsv' 2>/dev/null)
}

# verifica_issue_comando <file-issue>: il comando della «## Verifica» che il turno puo' eseguire, o
# vuoto. (2026-09-23, giro A5 della notte): e' testo ESTERNO — l'autore dell'issue puo' modificarlo
# dopo che Luca ha messo la label — e il turno lo esegue. Prima: grep -o sulla forma
# `(node|npm|python3?) …` + denylist → passavano `npm install <pacchetto>`, `npm exec`, `npm i`,
# `python3 -m pip install`, `node -e`, `python3 -c` (riprodotto: 8 vie). Ora la PRIMA riga che
# comincia con node/npm/python si valida PER INTERO: solo `npm test`, o un FILE del progetto
# eseguito (node|python3 <percorso relativo .js/.mjs/.cjs/.py> [argomenti semplici]).
verifica_issue_comando() {
  local riga
  riga=$(sed -n '/^## Verifica/,/^## /p' "$1" 2>/dev/null | grep -E '^(node|npm|python3?)( |$)' | head -1 | sed 's/[[:space:]]*$//')
  [ "$riga" = "npm test" ] && { printf '%s' "$riga"; return 0; }
  grep -qE '^(node|python3?) [A-Za-z0-9_./-]+\.(js|mjs|cjs|py)( [A-Za-z0-9_./=-]+)*$' <<<"$riga" || return 0
  case "$riga" in *" /"*|*..*|*" -"[ecm]" "*|*" --eval"*) return 0 ;; esac   # niente assoluti ne' risalite
  printf '%s' "$riga"
}

# prendi_lock_turno <dir-lock>: 0 = il lock e' di questo processo (preso ora, o gia' suo: il ciclo
# dopo `exec "$0"` ha lo stesso PID), 1 = lo tiene un altro turno VIVO. (Q10, 2026-09-23, giro A5
# della notte): prima contava l'eta' — oltre 1h il lock si toglieva, ma un ciclo con l'issue lenta
# dura fino a 4h (watchdog) e il lock si rubava a un turno vivo. Ora conta il PID: vivo e del
# turno = occupato, a qualunque eta'; morto, o riusato da un altro programma = orfano (E-026) e si
# prende subito. Un lock senza PID (versione di prima) tiene la vecchia regola dell'ora.
# (2026-09-24, notte dei giri, T2#3): davanti a un orfano, due avvii insieme lo prendevano ENTRAMBI
# (32 su 200 nel giro T2, 10 su 60 nel banco): il secondo `rm -rf` cancellava il lock appena preso
# dal primo. Ora il furto e' serializzato da un secondo mkdir (<lock>.furto), e dentro si RIGIUDICA:
# chi arriva dopo trova il lock gia' preso da un vivo e si ferma. Un .furto lasciato da un processo
# morto a meta' si toglie dopo 60 secondi (il furto dura millisecondi).
prendi_lock_turno() {   # [programma]: chi e' «vivo» (default night-shift; ciclo-vivo lo usa col suo nome)
  local L="$1" prog="${2:-night-shift}" rc
  if mkdir "$L" 2>/dev/null; then echo $$ > "$L/pid"; return 0; fi
  [ "$(cat "$L/pid" 2>/dev/null)" = "$$" ] && return 0
  lock_turno_orfano "$L" "$prog" || return 1
  if ! mkdir "$L.furto" 2>/dev/null; then
    [ "$(eta_secondi "$L.furto")" -gt 60 ] && rm -rf "$L.furto"
    return 1
  fi
  rc=1
  if lock_turno_orfano "$L" "$prog"; then
    rm -rf "$L"
    mkdir "$L" 2>/dev/null && echo $$ > "$L/pid" && rc=0
  fi
  rmdir "$L.furto" 2>/dev/null
  return $rc
}

# lock_turno_orfano <dir-lock> [programma]: 0 se il lock non e' di nessun processo vivo di quel
# programma — il PID dentro e' morto o di un altro programma; senza PID (versione di prima), se ha piu'
# di un'ora.
lock_turno_orfano() {
  local pid comando
  pid=$(cat "$1/pid" 2>/dev/null)
  if [ -n "$pid" ]; then
    comando=$(ps -p "$pid" -o command= 2>/dev/null)
    grep -qF -- "${2:-night-shift}" <<<"$comando" && return 1
    return 0
  fi
  [ "$(eta_secondi "$1")" -ge 3600 ]
}

# eta_secondi <percorso>: da quanti secondi esiste (0 se non esiste: un file sparito non e' vecchio)
eta_secondi() {
  local m
  m=$(mtime "$1" 2>/dev/null) || { echo 0; return; }
  echo $(( $(date +%s) - m ))
}

# commenta_una_volta <num> <owner/repo> <motivo> <corpo>: commenta l'issue UNA volta per motivo.
# (Q11, 2026-09-23, giro A5 della notte): il cancello Design/Territorio commentava a OGNI ciclo, e
# il turno riparte subito — centinaia di commenti identici in una notte. Il corpo porta un
# marcatore invisibile (<!-- night-gate:<motivo> -->); se c'e' gia', si tace. Commenti illeggibili
# (gh giu', rete) = non si commenta: rc 2, meglio un avviso in meno che uno spam.
commenta_una_volta() {
  local num="$1" repo="$2" marcatore="<!-- night-gate:$3 -->" corpo="$4" gia
  gia=$(gh issue view "$num" -R "$repo" --json comments -q '.comments[].body' 2>/dev/null) || return 2
  grep -qF -- "$marcatore" <<<"$gia" && return 0
  gh issue comment "$num" -R "$repo" --body "$corpo

$marcatore" >/dev/null 2>&1
}

# cancello_design <corpo-issue>: stampa il MOTIVO per cui l'issue non parte, o niente se passa.
# Motivi: territorio-assente · design-assente · «design-povero <caratteri>» · design-senza-fonte ·
# territorio-vago. (2026-09-23, notte dei giri): la sequenza viveva dentro il turno e il suo banco
# ne teneva una COPIA — con il gate spento il banco restava verde. Ora la sequenza vive qui, una
# volta, e tests/test-night-shift-design-gate.sh prova questa funzione. L'ordine conta: i controlli
# di ASSENZA vengono prima di quelli di QUALITA' (una sezione assente estrae una stringa vuota, che
# il controllo di qualita' intercetterebbe col messaggio sbagliato — set 2, 2026-08-22).
cancello_design() {
  local corpo="$1" design_raw design_body terr_body
  grep -q "^## Territorio" <<<"$corpo" || { echo "territorio-assente"; return 0; }
  grep -q "^## Design" <<<"$corpo" || { echo "design-assente"; return 0; }
  design_raw=$(printf '%s' "$corpo" | awk '/^## Design/{f=1;next} /^## /{f=0} f')
  design_body=$(printf '%s' "$design_raw" | tr -d '[:space:]')
  [ "${#design_body}" -lt 80 ] && { echo "design-povero ${#design_body}"; return 0; }
  # una lunghezza non e' una fonte: almeno UN riferimento verificabile (URL, link markdown,
  # SAL.md, un'issue #N, o un percorso di file) — set 2, prosa di riempimento da 87 caratteri
  grep -qiE 'https?://|\[[^]]+\]\([^)]+\)|SAL(\.md)?\b|(issue|pr|#)[[:space:]]*#?[0-9]+|\.[a-z]{2,4}\b' <<<"$design_raw" \
    || { echo "design-senza-fonte"; return 0; }
  terr_body=$(printf '%s' "$corpo" | awk '/^## Territorio/{f=1;next} /^## /{f=0} f')
  grep -qE '\.[a-z]{2,4}\b|file|riga|documento|md\b' <<<"$terr_body" || { echo "territorio-vago"; return 0; }
  return 0
}

