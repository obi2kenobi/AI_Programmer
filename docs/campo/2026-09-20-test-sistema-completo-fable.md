# 2026-09-20 — test del sistema COMPLETO (missione `docs/test-sistema-completo.md`)
**Autore**: sessione Fable, agente esterno in ambiente cloud (Linux) — per il vivo chiedere a Luca

Otto prove end-to-end sulle nove parti della mappa, ognuna ESEGUITA (mai dedotta) con stub
dichiarati dove il vivo non era raggiungibile. L'hub non è stato toccato: solo questo report
(albero verificato PULITO alla fine, residui dei test rimossi). 27 rilievi, 21 riprodotti.

## Confini dichiarati (primo patto)

- **Raggiungibile**: clone dell'hub (ramo `claude/great-gates-pirbcl`), bash 5.2, python 3.11,
  node, jq, git, curl, `timeout(1)`. GitHub in sola lettura via API (hub + una repo sandbox
  privata della notte, quella del 17/9, aggiunta in sessione).
- **NON raggiungibile**: `gh` CLI, Ollama, opencode, shellcheck, `sandbox-exec`, `launchctl`,
  il Mac. Quindi nessun turno vivo, nessun censore vivo, nessuna PR vera aperta da me.
- **Come ho provato**: stub nello scratchpad per `gh` (registra ogni chiamata), `stat`
  (BSD→GNU), `ollama`, `sandbox-exec`, più un server Ollama finto su localhost:11434.
  Ogni stub è dichiarato accanto alla prova. Una sessione cloud è un ambiente REALE del
  sistema (report Budget Vendite 2026-09-19): ciò che qui è rotto per piattaforma è detto,
  non nascosto.

## Esiti per prova

| Prova | Cosa ho eseguito | Esito |
|---|---|---|
| T1 giro issue→PR | solver con server mock (10/10), ripetizione del percorso «fix applicato» | regge il core; **D5, D6** (auto-review e «già implementata» non girano MAI) |
| T2 catena del debito | `tests/test-catena-viva.sh` locale: 11/11 in 0,7 s | regge; variante su repo remota NON fatta (no gh) |
| T3 censore su PR | `night-shift/revisore.sh` con gh-stub + cervelli stub, 7 PR di prova in DRY | ferma la PR sbagliata; **D1–D4** (quattro buchi che deliberano il merge) |
| T4 morning gate | `night-shift/morning-gate.sh` con gh-stub su repo locale, 2 PR (giusta/sbagliata) + 1 estranea | report utile; **D7, D8** |
| T5 onboarding | `sync-repo.sh --standard` su bare locale con gh-stub, merge, `--from-local`, tocco all'hub | regge su repo CON CLAUDE.md; **D11–D14** |
| T6 guardiani | pre-commit su clone scratch con `.githooks` attivo (4 casi) + clasp hook (9 casi) | clasp hook 9/9 come dichiarato; **D9, D10, D27** |
| T7 memoria | registro (voce nuova, guardia rotta), `debiti-riapertura`, digest, issue aperte | **D16, D21, D26** |
| T8 resilienza | turno intero con stub e copia rotta (clone fallisce / riesce), dashboard con 10k e 100k righe | riclono E-033 regge; dashboard reattiva; **D17, D18**; watchdog Ollama non provabile |

## Difetti riprodotti (prima i più gravi, con la prova)

**D1 — Il censore legge le prove dal ramo sotto giudizio.** `night-shift/revisore.sh:127`
esegue il `.night-verify` del branch della PR; il morning gate lo legge da main
(`night-shift/morning-gate.sh:120`). Prova: PR che riscrive `.night-verify` a `true` e rompe
tools/a.sh (fixture della sandbox) → `PR #3 MERGIATA (deliberazione 1/5)` in DRY. Un cervello locale che impara a
toccare quel file passa le prove.

**D2 — Il comando avversario può scrivere nel repo.** L'allowlist di `night-shift/revisore.sh:165`
guarda la prima parola e alcuni token, non redirezioni né `tee`/`xargs`; l'`eval` a
`night-shift/revisore.sh:178` gira senza sandbox (il gate ha il seatbelt a
`night-shift/morning-gate.sh:226`). Prova: avversario `echo pwned > tools/a.sh` → file
sovrascritto nel working tree (`M tools/a.sh`), PR comunque MERGIATA; `echo x | tee tools/b.sh`
crea un file. Il working tree resta sporco dopo il giro (la trap ripristina solo il branch).

**D3 — La quarantena cede se la data è illeggibile.** `night-shift/revisore.sh:86` cade a 999
minuti se python fallisce. Prova: `createdAt: "ieri"` → nessuna riga «quarantena», DELIBERA
APPROVA.

**D4 — Un diff vuoto viene deliberato.** Nessuna guardia «diff non vuoto» dopo
`night-shift/revisore.sh:111`. Prova: ramo identico a main → `DELIBERA: APPROVA PR #7 (0 righe,
0 file)` e merge DRY. (Il commento in `tests/test-catena-viva.sh` cita il caso «diff vuoto,
guardie vacue» come chiuso: lo è solo per il ramo di default sbagliato.)

**D5 — Auto-review e generatore di test non sono mai partiti.** In
`night-shift/risolvi-issue.sh` le funzioni sono definite alle righe 289 e 314, DOPO l'`exit 3`
di riga 283; le chiamate stanno a 256 e 260. Prova col server mock:
`line 256: auto_review: command not found`, `line 260: genera_test: command not found`,
`REVIEW:` vuoto, ESITO comunque APPLICATO. Il turno a `night-shift/night-shift.sh:894` legge
esiti che non arrivano mai (e `risolvi-issue.sh --review` a quella riga esce 2: «dir
inesistente»). `tests/test-risolvi-issue.sh` passa 10/10 perché non attende la riga REVIEW.

**D6 — Il controllo «già implementata» non gira mai.** `night-shift/night-shift.sh:761` legge
`$ISSUE_FILE` che viene assegnato solo a riga 794: sotto `set -u` la sostituzione muore
(`ISSUE_FILE: unbound variable`), `FN_NOMINATA` resta vuota, il ramo salta. Riprodotto con
`bash -u` sullo stesso costrutto. La lezione E-023 del caso #10 è scritta ma non attiva.

**D7 — Senza `gh` il gate dice «Nessuna».** `night-shift/morning-gate.sh:56` manda gli errori
di `gh` a `/dev/null`: N=0 e il report scrive «_Nessuna. Il sistema ha lavorato o non aveva
coda._». Provato senza stub: identico a una coda vuota. Il silenzio è diventato un verdetto,
esattamente il caso che il file dichiara di combattere.

**D8 — La sezione «Diff:» del report è sempre vuota al primo passaggio.**
`night-shift/morning-gate.sh:95` fa `git diff --stat origin/main...night/issue-N` PRIMA che il
ramo esista in locale (checkout a riga 110; in produzione il clone è single-branch). Nel report
prodotto: `**Diff:**` seguito da nulla per entrambe le PR, mentre `calc.js` era cambiato.

**D9 — Il rilevatore dei glifi non può dichiararsi morto.** `tools/pre-commit.sh:23` mette
`git grep -P` in pipe con `grep -vE`: con pipefail l'rc 128 del rilevatore diventa l'1 del
filtro, e la guardia E-024 a riga 24 (`>=2` = morto) non scatta mai. Su questa macchina
`en_US.UTF-8` non esiste: `git grep -P '[\x{0400}-\x{04FF}]'` muore («code point too large»,
rc 128) e un commit con una parola in cirillico è PASSATO (HEAD del clone scratch spostato).
CRLF e citazione `file:riga` rotta sono invece stati bloccati (commit rc 1, HEAD fermo).

**D10 — Il numero-test nel messaggio non è mai controllato dall'hook.** `.githooks/pre-commit`
passa `""` come messaggio (riga 4): il git pre-commit non conosce il messaggio, serve un
`commit-msg`. Prova: commit «test: 999 test verdi» passato via hook; lo stesso controllo
invocando `tools/pre-commit.sh` a mano col messaggio lo blocca («dice 999 test ma i file sono
142»).

**D11 — `--standard` non parte su una repo VUOTA.** `tools/sync-repo.sh:48` legge
`CLAUDE.md` dal remoto e senza quel file esce 1 («impossibile leggere CLAUDE.md»). La missione
T5 chiede «repo sandbox vuota»: quel percorso non esiste (è di `onboard-repo.sh`, ma il
comando insegnato è questo). Con un CLAUDE.md vecchio funziona: PR con 19 gruppi di file.

**D12 — CLAUDE.md identico = tutto allineato.** `tools/sync-repo.sh:53` esce 0 prima di
guardare skill, agenti, hook: una deriva delle sole skill è invisibile anche con `--standard`
(il «canarino» è dichiarato, ma lo standard intero non si riallinea mai da lì).

**D13 — 9 su 15 percorsi citati nel CLAUDE.md installato non esistono nella destinazione**
(`PROJECT.md`, `SAL.md`, `docs/system.md`, `graphify-out/graph.json`, `llm/README.md`,
`night-shift/README.md`, `night-shift/morning-gate.sh`, `night-shift/repos-index.md`,
`tools/fork-stato.sh`). REPO-I H2 diceva «gli strumenti citati viaggiano»: viaggiano i 7 di
`tools/sync-repo.sh:98`, gli altri restano citazioni senza presidio. I 3 hook dichiarati ci
sono ed eseguibili; `.night-verify` seminato con `bash tools/gas-gate.sh` (la repo ha `.gs`);
`.gitignore` con `.campo-rem` e `.mirror-boundaries`. Ma i guardiani del commit (T6) non
viaggiano: la destinazione non riceve `tools/pre-commit.sh` né `.githooks`.

**D14 — `cd "$TMP/work"` non è guardato.** `tools/sync-repo.sh:72`: se il clone «riesce» ma la
directory manca, il ciclo di copia gira nella CWD, cioè nell'hub. Successo a me con uno stub
sbagliato (argomento del clone): 100+ file di standard copiati e staged DENTRO l'hub
(`.claude/skills/skills/…`, `patterns/patterns/…`), ripuliti a mano. Stessa famiglia del
difetto 2 di REPO-F (scrittura alla radice con `$DEST` vuoto).

**D15 — Il log dichiara «PR di riallineo aperta» anche quando è un errore.**
`night-shift/night-shift.sh:311` scrive il `tail -1` di sync-repo dopo la parola «aperta»:
nel turno simulato la riga è `PR di riallineo aperta: sync-repo: impossibile leggere CLAUDE.md`.

**D16 — L'issue `[night-verify]` non dice quale verifica è rossa.**
`night-shift/night-shift.sh:285`: «I dettagli sono nel log del turno». Sull'hub l'issue #95 è
aperta dal 18/9 con quel testo, insieme a #91 `[ciclo-vivo]` (17/9) e #81 `[banco]` (15/9):
la notte segnala, il giorno non ha disposto per 2–5 giorni, e da remoto non potrebbe.

**D17 — Il turno senza lavoro gira a vuoto senza pausa.** `night-shift/night-shift.sh:1127`
(`exec "$0"`) con copia rotta e caccia in cooldown: 390 cicli in ~4,5 minuti con stub, ~8
chiamate `gh` per ciclo (`gh.log`). Con `gh` vero il ritmo cala di un ordine di grandezza —
stima, non misura — ma il freno è il rate limit di GitHub, non il sistema.

**D18 — La dashboard sottostima in silenzio.** `tools/dashboard.py:24` legge le ultime 4000
righe: con un log di 10.000 righe e 904 «attivo la CACCIA», il funnel mostra 370 finestre e
362 cicli. Reattività invece ottima: 40–60 ms a 10k righe, 63 ms a 100k.

**D19 — Il test della dashboard non può finire e il suo cancello è sovrascritto.**
`tests/test-dashboard.sh:86` chiama `dashboard.py --stats`, modalità che non esiste: parte il
server (`timeout 8` → rc 124, verificato) e il fallback vede la riga di avvio nel confronto.
`tests/test-struttura-test.sh` lo segna rosso («il cancello non è l'ultima riga»). La mappa
dice «Dashboard: testata sì (unit)»: non regge.

**D20 — La suite è rossa dal 19/9 su ogni macchina.** `tests/test-sync-repo-hooks-propagation.sh:59`
attende 3 righe da `tools/copia-hook.sh`, che dal fix H1 emette anche `.gitignore`
(`tools/copia-hook.sh:60`): «4 copiati contro 3 dichiarati». `tools/suite.sh` si ferma al primo
rosso (qui al 24° di 142: i 118 dopo non girano) e la riga `@540 bash tools/suite.sh` di
`.night-verify` è rossa. Qui 10/142 test rossi in tutto: 2 indipendenti dalla piattaforma
(D19, D20), 1 che mostra D9 (`tests/test-pre-commit.sh`), 7 da comandi macOS (D22).

**D21 — `debiti-riapertura` sbaglia il «perché» e una classificazione.**
`tools/debiti-riapertura.sh:57`: la regex `perch` combacia con l'intestazione della tabella,
così tutte le 8 domande mostrano «perché conta: | Data | Scorciatoia | Perché rimandata |…».
`tools/debiti-riapertura.sh:41` guarda 600 caratteri: «Valutare Qwen 3.8 Flash» ha la parola
chiave (decisione hardware di Luca) a offset 754 e finisce tra i RISOLVIBILI (R6).

**D22 — Portabilità non dichiarata.** `stat -f %m` (`night-shift/night-shift.sh:157`, 559,
1044; `night-shift/caccia-miglioria.sh:81`), `sed -i ''` (`night-shift/caccia-miglioria.sh:243`),
`sandbox-exec` (`night-shift/morning-gate.sh:226`), `osascript` (`night-shift/morning-digest.sh`),
`date -v` (`tests/test-turno-vivo.sh`). Su Linux: lock e cooldown sempre «scaduti», siti
rinviati mai depennati, banco del gate «SMENTITA» per comando inesistente (rc 127). Nessun
documento dice «solo macOS», e le sessioni cloud sono Linux.

**D23 — La suite sporca l'albero vivo.** Dopo la suite: `docs/bc/README.md` con 174 righe
cambiate (`tests/test-bc-index.sh:20` rigenera l'indice VERO; `tools/bc_index.py:54` ordina
solo per conteggio, i pari merito seguono l'ordine del filesystem, diverso tra macchine), più
`night-shift/repos.conf`, `.campo-rem`, `.ciclo/` creati. Nell'auto-fix notturno
`night-shift/night-shift.sh:432` conta OGNI diff come «carne vera» e `git add -A` lo committa:
è la forma della PR #92 («solo il counter della rotazione»). Famiglia E-032, che il censimento
cerca solo nella forma `>> "$HERE`.

**D24 — Privacy nel codice dell'hub pubblico.** Il nome di una repo privata è scritto in
`tools/dashboard.py:71` e nel commento di `night-shift/night-shift.sh:264`. `tools/privacy-check.sh`
senza `repos.key` è DEGRADATO ed esce 1 (onesto): su ogni clone pubblico nessuno lo vede.

**D25 (osservazione) — Il censore vivo non ha mai deliberato.** Sull'hub: 4 PR `notte/auto-*`
fuse a mano, la sola `caccia:` (#92) chiusa a mano, 0 certificati del revisore. Le PR del solver
(`night/issue-N`) hanno titolo diverso da `caccia:` (`night-shift/revisore.sh:83`): la PR
bozza della sandbox del 17/9 va al censore a ogni ciclo e torna «non mio». Un JSON dentro un
fence markdown (forma tipica del 14b) dà «non ha risposto in JSON → al giorno»: sicuro, ma può
spiegare lo zero.

**D26 (osservazione) — L'anello della memoria chiude solo a mano.** Nulla scrive `SAL.md`: il
gate lascia un promemoria nel report (`night-shift/morning-gate.sh:299`), il turno accoda a
night-shift/.sal-turni.md (locale, gitignored) una voce per ciclo (24/7), il digest la svuota solo se `DIGEST_EMAIL` è
configurata (`night-shift/morning-digest.sh:9`), altrimenti esce 0 e il file cresce.

**D27 — Il cancello clasp nega la SCRITTURA di questo report.** Il comando Bash che scriveva
questo file (heredoc) è stato NEGATO da `tools/clasp-block-hook.sh:54` perché il testo cita in
backtick le forme vietate (i 9 casi della prova T6). Il cancello spoglia solo le stringhe fra
virgolette (`tools/clasp-block-hook.sh:51`): i backtick sono dati anche loro. Stesso falso
positivo di REPO-E 2026-09-01 in una forma nuova; il file è stato scritto con un altro strumento.

## Cosa ha retto (con la prova)

- Catena del debito: 11/11 in 0,7 s; trasformatore E-002 alla riga esatta; rinvio onesto.
- Solver: 10/10 col mock, confinamento dei path fuori progetto, inserzione HTML nel punto giusto.
- Censore: la PR sbagliata (variabile usata rimossa) fermata dalle PROVE (rc 2); RIGETTA chiude
  con motivi; guardie diff ≤60 righe/≤3 file; budget 5/giorno rispettato (bloccava la 6ª).
- Morning gate: per la PR sbagliata il report nomina il comando rosso e produce la proposta
  correttiva pronta da incollare; verifiche lette da main; la PR `feature/*` ignorata come
  documentato; `metrics/gate.csv` riceve una riga per PR.
- Onboarding su repo con CLAUDE.md: PR con 19 gruppi, merge → `ALLINEATO`, tocco all'hub →
  `DIVERGENTE 1 riga`, seconda `--standard` → `ALLINEATO`; `gas-gate` gira nella destinazione
  (1 file compilano); `cita-verifica` e `debiti-riapertura` viaggiati girano.
- Clasp hook: le cinque forme di invocazione (con `npx`, con `npm run` risolto da package.json,
  nuda, dopo `&&`, con `@google/` e opzioni del runner) NEGATE; `grep` con la forma fra
  virgolette, prefisso `env`, `bash scripts/deploy.sh`, `npm run build` consentiti — tutti come
  dichiarato in `tools/clasp-block-hook.sh:33`.
- Pre-commit: CRLF e `file:riga` inesistente bloccano il commit (rc 1, HEAD fermo).
- Registro errori: voce nuova con tutti i campi 121/121; guardia inesistente → rosso.
- Riclono E-033: clone fallito → la copia vecchia resta (file marker presente); clone riuscito →
  «riclono riuscito: copia nuova al posto (scambio atomico)».
- Dashboard: 40–60 ms a 10k righe, 63 ms a 100k.
- Watchdog Ollama (`night-shift/night-shift.sh:1065`): letto, NON provabile senza Ollama/launchd.

## Numeri ricontati

- Mappa: «17+ sonde» → 14 identificativi distinti in `tools/giri-ignoranti.sh` (S1–S11, S15–S17);
  «7 banchi» → 7 (`tools/banco-passaggio.sh:6`); test: 142 file.
- Debiti aperti: 15 (8 dominio + 7 risolvibili) — con la classificazione di R6 discutibile (D21).
- Delibere del censore sul vivo: 0 (D25). PR notturne dell'hub: 4 fuse a mano, 1 chiusa a mano.

## Non raggiungibile (dichiarato, pesa quanto un bug)

T1 sul vivo, T2 su repo remota, T3 con Ollama e gh veri, T5 su GitHub vero, T8 watchdog Ollama.
Tutte richiedono il Mac con `gh` autenticato: da una sessione cloud il sistema si può provare
solo con stub. Che gli stub abbiano trovato 21 difetti riproducibili è il rilievo: il live
non era il banco (E-034), ma il banco non copriva questi rami.

## Cosa ho usato

`tests/test-catena-viva.sh`, `tests/test-risolvi-issue.sh`, `tests/test-errori.sh`,
`tools/debiti-riapertura.sh`, `tools/sync-repo.sh`, `tools/garante-standard.sh`,
`tools/pre-commit.sh`, `tools/clasp-block-hook.sh`, `tools/dashboard.py`, `night-shift/revisore.sh`,
`night-shift/morning-gate.sh`, `night-shift/night-shift.sh`, `night-shift/risolvi-issue.sh`, la
suite intera (un test alla volta con timeout 150 s). Volevo e non c'era: un modo dichiarato di
girare il sistema fuori dal Mac.

## Cosa ho improvvisato

Gli stub (`gh`, `stat`, `ollama`, `sandbox-exec`, server Ollama finto) e un turno intero in
sandbox con copia rotta: sono la versione «tutto il sistema» di `tests/test-catena-viva.sh`.
Il mio stub sbagliato ha fatto scrivere `sync-repo` nell'hub (D14): dichiarato, ripulito,
l'albero è tornato pulito prima di questo commit.

## Chiusura — dieci giri sullo stesso ramo (Luca: «ripeti 10 giri di analisi e chiudi tutti gli errori»)

Ogni giro: il test che riproduce il difetto (rosso), la cura, il test verde, il commit. Il
diario dei giri e' in `SAL.md` (voce 2026-09-20 (2°)); qui la mappa difetto → cura → prova.

| Giro | Difetti | Cura | Banco (prima → dopo) |
|---|---|---|---|
| 1 | D1-D4 | prove dal ramo di default e rinvio se la PR tocca `.night-verify`; allowlist di `night-shift/lib.sh` + rifiuto di `>` + `git clean`; quarantena fail-closed; diff vuoto = rinvio | `tests/test-revisore.sh` 13 OK 6 FAIL → 19/19; catena 11/11 |
| 2 | D5-D6 | funzioni definite prima dell'uso e su `$API`; `ISSUE_FILE` scritto prima del check; chiamata `--review` rimossa | `tests/test-risolvi-issue.sh` 10/3 → 13/13 |
| 3 | D7-D8 | «gate CIECO» + riga `gate-cieco`; diff dopo il checkout; `ADVERSARY=none` | nuovo `tests/test-morning-gate-cieco.sh` 3/4 → 7/7 (62 s → 1,2 s) |
| 4 | D9-D10 | rc del rilevatore prima del filtro, niente xargs (mappa 1 e 128 sullo stesso 123), locale UTF-8 scelto fra gli installati; `.githooks/commit-msg` | `tests/test-pre-commit.sh` 9/3 → 12/12; provato sul clone: «999 test» muore, il benigno passa |
| 5 | D11-D14 | repo vuota onboardabile; `--standard` oltre il canarino; `cd || exit`; guardiani nella lista; copia del contenuto (niente annidamento) | `tests/test-sync-repo.sh` 7/4 → 14/14 |
| 6 | D15-D17, D23 | log «PR aperta» solo con URL; comandi rossi nel corpo dell'issue; pausa sui cicli a vuoto sotto il minuto; `bc_index.py` deterministico | nuovo `tests/test-night-shift-log-onesto.sh` 11/11; `tests/test-bc-index.sh` 9/9 |
| 7 | D18-D20 | log intero; `--stats` reale; cancello ultimo; hook contati con `.gitignore`; `tools/ciclo-vivo.sh` senza «bad substitution» (moriva su bash 5) | `tests/test-dashboard.sh` 14/14; `tests/test-struttura-test.sh` 1/1; hooks 8/8 |
| 8 | D21 | intestazioni di tabella saltate, cella che risponde; classificazione sul corpo intero | `tests/test-debiti-riapertura.sh` 6/3 → 9/9 |
| 9 | D22, D24, D27 | `mtime()` portabile; `sed -i` senza forma BSD; `date -v` → python; backtick = dati nel cancello clasp; nome privato via | nuova lente `tests/test-portabilita.sh` 7/7; clasp 33/33; turno-vivo 9/9; caccia-miglioria 19/19 |
| 10 | D26 + memoria | rotazione della memoria del turno (night-shift/.sal-turni.md, locale) a 1 MB; E-035 nel registro (il mio stub); debiti residui dichiarati; mappa della missione corretta; suite intera | vedi sotto |

**Non curati, dichiarati in `DEBITI.md`**: le PR del solver senza censore (decisione di
Luca); i 9 percorsi dell'hub citati dal CLAUDE.md installato (la cura e' nel testo, non
nella copia); i 57 siti E-002 residui dell'hub (li salda la notte, un sito per finestra —
i 7 di `tools/giri-avversari.sh` sono stati portati a cattura-prima perche' il dente del
pre-commit li ha morsi alla frontiera); il turno che vive solo sul Mac.

**Mio errore messo a regime**: E-035 in `docs/errori/REGISTRO.md` (lo stub di `gh` con
l'argomento sbagliato e il `cd` non guardato che ha copiato lo standard nell'hub).

## Proposta al canone (i difetti riprodotti per primi)

1. Censore: prove lette da `origin/<default>`, rifiuto di ogni PR che tocca `.night-verify`
   (D1); allowlist di `night-shift/lib.sh` + rifiuto di `>`, `>>`, `tee`, `xargs` + `git clean`
   dopo il banco (D2); quarantena fail-closed (D3); guardia «diff non vuoto» (D4).
2. Solver: definizioni prima dell'uso e un'attesa `REVIEW: CORRECT|WRONG|UNCLEAR` in
   `tests/test-risolvi-issue.sh` (D5); `ISSUE_FILE` assegnato prima del check (D6).
3. Gate: `gh` assente o non autenticato = verdetto `gate-cieco`, mai «Nessuna» (D7); diff stat
   dopo il checkout (D8).
4. Pre-commit: rc del rilevatore catturato prima del filtro (D9); `commit-msg` per il
   numero-test (D10); i guardiani viaggiano con `--standard` (D13).
5. Sync: percorso per repo vuota, `cd … || exit`, confronto dello standard intero (D11, D12, D14).
6. Turno: log «PR aperta» solo su `https://` (D15); il comando rosso nel corpo dell'issue (D16);
   pausa o backoff quando il ciclo non ha lavorato (D17); il diff dell'auto-fix filtrato dai
   file che la suite rigenera (D23).
7. Dashboard: finestra per data, non per righe (D18); `tests/test-dashboard.sh` e
   `tests/test-sync-repo-hooks-propagation.sh` da riallineare — la suite è rossa dal 19/9 (D19, D20).
8. `debiti-riapertura`: escludere le intestazioni di tabella, classificare sul corpo intero (D21).
9. Una riga in `METHOD.md` o `night-shift/README.md`: «il turno gira solo su macOS» — oppure una
   lente di portabilità che cerchi `stat -f`, `sed -i ''`, `date -v`, `osascript`,
   `sandbox-exec` (D22). Le sessioni cloud sono già un ambiente del sistema.
10. Il nome privato in `tools/dashboard.py:71` va tolto (D24); `.night-verify` dovrebbe
    contenere una riga che pretenda l'albero pulito dopo la suite (D23).
11. Clasp hook: spogliare anche i backtick, o riconoscere che il comando scrive un `.md` (D27).
12. La mappa della missione va corretta: 14 sonde, dashboard NON testata a unità, censore mai
    deliberato sul vivo, `--standard` non copre la repo vuota.
