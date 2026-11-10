# bsd-sed-niente-interrogativo
**Àncora**: tools/giorno.sh (slug GitHub) · **Nato**: 2026-10-10 (R4 della Vetrina, due morsi)
Il sed di macOS (BSD) NON supporta `\?` nel BRE: `s#…\(\.git\)\?$##` matcha mai — il gruppo opzionale è un `?` letterale. Il nostro slug GitHub restava VUOTO in silenzio: le annotazioni saltavano senza dirlo (20 righe trovate, 0 annotate, preso dal vivo). Il secondo morso era dormiente da stamattina nel comando annota. Cura: mai `\?` nel sed di casa — strip in due tempi (`sed -e 's#prefisso##' -e 's#\.git$##'`), o python quando serve di piu'.

**Vedi anche**: `locale-del-turno` (la stessa famiglia Mac/Linux) · E-002 nel REGISTRO
