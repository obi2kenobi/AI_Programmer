#!/bin/bash
# sal-indice.sh — l'indice del SAL (giro 5/10): il diario cresce senza limite, chi
# arriva deve poter NAVIGARE. Rigenera la tabella dei contenuti dopo l'header fisso.
set -euo pipefail
HERE="$(cd "$(dirname "$0")/.." && pwd)"
SAL="$HERE/SAL.md"
[ -f "$SAL" ] || { echo "SAL.md non trovato"; exit 1; }

python3 - "$SAL" <<'PY'
import io, re, sys

path = sys.argv[1]
with io.open(path, encoding="utf-8") as f:
    sal = f.read()

voci = re.findall(r'^### (.{1,130})$', sal, flags=re.M)
if not voci:
    print("nessuna voce ### trovata"); sys.exit(0)

indice = ["<!-- SAL-INDICE: generato da tools/sal-indice.sh — non editare a mano -->", "## Indice del diario", ""]
for v in voci:
    anchor = re.sub(r'[^a-z0-9]+', '-', v.lower()).strip('-')
    indice.append(f"- [{v}](#{anchor})")
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
print(f"indice rigenerato: {len(voci)} voci")
PY
