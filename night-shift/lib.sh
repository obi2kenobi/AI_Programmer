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
run_guarded() {
  local secs="$1"; shift
  "$@" &
  local pid=$!
  local elapsed=0
  while kill -0 "$pid" 2>/dev/null; do
    if [ "$elapsed" -ge "$secs" ]; then
      kill -TERM "$pid" 2>/dev/null
      break
    fi
    sleep 1
    elapsed=$((elapsed+1))
  done
  wait "$pid" 2>/dev/null
  local rc=$?
  return $rc
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
# split consapevole delle virgolette: gli operatori DENTRO stringhe citate non separano
# (chiude anche il falso positivo documentato in DEBITI: grep -c "a;b" file)
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
        elif ch in ";|":
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
mask_secrets() {
  sed -E \
    -e 's/(secret|token|password|key)[a-z_]*[=: ][^ ,"]+/\1=***MASCHERATO***/gi' \
    -e 's/(Authorization)[=: ]+(Bearer|Basic|Token)[= ]+[^ ,"]+/\1: \2 ***MASCHERATO***/gi'
}

# repo_code(): il hub è pubblico — nei dati versionati (metrics, report esportati) le repo
# sono CODICI ANONIMI. La chiave vive solo in repos.key (locale, gitignored).
repo_code() {
  local repo="$1" key="$HERE/repos.key"
  if [ -f "$key" ]; then
    while IFS='=' read -r code name; do
      case "$code" in \#*|"") continue ;; esac
      [ "$name" = "$repo" ] && { echo "$code"; return 0; }
    done < "$key"
  fi
  echo "$repo"
}
