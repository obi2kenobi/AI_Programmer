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
  ghb=$(gh repo view -R "$(git -C "$dir" remote get-url origin 2>/dev/null | sed 's|.*github.com[:/]||; s|\.git$||')" \
    --json defaultBranchRef -q .name 2>/dev/null) && { echo "$ghb"; return 0; }
  echo "main" # fallback finale: CHIAMANTE deve avvisare che è un'assunzione
  return 1
}

# run_guarded(): esegue un comando con watchdog (i secondi) — l'asimmetria trovata dalla
# review §3 (.night-verify senza timeout fermava il gate per sempre) non torna.
run_guarded() {
  local secs="$1"; shift
  "$@" &
  local pid=$!
  ( sleep "$secs"; kill -TERM "$pid" 2>/dev/null ) &
  local wdg=$!
  wait "$pid"; local rc=$?
  kill "$wdg" 2>/dev/null
  return $rc
}

# gate_allowlist_ok(): TRUE solo se OGNI segmento del comando (split su && || ; |)
# inizia con uno strumento ammesso — e git solo in forma readonly.
# Review §3: la blacklist da sola è bucabile (find -delete, git reset --hard...);
# questa è la prima linea, il sandbox-exec è la seconda.
gate_allowlist_ok() {
  python3 - "$1" <<'PY'
import sys, re, shlex
cmd = sys.argv[1]
ALLOWED = {"node","npm","pnpm","yarn","python3","python","grep","cat","ls","wc",
           "awk","sed","jq","echo","test","bash","sh","diff","head","tail","git"}
GIT_RO = {"diff","log","show","grep","status","rev-parse","ls-files","blame"}
for seg in re.split(r"&&|\|\||;|\|", cmd):
    seg = seg.strip()
    if not seg:
        continue
    try:
        tokens = shlex.split(seg)
    except ValueError:
        sys.exit(1)
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
