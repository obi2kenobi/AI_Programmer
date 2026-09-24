#!/bin/bash
# test-skill-n-giri.sh — il metodo degli N giri e' una SKILL, non un artefatto da ricostruire
# (decisione di Luca, D9 2026-09-23: «a»). Il debito: nel report Budget Vendite (2026-09-19) il
# metodo «esiste solo come artefatto finito» e la sessione l'ha ricostruito a mano leggendo il
# risultato di agosto. La forma stabile e' nel §7.6 di quel report; le due regole pagate sul campo
# (il giro scrive il file PRIMA di rispondere; la convergenza non e' una conferma) nel §7.7-7.8.
# Qui si presidia che la skill porti OGNI elemento di quella forma — un elemento che manca e' il
# pezzo che la prossima sessione ricostruira' a mano, di nuovo.
set -uo pipefail
HERE="$(cd "$(dirname "$0")/.." && pwd)"
SK="$HERE/.claude/skills/n-giri"
PASS=0; FAIL=0
ok() { PASS=$((PASS+1)); echo "OK   $1"; }
ko() { FAIL=$((FAIL+1)); echo "FAIL $1"; }

[ -f "$SK/SKILL.md" ] && ok "la skill n-giri esiste" || { ko "skill n-giri assente"; echo ""; echo "$PASS OK, $FAIL FAIL"; exit 1; }
TUTTO=$(cat "$SK/SKILL.md" "$SK"/references/*.md 2>/dev/null)
attesa() { # attesa <regex> <cosa>
  grep -qiE "$1" <<<"$TUTTO" && ok "$2" || ko "manca: $2"
}
attesa 'brief (unico|comune)'                          "il brief unico, scritto prima dei giri"
attesa 'file:riga-riga|righe [0-9]+-[0-9]+|range di riga' "le aree ancorate a range di riga"
attesa 'una lente per giro'                            "una lente per giro, un'area per giro"
attesa 'prima di rispondere'                           "il giro scrive il suo file PRIMA di rispondere (§7.7)"
attesa 'nulla in questa lente'                         "«nulla in questa lente» e' un esito valido e dichiarato"
attesa 'Oggi.*Manca.*Proposta'                         "il formato Oggi / Manca / Proposta"
attesa '(tetto|massimo|max)[^.]*6 finding|6 finding per giro' "il tetto di 6 finding per giro"
attesa 'modello (dichiarato|per blocco)'               "il modello dichiarato per blocco"
attesa 'smentit'                                       "la verifica avversariale, con le smentite dichiarate"
attesa 'segnalato da N'                                "due colonne: segnalato da N lenti / verificato eseguendo (§7.8)"
attesa 'verificato eseguendo'                          "la convergenza non promuove mai a verificato"
attesa 'trasversal'                                    "i temi trasversali (>=3 aree indipendenti)"
attesa 'banco prima'                                   "la correzione parte dal banco (rosso prima)"
attesa 'Implementata.*Esclusa.*Rinviata.*coperta'      "la tassonomia a quattro categorie"
attesa 'stessa domanda'                                "la consolidazione delle lenti (stessi file, stessa domanda = una lente)"
attesa 'domande di dominio'                            "le domande di dominio in un file numerato, mai indovinate"
[ -f "$SK/references/brief-modello.md" ] && ok "il modello del brief e' pronto da copiare" || ko "manca references/brief-modello.md"
grep -q 'docs/ngiri-paralleli.md' "$SK/SKILL.md" && ok "rimanda al workflow docs/ngiri-paralleli.md" || ko "non rimanda a docs/ngiri-paralleli.md"
# (2026-09-24, terzo ventaglio, V3#4 — la lezione di E-044): i grezzi nello scratchpad sono spariti con /tmp;
# nel repo, con nomi qualunque (T1.md, B3.md), finirebbero nel commit. La skill dice DOVE: una cartella
# grezzi/ ignorata da git, e di verificarlo con git check-ignore prima di partire.
grep -c 'grezzi/' "$SK/SKILL.md" >/dev/null && grep -c 'git check-ignore' "$SK/SKILL.md" >/dev/null && grep -c 'grezzi/' "$SK/references/brief-modello.md" >/dev/null \
  && ok "la skill (e il brief modello) dicono dove vanno i grezzi e come verificarlo" || ko "la skill non dice dove scrivere i grezzi (E-044)"
(cd "$HERE" && git check-ignore -q docs/giri/qualunque/grezzi/T1.md) && ok "nell'hub docs/giri/*/grezzi/ e' ignorato da git" || ko "docs/giri/*/grezzi/ non ignorato: i grezzi finirebbero nel commit"
diff -rq "$SK" "$HERE/.opencode/skills/n-giri" >/dev/null 2>&1 && ok "specchio OpenCode identico" || ko "specchio .opencode/skills/n-giri assente o divergente"

echo ""
echo "$PASS OK, $FAIL FAIL"
[ $FAIL -eq 0 ]
