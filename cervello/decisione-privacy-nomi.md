---
tipo: decisione
data: 2026-09-21
titolo: Public repo, private work
---
Decisione di Luca: i nomi delle persone possono comparire, l'ACCESSO no.
- ~/.privacy-nomi contiene i nomi da non scrivere (il check li cerca)
- repos.key solo per segreti e persone
- clasp push MAI: l'hook blocca clasp push/deploy anche dentro npm run
  (risolve package.json scripts per non farsi bypassare)

Il confine e' l'accesso (credenziali, codice privato), non la cortesia dei
nomi. Un repo pubblico che racconta il sistema senza aprire le porte.

Aggiornamento (2026-09-24, R1 R2 del quinto ventaglio): sui nomi delle PERSONE la memoria dice due
cose. Questa nota dice che possono comparire; [[decisione-dominio-2026-09-23]] (punto 7) mette le
persone nella lista dei nomi da non scrivere. La domanda e' aperta in DEBITI.md (T5#4): qui non si
decide.

Aggiornamento (2026-09-29, Luca: «risolvi nel miglior modo»): il modello NER (rizzo-pii)
marchiava il nome del proprietario nei documenti come FULLNAME, e il cancello GDPR della
notte diventava rosso ogni notte — un rosso permanente insegna a ignorare i rossi. La
sintesi delle tre strade (esenzione cieca di docs/bc / allowlist / cancellazione) e':
**l'amnistia dichiarata del proprietario** — `~/.privacy-amnistia`, un nome per riga,
permessi 600, stessa famiglia di `~/.privacy-nomi`. Il nome resta nel documento, il
cancello lo conosce; ogni ALTRO nome e ogni altra categoria sensibile restano rossi.
Amnistia dichiarata, non oblio: il conteggio lo dice ogni corsa. Banco:
tests/test-privacy.sh (casi amnistia).

Postilla della stessa mattina (E-053): l'amnistia del proprietario da sola non bastava — il
modello proponeva PII senza forma (un decimale come carta, '1.0.0.134' come IP, i conti
'UTILI-M' come nomi) e il corpus pubblicato veniva ri-giudicato ogni notte. Il blocco NER ora
vive di quattro regole: il modello propone, la forma decide (veto sulle categorie con forma
canonica); i FULLNAME tutto-maiuscolo-con-cifre sono codici; l'amnistia del proprietario per
i nomi veri; e il tripwire scatta solo su cio' che ENTRA (staged) — il corpus docs/bc
pubblicato non si ri-giudica. Prove: IBAN di forma vera in staging → rosso; albero pulito →
verde col server vero. Banco: test-privacy 34/0.
