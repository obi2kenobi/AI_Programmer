# Registro degli incidenti esterni rovesciati

> Ogni incidente documentato è un giro di revisione gratuito sul nostro sistema.
> La mappa: causa → nostro equivalente → guardia (che c'era già, o che abbiamo
> costruito). Il registro NON duplica i pattern: punta a loro. Fonte primaria
> = documentato; fonte di terzi = raccontato (dichiarato, non nascosto).

## IE-001 OpenAI/HuggingFace — agenti isolati che si autoorganizzano (2026-08, processato 2026-08-31)
- **Fonte**: post ufficiale OpenAI + report tecnico + audit indipendenti (documentato; portato da Luca via video)
- **Causa 1** message board non autorizzata → la staffetta → **pattern `la-staffetta`** (NUOVO)
- **Causa 2** reward hacking → il teatro verde → **mutation-tests** (c'era già: l'incidente lo ha NOMINATO)
- **Causa 3** task impossibile senza uscita → agente che non si arrende → **«tre tentativi poi architettura»** + rilevatore anti-loop (c'era già, il perché profondo scritto ora)
- **Causa 4** scoperta tarda (settimane) → gate muto / notti perse → **turno-vivo + E-015/E-017** (c'era già)
- Vedi: docs/campo/2026-08-31-video-openai-hf-lezioni.md

## IE-002 Knight Capital — $440M in 45 minuti (2012-08-01, processato 2026-08-31)
- **Fonte**: post-mortem SEC + analisi tecniche (documentato)
- **Causa 1** deploy manuale incompleto: 7 server su 8 aggiornati, nessuna verifica
  → il nostro deploy è dell'umano (`clasp push` MAI da agente) e il turno notturno
  lavora su cloni → **regola clasp + fork-stato** (c'era già: l'incidente dice perché
  la regola del deploy-umano esiste — un deploy parziale è più pericoloso di nessun deploy)
- **Causa 2** codice morto riattivato da un flag riusato (POWER_TEST → RLP)
  → il nostro equivalente: funzioni/flag legacy nel parco GAS, l'indice pattern che
  punta a file inesistenti → **S7 registro↔file + sonde S10** (c'era già)
- **Causa 3** errore scambiato per successo: ripetevano il deploy vecchio pensando
  fosse il fix; 97 alert ignorati → l'equivalente nostro: il verde che mente
  (teatro verde) e gli alert che nessuno guarda (gate muto) → **mutation-tests +
  turno-vivo** (c'era già; l'incidente conferma la famiglia su scala industriale)
- **Lezione NUOVA da incassare**: il kill switch. Knight non lo premette per 45 min.
  Il nostro kill switch è `pkill -f "opencode run"` — usato a mano dopo 3 notti perse.
  Serve il kill switch AUTOMATICO: la decisione watchdog di Luca in DEBITI è ESATTAMENTE
  questa. L'incidente Knight la chiama per nome: la esitazione del kill switch costa
  $440M — la nostra è costata 3 notti. **La decisione merita l'urgenza.**

## IE-003 GitLab — 300GB cancellati, backup che non c'erano (2017-01-31, processato 2026-08-31)
- **Fonte**: post-mortem ufficiale GitLab (documentato, trasparente al punto da
  trasmettere il recovery in livestream — il post-mortem come atto di metodo)
- **Causa 1** comando distruttivo sul primario invece della replica, in un giorno
  stanco, senza conferma → il nostro equivalente: lo STANDARD vieta la scrittura
  su gas-src (specchio in sola lettura) e clasp push → **regola clasp + .night-mirror** (c'era già)
- **Causa 2** CINQUE backup, nessuno provato con un ripristino → il nostro equivalente:
  il backup esiste (backup-config.sh → gist) ma **nessun test prova il RIPRISTINO**
  → **BUCO**: aggiungere a test-backup-config il caso «il backup contiene ciò che
  serve e il ripristino è eseguibile» — l'operazione è costata a GitLab 6 ore di dati
- **Causa 3** l'unica copia buona era un pg_dump FATTO A MANO da una persona 6 ore prima
  → la lezione positiva: la copia informale di chi sta lavorando ha salvato GitLab;
  il nostro equivalente: i report di campo e SAL sono le copie informali che salvano
  le lezioni → **campo-triage + sal-archivia** (c'era già; l'incidente lo nomina: la
  copia viva fatta da chi lavora vale più del sistema formale rotto)

## Copertura verificata

| Famiglia di causa (senza dettagli) | Incidenti | Nostra guardia |
|---|---|---|
| Deploy parziale/manuale senza verifica | Knight | regola clasp-umano + fork-stato |
| Backup non provato col ripristino | GitLab | **BUCO → chiudere** |
| Kill switch esitato | Knight | decisione watchdog in DEBITI (da accelerare) |
| Codice morto che si riattiva | Knight | S7 + S10 (link morti) |
| Il verde che mente / errori scambiati per fix | Knight, OpenAI | mutation-tests |
| Comunicazione occulta fra agenti | OpenAI | pattern la-staffetta (canali dichiarati) |
| Task senza uscita → barare | OpenAI | tre-tentativi + anti-loop |
| Scoperta tarda | OpenAI, Knight (97 alert) | turno-vivo, battito |
| Copia informale che salva | GitLab | campo + SAL |

## Il metodo in una riga

Ogni incidente altrui è un banco gratuito: si carica il nostro sistema, si guarda
se regge, e ciò che non regge si costruisce — prima che l'incidente lo dimostri da solo.
