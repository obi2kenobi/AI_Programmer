# Settimo ventaglio — consolidamento (2026-09-25)

Brief: `docs/giri/2026-09-25-settimo/00-BRIEF.md`. Cinque lenti, un giro ciascuna, ognuno in un clone:
- V1: due giudici, due regole;
- V2: il codice d'uscita lungo la catena;
- V3: il calendario;
- V4: la lingua e la codifica;
- V5: il budget della suite.

I rapporti grezzi sono in `grezzi/`, ignorata da git (skill n-giri §2). Dettagli di ogni cura nel SAL, voce 18°,
righe «Settimo ventaglio».

## Esito

- **29 rilievi**: V1 6, V2 5, V3 6, V4 6, V5 6. Sono provati eseguendo, tranne dove il giro ha dichiarato «per
  lettura»: il Mac (la bash 3.2 che legge «» come parte del nome, il `tr` e il `sed` BSD), launchd.
- **Curati**: 26. Di questi, 2 sono solo in parte:
  - V4 R2: privacy-check sì, i dieci banchi col locale `en_US.UTF-8` a nome fisso no;
  - V4 R6: i motivi del censore sì, gli altri `cut -c` e `head -c` no.

  Ogni cura ha il suo banco rosso prima e il sabotaggio rosso dopo. Fa eccezione V5 R1, che è un costo e non un
  difetto: la prova è la misura (184 → 141 s) e l'uguaglianza delle 66 coppie, anche con la bash 3.2.57.
- **Rinviati** (con la domanda in DEBITI): V3 R5 (gli orologi del censore), V5 R4 (la batteria completa ogni notte),
  V5 R6 (le attese fisse dentro gli strumenti: ogni manopola di test è superficie in più).
- **Domande nuove in DEBITI**: 11. V1 R1 (`docs/bc/` e i nomi), D-V5-1 (il segno di un pass fallito), V2 D2 (dove
  sta node), V2 D1 (chi decide «sano»), D-V3-2 (un pass oltre 24 ore), D-V3-1 (l'età del report del gate), D-V3-3
  (il segnale «incastrato»), V4 D4 (la codifica degli export), D-V3-4 (il budget del censore), D-V5-2 (le mutazioni
  ogni notte), D-V5-3 (il budget `@540`). Dove la cura ha dovuto scegliere, la scelta provvisoria è dichiarata nella
  domanda.
- **Scoperte fuori dai rilievi**, venute dalle cure:
  - l'attacco A20 della batteria non aveva mai visto niente: la sua pianta non era una forma di segreto, e l'rc del
    gate degradato lo nascondeva (V5 R3);
  - il controllo delle citazioni del pre-commit passava a `grep` un nome col trattino come opzione (sesto ventaglio,
    trovato scrivendo il SAL);
  - `gate_banchi` contava verde un banco muto, che la suite rifiutava (in apertura).
- **Smentite**: una, in parte. V4 R1 non si riproduce qui nemmeno con la bash 3.2.57 compilata (glibc non classifica
  0xC2 come lettera). Il difetto resta quello visto sul Mac il 10/9; le graffe e la sonda valgono comunque.
- **Suite**: 191/191 all'ultima consegna, con cinque banchi nuovi:
  - `tests/test-grafo-semantico.sh`;
  - `tests/test-caccia-smistamento.sh`;
  - `tests/test-impara-recupero.sh`;
  - `tests/test-trattino-iniziale.sh` (dai rinviati del sesto);
  - la sonda dei caratteri non ASCII e quella di `$(NOME)` in `tests/test-portabilita.sh`.

## Temi trasversali

1. **Una regola, due copie, due verdetti** (V1, V4, V5). Casi:
   - la suite e `gate_banchi` sul banco muto;
   - il pre-commit e privacy-check sulla lista dei nomi (l'ultima riga, il «#»), sul locale, su `docs/bc/`;
   - il rilevatore delle forme e la maschera;
   - il turno, il censore e il gate sulle righe vuote di `.night-verify`;
   - il gate e il censore sul formato script.

   Cura comune: la regola in una funzione sola (`nomi_locali`, `riga_verifica_vuota`, `impronta_righe`,
   `prudente_nega`), citata da chi la usa.
2. **Il verdetto che non arriva a chi decide** (V2, V5). Casi:
   - l'rc dello strumento che la caccia buttava;
   - «sana» come ramo di default;
   - il 137 del ramo GNU di `ai_timeout`;
   - `node` assente letto come «codice rotto»;
   - l'rc di privacy-check letto come verdetto da due attacchi.
3. **L'orologio ingenuo** (V3). Casi:
   - tre `date` a fine pass contro una all'avvio;
   - due ore locali sottratte al cambio dell'ora;
   - un lock tolto a 24 ore col padrone vivo;
   - un report di un mese allegato come di oggi;
   - una lezione che salta se nessun ciclo parte dopo le 22.
4. **Il byte scambiato per un carattere** (V4). Casi: `${#}` e `cut -c` che contano byte secondo il locale, `tr` che
   fa a pezzi le vocali accentate, un export Windows-1252.

## Tassonomia

**Implementata**
- V1: R1 (una lettura della lista), R2 (impronta nello strato 1), R3 (il cancello sul quinto push), R4 (il gate
  esegue le prove di main), R5 (`riga_verifica_vuota`), R6 (gli stessi banchi della suite).
- V2: R1 (il deterministico è il pavimento, provvisorio), R2 (niente «sana» di default), R3 (`MANCA node`,
  `verdetto_verifica`), R4 (124 allo scadere), R5 (`${MIGLIOREA_DURATA}`).
- V3: R1 (report fresco, sospesi datati), R2 (`GRAFO_DATA`), R3 (il PID vivo tiene il lock), R4 (età in epoch),
  R6 (la lezione di ieri si recupera).
- V4: R1 (graffe, sonda, `prudente_nega`), R2 (in parte), R3 (caratteri in python), R4 (CSV non UTF-8 dichiarato),
  R5 (slug in python), R6 (in parte).
- V5: R1 (espansioni di bash), R2 (STOP al padre, E-049), R3 (A20 e G4 leggono il verdetto), R5 (attese
  condizionate).

**Esclusa**
- Nessuna.

**Rinviata**
- V3 R5, V5 R4, V5 R6 (sopra); V4 R2 per i dieci banchi, V4 R6 per gli altri tagli a byte.

**Già coperta**
- Nessuna.

## Da fare a mano (non potevo)

- Invariato dal sesto ventaglio: `rm -f /CLAUDE.md /claude-satellite.md` nel container; i `mutation-backup.*` orfani in
  `/tmp`.

## Errori miei in questo ventaglio

- **E-049** (nel REGISTRO, con guardia): il mio banco del grafo del sesto ventaglio era rosso a caso; uccidevo i figli
  prima del padre.
- Il commit `7e426c9` porta il tipo `perf`, che CLAUDE.md §4 non prevede. Non ho riscritto la storia pushata.
- Prime stesure prese dai banchi o dai rilevatori prima del commit:
  - due casi inseriti fra una prova e la sua verifica sullo stesso `$OUT` (lente, risolutore);
  - il caso d'autunno di `turno-vivo` con l'«adesso» un'ora avanti;
  - tre `$NOME` davanti a «» in un banco nuovo, presi dalla sonda nata stanotte;
  - il prefisso telefonico intero in un letterale di banco, preso dal pre-commit;
  - un `sed` col delimitatore `#` dentro il testo, fallito senza toccare il file.
- Una mia nota nel SAL diceva «muto con rc 0» di un banco che la suite avrebbe preso: corretta come errore mio.
- Il riavvio del processo ha ucciso una misura della suite a metà (rc 137): rifatta staccata.
