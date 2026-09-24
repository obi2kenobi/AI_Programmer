# Consolidamento — la notte dei giri (2026-09-23/24)

Primo ventaglio: 10 aree × 3 lenti (00-BRIEF.md), 29 giri scritti su 30 (A6-L3 mancante,
dichiarato). I file grezzi dei giri NON sono versionati (`docs/giri/*/A*-L*.md` in .gitignore): nella
prima stesura portavano 123 citazioni `file:riga` sbagliate. Qui entra solo ciò che è stato
**verificato eseguendo**: la convergenza fra lenti dice dove guardare, non cosa concludere (skill
n-giri §3). Il dettaglio di ogni cura (banco rosso prima, sabotaggio rosso dopo) è nel SAL, voce 18°.

## Temi trasversali (emersi da soli in 3 o più aree)
1. **Verde senza verdetto.** Uno strumento dà esito 0 senza aver giudicato.
   - Le sonde lette per nome (Q17, A2).
   - py-gate fuori da git, system-health, banco-passaggio, cervello-domanda (Q30, A7).
   - verifica-visiva sulla pagina di login e sulle pagine d'errore di Chrome (Q21, A7).
   - fork-stato senza shasum (Q18, A2).
   - Oracoli su dati vuoti (Q22a, A4).
   - Banchi-copia verdi con la copia vera spenta (Q24, A8).
   - mutation-tests che promuove un banco già rosso (Q32, A3).
2. **E-002 (`… | grep -q` sotto pipefail).**
   - Negli hook: avvisi persi sui comandi lunghi (Q27, A1).
   - Nei banchi, curati dalla caccia (Q31, A9).
   - Nella forma generale: il meta-audit rosso 18 volte su 20 sotto carico (Q31bis).
   - Chiuso alla radice: un rilevatore unico (`tools/e002-siti.py`) e zero siti nel repo.
3. **Liste scritte a mano che divergono.**
   - Tre installatori con tre liste (Q15, A8).
   - L'alfabeto di S9 e il pavimento «≥ 9» di S8 (Q17).
   - Chiavi del profilo taciute se sbagliate (Q28, A5).
4. **Banchi che scrivono il vivo.**
   - Indice dell'hub e percorsi fissi in /tmp (Q23, A9).
   - `metrics/gate.csv` sovrascritto (Q25, A9).
   - L'e2e di bootstrap senza override della coda (Q14, A8).
5. **Promesse nei commenti e nei documenti che il codice non mantiene.**
   - Il ritorno via «KeepAlive» (Q12, A5).
   - `--dry-run` «nessuna scrittura» (Q14).
   - AGENTS.md corrotto (Q19, A10).
   - I docstring degli oracoli, che sono diventati domande (Q22d).

## Tassonomia
- **Implementata** (verificata eseguendo, banco rosso prima, sabotaggio rosso dopo):
  - S1, S4;
  - Q1, Q2, Q3, Q4, Q5, Q7;
  - Q8, Q9, Q10, Q11, Q12, Q13, Q14, Q15, Q16, Q17, Q18, Q19, Q20, Q21;
  - Q22a, Q22b, Q22c, Q23, Q24, Q25, Q27, Q28, Q29, Q30, Q31, Q31bis, Q32;
  - il cancello del Design estratto in lib.sh e il banco di backup-config (i due risolvibili del
    settimo patto);
  - la negazione del saldo in debiti-riapertura;
  - i marcatori solo-hub con spazi o CRLF.
- **Esclusa** (serve una decisione di dominio o il sorgente): le 10 domande sugli oracoli (Q22d,
  `DOMANDE.md`), in DEBITI come DOMINIO.
- **Rinviata**:
  - il filtro sull'AUTORE delle issue (⏳ serve il `gh` del Mac);
  - la verifica dal vivo della sandbox, degli agenti OpenCode e di `claude -p` con il contesto su
    stdin (⏳ il Mac);
  - `tests/test-banco-passaggio.sh` rimette le esclusioni con un trap, che un SIGKILL salta.
- **Già coperta**: nessuna voce.

## Smentite (la prova che la verifica non è cosmetica)
- Q13: le skill custom del satellite sopravvivevano già a sync-repo (`cp -r dir/.` fonde).
- Q27: il DIVIETO di clasp push reggeva sui comandi lunghi (80/80 sotto carico): il comando è
  ridotto a una riga prima del controllo. Morivano solo gli avvisi.
- Q32: sostituire il file intero nel banco di mutazione è il disegno dichiarato, non un difetto.

## Errori miei, dichiarati
- **E-043**: un sabotaggio dichiarato rosso prima di leggerne l'uscita (Q28). Era verde: la riga
  sabotata era ridondante.
- Un trasformatore che ha messo il here-string dopo la `\` di continuazione (40 file). Visto con
  `bash -n` e rifatto.
- Un altro caso: ha riscritto una fixture dentro una stringa. Visto dal cricchetto.
- Un numero sbagliato nella domanda 1 di DOMANDE.md, corretto prima del commit.
- Una prova E-002 a 1 MB su una riga sola, che non poteva mordere.
- Q6 è un numero saltato nella coda: non corrisponde a nessuna voce.

## Non provato dal vivo (serve il Mac)
- Sandbox di `night-shift/agente.sh`.
- Lock del turno con `ps` BSD.
- Caricamento degli agenti OpenCode con `permission:`.
- `claude -p` col contesto su stdin.
- Primo pass Ollama del grafo.

## Secondo ventaglio (sei lenti trasversali, `10-BRIEF-SECONDO-VENTAGLIO.md`)
Ogni giro in un clone; 35 rilievi. I rapporti grezzi T1-T6 sono andati persi con E-044: T1 è stato
rifatto da capo, gli altri erano già curati o in lista. Il dettaglio di ogni cura (banco rosso prima,
sabotaggio dopo) è nel SAL, voce 18°.

### Temi trasversali
1. **Il confine non dichiarato.** Uno strumento agisce oltre il perimetro che il suo nome promette.
   - L'allowlist «di sola lettura» leggeva `~/.git-credentials` (T5#2).
   - Il censore eseguiva il codice della PR fuori dalla sandbox (T5#1).
   - La batteria d'attacchi mutava l'albero vero (T2#1).
   - Il morning-gate entrava nella cartella del turno vivo (T2#2).
   - Nel commit entravano i file nuovi non dichiarati (T5#2b).
2. **Il segreto che esce dalla porta sbagliata.**
   - Il termine protetto finiva nell'issue pubblica (T5#4).
   - La lente guardava dopo il push (T5#3a).
   - Le credenziali di clasp non erano una forma di segreto (T5#3b).
   - Il cloud riceveva il diff senza maschera (T5#5).
   - I prompt passavano negli argomenti (T5#6).
   - La chiave della privacy non aveva un guardiano al commit (T1#3).
3. **Lock che muoiono male.**
   - Il lock orfano si prendeva due volte (T2#3).
   - Il lock per repo contava l'età (T2#4).
   - Il lock di ciclo-vivo non scadeva mai (T2#5).
   - Il perl uccideva senza TERM, e i trap non giravano (T3#1).
4. **Il satellite che presuppone l'hub.**
   - I guardiani del commit arrivavano spenti (T1#2).
   - Gli hook citavano file dell'hub (T1#4).
   - Il garante si credeva l'hub (T1#5).
   - La lente del registro era rossa dalla nascita (T1#6).
   - I comandi installati non partivano da symlink (trovato di passaggio).
5. **Due liste, due regex, una verità.**
   - Due installatori scrivevano la coda con due regex sbagliate in modi opposti (T6#6).
   - Il `cut` spezzava i comandi delle lenti (T6#2).
   - Una dichiarazione finiva nel `.gitignore` come un residuo (T6#3).

### Tassonomia
- **Implementata** (verificata eseguendo, banco rosso prima, sabotaggio dopo):
  - T5#1, T5#2, T5#2b, T5#3a, T5#3b, T5#4, T5#5, T5#6;
  - T3#1, T3#3, T3#6;
  - T2#1, T2#2, T2#3, T2#4, T2#5;
  - T4 (AGENTS.md, README del turno, MANUALE, system.md);
  - T6#1, T6#2, T6#3, T6#5, T6#6, T6#7, T6#8;
  - T1#2, T1#3, T1#4, T1#5, T1#6;
  - i comandi installati.
- **Esclusa** (serve una decisione di dominio), con le domande in DEBITI:
  - i termini della privacy (T5#4);
  - opencode e i suoi file nuovi (T5#2b);
  - la visibilità di default del bootstrap (T1#1);
  - il privacy-check nei satelliti (T1#3).
- **Rinviata** (⏳ serve il Mac o una sessione dal vivo), in DEBITI:
  - la sandbox vera del censore (T3#2, T5#1);
  - il ramo di timeout;
  - `ps` BSD;
  - `/qwen` fuori dal repo (`/nuova-commessa` invece c'è: il wizard di ZCode — E-045);
  - il promemoria di Stop (T6#4);
  - il caricamento delle skill in OpenCode (T6#8).
- **Già coperta**: T3#5, cioè bash 3.2 (suite verde con verdetti identici, misurata dal giro).

### Smentite e correzioni
- T3#4: `\b` e `\s` funzionano nel grep del Mac (REG_ENHANCED, letto nei sorgenti Apple). La parte
  «`\b`» di T6·6 non era un difetto; il confine di parola invece sì.
- In T6#7 le due difese si sono rivelate ridondanti: sabotata una sola, il banco resta verde. È
  dichiarato, e tenute entrambe per guasti diversi.

### Errori miei, dichiarati
- **E-044** (grave): un sabotaggio su una variabile che finiva in `rm -rf` ha svuotato `/tmp`. Due
  ore senza firma dei commit, e i rapporti grezzi persi.
- **E-043 ripetuto** una volta: in T6#6 il verdetto del sabotaggio era scritto prima di leggerlo (3
  rossi dichiarati, erano 2), corretto nel SAL.
- Prime stesure bucate, viste dal banco prima della consegna:
  - la maschera per un solo termine (T5#4);
  - `mtime || date` che stampava due righe (T2#3);
  - l'esclusione mai loggata sul successo (T5#2b);
  - `compgen -G` senza asterisco (T1#4).
