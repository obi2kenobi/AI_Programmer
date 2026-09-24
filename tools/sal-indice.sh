#!/bin/bash
# sal-indice.sh — l'indice del SAL (giro 5/10): il diario cresce senza limite, chi
# arriva deve poter NAVIGARE. Rigenera la tabella dei contenuti dopo l'header fisso.
# ⚠ QUESTO TOOL SCRIVE: rigenera la tabella dei contenuti dentro SAL.md, e dentro SAL-ARCHIVIO.md se c'e'
# (2026-09-24, quinto ventaglio, R1 R5: l'indice dell'archivio, copiato alla separazione, non lo rigenerava
# nessuno — 30 link su 167 puntavano a voci rimaste nel diario).
set -euo pipefail
HERE="$(cd "$(dirname "$0")/.." && pwd)"
SAL="$HERE/SAL.md"
[ -f "$SAL" ] || { echo "SAL.md non trovato"; exit 1; }
FILE=("$SAL"); [ -f "$HERE/SAL-ARCHIVIO.md" ] && FILE+=("$HERE/SAL-ARCHIVIO.md")

for F in "${FILE[@]}"; do
python3 - "$F" <<'PY'
import io, os, re, sys

path = sys.argv[1]
with io.open(path, encoding="utf-8") as f:
    sal = f.read()

def slug(v):
    """L'ancora che GitHub da' al titolo. (2026-09-24, quinto ventaglio, R1 R4): era
    `re.sub(r'[^\w-]+', '-', …)` — ogni gruppo di non-parola diventava UN trattino, GitHub invece toglie la
    punteggiatura e fa di OGNI spazio un trattino, senza fondere: «(8) — l'hub: n.2» e' «8--lhub-n2». Sul
    diario vero 146 link su 146 non combaciavano. Le lettere accentate restano (\w e' Unicode: revisione
    14 lenti, 2026-08-28). ASSUNTO dichiarato: l'algoritmo e' quello di github-slugger, non provato contro
    github.com da una sessione che non lo raggiunge."""
    return re.sub(r"[^\w\- ]", "", v.lower()).replace(" ", "-")

# i titoli uguali prendono -1, -2 nell'ordine del documento, contando TUTTI i livelli (come GitHub)
visti, ancore_voci = {}, []
for livello, h in re.findall(r'^(#{1,6}) (.+?)\s*$', sal, flags=re.M):
    b = slug(h); n = visti.get(b, 0); visti[b] = n + 1
    if livello == "###":
        ancore_voci.append(b if n == 0 else f"{b}-{n}")

# (giro 25, 2026-09-20 — D38): era `.{1,130}` — un titolo piu' lungo di 130 caratteri
# spariva dall'indice IN SILENZIO, la sonda S16 diceva «indice FERMO» e l'antivirus dei
# rilevatori accusava la sonda. L'indice e' una mappa: tutte le stanze; il titolo lungo
# si segnala su stderr, non si scarta.
voci = re.findall(r'^### (.+?)\s*$', sal, flags=re.M)
if not voci:
    print("nessuna voce ### trovata"); sys.exit(0)
for v in voci:
    if len(v) > 130:
        print(f"sal-indice: titolo lungo ({len(v)} caratteri, il canone ne vuole <=130 — indicizzato comunque): {v[:60]}...", file=sys.stderr)

indice = ["<!-- SAL-INDICE: generato da tools/sal-indice.sh — non editare a mano -->", "## Indice del diario", ""]
for v, a in zip(voci, ancore_voci):
    indice.append(f"- [{v}](#{a})")
indice.append("")

blocco = "\n".join(indice)
if "<!-- SAL-INDICE" in sal:
    sal = re.sub(r'<!-- SAL-INDICE[\s\S]*?-->\n## Indice del diario\n(?:.*\n)*?(?=\n#|\n## [^I]|\Z)', blocco + "\n", sal, count=1)
    # fallback semplice: sostituzione dall marker al primo ## successivo non-Indice
else:
    # inserisce dopo il primo blocco di intestazione (dopo la prima riga vuota seguente il titolo)
    parti = sal.split("\n\n", 2)
    if len(parti) >= 3:
        sal = parti[0] + "\n\n" + parti[1] + "\n\n" + blocco + "\n" + parti[2]
    else:
        sal = sal + "\n" + blocco

with io.open(path, "w", encoding="utf-8") as f:
    f.write(sal)
print(f"indice rigenerato: {len(voci)} voci" + ("" if os.path.basename(path) == "SAL.md" else f" ({os.path.basename(path)})"))
PY
done
