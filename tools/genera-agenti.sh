#!/bin/bash
# genera-agenti.sh — genera gli specchietti per harness dai ruoli canonici (roles/).
#
# (2026-10-03, decisione di Luca: «AI_Programmer non è un sistema solo Claude —
# tutto deve essere disponibile a tutti gli LLM, anche i cinesi open-weight».)
# I ruoli vivono UNA volta sola in roles/, formato neutrale. Questo script li
# proietta nei due formati con frontmatter proprietario:
#   .claude/agents/<nome>.md  (name, description, tools)
#   .opencode/agent/<nome>.md (description, mode, permission)
# Gli specchietti sono GENERATI: chi li editinga a mano vede il lavoro
# cancellato al giro dopo (è voluto — la deriva tra copie muore così).
# Idempotente: due giri di fila producono lo stesso albero (banco verde).
#
# Uso: genera-agenti.sh [--controlla]
#   senza flag: genera (e toglie gli specchietti orfani di un ruolo rimosso)
#   --controlla: non scrive nulla, esce 1 se gli specchietti deriverebbero
#
# bash 3.2 (macOS): niente case/continue dentro process substitution (E-036).
set -euo pipefail
cd "$(dirname "$0")/.."
SOLO_CONTROLLA=0
[ "${1:-}" = "--controlla" ] && SOLO_CONTROLLA=1

python3 - "$SOLO_CONTROLLA" <<'PYGEN'
import glob, os, re, sys
solo_controlla = sys.argv[1] == "1"

ruoli = {}
for f in sorted(glob.glob("roles/*.md")):
    base = os.path.basename(f)[:-3]
    if base == "README":
        continue
    s = open(f).read()
    m = re.match(r"^---\n(.*?)\n---\n\n?(.*)$", s, re.S)
    if not m:
        print(f"ATTENZIONE: {f} senza frontmatter valido — saltato", file=sys.stderr)
        continue
    fm, corpo = m.group(1), m.group(2)
    def campo(nome):
        mm = re.search(rf"^{nome}: (.+)$", fm, re.M)
        return mm.group(1) if mm else ""
    nome = campo("nome") or base
    descrizione = campo("descrizione")
    if not descrizione:
        print(f"ATTENZIONE: {f} senza descrizione — saltato", file=sys.stderr)
        continue
    edita = "no" if campo("edita").strip().lower() in ("no", "") else "si"
    ruoli[nome] = (descrizione, edita, corpo.rstrip() + "\n")

def scrivi(percorso, contenuto):
    if solo_controlla:
        if not os.path.exists(percorso) or open(percorso).read() != contenuto:
            print(f"DERIVA: {percorso} differisce da roles/ (o manca) — lancia genera-agenti.sh", file=sys.stderr)
            return 1
        return 0
    os.makedirs(os.path.dirname(percorso), exist_ok=True)
    open(percorso, "w").write(contenuto)
    return 0

rc = 0
for nome, (descrizione, edita, corpo) in sorted(ruoli.items()):
    tools = "Read, Grep, Glob, Bash" + (", Edit, Write" if edita == "si" else "")
    claude = f"---\nname: {nome}\ndescription: {descrizione}\ntools: {tools}\n---\n\n{corpo}"
    perm_edit = "allow" if edita == "si" else "deny"
    opencode = (f"---\ndescription: {descrizione}\nmode: subagent\npermission:\n"
                f"  edit: {perm_edit}\n  bash: allow\n  webfetch: deny\n---\n\n{corpo}")
    rc |= scrivi(f".claude/agents/{nome}.md", claude)
    rc |= scrivi(f".opencode/agent/{nome}.md", opencode)

# specchietti orfani (un ruolo cancellato da roles/ lascia il file nel mirror)
for patterns in ((".claude/agents/*.md",), (".opencode/agent/*.md",)):
    for f in glob.glob(patterns[0]):
        base = os.path.basename(f)[:-3]
        if base not in ruoli:
            if solo_controlla:
                print(f"DERIVA: {f} e' orfano (il ruolo non esiste piu' in roles/) — lancia genera-agenti.sh", file=sys.stderr)
                rc = 1
            else:
                os.remove(f)
                print(f"rimosso orfano: {f}")

if solo_controlla:
    sys.exit(rc)
print(f"genera-agenti: {len(ruoli)} ruoli proiettati in .claude/agents/ e .opencode/agent/")
PYGEN
