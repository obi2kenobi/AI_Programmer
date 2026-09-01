# 2026-09-01 — REPO-K, terza sessione: 3 giri extra, la scoperta che clasp push non basta

Autore: sessione Claude Code (terza sessione sullo stesso repo, git history continua)

## Cosa ho usato
Stesso metodo a lenti concordato con l'utente. Richiesta esplicita: "rieseguire tutto il
controllo su tutto il codice con tutte le lenti possibili, una volta eseguito riesegui le
correzioni e riesegui il loop altre due volte" — tre cicli completi, ciascuno chiuso con
una PR propria. Il trucco FIFO + run_in_background nativo per clasp login (proposto nella
sessione precedente dopo un fallimento): usato due volte qui, andato liscio entrambe —
prima conferma che il fix regge oltre il caso che lo ha originato.

## Cosa ho improvvisato
- **"Cerca lenti nuove, non rigirare le stesse"**: alla terza richiesta dello stesso giro,
  il rischio era manifatturare rilievi. Per ogni ciclo ho tenuto l'elenco di lenti/file già
  coperti e cercato deliberatamente angoli non battuti. Risultato onesto: i rilievi si sono
  ridotti in numero e gravità ciclo dopo ciclo — dichiarato così nelle PR, non gonfiato.
- **LA SCOPERTA**: l'utente ha chiesto di verificare che la dashboard "live" funzionasse
  dopo clasp push. Il fetch reale dell'URL ha rivelato che clasp push aggiorna SOLO i
  sorgenti — non l'URL di produzione, se questo punta a un deployment VERSIONATO invece
  che @HEAD. Nessun segnale d'errore nel comando: il push "riuscito" lascia gli utenti
  sulla versione vecchia. Ho dovuto: (1) dedurre quale deployment fosse produzione dal
  pattern di naming (il solo con nome non generico, numerazione progressiva); (2) creare
  una nuova versione con clasp deploy -i <id>; (3) verificare con curl che l'HTML contenesse
  marcatori specifici del codice appena pushato (un id introdotto, l'assenza di una variabile
  rimossa) — non un fetch generico.
- **PR stacked quando la base viene mergiata prima**: ririgirate le PR aperte verso il
  branch bersaglio reale (verificando con merge-base --is-ancestor che il contenuto fosse
  già incluso).

## Cosa ha retto / ostacolato
- Ha retto: un ciclo/una PR/un riepilogo onesto — il calo di rendimento visibile al posto
  di nascosto. Il primo ciclo extra trovava ancora un bug funzionale vero (cache non
  invalidata dopo "aggiorna" manuale, con la sorella-funzione che invece lo faceva), l'ultimo
  soprattutto codice morto. Nessun rilievo manifatturato.
- Ha ostacolato: "il codice è in produzione dopo clasp push" è FALSO per qualunque progetto
  con deployment versionato — e clasp push non dà nessun segnale. Un push "riuscito" e un
  utente che chiede "controlla che sia live" sono l'occasione in cui emerge, ma solo se
  qualcuno lo controlla DAVVERO.

## Proposta al canone
**Pattern: clasp push non è "andare in produzione"** — verificalo, non presumerlo. Per
qualunque progetto Apps Script servito come web app: clasp push aggiorna solo i sorgenti;
l'URL pubblico dipende da QUALE deployment è collegato. Se esiste un deployment versionato
con numerazione progressiva, quello è la produzione reale e va aggiornato con clasp deploy
-i <deploymentId>. La verifica corretta di "è live": un fetch dell'URL /exec che cerchi un
marcatore specifico del codice appena cambiato — non un HTTP 200 generico.
