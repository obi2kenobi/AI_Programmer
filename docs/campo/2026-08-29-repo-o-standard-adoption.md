# REPO-O/REPO-P — report di stato e adozione dello standard (dal campo 2026-08-29)

## Cosa ho usato
Il metodo per intero su due progetti: revisione a 50 passate + banco avversariale,
caccia con lenti nuove, riga-verdetto prescritta, documenti vivi prima del codice,
charter come decisioni vive (9 idee mappate senza scrivere codice).

## Cosa ho improvvisato
Nulla di sostanziale: le suite di collaudo nate come banco sono diventate il
.night-verify di fatto (da agganciare formalmente).

## Il conto
26 difetti corretti tutti dimostrati al banco prima della correzione; 21+4 commit;
5 suite verdi (89 controlli); schema v7 con scheda Persona e scadenzario generato;
16/16 incroci FK+polimorfi su 38 tabelle; privacy: nomi riservati che uscivano in
Excel e fascicolo — trovati e corretti. Il secondo progetto (rendiconto) fermo al
passo 3 DI PROPOSITO: senza un anno vero di estratti, lettori e quadrature non sono
verificabili (lista materiali sbloccanti nel progetto).

## Le cinque lezioni per l'hub (pagate)
1. Il banco è la memoria eseguibile: ~60 sospetti, 23 promossi dimostrati, 1 smentito.
2. Le fixture degradano con i rilanci: ogni giro autonomo con reset dichiarato.
3. Le guardie si provano col caso reale (commonpath normalizza i ..; i commenti dello
   schema DENTRO i CREATE o sqlite li perde; il metro non contiene il campione).
4. LE FAMIGLIE DI DIFETTI GENERALIZZANO FRA LINGUAGGI: le famiglie misurate sul corpus
   GAS sono ricomparse IDENTICHE in Python/SQLite (normalizzazione int/testo, «non
   letto» vs «vuoto», guardiano cieco, scritture multi-fase senza lock).
5. Charter come decisioni vive: 16 proposte con dentro/fuori/decisione, principio
   «il programma prepara, l'umano invia».

## Le richieste all'hub
(1) Onboarding: sync-repo --standard + repos.conf — fatto per REPO-O (REPO-P quando
arriva su GitHub). (2) Oracolo del rendiconto: serve lo schema ufficiale della
controparte (controllo-gestione + censitore-forma-dati pronti), non nuovi strumenti.
(3) Confine gestionale↔rendiconto: P10 del piano CRM, proposta negli artefatti —
decisione di charter.

## Proposta al canone
La lezione 4 va nel catalogo famiglie: le famiglie sono del PENSIERO sbagliato, non
del linguaggio — cercarle solo nel proprio stack è cercarle male.
