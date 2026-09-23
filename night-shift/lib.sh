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
    if tokens[0] == "git":
        sub = tokens[1] if len(tokens) > 1 else ""
        if sub not in GIT_RO:
            sys.exit(1)
        # (revisione 10 giri): le opzioni che fanno ESEGUIRE (git grep -O<prog>,
        # --open-files-in-pager, --ext-diff, --textconv) o SCRIVERE (--output) un sottocomando
        # di sola lettura — riprodotto: `git grep -O'echo X' …` eseguiva echo.
        for t in tokens[2:]:
            if t.startswith("-O") or t.startswith("--open-files-in-pager") or t.startswith("--output") \
               or t in ("--ext-diff", "--textconv"):
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
mask_secrets() {
  python3 -c '
import sys, re, hashlib
def imp(v):
    return "«segreto %s · %d caratteri»" % (hashlib.sha256(v.encode("utf-8", "surrogateescape")).hexdigest()[:8], len(v))
AUTH = re.compile(r"(Authorization[=: ]+(?:Bearer|Basic|Token)[= ]+)([^\s,\"«][^\s,\"]*)", re.I)
# (revisione 10 giri): anche la chiave e il valore fra virgolette — JSON e X="y" (\x27 = apostrofo:
# questo codice vive fra apici singoli di bash)
KW = re.compile(r"((?:secret|token|password|key)[a-z_]*[\"\x27]?\s*[=:]\s*[\"\x27]?|(?:secret|token|password|key)[a-z_]* )([^\s,\"\x27«][^\s,\"\x27]*)", re.I)
NUDI = re.compile(r"(?:ghp_|gho_|github_pat_|sk-ant-|sk-proj-|xox[bp]-|AKIA)[A-Za-z0-9_-]{12,}")
for raw in sys.stdin.buffer:
    l = raw.decode("utf-8", "surrogateescape")
    l = AUTH.sub(lambda m: m.group(1) + imp(m.group(2)), l)
    l = KW.sub(lambda m: m.group(1) + imp(m.group(2)), l)
    l = NUDI.sub(lambda m: imp(m.group(0)), l)
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
