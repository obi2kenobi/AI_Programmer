# 2026-09-30 — punto sui due repo gemelli, poi EDIL in SD (sonde e passo 1a)
**Autore**: sessione Claude Code (claude/charming-bohr-lceeat), con Luca

## Cosa ho usato
Apertura: `tools/debiti-riapertura.sh` (hub), `add_repo` e clone dei due repo, lettura di PROJECT.md, SAL, DEBITI,
docs/campo, issue e PR. Poi, su Registrazione_Fatture_Acquisto: skill `gas-sviluppo` (caricata dopo il promemoria
dell'hook), tre sonde di sola lettura sull'EDIL (S1 esistente, S2 e S3 scritte da me, lanciate da Luca), `test_fase2`
con sabotaggi e il gate `.night-verify` riga per riga, il passo 1a (`ControlloEdil.gs`) e il README §42.10-§42.11.
PR di Registrazione: #234, #235, #236 (mergiate), #238 (aperta); sulla #237, di un'altra sessione, ho solo unito
`main` per risolvere il conflitto. Non ho usato il grafo (graphify assente, navigazione a grep).

## Cosa ho improvvisato
Il metodo non dice come trattare una risposta dell'ufficio che arriva dentro la PR di un'altra sessione: l'ho
trovata solo quando Luca mi ha dato il link (non era su `main` né su nessun ramo che avessi scaricato).
Le sonde per l'EDIL le ho progettate copiando la forma di quelle della BIOC (§40.1), non da una ricetta scritta.

## Cosa ha retto / ostacolato
Ha retto: sonde di sola lettura prima delle regole. S2 ha mostrato che l'ordine diviso è la forma normale
dell'EDIL, S3 ha risposto a «come abbassa l'importo» (sconto di riga, non costo). Il banco con i sabotaggi ha
dichiarato otto cascate vecchie sui casi nuovi invece di lasciarle cadere in silenzio.
Ostacolato: il **mio errore**: ho posto a Luca una domanda di dominio («cosa fare se il totale differisce?») prima
di aver misurato; Luca mi ha corretto («indaghiamo con sonde, come per la BIOC»). Inoltre più sessioni aggiungono
sezioni in coda allo stesso README: #236, #237 e #238 si sono contese la fine del file (conflitto sulla #237,
testo finito nella sezione sbagliata).

## Proposta al canone
1. Le domande di dominio si fanno DOPO la sonda e portano i numeri misurati (la regola «le domande prima del
   codice» non deve diventare «le domande prima della misura»).
2. Un README a sezioni numerate scritto da più sessioni: chi aggiunge inserisce prima dell'ultima intestazione o
   in una sezione propria, mai in fondo al file, perché due PR che appendono si bloccano a vicenda.
3. Portare `debiti-riapertura.sh` anche nei repo gemelli (oggi il settimo patto lì non è eseguibile; il conteggio
   dei debiti di Magazzino_Treviso è stato fatto a grep, quindi è una stima).
