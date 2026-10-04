# 2026-10-04 — sito delle NC (6 fasi + integrazione) e giri di correzione su due repo
**Autore**: sessione Claude (Sonnet 5.5) per Luca — sessioni Magazzino_Treviso e Registrazione_Fatture_Acquisto

## Cosa ho usato
Agenti `sviluppatore-gas` (6 fasi del sito + integrazione + gruppi di correzione), `revisore-gas` (31 giri di lettura in sola lettura), `Explore` (censimento delle giunture fra i due repo); skill `n-giri` (brief unico, rapporti scritti prima di rispondere in `docs/giri/…/grezzi/` ignorata da git, tetto di 6 finding, «nulla in questa lente» ammesso). Ho voluto usare `tools/verifica_banco.py` come meccanismo del gate di Registrazione: **non c'era** nel repo (il gate leggeva solo il codice di uscita) e l'agente l'ha dovuto scrivere.

## Cosa ho improvvisato
- **Una PR sola verso `main` per ogni catena**: ho scoperto che le PR impilate (#356–#371 di Registrazione) erano state unite ognuna nel ramo della precedente, e solo la #355 era in `main`. Il lavoro di 16 giri non era in `main`. Ho aperto la #372 con tutta la catena; per Treviso ho aperto un ramo di integrazione unico (#195). Regola proposta sotto.
- Il «cinquanta giri» non è un numero sacro: 16 giri per repo (aree × lenti distinte, scarto dichiarato nel brief).
- Il contratto fra i due repo non esisteva: `CONFERME` e `Fatture` sono letti per NOME da Registrazione e per POSIZIONE da Treviso, con ID di fogli in due posti. Ho fatto fare un censimento delle giunture (file di lavoro, non versionato) e deciso `contratto-giunture.json` con un banco per repo (gruppo G6, non ancora fatto).

## Cosa ha retto / ostacolato
- **Ha retto:** i rapporti scritti prima di rispondere (nessuno perso quando due volte il limite di sessione ha fermato gli agenti); il cancello rilanciato da me dopo ogni consegna (ha sempre coincidenza col dichiarato, ed ha trovato che un gate verde non leggeva le attese); «banco prima della correzione» (il rosso iniziale ha smentito un rilievo e corretto la stima di un sabotaggio).
- **Ostacolato:** il limite di sessione (429) ha interrotto 2+2 agenti: si riprendono con `SendMessage` ma costano un giro; lo scratchpad condiviso fra agenti paralleli (un agente ha riscritto un file di un altro); il rapporto grezzo citava un file inesistente e ha reso rossa la lente `test-citazioni-vere` (la lente scandisce anche file ignorati da git).

## Proposta al canone
1. **Catena di PR impilate: una sola PR finale verso `main`** (o ramo di integrazione), mai unioni a cascata; il controllo è `git merge-base --is-ancestor <ultimo commit> origin/main` dopo l'ultima unione.
2. Il gate deve esigere la riga-verdetto `attese eseguite: N/M · fallite: 0` per ogni banco (non solo il codice di uscita) e dichiarare come DEGRADATO, non verde, un salto di banchi (es. `playwright-core` assente).
3. Le lenti che citano file (`test-citazioni-vere`) devono scandire solo i file tracciati (`git ls-files`).
4. Brief `n-giri`: aggiungere la riga «agenti paralleli: nome dei file di lavoro con prefisso del giro» (lo scratchpad è condiviso).
