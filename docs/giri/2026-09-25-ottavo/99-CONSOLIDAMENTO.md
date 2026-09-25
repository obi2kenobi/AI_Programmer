# Ottavo ventaglio — consolidamento (2026-09-25)

Brief: `docs/giri/2026-09-25-ottavo/00-BRIEF.md`. Cinque lenti, un giro ciascuna, ognuno in un clone:
- O1: il modello come avversario;
- O2: GitHub come avversario;
- O3: la crescita;
- O4: le versioni degli strumenti;
- O5: le azioni verso l'esterno, ripetute.

I rapporti grezzi sono in `grezzi/`, ignorata da git (skill n-giri §2). Dettagli di ogni cura nel SAL, voce 18°,
righe «Ottavo ventaglio».

## Esito

- **29 rilievi**: O1 5, O2 6, O3 6, O4 6, O5 6. Sono provati eseguendo, tranne dove il giro ha dichiarato «per
  lettura»:
  - i passi del turno fuori dalla sandbox (O1 R1) e il censore (O1 R5);
  - postfix sul Mac (O5 R2);
  - l'Apple git senza PCRE (O4 R4): non provato, ricordato da segnalazioni pubbliche.
- **Curati**: 20, ognuno col banco rosso prima e il sabotaggio rosso dopo. A fine ventaglio ho rifatto i sabotaggi delle
  ultime nove cure in un worktree pulito: tutte rosse col sorgente di prima, verdi con la cura.
  - Quattro cure non hanno un banco che esegue il codice vero. O2 R2, R3, R4 e R5 sono guardie statiche sulle righe di
    `night-shift/night-shift.sh`; per R5 si riesegue anche la forma nuova, fuori dallo script.
  - O5 R1 è provato nel laboratorio del giro, col blocco vero estratto e un `gh` finto con stato. Nella suite resta una
    guardia statica.
- **Già coperto**: O5 R6, dalla cura di O2 R3 (le letture dei commenti con `GH_NON_SO`). Metà di O5 R5 (un
  `gh pr view` fallito che riscrive la PR) è coperta da O2 R1.
- **Rinviati** (con la domanda in DEBITI): O1 R3, O1 R5, O3 R1, O3 R3, O4 R4, O4 R5, O5 R4, O5 R5.
- **Domande nuove in DEBITI**: 11. Nove di dominio, due d'ambiente. Dove la cura ha dovuto scegliere, la scelta
  provvisoria è dichiarata nella domanda:
  - O5 R1: il prefisso `notte/` e la PR del grafo a ogni giorno;
  - O4 R1: i gist vecchi e `repos.key` in un gist;
  - O5 R2: il ripiego della posta;
  - O3 R1: la storia di `graphify-out/` nella scansione della privacy;
  - O3 R3: la rotazione della console;
  - O4 R4 e O4 R5: PCRE sul Mac; graphify e la versione di gh;
  - O1 R3: il blocco del risolutore che tocca altre funzioni;
  - O1 R5: il verdetto fuori vocabolario;
  - O5 R4 e R5: l'issue d'allarme a verde, e il «no» di Luca;
  - O2 (domanda del giro): una PR di issue aperta si può riscrivere?
- **Smentite**: nessuna.
- **Fuori tetto** (visti dai giri, non contati): lo slug vuoto di `tools/cervello-impara.sh` per un titolo tutto non
  ASCII (O1); un `FAIL_DETAIL` con una riga `GATE_EOF` e il ramo oltre le 1000 PR più recenti (O2), che la scopa cancellerebbe: è in DEBITI come debito di crescita. Nessuno
  provato.
- **Esiti nulli misurati**:
  - O4: curl, jq 1.6 e python 3.9 contro le forme usate;
  - O3: dove la crescita non morde;
  - O1: i percorsi `../`, i link simbolici e i file enormi letti dall'agente.

  Sono nei grezzi, sezioni «Guardato».
- **Suite**: 191/191 a ogni consegna.

## Temi trasversali

1. **L'errore letto come «niente»** (O2, O5, O1). È il tema forte: sette rilievi da tre lenti, ognuno con la stessa
   forma: una lettura che fallisce vale «vuoto», e la scrittura che segue parte. Casi:
   - `gh pr view` fallito come «nessuna PR»;
   - `$(gh … 2>/dev/null || true)` nelle guardie anti-doppione;
   - la PR contata creata senza URL;
   - «(nessuna)» nella domanda del giorno;
   - la chiusura fallita detta «chiusa»;
   - `mail` in coda detto «inviato»;
   - l'azione illeggibile presa per «ho finito».

   Cura comune: una sentinella per «non so» (`GH_NON_SO`, `stato_pr_ramo` con rc 2), e la scrittura esterna si salta
   nel ciclo in cui la lettura è caduta.
2. **Il testo di un altro sistema preso per fidato** (O1, O2). Casi:
   - il modello che scrive in `.git/`;
   - l'ultima riga JSON che vince;
   - la prosa prima dell'azione;
   - i titoli di GitHub dentro `echo -e`.
3. **Il tetto nascosto** (O2, O3). Casi:
   - il `--limit` di default di gh (20 o 30);
   - `head -200` nella sonda S16;
   - `^## E-0` fino a E-099;
   - `tail -25` nella lente delle sonde;
   - dieci PR per repo nella domanda del giorno.

   Si somiglia a sé stesso: un numero piccolo scelto quando i dati erano piccoli.
4. **Il finto più indulgente del vero** (O4). Il `gh` finto dei banchi accettava `--secret`, `-q` e `-R` su
   `gh repo view`, che il gh vero rifiuta. Tre strumenti non avevano mai funzionato (backup, bootstrap, il ripiego di
   `default_branch`) con la suite verde. Cura: il finto del bootstrap ora rifiuta il `-q`. Le forme nuove sono provate
   col gh 2.45 vero a rete chiusa, che arriva all'errore di rete e non a quello dei flag.

## Tassonomia

**Implementata**
- O1: R1 (`percorso_ammesso` rifiuta `.git`), R2 (un solo `sicuro:false` vince), R4 (l'azione illeggibile torna al
  modello).
- O2: R1 (`stato_pr_ramo`), R2 (`--limit` esplicito ovunque), R3 (`GH_NON_SO`), R4 (la PR si conta con un URL), R5
  (`printf '%s'`), R6 («gh non ha risposto», totali «almeno»).
- O3: R2 (`DEBITI_SENZA_DERIVA`), R4 (niente `head -200`), R5 (`E-[0-9]`), R6 (le righe FIND prima della coda).
- O4: R1 (il backup su gist col gh vero), R2 (niente `-q`), R3 (`git ls-remote --symref`), R6 (`versioni_turno`).
- O5: R1 (il patch-id contro le PR `notte/auto-*` aperte), R2 («coda locale», la memoria resta), R3 (il segno del
  rigetto, `ready --undo`).

**Esclusa**
- Nessuna.

**Rinviata**
- O1 R3, O1 R5, O3 R1, O3 R3, O4 R4, O4 R5, O5 R4, O5 R5 (sopra).

**Già coperta**
- O5 R6 (da O2 R3).

## Da fare a mano (non potevo)

- Sul Mac: leggere la riga d'ambiente del primo turno dopo il merge. Dice se git ha PCRE (O4 R4) e quale gh gira
  (O4 R5).
- Invariato dai ventagli di prima: `rm -f /CLAUDE.md /claude-satellite.md` nel container; i `mutation-backup.*` orfani in
  `/tmp`.

## Incidenti del laboratorio (dichiarati)

- Il giro O1 ha chiamato `rianima_ollama`, che fa `pkill` di `ollama serve`. Nel container non c'era niente da colpire,
  ma la regola del brief lo vietava.
- Il giro O4 ha fatto una chiamata `gh` in sola lettura che è arrivata al proxy (403). Nessuna scrittura.

## Errori miei in questo ventaglio

- Prime stesure prese dai rilevatori prima del commit:
  - quattro `$NOME` attaccati a «» in righe nuove di banco, presi dalla sonda di `tests/test-portabilita.sh`;
  - un `timeout` nudo (ora `ai_timeout`);
  - un `grep -c … || echo 0` che dava due zeri;
  - citazioni nude nel brief, prese dal pre-commit;
  - un `$(…)` senza virgolette (SC2046).
- La sonda PCRE di O4 R6 diceva «NO» a torto: il file stava fuori da una repo. Corretta prima del commit.
- Due casi di banco inseriti fra una prova e la verifica del suo `$OUT`: spostati.
- Il laboratorio di O5 era sporco (un `.night-patch-o5.js` non tracciato faceva differire i diff a ragione): tolto e
  rifatta la prova.
- **O3 R4**: ho scritto la cura prima del banco. Rimediato col banco e il sabotaggio subito dopo; il metodo dice
  l'ordine inverso.
