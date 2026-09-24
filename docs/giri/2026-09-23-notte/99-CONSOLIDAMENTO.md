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

## Secondo ventaglio
In corso: 10-BRIEF-SECONDO-VENTAGLIO.md, sei lenti trasversali. Il suo consolidamento segue qui.
