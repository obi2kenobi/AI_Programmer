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
# Due modalità:
#   genera-agenti.sh                 → HUB: proietta TUTTI i ruoli nei mirror dell'hub
#   genera-agenti.sh --controlla     → HUB, a secco: esce 1 se i mirror deriverebbero
#   genera-agenti.sh --repo <dir>    → SATELLITE: proietta SOLO i ruoli attivi del repo
#                                      (.git/ruoli-attivi) dentro <dir>/.claude/agents/
#                                      e <dir>/.opencode/agent/. I file generati portano
#                                      un marcatore: si aggiungono, si sostituiscono e
#                                      si tolgono SOLO quelli col marcatore — un agente
#                                      scritto a mano nel satellite resta intatto.
#                                      (2026-10-04, giro 2: col cervello centrale il
#                                      satellite non copia gli agenti — ma Claude Code
#                                      legge .claude/agents dal repo: senza questa
#                                      proiezione le sessioni di giorno nei satelliti
#                                      restano senza specialisti di dominio.)
#
# bash 3.2 (macOS): niente case/continue dentro process substitution (E-036).
set -euo pipefail
MODO="${1:-}"
REPO_DIR=""
if [ "$MODO" = "--repo" ]; then
  REPO_DIR="${2:?uso: genera-agenti.sh --repo <dir-repo>}"
  [ -d "$REPO_DIR/.git" ] || { echo "genera-agenti: $REPO_DIR non è un repo git" >&2; exit 1; }
  [ -f "$REPO_DIR/.git/ruoli-attivi" ] || { echo "genera-agenti: $REPO_DIR non dichiara ruoli (.git/ruoli-attivi) — niente da proiettare (rileva-ruoli.sh prima)"; exit 0; }
  cd "$(dirname "$0")/.."
else
  MODO="${MODO:-}"
  cd "$(dirname "$0")/.."
fi
SOLO_CONTROLLA=0
[ "${1:-}" = "--controlla" ] && SOLO_CONTROLLA=1

python3 - "$SOLO_CONTROLLA" "$MODO" "$REPO_DIR" <<'PYGEN'
import glob, os, re, sys
solo_controlla = sys.argv[1] == "1"
modo = sys.argv[2]
repo_dir = sys.argv[3]

MARCATORE = "<!-- GENERATO da tools/genera-agenti.sh da roles/{nome}.md: si cambia roles/ nell'hub, non questo file -->"

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

def emetti(nome, descrizione, edita, corpo, con_marcatore):
    tools = "Read, Grep, Glob, Bash" + (", Edit, Write" if edita == "si" else "")
    if con_marcatore:
        corpo = MARCATORE.format(nome=nome) + "\n\n" + corpo
    claude = f"---\nname: {nome}\ndescription: {descrizione}\ntools: {tools}\n---\n\n{corpo}"
    perm_edit = "allow" if edita == "si" else "deny"
    opencode = (f"---\ndescription: {descrizione}\nmode: subagent\npermission:\n"
                f"  edit: {perm_edit}\n  bash: allow\n  webfetch: deny\n---\n\n{corpo}")
    return claude, opencode

if modo == "--repo":
    # SATELLITE: solo i ruoli attivi dichiarati dal repo, con marcatore.
    attivi = []
    for riga in open(os.path.join(repo_dir, ".git/ruoli-attivi")).read().splitlines():
        r = riga.strip()
        if r and not r.startswith("#") and r in ruoli:
            attivi.append(r)
        elif r and not r.startswith("#") and r not in ruoli:
            print(f"ATTENZIONE: ruolo '{r}' dichiarato ma assente in roles/ — saltato", file=sys.stderr)
    n_scritti = 0
    for nome in attivi:
        descrizione, edita, corpo = ruoli[nome]
        claude, opencode = emetti(nome, descrizione, edita, corpo, con_marcatore=True)
        scrivi(os.path.join(repo_dir, ".claude/agents", f"{nome}.md"), claude)
        scrivi(os.path.join(repo_dir, ".opencode/agent", f"{nome}.md"), opencode)
        n_scritti += 1
    # i generati disattivati si tolgono (SOLO quelli col marcatore: il manuale resta)
    for patterns in (os.path.join(repo_dir, ".claude/agents", "*.md"),
                     os.path.join(repo_dir, ".opencode/agent", "*.md")):
        for f in glob.glob(patterns):
            nome = os.path.basename(f)[:-3]
            if nome in attivi:
                continue
            if os.path.basename(f) == "README.md":
                continue
            try:
                s = open(f).read()
            except OSError:
                continue
            if MARCATORE.format(nome=nome) in s:
                os.remove(f)
                print(f"rimosso (ruolo non piu' attivo): {f}")
    print(f"genera-agenti --repo: {n_scritti} ruoli attivi proiettati in {repo_dir}")
    sys.exit(0)

# HUB: tutti i ruoli, senza marcatore (i mirror dell'hub sono la copia di lavoro)
rc = 0
for nome, (descrizione, edita, corpo) in sorted(ruoli.items()):
    claude, opencode = emetti(nome, descrizione, edita, corpo, con_marcatore=False)
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
