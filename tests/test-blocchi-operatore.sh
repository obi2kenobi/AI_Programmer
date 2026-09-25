#!/bin/bash
# test-blocchi-operatore.sh — CLAUDE.md §3 «What you hand to a human to run is code»: nei blocchi di comandi dei .md
# che una persona incolla, niente commenti in riga (2026-09-24, sesto ventaglio, S1 R4). La regola non aveva una
# guardia: il MANUALE era stato ripulito a mano e cinque blocchi altrove restavano. In zsh senza
# interactive_comments (il default) il commento e' testo: un apostrofo al suo interno apriva una stringa e nessun
# comando del blocco girava, `(4h, …)` era un «unknown file attribute», `git worktree remove X   # a PR chiusa`
# non toglieva il worktree. E un ramo `fix/`, `feature/` insegnato in un blocco nessun giudice lo vede (§4).
# Fuori, dichiarati: la storia (SAL, archivio, giri, campo, registro, studi), il grafo generato, e la skill
# graphify, vendorizzata, che scrive comandi per l'agente (bash del tool), non per una persona.
set -uo pipefail
HERE="$(cd "$(dirname "$0")/.." && pwd)"
PASS=0; FAIL=0
ok() { PASS=$((PASS+1)); echo "OK   $1"; }
ko() { FAIL=$((FAIL+1)); echo "FAIL $1"; }
RIS=$(cd "$HERE" && git -c core.quotePath=false ls-files -z '*.md' | python3 -c '
import re, sys
fuori = ("SAL.md", "SAL-ARCHIVIO.md", "docs/giri/", "docs/campo/", "docs/errori/", "docs/studi/", "graphify-out/",
         ".claude/skills/graphify/", ".opencode/skills/graphify/")
for f in filter(None, sys.stdin.read().split("\0")):
    if f.startswith(fuori): continue
    dentro = False; lingua = ""
    for n, l in enumerate(open(f, encoding="utf-8", errors="ignore"), 1):
        m = re.match(r"^\s*```(\w*)", l)
        if m:
            dentro, lingua = (not dentro), m.group(1)
            continue
        if not dentro or lingua not in ("", "bash", "sh", "zsh", "shell", "console"): continue
        t = re.sub(r"\x27[^\x27]*\x27|\"[^\"]*\"", "", l)
        if re.match(r"^\s*#", t) or re.search(r"\s#\s", t): print(f"COMMENTO {f}:{n}: {l.strip()[:90]}")
        if re.search(r"(-b|checkout -b|switch -c)\s+(fix|feature|feat|hotfix)/", l): print(f"RAMO {f}:{n}: {l.strip()[:90]}")
')
C=$(grep -c '^COMMENTO' <<<"$RIS"); R=$(grep -c '^RAMO' <<<"$RIS")
[ "$C" -eq 0 ] && ok "nessun commento in riga nei blocchi da incollare" || ko "$C righe con un commento in riga (zsh senza interactive_comments le legge come testo):"$'\n'"$(grep '^COMMENTO' <<<"$RIS")"
[ "$R" -eq 0 ] && ok "nessun ramo fuori convenzione insegnato in un blocco (CLAUDE.md §4: night/, claude/, glm/)" || ko "$R rami che nessun giudice vede:"$'\n'"$(grep '^RAMO' <<<"$RIS")"
# (S1 R6): i blocchi che uno STRUMENTO scrive in un rapporto. Il morning-gate apriva il blocco dentro una citazione
# (`> ```bash`) e lo chiudeva fuori: in CommonMark il blocco finisce con la citazione, il comando usciva dal blocco
# e il resto del rapporto ci finiva dentro.
Q=$(grep -nE 'echo "> \\`\\`\\`' "$HERE"/night-shift/*.sh "$HERE"/tools/*.sh 2>/dev/null || true)
[ -z "$Q" ] && ok "nessun blocco di codice aperto dentro una citazione nei rapporti degli strumenti" || ko "blocco aperto in una citazione:"$'\n'"$Q"
echo ""
echo "$PASS OK, $FAIL FAIL"
[ $FAIL -eq 0 ]
