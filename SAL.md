# SAL — il diario vivo del sistema

> Diario del sistema di sviluppo (hub + cervelli + turno notturno + giudizio).
> Ogni decisione porta la data e i fatti che l'hanno imposta. Aggiornato dal morning-gate
> e a ogni decisione strutturale.

<!-- SAL-INDICE: generato da tools/sal-indice.sh — non editare a mano -->
## Indice del diario

- [2026-08-27 (8) — quarto report: 30 agenti su REPO-I, cinque proposte, quattro adottate](#2026-08-27-8-quarto-report-30-agenti-su-repo-i-cinque-proposte-quattro-adottate)
- [2026-08-27 (9) — trenta giri anti-collo-di-bottiglia: quattro eliminati, tre gated](#2026-08-27-9-trenta-giri-anti-collo-di-bottiglia-quattro-eliminati-tre-gated)
- [2026-08-27 (10) — trenta giri n.2: il collegamento rotto ero io](#2026-08-27-10-trenta-giri-n-2-il-collegamento-rotto-ero-io)
- [2026-08-27 (11) — quinto report: 50 agenti su REPO-F, due rifiuti che sono il metodo](#2026-08-27-11-quinto-report-50-agenti-su-repo-f-due-rifiuti-che-sono-il-metodo)
- [2026-08-27 (12) — report REPO-I fase 2: catalogo esaurito, quattro regole nuove](#2026-08-27-12-report-repo-i-fase-2-catalogo-esaurito-quattro-regole-nuove)
- [2026-08-27 (13) — sesto report (REPO-H, 12 PR): pattern 23-24 e il workaround vm](#2026-08-27-13-sesto-report-repo-h-12-pr-pattern-23-24-e-il-workaround-vm)
- [2026-08-27 (14) — quattordici lenti su REPO-G: il metodo chiede adottare il metodo](#2026-08-27-14-quattordici-lenti-su-repo-g-il-metodo-chiede-adottare-il-metodo)
- [2026-08-27 (15) — consolidazione: tutto ciò che i cicli hanno scoperto è nel canone](#2026-08-27-15-consolidazione-tutto-ciò-che-i-cicli-hanno-scoperto-è-nel-canone)
- [2026-08-27 (16) — cinquanta giri su REPO-I: le cinque lenti per area](#2026-08-27-16-cinquanta-giri-su-repo-i-le-cinque-lenti-per-area)
- [2026-08-28 (1) — L'Hub Allo Specchio: 14 lenti indipendenti sull'hub stesso, 9 batch di fix](#2026-08-28-1-l-hub-allo-specchio-14-lenti-indipendenti-sull-hub-stesso-9-batch-di-fix)
- [2026-08-27 (17) — quarto report REPO-G: eseguite le 62 proposte, due pattern nuovi, un'obiezione superata](#2026-08-27-17-quarto-report-repo-g-eseguite-le-62-proposte-due-pattern-nuovi-un-obiezione-superata)
- [2026-08-27 (18) — il tesoro sigillato: convergenza cieca, obiezioni che invecchiano, gerarchia DOM](#2026-08-27-18-il-tesoro-sigillato-convergenza-cieca-obiezioni-che-invecchiano-gerarchia-dom)
- [2026-08-27 (19) — magazzino: 72 commit (20 bug + 55 proposte) e il handoff gap](#2026-08-27-19-magazzino-72-commit-20-bug-55-proposte-e-il-handoff-gap)
- [2026-08-28 — dossier SD Dashboard: 86 rilievi, 71 dichiarati NON VERIFICATI](#2026-08-28-dossier-sd-dashboard-86-rilievi-71-dichiarati-non-verificati)
- [2026-08-28 — REPO-I fase 3 chiude il ciclo: 245 idee, 7 proposte, due pattern nuovi](#2026-08-28-repo-i-fase-3-chiude-il-ciclo-245-idee-7-proposte-due-pattern-nuovi)
- [2026-08-28 — trenta giri di indagine completa: il repo è sano, una guardia nuova per la prosa](#2026-08-28-trenta-giri-di-indagine-completa-il-repo-è-sano-una-guardia-nuova-per-la-prosa)
- [2026-08-28 (2) — cinquanta giri nuove lenti: qualità, non solo presenza](#2026-08-28-2-cinquanta-giri-nuove-lenti-qualità-non-solo-presenza)
- [2026-08-28 (3) — 50 giri 3ª batteria: lenti di evoluzione e cambiamento](#2026-08-28-3-50-giri-3ª-batteria-lenti-di-evoluzione-e-cambiamento)
- [2026-08-28 (4) — REPO-J 50 agenti: 13 confermati, 2 smentiti, l'onore funziona](#2026-08-28-4-repo-j-50-agenti-13-confermati-2-smentiti-l-onore-funziona)
- [2026-08-28 (5) — REPO-K: dal dossier ai fix, 86+25 in sessione continua](#2026-08-28-5-repo-k-dal-dossier-ai-fix-86-25-in-sessione-continua)
- [2026-08-28 (6) — l'hub allo specchio: revisione indipendente, 60+ finding](#2026-08-28-6-l-hub-allo-specchio-revisione-indipendente-60-finding)
- [2026-08-28 (7) — 8 proposte dell'audit implementate + 15 report campo triati](#2026-08-28-7-8-proposte-dell-audit-implementate-15-report-campo-triati)
- [2026-08-28 (8) — REPO-J live drift: 3 divergenze reali, 25 fix confermati, primo deploy](#2026-08-28-8-repo-j-live-drift-3-divergenze-reali-25-fix-confermati-primo-deploy)
- [2026-08-28 (9) — REPO-L (Unicredit_Factoring): 9 confermati, SECRET in history, la buona notizia provata](#2026-08-28-9-repo-l-unicredit_factoring-9-confermati-secret-in-history-la-buona-notizia-provata)
- [2026-08-28 (10) — REPO-M (Energikal): backlog di 15+20 voci, 5 domande di dominio](#2026-08-28-10-repo-m-energikal-backlog-di-15-20-voci-5-domande-di-dominio)
- [2026-08-28 (11) — REPO-L (Unicredit_Factoring): 30 agenti + 14 fix, terza sessione continua](#2026-08-28-11-repo-l-unicredit_factoring-30-agenti-14-fix-terza-sessione-continua)
- [2026-08-28 (12) — REPO-N (parrocchie): il metodo su Flask/SQLite, 13 difetti al banco](#2026-08-28-12-repo-n-parrocchie-il-metodo-su-flask-sqlite-13-difetti-al-banco)
- [2026-08-28 (13) — Energikal: chiusura sessione (5 decisioni di dominio prese, PR #55 aperta)](#2026-08-28-13-energikal-chiusura-sessione-5-decisioni-di-dominio-prese-pr-55-aperta)
- [2026-08-28 (14) — REPO-N giornata completa: 159 giri, 26 difetti corretti, 5 suite](#2026-08-28-14-repo-n-giornata-completa-159-giri-26-difetti-corretti-5-suite)
- [2026-08-28 — 60 giri di revisione completa: privacy bonificata, pattern collegati](#2026-08-28-60-giri-di-revisione-completa-privacy-bonificata-pattern-collegati)
- [Giro 1/30 ciclo ABC: 9 finding corretti (6 agenti pattern, 3 skill collegate)](#giro-1-30-ciclo-abc-9-finding-corretti-6-agenti-pattern-3-skill-collegate)
- [2026-08-28 — Il falso positivo strutturale del ciclo-vivo (pipefail + grep -q) e il canone svuotato che nessuno notava](#2026-08-28-il-falso-positivo-strutturale-del-ciclo-vivo-pipefail-grep--q-e-il-canone-svuotato-che-nessuno-notava)
- [2026-08-28 (2) — Altri 100 giri: il ciclo che misurava se stesso, e il test anti-drift che non testava](#2026-08-28-2-altri-100-giri-il-ciclo-che-misurava-se-stesso-e-il-test-anti-drift-che-non-testava)
- [2026-08-28 (3) — Altri 100 giri col battito + la tecnica estesa a TUTTO il repo](#2026-08-28-3-altri-100-giri-col-battito-la-tecnica-estesa-a-tutto-il-repo)
- [2026-08-28 (4) — I 100 giri IGNORANTI: le sonde scortesi che trovano ciò che le lenti educate non vedono](#2026-08-28-4-i-100-giri-ignoranti-le-sonde-scortesi-che-trovano-ciò-che-le-lenti-educate-non-vedono)
- [2026-08-28 (5) — I 100 giri AVVERSARI: attaccare il sistema per conto terzi](#2026-08-28-5-i-100-giri-avversari-attaccare-il-sistema-per-conto-terzi)
- [2026-08-28 (6) — I 100 giri sui TEST: i quattro teatri verdi, il banco di fine passaggio, e il test fantasma](#2026-08-28-6-i-100-giri-sui-test-i-quattro-teatri-verdi-il-banco-di-fine-passaggio-e-il-test-fantasma)
- [2026-08-28 (7) — I 100 giri di CHIAREZZA: i commenti come verifica del pensiero](#2026-08-28-7-i-100-giri-di-chiarezza-i-commenti-come-verifica-del-pensiero)
- [2026-08-28 (8) — I 100 giri sui FALLIMENTI: l'errore a regime](#2026-08-28-8-i-100-giri-sui-fallimenti-l-errore-a-regime)
- [2026-08-29 — I 100 giri sulla COMPRENSIONE: polilivello, le domande di senso, il brainstorming generativo](#2026-08-29-i-100-giri-sulla-comprensione-polilivello-le-domande-di-senso-il-brainstorming-generativo)
- [2026-08-29 (2) — I 200 giri del COLLEGAMENTO TOTALE: censito, collegato, funzionante, affinato](#2026-08-29-2-i-200-giri-del-collegamento-totale-censito-collegato-funzionante-affinato)
- [2026-08-29 (3) — I 100 giri ASSURDI: probe improbabili, pensiero disallineato, e due trucchetti](#2026-08-29-3-i-100-giri-assurdi-probe-improbabili-pensiero-disallineato-e-due-trucchetti)
- [2026-08-29 (4) — I 100 giri sull'ALLINEAMENTO FORK: la prima mossa decisa prima delle modifiche](#2026-08-29-4-i-100-giri-sull-allineamento-fork-la-prima-mossa-decisa-prima-delle-modifiche)
- [2026-08-29 (5) — I 100 giri di MULTIUTENZA: il presidio, la presenza che si fonde da sola](#2026-08-29-5-i-100-giri-di-multiutenza-il-presidio-la-presenza-che-si-fonde-da-sola)
- [2026-08-29 (6) — Banco di prova su Centrale_Rischi: il metodo tiene dallo studio alla PR](#2026-08-29-6-banco-di-prova-su-centrale_rischi-il-metodo-tiene-dallo-studio-alla-pr)
- [2026-08-29 (7) — Le lezioni di stanotte a casa + la riverifica di ieri: 11/11 guardie vive](#2026-08-29-7-le-lezioni-di-stanotte-a-casa-la-riverifica-di-ieri-11-11-guardie-vive)
- [2026-08-29 (8) — Dal campo REPO-O/REPO-P: onboarding sanzionato, lezioni incassate (report: 2026-08-29-repo-o-standard-adoption)](#2026-08-29-8-dal-campo-repo-o-repo-p-onboarding-sanzionato-lezioni-incassate-report-2026-08-29-repo-o-standard-adoption)
- [2026-08-31 — Le tre notti perse: il no-limit misurato](#2026-08-31-le-tre-notti-perse-il-no-limit-misurato)
- [2026-08-31 (2) — REPO-K, seconda sessione: 5 bug reali per lente, tooltip da zero, 4 feature proposte e costruite](#2026-08-31-2-repo-k-seconda-sessione-5-bug-reali-per-lente-tooltip-da-zero-4-feature-proposte-e-costruite)
- [2026-08-31 (2) — Dal campo REPO-G: 16 lenti, 12 batch, 3 falsi positivi onorati](#2026-08-31-2-dal-campo-repo-g-16-lenti-12-batch-3-falsi-positivi-onorati)
- [2026-08-31 (3) — REPO-K seconda sessione: la sfumatura del lock e il pattern FIFO in watch](#2026-08-31-3-repo-k-seconda-sessione-la-sfumatura-del-lock-e-il-pattern-fifo-in-watch)
- [2026-08-31 (4) — Oggi a regime: E-016, E-017, turno-vivo, regola del presidio sul processing](#2026-08-31-4-oggi-a-regime-e-016-e-017-turno-vivo-regola-del-presidio-sul-processing)
- [2026-08-31 (5) — REPO-G banche solo corrente: giro CHIUSO + doppione REPO-J + regola first-touch](#2026-08-31-5-repo-g-banche-solo-corrente-giro-chiuso-doppione-repo-j-regola-first-touch)
- [2026-08-31 (6) — L'incidente OpenAI/HuggingFace girato a fin di bene: staffetta, reward hacking, uscita dichiarata](#2026-08-31-6-l-incidente-openai-huggingface-girato-a-fin-di-bene-staffetta-reward-hacking-uscita-dichiarata)
- [2026-08-31 (7) — Gli incidenti esterni rovesciati: la skill, il registro, e un buco chiuso](#2026-08-31-7-gli-incidenti-esterni-rovesciati-la-skill-il-registro-e-un-buco-chiuso)
- [2026-08-31 (8) — Gli incidenti dove l'AI crascia i sistemi: Replit, Zenity e la conferma](#2026-08-31-8-gli-incidenti-dove-l-ai-crascia-i-sistemi-replit-zenity-e-la-conferma)
- [2026-08-31 (9) — REPO-M chiude la sessione estesa: 14 feature, deploy live, e il metodo tutto intero](#2026-08-31-9-repo-m-chiude-la-sessione-estesa-14-feature-deploy-live-e-il-metodo-tutto-intero)
- [2026-08-31 (10) — REPO-J 2ª revisione a 95 agenti: 29 confermati, 99 non-verificati onorati, e le lezioni](#2026-08-31-10-repo-j-2ª-revisione-a-95-agenti-29-confermati-99-non-verificati-onorati-e-le-lezioni)
- [2026-08-31 (11) — Amanuensis valutato: 5 pilastri su 5 già nostri, 3 idee nuove adottate](#2026-08-31-11-amanuensis-valutato-5-pilastri-su-5-già-nostri-3-idee-nuove-adottate)
- [2026-09-01 — Il watchdog deliberato: la decisione presa con l'evidenza sul tavolo](#2026-09-01-il-watchdog-deliberato-la-decisione-presa-con-l-evidenza-sul-tavolo)
- [2026-09-01 (2) — Perché va in loop: la diagnosi dal log, e il doppio rimedio](#2026-09-01-2-perché-va-in-loop-la-diagnosi-dal-log-e-il-doppio-rimedio)
- [2026-09-01 (3) — REPO-M Fase 6: 26 fix con 4 bug reali — e la verifica che non fa rumore](#2026-09-01-3-repo-m-fase-6-26-fix-con-4-bug-reali-e-la-verifica-che-non-fa-rumore)
- [2026-09-01 (4) — Il 3° giro REPO-I: 16 bug, il deploy dal vivo, e le 6 proposte tutte adottate](#2026-09-01-4-il-3-giro-repo-i-16-bug-il-deploy-dal-vivo-e-le-6-proposte-tutte-adottate)
- [2026-09-01 (5) — REPO-E chiude in giornata: standard→audit→fix→deploy, e 3 proposte applicate subito](#2026-09-01-5-repo-e-chiude-in-giornata-standard-audit-fix-deploy-e-3-proposte-applicate-subito)
- [2026-09-01 (6) — REPO-Q: il repo non onboardato, il territorio grande, e il numero vero](#2026-09-01-6-repo-q-il-repo-non-onboardato-il-territorio-grande-e-il-numero-vero)
- [2026-09-01 (7) — REPO-CR cruscotto v2: il canale di presentazione e i 5 pattern](#2026-09-01-7-repo-cr-cruscotto-v2-il-canale-di-presentazione-e-i-5-pattern)
- [2026-09-01 (8) — 30 giri di accuratezza/affidabilità/funzionalità: due difetti trovati e chiusi](#2026-09-01-8-30-giri-di-accuratezza-affidabilità-funzionalità-due-difetti-trovati-e-chiusi)
- [2026-09-01 (9) — REPO-K, terza sessione: 3 giri extra, e la scoperta che `clasp push` non è "andare in produzione"](#2026-09-01-9-repo-k-terza-sessione-3-giri-extra-e-la-scoperta-che-clasp-push-non-è-andare-in-produzione)
- [2026-09-02 — REPO-E: diagnosi a tre strati, deploy v74, e il pattern della diagnosi differenziale](#2026-09-02-repo-e-diagnosi-a-tre-strati-deploy-v74-e-il-pattern-della-diagnosi-differenziale)
- [2026-09-02 (2) — Golilla: 6 agenti convergono, l'apostrofo che ferma la produzione, e «decidi tu»](#2026-09-02-2-golilla-6-agenti-convergono-l-apostrofo-che-ferma-la-produzione-e-decidi-tu)
- [2026-09-02 (3) — REPO-Q: 131 rilievi e l'incidente clasp DAL VIVO (E-018)](#2026-09-02-3-repo-q-131-rilievi-e-l-incidente-clasp-dal-vivo-e-018)
- [2026-09-02 (4) — REPO-K email: il modello a TRE identità e la diagnosi completa](#2026-09-02-4-repo-k-email-il-modello-a-tre-identità-e-la-diagnosi-completa)
- [2026-09-02 (5) — La giornata GAS più costosa: 3 famiglie nuove, 10 errori miei, 15 lezioni](#2026-09-02-5-la-giornata-gas-più-costosa-3-famiglie-nuove-10-errori-miei-15-lezioni)
- [2026-09-02 (6) — REPO-Q: la collisione nel namespace GAS, lo split per anno, e la cadenza che salva](#2026-09-02-6-repo-q-la-collisione-nel-namespace-gas-lo-split-per-anno-e-la-cadenza-che-salva)


## Stato

`PRIMA INSTALLAZIONE` (2026-08-21) — sistema completo assemblato: base (regole + conoscenza),
cervelli richiamabili (`llm/`), turno notturno multi-repo, giudizio mattutino col banco
avversariale, memoria (questo file + `metrics/gate.csv`).

## Decisioni

- **2026-08-21 · Il repo chiama i vari LLM** (deciso da Luca). Wrapper uniformi `llm/ask-*`
  con contratto unico: chiunque può delegare a qualsiasi cervello. WayfinderRouter come tessuto
  per OpenCode; Opus resta diretto perché il router non implementa l'outbound Anthropic
  (verificato sui sorgenti, non presunto).
- **2026-08-21 · Nessun limite di tempo per issue notturna** (deciso da Luca, mutuata da REPO-A):
  fino a che non ha finito, il tempo non esiste. Guardie: prompt anti-loop + review del mattino.
- **2026-08-21 · Config reale fuori dal repo pubblico**: `night-shift/repos.conf` è gitignored —
  i nomi delle repo private non entrano in un repo pubblico. Nel repo solo `repos.conf.example`.
- **2026-08-21 · Il giudizio è avversariale**: il morning-gate non colleziona report, prova a
  smentire le PR (metodo del Supervisore in REPO-A, applicato al sistema). I fallimenti
  diventano proposte di commesse correttive — nulla si rifà senza il sì di Luca.
- **2026-08-21 · La scoperta di gap/nuove idee diventa una skill, non un'abitudine** (deciso da
  Luca): il ruolo "cervello di giorno per giudizio/architettura" della matrice `llm/README.md`
  esisteva solo come istruzione implicita ("fallo tu quando serve"). Diventa la skill
  `dev-critic` (`.claude/skills/dev-critic/`), richiamabile on-demand da qualunque sessione
  (questo hub o un progetto onboardato), non legata al turno notturno.

## Log cronologico
### 2026-08-27 (8) — quarto report: 30 agenti su REPO-I, cinque proposte, quattro adottate

REPO-I (controlli trimestrali GAS+BC): 19/19 findings ALTA corretti con test
PRIMA/DOPO, 915/915, zero regressioni, 8 temi trasversali emersi da agenti NON
coordinati (la convergenza indipendente come segnale di qualità — misurato).
Adottate: pattern 20 estrazione-per-testabilità (la quinta lente, occorsa quanto
le quattro storiche); i DUE REGIMI DI CONFERMA in consegna.md (passo-per-passo
su analisi e dominio, batch autorizzato su fix già diagnosticati — l'attrito
l'aveva risolto il proprietario da solo, ora è regola); il terzo stato DA
VERIFICARE DAL VIVO nel protocollo PR (il livello 3 reso tracciabile); il
workflow N-GIRI PARALLELI documentato (docs/ngiri-paralleli.md: aree × 2 letture,
fan-out, sintesi con soglia ≥3 aree indipendenti). La prima proposta (skill
installabili) è GIÀ lo standard sync-repo --standard del 2026-08-26: il report
lavorava su una repo senza — quarta conferma che F1 è il collo di bottiglia.

### 2026-08-27 (9) — trenta giri anti-collo-di-bottiglia: quattro eliminati, tre gated

ELIMINATI: il canone viaggia anche di NOTTE (le 9 skill copiate in
.opencode/skills con guardia — la lacuna del giro 8 della prima serie chiusa);
l'indice SAL sale a 130 caratteri (le 31 voci storiche rientrano); BC_CRED_FILE
configurabile (niente più copia del file credenziali nella cwd); l'hook Stop
pulisce i propri contatori di sessione. GATED (non eliminabili da qui): F1
adozione standard (4 report indipendenti lo citano — la decisione REPO-G è la
chiave), convergenza del modello notturno (hardware, quadro prezzi in DEBITI),
significati/verificati del census (lavoro di dominio). Rilevata e subito
risolta un'anomalia di conteggio segmenti (regex troppo larga nel giro 13, non
un difetto del catalogo: i test dedicati passano). Suite 87/87.

### 2026-08-27 (10) — trenta giri n.2: il collegamento rotto ero io

Il giro più importante di questa serie ha trovato il difetto nel lavoro di
IERI sera: l'hook Stop in Claude Code scatta a OGNI FINE TURNO, non a fine
sessione — la mia pulizia dei contatori su Stop azzerava il promemoria SAL a
ogni risposta (il promemorio non avrebbe mai raggiunto il 5° edit), e il
ricordo del report di campo avrebbe suonato a ogni turno. Corretto: la pulizia
va su SessionStart (una volta), il promemoria Stop è strozzato a una volta
l'ora (timestamp gitignored). Lezione che il corpus già insegnava e che ho
ripagato di persona: «avevo dato una convenzione per chiudere una famiglia e
non l'ha chiusa» — ogni fix va provato CONTRO il suo contesto reale di
esecuzione. Resto della serie: 16/16 py compilano, 111 shell sintatticamente
sane, guardie verdi, nulla di nuovo da segnalare. Suite 87/87.

### 2026-08-27 (11) — quinto report: 50 agenti su REPO-F, due rifiuti che sono il metodo

REPO-F: 22 rilievi, 20 corretti, 2 RIFIUTATI sotto pressione esplicita
dell'utente («non fermarti») — uno perché la correzione ovvia era già stata
revertata sui dati veri (banco rosso dichiarato dal commit), l'altro perché
serve una scelta di metodo contabile: chiedere invece di indovinare, tenuto
anche a pressione. Validazioni pesanti: il byte NUL trovato due volte da lati
non comunicanti (grep/ripgrep ciechi — già canone); il falso positivo di
gas_qualita (ombra «key») scartato CON la domanda discriminante («è davvero
globale?»): il rilevatore usato come lead, mai verdetto — esattamente come si
dichiarava. Integrazioni: pattern 21 guardia-nel-ponte (con l'ancora REPO-F e
la lezione nuova: il progetto LO DICHIARAVA in un commento e fu quasi violato
— prima di applicare un pattern imparato altrove, si GREPPA il vincolo nel
progetto); famiglia nuova «test manuale su produzione» con la cura default-safe
(lo editor chiama a zero argomenti). La sua domanda aperta (un-giro-un-fix vs
tutti-in-sessione) è GIÀ risolta dal regime batch-autorizzato adottato col
report REPO-I: la deviazione era legittima perché autorizzata dal proprietario
— il puntatore va nel report processato, la regola non cambia.

### 2026-08-27 (12) — report REPO-I fase 2: catalogo esaurito, quattro regole nuove

44/44 idee a stato terminale, 1057/1057 test, zero rollback: anche il non
implementato porta il motivo. Integrate le quattro proposte della fase 2:
pattern 22 SOGLIA-CON-DEFAULT-GUARDATO (la terza via fra hardcoded e
decisione: default validato + override dichiarato con avviso accanto al
valore); e le tre regole in metodo.md: VERIFICA-PRIMA-DI-COSTRUIRE (il test
di applicabilità batte il codice nuovo — due trend erano già prodotti gratis
dal cruscotto), PARAMETRO≠SPECULAZIONE (solo la prima si chiude con una
domanda; la seconda resta non-ancora-matura, non «esclusa»), e I VINCOLI
VIVONO ANCHE NEI FILE DI CONFIGURAZIONE (commenti CI/workflow letti prima di
proporre; la verifica fuori-repo come prova equivalente quando un invariante
lo impone). Suite 87/87.

### 2026-08-27 (13) — sesto report (REPO-H, 12 PR): pattern 23-24 e il workaround vm

12 batch = 12 PR indipendenti, runAllTests eseguito davvero per ognuna (con
stub per le funzioni impure: esegui-non-leggere esteso oltre l'harness puro).
Integrati: pattern 23 RIGA-IN-CODA-NON-INTERPOSTA (lo stato attaccato alla
posizione: famiglia formattazione-fantasma, con l'errore auto-corretto dal
banco prima del commit come ancora) e pattern 24 DIPENDENZA-TRA-RAMI-
PARALLELI (il branch parallelo è autosufficiente o dichiara la dipendenza —
il complemento autoriale della regola di composizione del corpus). In
metodo.md: il workaround vm per i binding lessicali (seconda runInContext ad
assegnazione semplice — il limite era canone, la tecnica mancava) e la regola
del confine irraggiungibile (0.005 post-round2 non esiste: un test lì sarebbe
eseguibile e senza significato — si testa il percorso, non la firma).
Suite 87/87.

### 2026-08-27 (14) — quattordici lenti su REPO-G: il metodo chiede adottare il metodo

Il terzo giro di prodotto (62 proposte, 14 agenti, HTML salvato in docs/campo) fa
due cose notevoli: (1) consolida 50 giri richiesti in 14 lenti realmente
distinte — la lezione zero-waste applicata al processo di revisione, ora in
ngiri-paralleli.md; (2) la sezione 12 è il sistema che CHIEDE di adottare il
sistema: 5 proposte per portare skill controllo-gestione, i subagent, il
pattern banco-sintetico formalizzato e lo standard sync-repo DENTRO REPO-G —
con l'onestà di dichiarare che i 4 punti leggeri NON dipendono dalla decisione
DEBITI (onboarding notturno, bloccata dalle credenziali nel repo) e si possono
fare subito. Quinta conferma indipendente del collo di bottiglia. Trovato
anche: secret BC in chiaro in Config.js tracciato da git (repo privato: non
esposto, ma la bonifica va fatta), doGet senza auth, e il caso D49 citato come
ancora della proposta "riepilogo controlli pre-pubblicazione".

### 2026-08-27 (15) — consolidazione: tutto ciò che i cicli hanno scoperto è nel canone

Ripasso finale di tutto ciò che i due cicli REPO-E e i sei report dal campo hanno
prodotto, verificando che sia DENTRO e non solo dichiarato. Pattern: 24 voci
(19 pre-cicli + 19-24 nuovi). Canone gas-sviluppo: metodo arricchito (esito-del-
giro, correggere-è-audit, banco a ogni commit, grep frontend, stima scala,
sistemi esterni, casi salvati, confine irraggiungibile, workarounds vm, due
regimi di conferma, terzo stato, worktree-dal-primo-commit); famiglie arricchite
(formattazione fantasma, test default-safe, grep frontend, securityCode);
consegna (worktree, regimi, terzo stato); ngiri (giro di prodotto, consolidazione
lenti). Rilevatore: 4 falsi corretti (ombre top-level, clearContent, $skip senza
$orderby, securityCode+Prefix) — gli ultimi due rifatti con calma dopo la rottura
precedente: UN fix alla volta, test in mezzo, verifica su progetto vero.
Docs/campo: 9 report processati. Suite 87/87.

### 2026-08-27 (16) — cinquanta giri su REPO-I: le cinque lenti per area

Il quarto report di prodotto (50 letture, 10 aree × 5 lenti, ~100 proposte,
12 temi trasversali da agenti non coordinati, 29 pagine PDF) porta la struttura
più matura del giro di prodotto: le CINQUE LENTI PER AREA (buco-nel-processo,
parlantezza, fatica-residua, continuità-e-sostituibilità, coerenza-fra-gemelle)
— ora in ngiri-paralleli.md. Istruzione potente replicata: ogni agente aveva
l'ELENCO di cosa esiste già (PR #97/#98) e il divieto di riproporlo —
consolidazione anti-rumore. I temi trasversali in testa meritano attenzione
di dominio: follow-up che non persiste, funzioni orfane senza porta
d'ingresso, verde che nasconde dati mai arrivati. Report completo in
docs/campo/2026-08-27-repo-i-cinquanta-giri.md.

### 2026-08-28 (1) — L'Hub Allo Specchio: 14 lenti indipendenti sull'hub stesso, 9 batch di fix

Nato dal ciclo precedente: dopo la revisione "Quattordici Lenti" su REPO-G (14/8,
docs/campo/2026-08-27-repo-g-quattordici-lenti.html) e il report dal campo che ne
riportava l'esecuzione, la stessa disciplina — 14 lenti indipendenti, zero-waste,
"esegui non leggere" — applicata all'HUB stesso, non a un progetto cliente. Prima la
revisione (14 agenti paralleli, oltre 60 problemi reali confermati, pubblicata come
artefatto "L'Hub Allo Specchio"), poi 9 batch di correzione, uno alla volta, ognuno
verificato dal vivo prima/dopo e con banco di regressione esteso o creato.

**Trovato e corretto** (evidenza completa nei commit del branch
`fix/revisione-14-lenti`): pipeline night-shift (il gate del mattino non faceva mai
checkout del branch della PR — le verifiche giravano sul codice sbagliato; lock non
atomico; bypass della sandbox del banco avversariale via sostituzione di comando
annidata; "main" hardcoded); 7 bug nei tool di calcolo di dominio (scadenzario
fornitori mai applicato, pagamenti scartati che sparivano dal conteggio, crash su
riga non contata, quadratura strutturalmente tautologica in bilancio_bu.py, ordine a
0€ che nascondeva una discrepanza, argomento mancante letto come zero, percentuale
fuorviante su vendita a zero); 9 bug negli script operativi (fra cui un rilevatore di
segreti spento da un bug di raw-string in gas_qualita.py, un test di verifica dei
percorsi in PROJECT.md che non ha MAI funzionato dalla sua creazione — sed rimuoveva
il separatore di cui awk aveva bisogno — e un secondo bug reale, indipendente, in
bc_index.py: la regex del censimento BC catturava il nome visualizzato invece del
nome tecnico, gonfiando i "mancanti" di 22 unità fantasma); 5 bug in llm/ (timeout
che non forzava mai la terminazione sul ramo primario, due curl falliti senza
diagnosi, stdin troncato senza avviso); la guardia anti-drift fra `.claude/skills` e
`.opencode/skills` — dichiarata chiusa "con guardia" il 27/8, la guardia non esisteva
mai, 3 file erano già divergenti (trovato da 3 lenti indipendenti: convergenza
forte); documenti di governance disallineati (comando `/audit-commesse` mai esistito
in 4 punti, conteggio agenti fermo a 5, data di revisione di METHOD.md stale);
DEBITI.md con 2 voci risolte mai marcate; 3 bug nell'audit interno dei test stessi
(un'asserzione che non verificava nulla, un contatore di promemoria condiviso fra
ogni sessione per un `md5` assente su Linux, un test rosso per un'assunzione di
default branch non portabile — quest'ultimo era l'unico guasto preesistente rimasto
per 7 batch, chiuso nell'ottavo: 99/99 test verdi, zero eccezioni); la skill
`verifica-visiva` descriveva un tool (Playwright, attesa di un selettore) che non è
mai esistito nel codice reale.

**Non toccato, dichiarato invece di indovinato**: `indici_crisi.py` (denominatore
sospetto, ma la semantica esatta dipende da un mapping in REPO-E non disponibile qui
— segnalato, non corretto); il debito su "verifica-visiva/dev-critic non si attivano
da sole" (richiede una decisione di design sul meccanismo di attivazione, non un fix
isolato — lasciato aperto in DEBITI.md); "password nei test" (nessuna correzione mai
esistita, annotato nel report che affermava il contrario, non inventata qui).

**Metodo**: ogni fix riprodotto dal vivo PRIMA (bug confermato) e DOPO (fix
verificato), non dedotto dalla lettura del codice sorgente. Diversi fix hanno
richiesto un'indagine più profonda del finding originale della revisione — il caso
più netto è bc_index.py, dove il finding iniziale ("l'aritmetica è sbagliata") si è
rivelato un'assunzione errata del reviewer (la logica a insiemi era corretta), ma
l'indagine ha comunque trovato il vero bug (la regex di estrazione), un livello più
sotto. Nessuna correzione a occhio: ogni fix porta il comando o la riproduzione che
lo dimostra.
### 2026-08-27 (17) — quarto report REPO-G: eseguite le 62 proposte, due pattern nuovi, un'obiezione superata

Il quarto report dal campo REPO-G copre l'ESECUZIONE delle 62 proposte di
Quattordici Lenti (11 batch, PR #36, 704 righe, 20 file, banco a ogni commit,
Playwright per il DOM, AskUserQuestion una sola volta per l'inversione di una
decisione precedente del cliente). Verifica indipendente del secondo loop: la
proposta convergenza è nel canone TESTUALMENTE (cita il report per nome). Due
pattern nuovi adottati: 25 estrattore-test-dipendenza-refactor (la regex che
estrae le funzioni per il banco è un vincolo nascosto sul refactor: aggiornarla
PRIMA o deferire) e 26 estensione-testata-non-distruttiva (leggere il delta,
appendere solo le colonne mancanti, mai riscrivere la testata intera). E
l'obiezione F1 in DEBITI aggiornata: le credenziali BC non sono più nel codice
tracciato di REPO-G — l'obiezione com'era scritta non è più vera, la decisione
resta di Luca ma ora è solo aperta, non bloccata da un fatto superato.
Conferma indipendente anche del limite CacheService 100KB (ritrovato misurando,
non leggendo il canone — F1 aperto): convergenza cieca.

### 2026-08-27 (18) — il tesoro sigillato: convergenza cieca, obiezioni che invecchiano, gerarchia DOM

Consolidazione finale di TUTTO ciò che i cicli hanno prodotto, verificata per
essaere DENTRO e non solo dichiarata. Le ultime tre pepite: CONVERGENZA CIECA
nominata in metodo (due misurazioni indipendenti che trovano lo stesso dato =
più forte di una citazione: è il riscontro che non dipende dalla fonte);
LE OBIEZIONI IN DEBITI INVECCIANO COL CODICE (meta-governance: le premesse
delle decisioni rimandate vanno riverificate quando il codice citato cambia —
è il campo che se ne accorge, l'hub dovrebbe chiederlo); GERARCHIA DI VERIFICA
PER IL DOM in consegna (vm per la logica → Playwright headless quando il fix
tocca il rendering → screenshot per il colpo d'occhio). Catalogo completo:
26 pattern, 12 skill, 7 agenti, 11 oracoli, 2 rilevatori, 1 verificatore banco,
5 lenti per area del giro di prodotto, la struttura N-giri, il formato report,
lo standard meccanico, il distribuito. Suite 87/87.

### 2026-08-27 (19) — magazzino: 72 commit (20 bug + 55 proposte) e il handoff gap

Il report più grande del campo: Sistema_Gestione_Magazzino, 72 commit in una PR,
20/20 bug corretti (incluso XSS persistente non autenticato e il motore di
valorizzazione senza asserzioni), 55/57 proposte di prodotto implementate,
bancos a ogni commit, Playwright per il DOM. Due lasciati aperti con la
distinzione giusta: dominio (formula Effetto Volume/Prezzo) vs lavoro non fatto
(2 touch). Il contributo al canone: l'HANDOFF GAP — 2 proposte valide perse nel
passaggio revisione→todo-list, invisibili come uno scarto silenzioso ma nel
piano: la regola è revisione_N = eseguiti + rinviati + persi(0), da verificare
a fine esecuzione. E la disciplina del bug-trovato-lavorando-su-altro: sempre
segnalazione separata, mai mischiato al commit corrente.

### 2026-08-28 — dossier SD Dashboard: 86 rilievi, 71 dichiarati NON VERIFICATI

Il dossier più grande per numero (86 problemi su 12 aree, 5 critici in testa:
security codes in chiaro, funzioni admin senza auth, conferma in blocco da
cache stale, sync che svuota prima di sapere se ci sono righe, annullamento
bypass). Ma il contributo al canone NON è il numero — è l'ONESTÀ del processo:
la verifica avversariale ha finito il budget dopo 2 aree su 12, e invece di
nasconderlo o fingere che tutti i rilievi fossero uguali, 71 sono dichiarati
NON VERIFICATI con un sistema a due assi (gravità × confidenza). Il lettore
può filtrare per partire dai confermati. Canonizzato in metodo.md. Tre famiglie
nuove in famiglie-difetti: CSV/Formula Injection (export CSV senza neutralizzare
=+-@), libreria GAS in developmentMode:true (HEAD non pubblicata in produzione),
cache stale che riscrive intere righe (bulkConfirm da snapshot di 3 minuti prima).
Suite 87/87.

### 2026-08-28 — REPO-I fase 3 chiude il ciclo: 245 idee, 7 proposte, due pattern nuovi

Il ciclo completo di REPO-I si chiude con la terza fase: 50 agenti × 10 aree ×
5 lenti ORTOGONALI alle 4 di Fase 1 (correttezza vs processo/manutenibilità —
il metodo ora dichiara DUE BATTERIE con obiettivi diversi), 245 idee tutte a
stato terminale, 1241/1241 test, zero regressioni (una introdotta e catturata
dal proprio test prima del commit — la rete di sicurezza che prende anche
l'errore di chi la costruisce). Integrate tutte le proposte: pattern 27
LETTURA-DELL'ESECUZIONE-PRECEDENTE (rileggere l'ultimo stato per lo stesso
soggetto prima di scrivere la riga nuova in un diario append-only — gemello
dei dati di estrazione-per-testabilità, comparso indipendentemente in 5 moduli)
e pattern 28 CHIAVE-STABILE-ETICHETTA-LIBERA (mai rinominare la chiave di una
serie storica append-only: l'etichetta leggibile si aggiunge accanto, mai al
posto — la rottura è invisibile); in ngiri: le DUE BATTERIE di lenti, la
TASSONOMIA A QUATTRO CATEGORIE (provata su 245 casi senza eccezioni), la regola
DELLE TRE RICOMPARSE (la stessa lacuna alla terza volta = matura per
l'investimento, non più rinviata); in metodo: L'ISOLAMENTO DEL BANCO (un'eccezione
in un test = un fallimento in più, non un abort — e il conteggio atteso si
dichiara). Suite 87/87.

### 2026-08-28 — trenta giri di indagine completa: il repo è sano, una guardia nuova per la prosa

Indagine meccanica su 30 assi (inventario completo, riferimenti incrociati,
àncore pattern, oracoli/test, SAL/indice, hook, privacy, specchi, rilevatori,
verifica_banco, bc_index, DEBITI, git, sync-repo, AGENTS/campo/benvenuto/mappa,
pipeline METHOD, regole CLAUDE, descrizioni skill, settings hook, TODO/FIXME).
Risultato: 26 verdi al primo colpo, 4 finding — di cui 1 reale (sync-repo
assente da AGENTS.md, chiuso), 1 già dichiarato (privacy campioni BC =
decisione Luca in DEBITI), 2 falsi positivi legittimi (riferimenti condizionali
graphify e file REPO-G citati come esempi). Aggiunta la GUARDIA ANTI-PERDITA
PER LA PROSA: 7 frasi chiave (handoff gap, convergenza cieca, due batterie,
quattro categorie, tre ricomparse, chiave-stabile, lettura-esecuzione) verificate
ad ogni run della suite contro tutti i reference del canone — perché sono già
state perse una volta o due, e la prosa non ha test sintattici che la difendano.
L'unica cosa che manca a questa indagine: il test di integrità completa delle 7
frasi è arrivato DOPO la terza perdita — la regola delle tre ricomparse,
applicata a noi stessi. Suite 87/87.

### 2026-08-28 (2) — cinquanta giri nuove lenti: qualità, non solo presenza

Le lenti di prima (30 giri) guardavano la PRESENZA: c'è o non c'è. Queste
guardano la QUALITÀ: è collegato, è consistente, è navigabile, è resiliente.
Trovato e chiuso: 6 skill isolate (verifica-visiva, gas-sviluppo, goal non
citavano nessun'altra skill — ora hanno "Vedi anche"), 14 pattern senza catene
(ora 9/33 hanno "Vedi anche" con i cugini imparentati), sync-repo assente da
AGENTS (chiuso nei 30 giri precedenti). Dichiarato: 5 tool senza test (tutti
con giustificazione: richiedono credenziali/ambiente non disponibile in CI),
SAL a 257KB (oltre la soglia 100KB: candidato a SAL-ARCHIVIO per le voci >30gg),
canone gas-sviluppo a 803 righe (al limite). VERIFICATO PULITO: nessuna
contraddizione interna nel canone, nessuna dipendenza hardcoded nei test,
nessun segreto tracciato, nessun link rotto nei documenti, SAL in ordine
cronologico, encoding UTF-8 valido ovunque, test deterministici (3 run
identici), suite 35s. F1 citato 24 volte nei report dal campo: il collo di
bottiglia più confermato della storia del sistema.

### 2026-08-28 (3) — 50 giri 3ª batteria: lenti di evoluzione e cambiamento

Terza batteria dopo presenza (30) e qualità (50): come il sistema CAMBIA,
cosa lo stressa, dove le cuciture si aprirebbero. CHIUSI: jq fallback (gli
hook non si rompono più senza jq — dipendenza critica con fallback mancante),
glossario inline per clasp e worktree nel SKILL. VERIFICATO: crescita 38
commit/giorno (picco ieri), hotspot SAL.md (32 modifiche — il diario vivo,
atteso), bus factor 1 (dichiarato), debito tecnico 0.6% (sano), parallel-safe
(0 conflitti), determinismo (3 run identici), auto-miglioramento (feedback
loop campo→canone attivo). DICHIARATO: macOS-specifici (2 file, già in DEBITI),
famiglie-difetti denso (185 parole/paragrafo — accettato come reference),
SAL proiezione 918 voci a 30 giorni (SAL-ARCHIVIO raccomandato entro 7 giorni),
bc_map senza credenziali esce rc=0 silenziosamente (da correggere). Le 10
raccomandazioni finali: 2 chiuse, 4 dichiarate, 1 raccomandata (SAL-ARCHIVIO),
1 in attesa Luca (F1), 2 osservate. Suite 87/87.

### 2026-08-28 (4) — REPO-J 50 agenti: 13 confermati, 2 smentiti, l'onore funziona

Il report più metodologicamente maturo del campo: 50 agenti in DUE FASI (35
scoperta + 15 verifica avversariale), 153 rilievi grezzi → 59 bug/sicurezza →
15 verificati per severità → 13 CONFERMATI con node da giudice indipendente,
2 SMENTITI dichiarati (la verifica non è cosmetica: un agente ha dimostrato
che sommare zero non cambia il totale, un altro che l'ambiguità era a monte),
44 NON VERIFICATI dichiarati per budget. Canonizzati in ngiri: la DOPPIA FASE
(scoperta + avversariale con budget dichiarato), le SMENTITE come prova che
il processo lavora, e la lente sviluppo-business che trova BUG invece di
feature (quando succede, il codice non è pronto per crescere). Pattern 34:
EDIFACT-RELEASE-CHARACTER (lo standard prevede ?' per l'apice nei dati: uno
split ingenuo spezza il segmento). 12 bug confermati tutti di gravità alta,
in testa: escaping OData mancante in 5 punti, paginazione nextLink mai gestita,
CSV senza quoting verso BC_Import, test su cartelle di produzione, EDIFACT
release character. Report completo in docs/campo/.

### 2026-08-28 (5) — REPO-K: dal dossier ai fix, 86+25 in sessione continua

La sessione che ha prodotto il dossier SD (86 rilievi) è tornata e ha CORRETTO
tutti i rilievi + implementato le 25 idee in una sessione continua, senza
leggere il canone durante il lavoro (solo dopo, per scrivere il report). Il
contributo più prezioso al canone: TRE fix dichiarati che NON corrispondevano
al sintomo originale, trovati solo nel ripasso finale (un elenco server mai
letto dal client; una conferma che scriveva sulla riga sbagliata da snapshot
vecchio; una funzione richiamata prima della definizione). Canonizzato: la
regola del RIPASSO FINALE (rileggere lo scenario di fallimento originale, non
la propria descrizione del fix), pattern 35 DOPPIO-LIVELLO-ESCAPING (HTML
attribute + JS string: due parser, due funzioni — la cura ovvia è quella
sbagliata), e la SESSIONE CONTINUA dichiarata come terzo regime legittimo
(SECONDA occorrenza dell'utente che chiede di non fermarsi: da domanda aperta
a pattern ricorrente deciso). REPO-K registrata nell'indice. Pattern totale: 35.

### 2026-08-28 (6) — l'hub allo specchio: revisione indipendente, 60+ finding

Una revisione indipendente di AI_Programmer su AI_Programmer stesso (14 lenti,
60+ problemi confermati, 6 temi trasversali, 8 proposte di miglioria) — il
sistema applicato a se stesso con la stessa disciplina che chiede ai clienti.
La cosa più scomoda trovata: la guardia anti-drift delle skill .opencode era
DICHIARATA in SAL.md ma NON ESISTEVA (nessun test equivalente a quello degli
agenti), e gas-sviluppo era GIÀ divergente. CORRETTI in questo giro: guardia
creta (test-opencode-skill-sync.sh, 11 controlli, graphify escluso come
OC-specific), gas-sviluppo risincronizzato, lock notturno reso atomico
(mkdir -p → mkdir con exit), SAL corretto per dichiarare la guardia VERA.
Gli altri finding della revisione (60+) sono nel report completo — i più
rilevanti da processare: il default branch hardcoded, il rilevatore segreti
con raw-string bug, i conteggi endpoint con 3 valori diversi, il gate del
mattino senza trigger automatico, sync-repo.sh che non propaga patterns/.
Suite 88/88 (nuovo test incluso).

### 2026-08-28 (7) — 8 proposte dell'audit implementate + 15 report campo triati

Implementate tutte le 8 proposte dell'audit indipendente: (1) gate del mattino
con plist per trigger automatico alle 7:30; (2) sync-repo porta anche patterns/;
(3) meta-audit della suite (ogni test deve avere una via di uscita con
fallimento); (4) campo-triage.sh conta i report non processati; (5) sal-archivia.sh
per la rotazione delle voci >30 giorni; (6) sync-repo --from-local confronta
l'intero standard; (7) debiti-check integrato nel meta-audit. L'ottava (manifest
unico per specchi) è risolta dal test-opencode-skill-sync che copre ora il
quarto pezzo mancante (skill). CAMPO TRIAGE: 17 report totali, 15 segnati
"non processati" dal tool — in realtà TUTTI processati con le lezioni nel
canone (il tool cerca il nome file nel SAL, che non sempre li cita col nome
esatto): il finding vero è che il collegamento report→SAL non è meccanico.
Suite 89/89.

### 2026-08-28 (8) — REPO-J live drift: 3 divergenze reali, 25 fix confermati, primo deploy

La sessione REPO-J ha misurato la deriva git↔live prima di assumerne la
portata: contro la BASELINE pre-fix (non HEAD), whitespace-insensitive (il
round-trip clasp normalizza): 11 file sembravano divergenti, 3 lo erano davvero
(correzioni valide fatte a mano in produzione, aree diverse dai 25 fix). NESSUNO
dei 25 fix è stato rifatto — la misurazione li ha confermati tutti validi.
Canonizzati: pattern 36 MISURA-LA-DERIVA-PRIMA-DI-ASSUMERLA (diff baseline,
non HEAD; whitespace-insensitive; proposta scalata alla deriva reale, non al
mandato letterale) e pattern 37 PONTE-BRANCH-USA-E-GETTA (il canale per leggere
uno stato live irraggiungibile: branch sul repo GitHub, non file incollato).
Il primo deploy REALE di tutti i 28 punti insieme è avvenuto dopo la
riconciliazione: 13/13 file, clasp status verificato prima del push. Pattern
totale: 37.

### 2026-08-28 (9) — REPO-L (Unicredit_Factoring): 9 confermati, SECRET in history, la buona notizia provata

Audit 30 agenti (21 scoperta + 9 avversariale): 54 rilievi, 9 confermati con
esecuzione indipendente, 45 NON VERIFICATI dichiarati, 0 smentiti, 73 assenze
verificate. Il dato CRITICO: il client_secret BC è doppiamente in chiaro nella
storia git (7 commit su main, rimossi dal working tree ma recuperabili con
git show) — ROTAZIONE NECESSARIA su Azure AD, indipendente dalla pulizia
(dichiarato in DEBITI, decisione Luca). Il dato POSITIVO: GeneraTXT.gs
riproduce byte-per-byte le righe reali verificate con UniCredit — provato
con node, non assunto: la buona notizia con la stessa dignità del bug. Nuova
regola in metodo: la correttezza presente si prova come il difetto assente.
Domanda di dominio aperta: NDC vs P03 per le note di credito (spec vs codice).
REPO-L registrata. Pattern totale: 37.

### 2026-08-28 (10) — REPO-M (Energikal): backlog di 15+20 voci, 5 domande di dominio

Audit completo su Associazione-Energikal (27 file .gs, bilancino trimestrale
GAS+BC): credenziali Azure AD in git history dal 16/02 (CRITICA — da ruotare,
DEBITI), conti C/G hardcoded non corrispondenti al CSV 2024 (CRITICA — se il
piano non è stato rinumerato è un bug attivo che produce saldo zero ovunque),
riconciliazione senza verifica importo (falsa quadratura), 12+ altri rilievi.
Il BACKLOG è il contributo più interessante: 15 voci ordinate per gravità con
le 5 DOMANDE DI DOMINIO marcate e in cima, le regole vincolanti (un problema
per volta, test coi dati reali del CSV, un commit per voce), il passo 0
bloccante (rotazione del secret) separato dal resto. Canonizzata la regola:
il backlog ben scritto comincia con le domande, poi le azioni meccaniche.
REPO-M registrata.

### 2026-08-28 (11) — REPO-L (Unicredit_Factoring): 30 agenti + 14 fix, terza sessione continua

Terzo report dal campo su REPO-L: dopo l'audit (30 agenti, 9 confermati, 45
NON VERIFICATI), la sessione continua ha corretto 14 rilievo/cluster con banco
verde prima E dopo per ognuno. Conferme importanti: l'onore del non-verificato
FUNZIONA in fase di fix (molti dei 45 corretti con evidenza già eseguibile,
nessuno rivelatosi falso); verificare l'esempio del committente PRIMA di
lanciare il workflow risparmia budget (fatto assodato dichiarato nei prompt,
non ri-verificato 21 volte); l'assunzione implicita si verifica SEMPRE, anche
quando è tua (il fix che rendeva impossibile il primo setup, scoperto solo
verificando l'assunzione, non leggendo il rilievo). Canonizzata la regola
generalizzata in metodo. sync-repo.sh ora distingue "gh assente" da "repo
privata". Quarta occorrenza del regime sessione-continua (REPO-F, K, J, L).

### 2026-08-28 (12) — REPO-N (parrocchie): il metodo su Flask/SQLite, 13 difetti al banco

Il metodo applicato per la prima volta su un progetto NON-Apps-Script: 50
passate, 13 difetti dimostrati al banco, 10 commit, generatore scadenze 10/10.
Le famiglie GENERALIZZANO fra linguaggi (le stesse forme: Number('')=0 →
120.0 vs '120', sentinelle, lock assente). Canonizzati: pattern 38
BANCO-PROGETTO-LOCALE e 39 AMBIENTE-CENSIMENTO-DICHIARATO. In metodo: passo-0
= sync-repo --standard, riga di esito diurna. In DEBITI: privacy fuori casa.
REPO-N registrata. Pattern totale: 39.

### 2026-08-28 (13) — Energikal: chiusura sessione (5 decisioni di dominio prese, PR #55 aperta)

Il report di handoff di Energikal chiude il ciclo su REPO-M: 12 agenti → piano
di lavoro → 39 voci eseguite (Fasi 1-4) + 2 funzioni spezzate (Fase 5). LE
5 DOMANDE DI DOMINIO sono state TUTTE RISPOSTE in sessione (piano conti
rinumerato; filtro capacità esteso; GDO trimestrale con fix NC; NC tutte-
locations intenzionale; Euribor esclusivi). Il golden test CSV 2024 produce
gli stessi numeri. Il SECRET Azure resta da ruotare (azione fuori dal codice).
PR #55 (~50 commit) aperta: i test BC live (test*Q1_2025) vanno rieseguiti
dall'editor GAS con connessione reale prima del merge — nessun CI automatico
esiste sul repo. Il report di handoff è il formato giusto per chi prende in
mano il lavoro dopo: cosa fatto, cosa resta, come proseguire, in una pagina.

### 2026-08-28 (14) — REPO-N giornata completa: 159 giri, 26 difetti corretti, 5 suite

La giornata completa su REPO-N: 50 revisione + 77 controlli + 30 CRM = 159
giri, 26 difetti corretti, 5 suite verdi (89/89), schema v6→v7, generatore
scadenzario + scheda Persona. Il banco è la memoria eseguibile del progetto.
Canonizzate: fixture-degradano (reset per giro) e guardie-caso-reale.


> Collegamento report campo→SAL (chiuso G08, 2026-08-28):
> · `2026-08-27-cespiti-12-pr.md`
> · `2026-08-27-controlli-trimestrali.md`
> · `2026-08-27-magazzino-esecuzione.md`
> · `2026-08-27-prodotto-magazzino.md`
> · `2026-08-27-repo-f-50-agenti.md`
> · `2026-08-27-repo-g-esecuzione-quattordici-lenti.md`
> · `2026-08-27-repo-g-quattordici-lenti.html`
> · `2026-08-27-repo-i-cinquanta-giri.md`
> · `2026-08-27-revisione-cespiti-gas-bc.md`
> · `2026-08-27-test-repo-e-ciclo2.md`
> · `2026-08-27-test-repo-e.md`
> · `2026-08-28-bricoman-50-agenti.md`
> · `2026-08-28-bricoman-dal-audit-ai-fix.md`
> · `2026-08-28-bricoman-git-live-drift.md`
> · `2026-08-28-energikal-analisi-revisione.md`
> · `2026-08-28-energikal-backlog-correzione.md`
> · `2026-08-28-energikal-chiusura-sessione.md`
> · `2026-08-28-hub-allo-specchio-revisione-14-lenti.md`
> · `2026-08-28-parrocchie-fase1.md`
> · `2026-08-28-parrocchie-giornata-completa.md`
> · `2026-08-28-repo-i-fase3.md`
> · `2026-08-28-repo-k-dal-dossier-a-tutti-i-fix.md`
> · `2026-08-28-repo-l-fattura-factoring-revisione-poi-fix.md`
> · `2026-08-28-repo-l-fix.md`
> · `2026-08-28-sd-dashboard-dossier.md`
> · `2026-08-28-unicredit-factoring-30-agenti.md`
> · `README.md`

### 2026-08-28 — 60 giri di revisione completa: privacy bonificata, pattern collegati

Sei batterie di lenti sulla settimana intera. I finding piu gravi corretti: PRIVACY
(7 file con nomi reali bonificati: HASSLACHER/Bricoman/Golilla nei pattern, indice,
ngiri), PATTERN IRRAGGIUNGIBILI (riferimento al catalogo aggiunto a metodo + 4 agenti
+ gas-sviluppo SKILL), VEDI-ANCHE (24 pattern collegati ai cugini), ORACOLI senza
limiti (4 tool arricchiti). Verificato pulito: suite 101/101, nessun segreto, SAL
coerente, specchi sincronizzati, test deterministici. Dichiarato: SAL 275KB rotation,
24/27 campo senza nome in SAL, 6 tool senza test giustificati.

### Giro 1/30 ciclo ABC: 9 finding corretti (6 agenti pattern, 3 skill collegate)

### 2026-08-28 — Il falso positivo strutturale del ciclo-vivo (pipefail + grep -q) e il canone svuotato che nessuno notava

Due difetti scoperti insieme, uno causa dell'altro:

1. **La lente 2 del ciclo-vivo produceva falsi COLLEGAMENTO.** `echo "$CANONE" | grep -q "$base"` con
   `set -o pipefail`: quando il pattern è trovato presto, grep -q esce, echo riceve SIGPIPE (141), la
   pipeline "fallisce" e il pattern CITATO viene segnalato come mancante. Visibile solo con canone oltre
   i 64KB di buffer pipe. L'analisi dei 100 giri ("34 pattern mai citati") mescolava 33 gap veri e falsi
   positivi: il numero cambiava fra run identici (34, 36, 39) — la non-deterministicità era l'indizio.
   Fisso: grep -qF diretto sui file, niente pipe. Pattern: `pipefail-grep-sigpipe`.

2. **Il canone è stato svuotato per un'ora e la suite rimasta 103/103.** Un `open(path,'w')` python
   eseguito prima di un NameError ha troncato metodo.md a 0 byte; la riscrittura successiva ci ha
   messo sopra solo l'indice (314 righe → 9). Nessun test guardava il CONTENUTO del canone. Fisso:
   `tests/test-canone-integrita.sh` (sezioni portanti + soglia 10KB + indice che punta solo a file
   esistenti) + write atomico via file temporaneo e os.replace.

3. **La lente 3 aveva la logica invertita** (segnalava "sezione nel metodo non implementata" proprio
   quando la sezione NON era nel metodo) e cercava il backing dentro references/ (circolare). Fissata:
   salta le sezioni assenti, cerca backing in tools/ + agents/ + SKILL.md.

Fatto dopo: indice rapido dei pattern per tema in fondo a metodo.md (tutti i 40 pattern citati dal
canone), pattern `pipefail-grep-sigpipe` nel catalogo, ciclo verificato deterministico.

### 2026-08-28 (2) — Altri 100 giri: il ciclo che misurava se stesso, e il test anti-drift che non testava

Eseguiti 100 giri con memoria pulita. Dati: giro 13 livello 3 pulito → 4; giri 14-16 livello 4 a zero finding
(il livello era VUOTO: nessuna lente, tre passes gratis); dal 17 al 112 livello 5 in OSCILLAZIONE PERFETTA
0,1,0,1 — 48 META finding su 97 giri. Due difetti strutturali:

1. **Meta-lente degenere**: `CURRENT >= PREV` con entrambi a zero è VERA → steady-state perfetto
   segnalato come "il ciclo non migliora". Fissata: regressione = finding in AUMENTO (`>`). Lo zero
   stabile è successo, non stallo.

2. **Livello 4 (architettura) senza lenti**: costruite quattro invarianti reali — specchio skills
   (bidirezionale, graphify esclusa), specchio agenti per contratto di corpo (con asserzione NON-VUOTO),
   copertura tool.py→test (normalizzando - e _), registro patterns/README.md ↔ file.

E mentre si costruiva la lente specchi, la scoperta più grossa: **test-opencode-agent-sync.sh non ha mai
testato niente**. `corpo()` usava due `sed '1,/^---$/d'` concatenate: la prima consuma ENTRAMBE le
recinzioni del frontmatter, la seconda non trova più `---` e cancella fino a EOF → corpo sempre vuoto →
`diff vuoto vuoto` verde per sempre. Gli specchi erano driftati DAVVERO (5 agenti su 6 senza la sezione
Graphify) sotto il test verde. Fisso: una sola sed + asserzione di non-vuoto prima del diff + conteggio
righe confrontate nell'output. Specchi risincronizzati. Pattern: `confronto-non-vuoto`.

Il ciclo ora ha un CUORE: dopo 3 giri puliti al livello 5 torna al livello 1 (dente di sega 1→5→1),
perché fermo al 5 verificherebbe solo il 5 mentre le fondamenta invecchiano. Le guardie per finding
ricorrenti (3+) ora vengono ACCODATE su file (.ciclo/guardie/da-generare-*.txt), prima venivano solo
stampate. Copertura completata: test per leasing_amministrativo (aritmetica a mano: residuo 14000 =
23000×14/23, adeguamento trimestrale 0.875→0.88) e bc_tipi_metadata (contratto offline: mappa EDM,
fallimento senza rete via credenziali avvelenate su 127.0.0.1:1). Suite 106/106.

### 2026-08-28 (3) — Altri 100 giri col battito + la tecnica estesa a TUTTO il repo

**I 100 giri (19-118)**: distribuzione del dente di sega perfettamente regolare — L1:18, L2:20,
L3:21, L4:21, L5:20, sei CUORE, zero finding. Il ciclo non si impantana più al livello 5: ogni
livello viene ri-verificato a ogni battito.

**La tecnica (lenti di invarianti deterministici) estesa alle zone non coperte.** Il ciclo guardava
.claude/.opencode/patterns/tools-py; non guardava docs/ (269 file), night-shift/, llm/, i 30 script
shell, gli hook, DEBITI, il conteggio campo. Spazzata diretta su tutto:

- 54 script shell compilano (bash -n) · tutti eseguibili · hook di settings.json puntano a file
  esistenti · DEBITI senza ref pendenti · night-shift/lib.sh esiste · bc: 231 file endpoint = 231
  nell'indice rigenerato · docs cross-riferiti coerenti (i ref "mancanti" erano esterni REPO-* o
  nomi nudi di tool: falsi positivi della mia spazzata, non del repo).
- UN fix vero: campo-triage contava README.md come report di campo (27 vs 26 veri) e la sua
  verifica passava per coincidenza (grep "README" matcha SAL ovunque). Escluso dal conteggio.

**Le spazzate sono diventate lenti permanenti**: L1 ora fa bash -n su tutti gli .sh (la classe
d'errore del parse error capitata davvero); L4 ha quattro lenti nuove — hook vivi, campo-triage a
zero non processati, file BC = indice BC, ref DEBITI esistenti. Verificate pulite sul vivo e col
caso negativo ciascuna (hook monco → finding; script rotto → finding).

Nota onesta: la spazzata repo-wide ha trovato quasi tutto già coerente — perché 106 test coprono
già quelle zone. Il valore delle lenti non è l'audit una tantum ma la CONTINUITÀ: il ciclo continua
a guardare fra un run di test e l'altro, quando i file cambiano. Cammino post-estensione verificato:
15 giri, 1→2→3→4→5→CUORE→1, zero finding. Suite 106/106.

### 2026-08-28 (4) — I 100 giri IGNORANTI: le sonde scortesi che trovano ciò che le lenti educate non vedono

Su richiesta di Luca: «giri un po' ignoranti, insoliti, inusuali per scovare ogni genere di
inesattezza, incongruenza, errore, ostacolo». Circa 70 sonde praticate a mano + 6 consolidate
nella batteria permanente `tools/giri-ignoranti.sh`. Catture:

1. **Carattere CJK in SAL-ARCHIVIO** (glifi cinesi dentro una parola italiana) — la classe di corruzione che
   avevo introdotto io stesso ieri in un pattern: era già successa ed era rimasta. S1 ora la
   cerca ovunque.
2. **Numeri claims marciti**: AGENTS.md diceva «~75 test» (realtà 106) e «39 pattern» (41).
   Numeri tolti o resi non-fragili: un conteggio in un doc è una promessa che marcisce a ogni
   commit. S2 confronta ogni «N test/pattern/agenti» nei doc di testa con i file veri.
3. **Oracoli che muoiono di Traceback nudo** su input assente: indici_crisi e rollforward_cespiti
   ora dicono «uso:» ed escono 1; scadenzario_aging con header spazzatura dichiara le colonne
   attese invece del KeyError. S3 li prova tutti con /dev/null e header `a,b`.
4. **La porta d'ingresso non portava da nessuna parte**: MANUALE-OPERATIVO.md e
   benvenuto-collaboratori.md erano linkati da ZERO file — il manuale per l'uso quotidiano e
   il benvenuto per i collaboratori, invisibili a chi arriva. Linkati dal README. S4 caccia
   i doc orfani.
5. **sync-repo.sh implementava --standard ma l'uso non lo documentava**: il benvenuto
   insegnava un comando che lo script stesso non dichiarava. S5 verifica che ogni flag
   implementato stia nell'intestazione d'uso.

Nota di metodo: la sonda S4 mi ha beccato lo stesso giorno — `grep -v -c .` conta le righe VUOTE
(non quelle piene): risultato sempre 0, tutto sembrava orfano. È il pattern confronto-non-vuoto
al contrario: un conteggio che non può che dare 0 non misura niente. Le sonde vanno verificate
col caso noto (system.md È citato) prima di fidarsi del loro verdetto.

Batteria finale: 6 sonde, 0 finding. Suite 106/106.

### 2026-08-28 (5) — I 100 giri AVVERSARI: attaccare il sistema per conto terzi

Su richiesta di Luca: giri che «provano a contestare il sistema, forzandolo, andando
contro le regole, aggirandole». Costruito tools/giri-avversari.sh: 95 attacchi in 7
categorie (mutazioni da prendere, bypass hook, gaming lenti, input ostili, privacy,
regole senza denti, copertura), ognuno mutazione → difesa → verdetto → ripristino.
Percorso: 54 tengono → 70 → 83 → **87 tengono, 0 aggirati, 8 limiti dichiarati**.

**I buchi veri trovati e chiusi:**
1. **Il dente mancante**: «clasp push MAI» era SOLO un promemorio — zero deny in tutto
   il sistema. Ora tools/clasp-block-hook.sh NEGA clasp push/deploy (permissionDecision
   deny) e avvisa sui comandi che toccano credenziali. La prima regola con enforcement
   tecnico, non memoria dell'agente.
2. **La sicurezza che perdeva contro la documentazione** (B1): nel pattern-reminder-hook
   il promemoria SAL scattava PRIMA del ramo sensibile e con exit 0 lo SOPPROMEVA — ogni
   quinto edit su un file di credenziali perdeva il contesto dei pattern. Priorità
   invertita; ora il sensibile viene prima e il SAL si accoda.
3. **Oracoli che mandavano giù nan/inf in silenzio** (D5/D6/D20): scadenzario metteva nan
   nel bucket LUNGO, bilancio stampava margine -inf. Guardia isfinite che dichiara il dato
   marcio; leasing rifiuta le date invertite (D7).
4. **La difesa rotta dal proprio pattern** (A3): il controllo INDICE-ROTTO del test di
   integrità finiva `done | grep -q` sotto pipefail — SIGPIPE, 141, il ramo `|| ok` scattava
   SEMPRE. Il test che difendeva l'indice non ha mai difeso niente: il pattern
   pipefail-grep-sigpipe, scoperto due giorni fa, era dentro il mio stesso test. Riscritto
   senza pipe sul verdetto.
5. **SHAPES che non potevano funzionare** (G4): `\{20\}` in ERE matcha le parentesi graffe
   LETTERALI, non il quantificatore — i pattern ghp_/AKIA del privacy-check non hanno mai
   potuto catturare nulla.
6. **La regola campo mai scritta** (G9): il puntatore a docs/campo NON ESISTEVA in CLAUDE.md
   (solo nell'hook). Ora è regola scritta in §5, con presidio.
7. Pavimenti alzati al reale (famiglie 45/48, skill 9/9), marker SAL presidiato, lista
   standard allineata (manca .opencode/plugins), flag --standard nel case.

**Lezioni di metodo (le più care):**
- **Attaccare un albero sporco è auto-sabotaggio**: i checkout di ripristino
  dell'harness hanno CANCELLATO i miei fix non committati, e i verdetti diventavano
  rumore a cascata. L'harness ora esige albero pulito (e la guardia ha fermato pure me).
- **`batteria | grep -q && tiene || aggirato` sotto pipefail inverte il verdetto**: la
  batteria esce 1 PER DESIGN quando trova qualcosa. Stessa famiglia del SIGPIPE: le
  difese catturano l'output prima di giudicarlo.
- **L'arnese che porta i propri attacchi in letterale si auto-segnala**: payload costruiti
  a runtime (CJK, segreti finti) o l'attrezzo finisce nel mirino delle proprie sonde.

Suite 107/107. Batteria ignoranti 0 finding. La batteria avversaria esce 0: rifacibile
a ogni giro (`bash tools/giri-avversari.sh`), esce 1 al primo aggirato non dichiarato.

### 2026-08-28 (6) — I 100 giri sui TEST: i quattro teatri verdi, il banco di fine passaggio, e il test fantasma

Su richiesta di Luca: concentrarsi sui test, sulla verifica del codice appena scritto, su banchi
efficaci a fine loop o a goal raggiunto. Circa 100 azioni di verifica (5 batterie di mutazione
complete da 23-26 tool, una dozzina di cicli fix-e-verifica, 4 run del banco intero, 6 run di
suite). Il goal lo dichiara il banco stesso: «PASSAGGIO CHIUSO — tutto tiene».

**Il metodo nuovo: mutation-testing dei TEST.** tools/mutation-tests.sh neutralizza ogni tool
(exit 0) e il suo test DEVE arrossire. Un test che passa col soggetto neutralizzato è un
TEATRO VERDE: verifica l'idea del codice, non il codice. Ne ha trovati quattro:
1. test-backup-config: con gh installato si saltava da solo (3 OK di nulla) — e il tool,
   scoperto a seguire, moriva 127 IN SILENZIO senza gh: contratto mai soddisfatto, mai provato.
2. test-install: asserzione ok||ok — un install che non fa NIENTE passava. Resa load-bearing,
   ha trovato un bug VERO: install.sh risolveva la home con `eval echo ~user` ignorando $HOME
   — i test scrivevano symlink nella home VERA dell'utente.
3. test-lib: il source di un lib.sh neutralizzato esegue exit 0 DENTRO il test, che moriva
   verde. Guardia pre-source: la funzione deve esistere nel sorgente prima di caricarlo.
4. test-bootstrap-app: testava le proprie copie delle funzioni, nulla lo legava al file reale.
   Agganciato alla struttura portante (solo codice, non i commenti che la documentano).

**Il test fantasma.** test-campo-triage.sh non era MAI STATO COMMITTATO: girava nella suite da
sempre, invisibile a git. Un esperimento l'ha sovrascritto, il checkout di ripristino falliva
in silenzio (non tracciato), e la versione banale è finita committata per errore MIO. Il banco
l'ha scoperta in due banchi indipendenti (suite rossa via mutation-tests + teatro dichiarato).
Ricostruito in sandbox dal contratto del tool: teatro-proof e indipendente dallo stato del giorno.

**Il banco di fine passaggio.** tools/banco-passaggio.sh: sette banchi con verdetto su una riga
(suite, ignoranti, avversari, mutazioni, privacy, ciclo, copertura). Il banco 7 è la risposta a
«verifica del codice appena scritto»: ogni file di codice cambiato o NUOVO (status --porcelain:
git diff non vedeva i non tracciati — il caso tipico!) deve essere citato da un test o dichiarato
con giustificazione. Il banco se l'è applicato da solo: SCOPERTO tools/banco-passaggio.sh —
ora ha il suo test. E il self-test del banco ha trovato l'auto-copertura circolare: il probe di
prova citato dal test stesso risultava «coperto»; nome del probe unico a runtime ($$).

Suite 110/110 · mutazioni 26/26 reagiscono · ignoranti 0 · avversari 0 aggirati · VERDETTO:
PASSAGGIO CHIUSO. `bash tools/banco-passaggio.sh` da qui in poi è la porta di chiusura di ogni
loop e ogni goal: se non dice CHIUSO, non si chiude.

### 2026-08-28 (7) — I 100 giri di CHIAREZZA: i commenti come verifica del pensiero

Su richiesta di Luca: codice sempre commentato perché la seconda lettura ne capisca
l'intenzione oltre le formule, e aiuti a scovare incongruenze fra il pensato e lo
scritto — o il pensato male. Tre mosure: censimento, riletture claim-per-claim,
lente permanente.

**Il censimento mentiva (due volte).** La prima metrica (# commenti) dichiarò
«nudi» i file .py migliori del repo: contava i #, non le docstring — chiamò
sparuto il più documentato. Rifacta con docstring contate: davvero scarsi erano
solo 4 file. Lezione: prima di misurare la chiarezza, verifica che la metrica
misuri la chiarezza (confronto-non-vuoto, ancora).

**La caccia alle discordanze (claim↔codice), il cuore della richiesta.** Ogni
affermazione comportamentale letta e verificata contro il codice: valorizzazione
6/6, verifica_banco 5/5 (il giudice dei banchi: cinque controlli dichiarati,
cinque implementati), lib.sh 2/2 (i fix descritti nelle note sono il codice
sotto le note), rating 4/4 contro il Codice.js VERO (≤7 giorni, <1 EUR, guardia
0-365, data cessione 2000+aa). **Una discordanza trovata, ed era quella giusta**:
l'header di ciclo-vivo descriveva il progetto del primo giorno — «ciclo A-B-C»,
«memoria in .ciclo/stato.json», «genera un test automatico», «prioritizza dove
guardare» — NESSUNA di queste cose esisteva: la memoria sono sei file piatti, le
guardie si accodano, la prioritizzazione non c'è mai stata. L'header era il
fossile del pensiero iniziale: chi l'avesse creduto avrebbe cercato stato.json.
Riscritto su cosa È, con la storia dichiarata (nato come A-B-C, sopravvissuto
meno del previsto).

**Venticinque funzioni opache ora dichiarano l'intenzione**: bc_map (il client
BC: token in memoria, paginazione nextLink, tipi da campione che bc_tipi
corregge), gli oracoli (il cuore di riconciliazione con «non contato ≠ contato
a zero», le fasce di aging, il roll-forward che non forza la quadratura, il
main di bilancio col confine del margine DIRETTO), sal-archivia (perché il
taglio viene DOPO l'indice, perché solo le voci datate, perché append-only).

**La lente permanente**: tests/test-chiarezza.sh in suite — S1 intent in testa
ovunque, S2 densità (docstring incluse) ≥15% con UN'esenzione dichiarata
(l'harness avversario si autodescrive nei verdetti-echo), S3 nessuna def opaca.
Trovata rossa la prima volta: 4 file scarsi, 25 funzioni senza docstring.

**E il banco 7 si applicò all'autore**: le modifiche di chiarezza stesse
(ciclo-vivo, sal-archivia, status-page) sono emerse SCOPERTE — cambiate senza
test. Risposta: tre test veri, uno per tool, incluso sal-archivia reso
sandbox-abile (path overridabili: il test NON ruota il SAL vero) e status-page
con NOOPEN=1 (il test non apre browser).

Suite 114/114 · banco PASSAGGIO CHIUSO · chiarezza 3/3. Le regole della
chiarezza d'ora in poi sono presidiare: la lente arrossisce al primo file che
tace sulla propria intenzione.

### 2026-08-28 (8) — I 100 giri sui FALLIMENTI: l'errore a regime

Su richiesta di Luca: quando vediamo che abbiamo sbagliato, mettere l'errore a regime —
capirne i motivi, come migliorare, come non farlo risuccedere, come aggirarlo, come
migliorare il ragionamento. Tre pezzi consegnati:

**1. La skill post-mortem** (.claude/skills/post-mortem/, specchiata in .opencode):
sette campi obbligatori — sintomo, causa prossima, CAUSA DEL RAGIONAMENTO (la parte
che migliora chi sbaglia), perché non ci ha fermati, guardia, VERIFICA della guardia
(si chiude solo dopo averla vista rossa sul proprio errore), aggiramento. E sei
famiglie di ragionamento, gli errori COGNITIVI ricorrenti: R1 assunzione non
verificata · R2 verde senza dati · R3 precondizione non chiesta · R4 autoriferimento ·
R5 memoria contro realtà · R6 effetto collaterale ignorato.

**2. Il registro** (docs/errori/REGISTRO.md): 13 errori VERI backfillati, tutti
fatti e documentati in queste sessioni — dal canone svuotato dal write anticipato
(E-001) ai falsi SIGPIPE (E-002), dal test che confrontava vuoto con vuoto (E-003)
all'harness che attaccava l'albero sporco cancellando i propri fix (E-004), dalla
metrica che misurava un'altra cosa due volte (E-006) all'header fossile (E-012).
Ogni voce con la sua guardia citata PER FILE.

**3. La lente** (tests/test-errori.sh): ogni voce ha i sette campi, la famiglia
canonica, e — la parte che conta — la guardia citata ESISTE: una promessa senza
file è il parente della promessa fossile. 43 controlli verdi.

beccato altri due glifi alieni nel testo che stavo scrivendo (evidenza in registro, E-013) — terza volta nello stesso giorno. Registrato come ricorrenza:
la guardia funzionava già, il punto è che senza lente tre testi pubblici
sarebbero usciti sporchi. Il sistema si è applicato a se stesso nel momento
stesso in cui veniva costruito.

**E il battito ha pagato**: il banco 6 (un giro del ciclo) è uscito rosso per una
regressione VERA introdotta dal mio irrigidimento avversario di ieri — la lente
copertura "match esatto" rompeva la copertura legittima (bc_map presidiato da
test-bc-map-leggi-curati.sh). Corretta a prefisso ancorato: il caso avversario
C2 resta preso, quello legittimo torna accettato. Prima guardia del registro che
viene messa alla prova dal sistema che l'ha generata.

Regola vincolante in CLAUDE.md §5: errore trovato → skill post-mortem, registro,
guardia vista rossa prima di chiudere. Suite 115/115.

### 2026-08-29 — I 100 giri sulla COMPRENSIONE: polilivello, le domande di senso, il brainstorming generativo

Su richiesta di Luca: comprensione del progetto di destinazione attraverso analisi
polilivello, domande di senso (cosa fa? come lo fa? come potrebbe farlo meglio?),
potenziare lo studio e il brainstorming. Tre pezzi:

**1. La skill polilivello** (specchiata opencode): sei livelli in ordine dal grosso
al fine — L1 identità (UNA riga guadagnata: se non la sai scrivere, non hai capito,
hai solo letto), L2 struttura, L3 comportamento (COSA FA: per entrypoint
trigger→input→output), L4 meccanica (COME: formule citate file:riga, assunzioni
implicite), L5 storia (le cicatrici non si sistemano senza sapere cosa hanno guarito),
L6 critica — che APRE il brainstorming. Regola dura: la critica senza le prime due
domande è vietata.

**2. Il brainstorming potenziato** (§4 della skill): dieci provocazioni P1-P10 in
tre famiglie — sul COSA (test del vuoto, next-question, il vicino), sul COME (scala
×10, ribaltamento, costo zero), sul CHI (domanda di dominio, l'ostacolo, il debito
visibile, la fusione). Le provocazioni senza comprensione sono modelli, non idee.

**3. tools/polilivello.sh**: lo scaffold meccanico di L2/L4/L5 (entrypoint, ID,
dipendenze, formule candidate, costanti magiche, date, debito). Il campo l'ha
corretto subito: i progetti GAS nominano gli entrypoint con VERBI DI DOMINIO
italiani (analizza, calcola, genera...) — il grep doGet/main li mancava TUTTI;
gli ID stanno in const in testa, non in letterali. Due iterazioni sul primo
bersaglio vero.

**La demo completa** (docs/campo/2026-08-29-polilivello-demo-rating.md): analisi
L1→L6 del progetto Rating Clienti del parco. La fase critica ha prodotto sei idee
in un passaggio: l'anno CABLATO nella regex dei codici documento (25OV-… non
matcherà più dal 2026: bomba orologio), l'oracolo hub che la regex giusta l'ha
già scritta (il fix a costo zero è copiare la lezione già pagata), il
primo-file-trovato nella folder, e LA domanda di dominio che nessun codice può
rispondere: il DSO col factoring misura il cliente o la banca? Validato anche sul
progetto più grande del parco (26.190 righe: 12 entrypoint colti, trigger
programmatici, config BC). Suite 117/117.

### 2026-08-29 (2) — I 200 giri del COLLEGAMENTO TOTALE: censito, collegato, funzionante, affinato

Su richiesta di Luca: assicurarsi che tutto il repo sia collegato, funzioni, sia censito,
sviluppato e affinato. Quattro fasi, una per parola.

**CENSITO** — 554 file tracciati, mappati per zona ed estensione. La matrice di
connessione (ogni oggetto citato da almeno un altro) è quasi perfetta: skill, agenti,
pattern, tool, documenti — TUTTI raggiunti; i 30 «orfani» sono test, by-design (si
scoprono via glob). Un falso allarme istruttivo: il «file col nome tra virgolette» era
git che escapea la à di capacità (core.quotepath) — la metrica ancora, contro la realtà.

**COLLEGATO** — 19 link pendenti trovati e triati: 12 oracoli citati nudi in
mappa-dominio (prefisso tools/), i file-del-target dichiarati per contratto (il
CATALOGO_ENDPOINT nel progetto, la GRAMMATICA che il template ordina di creare).
README ora linka SAL.md e SAL-ARCHIVIO.md — l'archivio era ORFANO dalla porta
d'ingresso. E il grafo dei pattern è diventato CONNESSO: da 21 isole a ZERO, ogni
pattern citato da almeno un altro via Vedi-anche, con parent naturali e non a caso.
La trappola del conteggio: il primo batch scriveva nomi senza backtick e il riconteggio
li cercava coi backtick — formato incoerente, famiglia E-006 (la metrica misura ciò
che dice?), normalizzato.

**FUNZIONA** — eseguiti in safe-mode i tool mai eseguiti: system-health (Ollama e
Wayfinder attivi), gate-summary (metriche a schema), status-page NOOPEN, sync-repo
--from-local (ALLINEATO), morning-digest (no-op educato senza email). DEBITI triati:
i chiudibili erano già saldati, le restanti sono decisioni di Luca (privacy dei campioni
BC, rotazione secret REPO-L) — nessuna chiusura forzata.

**AFFINATO** — due sonde permanenti nuove in giri-ignoranti: S10 (link pendenti nel
canone, con le esclusioni-per-contratto imparate oggi) e S11 (grafo pattern connesso).
Undici sonde totali, 0 finding. Suite 117/117 (nel messaggio di commit ho scritto 118:
numero sbagliato, già pushato — lo dichiaro qui invece di lasciarlo correre), banco
completo PASSAGGIO CHIUSO.

### 2026-08-29 (3) — I 100 giri ASSURDI: probe improbabili, pensiero disallineato, e due trucchetti

Su richiesta di Luca: tutto quello che non abbiamo pensato prima, pensiero disallineato,
probe assurde, situazioni improbabili — e trucchi che migliorano il sistema.

**Le probe assurde (dieci eseguite, quattro hanno morso):**
1. **DUE cicli in simultanea**: entrambi leggevano giro=N, entrambi scrivevano N+1 —
   GIRO PERSO. La memoria del ciclo è una risorsa condivisa senza lock: l'AUTORE del
   pattern lock-per-risorsa non lo usava. Fix: lock mkdir atomico in ciclo-vivo, con
   attesa e uscita pulita dopo 50 tentativi. Riverificato: due simultanei → giro=2.
2. **Il pattern narcisista**: un pattern che si cita solo da sé nell'S11 risultava
   «collegato» — l'autocitazione contava come connessione. Fix: citati esclude v==p.
3. **CRLF**: uno script editato su Windows passa bash -n e MUORE a runtime. Nuova
   sonde S10bis (byte \r negli script tracciati).
4. **L'hook pre-commit ha mentito alla prima prova**: il mio trucco nuovo diceva OK
   con un glifo staged — il grep BSD di macOS non ha -P e moriva nel 2>/dev/null.
   Falso verde trovato verificando l'hook COL SUO METODO (il tool si prova quando
   DEVE fallire). Fix: git grep -P, e il caso avverso ora è il test stesso.

Innocue (verificate e archiviate): esecuzione da directory diverse (HERE tiene),
LC_ALL=C (determinismo confermato), 29 febbraio nella rotazione, nome file di 200
caratteri (già presidiato dal ciclo lens 4d), git quotepath (l'escape della à).

**I due trucchetti:**
- **tools/pre-commit.sh + .githooks/**: i controlli rapidi (2-3 secondi) alla
  frontiera di ogni commit — glifi alieni nei file staged, CRLF, link pendenti nei
  .md, e il numero-test del messaggio confrontato coi file veri (sarebbe bastato
  ieri per il mio 118-fantasma). Attivato su questa copia e via install.sh.
- **tools/help.sh**: il menu dei verbi, organizzato per MOMENTO D'USO (chiusura,
  batterie, studio, diario, propagazione) — ogni comando citato esiste, testato.

La batteria ignorante ora conta 12 sonde (S10bis CRLF nuova). Suite 119/119,
banco PASSAGGIO CHIUSO. E la copertura ha preteso i test dei due trucchetti
stessi: il sistema chiede a chiunque, anche a chi gli sta costruendo il negozio.

### 2026-08-29 (4) — I 100 giri sull'ALLINEAMENTO FORK: la prima mossa decisa prima delle modifiche

Problema di Luca, detto con precisione: si lavora sul nostro repo (magari il più vecchio),
si fanno modifiche, POI ci si accorge del fork — e qualunque cosa si faccia a quel punto
è confusione e disallineamento. E per i GAS: il vivo è SEMPRE l'elemento definitivo, in
produzione, mai un'ipotesi.

**La skill allineamento-fork** (specchiata opencode): cinque mosse in ordine vincolato —
enumera le copie (anche quelle dimenticate), LEGGI IL VIVO (clasp clone fresco; illeggibile
= DEGRADATO dichiarato, non silenzioso), misura la deriva, decidi con la TABELLA M4, scrivi
FORK-STATO.md. La tabella è il «da farsi sin da subito»: vivo avanti → il vivo è la base e
prima si allinea la copia; fork avanti → si lavora lì SAPENDO che le sue modifiche non
deployate sono ipotesi; la tua copia indietro su tutti → NON si tocca niente finché non
si allinea. Tre regole non negoziabili, la prima in maiuscolo: IL GAS VIVO È DEFINITIVO —
si legge, non si immagina; «dovrebbe essere così» è la frase vietata.

**tools/fork-stato.sh**: la misura (N copie → file, righe, impronta NORMALIZZATA —
formattazione non conta come deriva — matrice, verdetto con la regola del vivo e l'ordine
di scrivere lo stato). Scoperto sul campo: bash 3.2 di macOS non ha declare -A (gli array
indicizzati bastavano). Test in sandbox: 8 contratti incluse la formattazione-non-deriva
e la copia inesistente.

**Pattern gas-vivo-definitivo** nel catalogo (42 voci, agganciato da misura-la-deriva),
regola vincolante in CLAUDE.md §1 e sezione nel metodo, benvenuto-collaboratori aggiornato
(chi arriva per la prima volta legge la regola della prima mossa), verbo in help.sh.

Il sistema ha preteso il pedaggio alla consegna: S10 dichiarava pendente FORK-STATO.md
(file-del-target: esclusione imparata), S11 dava il pattern nuovo come isola (agganciato),
skills-structure idem con le backtick di gas-src. Suite 120/120.

### 2026-08-29 (5) — I 100 giri di MULTIUTENZA: il presidio, la presenza che si fonde da sola

Su richiesta di Luca: due o più utenti con AI_Programmer sullo stesso repo nello stesso
momento — sistemi per il lavoro condiviso e distribuito.

**La fondazione c'era già ed è VERIFICATA SUL CAMPO oggi**: il merge union su SAL e
report di campo — due cloni, due append, merge → ENTRAMBE le righe sopravvivono, zero
conflitti (esperimento ripetuto, non presunto). L'assignee GitHub per le commesse, la
notte centralizzata per disegno.

**Il pezzo che mancava: la presenza in tempo reale.** tools/presidio.sh — il registro
dei presidii («sto toccando gli oracoli fino alle 14:30, note»): claim/lista/rilascia,
scadenza 4h con potatura DICHIARATA, contesa urlata quando due CHI distinti dichiarano
la stessa zona. PRESIDI.md è append-only col driver union: i presidii di due cloni si
fondono da soli al merge. Identità: PRESIDIO_USER esplicito vince sul git config (due
utenti possono provare sullo stesso clone). NESSUN LOCK: visibilità, non permesso — la
contesa si risolve parlandosi, un lock distribuito fingerebbe il contrario.

**La skill lavoro-condiviso**: le tre classi di file (append-only: due mani SICURE;
codice: una mano un ramo una PR; stato locale: ogni clone il suo ciclo), la disciplina
del push (pull --rebase prima, mai force su condivisi, i diari si pushano spesso),
la contesa come allerta non divieto. AGENTS §0bis esteso, benvenuto collaboratori
aggiornato, verbo nel menu.

**E la lezione che si è data da sola (E-014 nel registro)**: il test nuovo del
presidio è caduto DUE VOLTE nella trappola pipefail-grep-q — `cmd | grep -q` sotto
pipefail inverte il verdetto proprio quando funziona (SIGPIPE, 141) — TERZA ricorrenza
in due giorni, stavolta scritta NUOVA da chi il pattern l'aveva catalogato. Con
variante inedita: `grep -c | grep -q "^0$"` fallisce quando conta zero (grep -c esce
1). La regola ormai è forma, non sapere: nei test si cattura l'output prima. Suite
121/121.

### 2026-08-29 (6) — Banco di prova su Centrale_Rischi: il metodo tiene dallo studio alla PR

200 giri di autonomia su un progetto VERO (iniziato ieri come test del metodo):
issue #2 ferma alla regola «tre tentativi poi architettura» per la latenza reale
misurata in produzione. Consegnata l'architettura: PIPELINE A RIPRESA (Pipeline.gs)
— OCR una volta, pagine in tab nascosto, chunk ≤8 pagine o 4,5 min, checkpoint,
trigger che rigenera se stesso, retry≤2 poi dichiarata fallita, abort umano che non
cancella i fatti compiuti. Banco test-pipeline.js: 7 attese, HA TROVATO PRIMA DEL
DEPLOY il bug del cursore (le pagine fallite restavano dietro il cursore: il retry
non sarebbe mai scattato in produzione). PR #7 aperta, deploy all'umano per regola.

**Il processo giudicato dal campo**: (1) il banco-prima-del-deploy non è cerimonia —
il bug era invisibile a occhio; (2) polilivello regge sul bersaglio esterno e il SUO
bug è emerso al primo uso vero (riga Properties con avanzo di scrittura: riparata
con la provenienza nella riga); (3) il loop di ieri CHIEDEVA due portate al hub e
oggi sono arrivate: pattern estrazione-llm-spezzata (anti-pattern monolitico
MISURATO + la forma a ripresa) e la lezione del segreto in sessione cloud (env var
del proprietor, mai incollata in chat) nel metodo.

**Migliorie proposte dal campo** (nel report): sonda PROJECT.md-stale per i repo
target; stub GAS riutilizzabile per i banco node-vm (Stato+Trigger); checklist
post-deploy templata nelle PR. Nuovo codice REPO-CR nel repos-index (repo pubblica:
citanile per nome — S9 estesa CON dichiarazione, non in silenzio).

Report: docs/campo/2026-08-29-centrale-rischi-banco-di-prova.md. Suite 121/121.

### 2026-08-29 (7) — Le lezioni di stanotte a casa + la riverifica di ieri: 11/11 guardie vive

**Stanotte incassata, tutta.** (1) Il LOOP DI RIPLETTURE: piano perfetto ripetuto 5+
volte senza eseguire — prompt anti-loop nel turno («SMETTI di rileggere, scrivi ORA la
modifica più piccola») + rilevatore post-run (3+ righe consecutive identiche nella coda
del log = loop dichiarato in log e metriche). (2) Il GATE CHE NON GIUDICAVA: causa
radice NON il fetch mancante ma il clone --single-branch (refspec solo main): si fetcha
il branch singolo via FETCH_HEAD — verificate le 6 PR prima invisibili, ora il gate
esegue le verifiche vere (2005 asserzioni, banco avversariale che scarta grep non
allowlistate). (3) La COPIA OPERATIVA STANTIA (5 commit indietro): il turno ora fa
self-pull --ff-only all'avvio. (4) Il BATTITO del gate (GIUDICE FERMO nel digest):
tentato e REVERTITO dopo due trappole set -e fixate e una terza nascosta — a DEBITI con
sessione dedicata e test sui tre casi. E-015 nel registro, lente errori estesa a
night-shift/ come luogo di guardia.

**Ieri riverificato, tutto.** Mappa lezioni→guardia: SIGPIPE→lente2+pattern,
vuoto==vuoto→sync-test+pattern, canone→integrità, teatri→mutation-tests, fantasma→
campo-triage-sandbox, install-HOME→test-install, metrica-mentde→chiarezza,
probe→banco-passaggio, albero-sporco→avversari, fossile→ciclo-test, regola-campo→
report-campo: **11/11 vive**, suite 121/121. Le lezioni non sono ricordi: sono
file che arrossiscono.

### 2026-08-29 (8) — Dal campo REPO-O/REPO-P: onboarding sanzionato, lezioni incassate (report: 2026-08-29-repo-o-standard-adoption)

Arrivato il report di due progetti nuovi (gestionale parrocchiale schema v7 + rendiconto
annuale nato dai documenti vivi): 26 difetti corretti TUTTI dimostrati al banco, 5 suite
verdi (89 controlli) che sono il .night-verify di fatto. Le richieste eseguite:
- **Onboarding REPO-O**: sync-repo --standard → ramo claude/standard-20260829 (9 gruppi);
  gh ha abortito la creazione della PR lasciando il ramo orfano — PR #1 aperta a mano
  dopo. Registrato in repos.conf del turno: la notte lavora sui banchi già verdi.
- **REPO-P** (rendiconto): non ancora su GitHub — onboarding rinviato al suo arrivo;
  i codici REPO-O/REPO-P nel repos-index.
- **Lezione NUOVA incassata nel catalogo famiglie**: le famiglie di difetti misurate su
  GAS sono ricomparse IDENTICHE in Python/SQLite — le famiglie sono del pensiero
  sbagliato, non del linguaggio: su uno stack nuovo si cercano PRIMA le famiglie già
  pagate altrove.
- Le altre quattro lezioni confermate già vive nel metodo (banco=memoria eseguibile,
  fixture che degradano, guardie col caso reale, charter come decisioni vive).
- Oracolo del rendiconto: servono i materiali dell'utente (schema ufficiale della
  controparte) — censitore-forma-dati e controllo-gestione pronti, nessuno strumento
  nuovo. Confine gestionale↔rendiconto: decisione di charter (P10).

### 2026-08-31 — Le tre notti perse: il no-limit misurato

«Come sono andate le ultime notti?» — male, e adesso sappiamo il perché con i numeri.
Il turno del 28/8 NON è mai finito: opencode sull'issue #12 in loop di rilettura per
~59 ore (104 di CPU), piano perfetto mai eseguito. Il job vivo ha impedito a launchd
di avviare i turni del 29 e 30 (niente doppioni): TRE notti perse in silenzio — la
stessa famiglia del gate muto (E-015): l'assenza di log sembrava «coda vuota». Ucciso
il processo stamattina: il turno si è sciolto regolarmente (TURNO FINITO 10:11) e il
gate di qualità ha saltato l'issue #10 col motivo giusto (design senza riferimenti
reali). Nessuna modifica sporca lasciata nella copia di lavoro. La decisione «nessun
limite sulle issue» (Luca, 21/8) passa a DEBITI con l'evidenza: il rilevatore post-run
non può scattare su un processo che non ritorna — serve il watchdog DURANTE, che è il
pattern che l'eccezione aveva waiversato. La copia di lavoro è pulita: 59 ore di loop
non hanno toccato un file (rilette, appunto).

### 2026-08-31 (2) — REPO-K, seconda sessione: 5 bug reali per lente, tooltip da zero, 4 feature proposte e costruite

Continuazione diretta della sessione REPO-K del 28/8, stesso repo: richiesta utente
"100 giri robustezza + 100 giri grafica con tooltip ovunque", negoziata con
`AskUserQuestion` (repo target, metodo a batch progressivi) invece di eseguita alla
lettera. 5 lenti di robustezza sequenziali hanno trovato 5 bug VERI (zero rumore):
due race condition (scritture concorrenti Database.gs non protette, sync BC
duplicabile da due esecuzioni sovrapposte), una lista di stati ammessi disallineata
dal codice reale (`Config.gs` vs `STATUS_BADGE_CLASSES` in Scripts.html — due fonti
di verità divergenti, trovate solo perché la lente ha fatto leggere entrambe nello
stesso giro), un bug multi-riga EDIL/Legna ricomparso in una quarta funzione dopo
essere già stato corretto in tre. La lente grafica ha scoperto che `data-tooltip`
esisteva già su 12 elementi dal dossier precedente ma SENZA CSS/JS — un motore
tooltip mai completato, non mai iniziato. 4 nuove feature proposte con
`AskUserQuestion` (multiSelect, tutte scelte) PRIMA di scrivere codice, come da
istruzione esplicita dell'utente: pannello errori, storico modifiche in UI,
indicatore sync BC, modifica data in blocco (quest'ultima per DELEGA a `changeDate`
esistente, zero logica duplicata). PR aperta, mergiata, `clasp push` in produzione.

**Lezione di processo, non di codice**: il trucco FIFO per `clasp login`
non-interattivo si è rotto al secondo uso — `nohup ... & disown` manuale non
sopravvive in modo affidabile tra chiamate separate dello strumento di esecuzione
comandi (i processi backgrounded a mano possono sparire silenziosamente), causando
una race fra un vecchio tentativo di login bloccato e un nuovo tentativo, con
`Authorization rejected: state parameter mismatch`. Risolto usando il backgrounding
NATIVO dello strumento invece del backgrounding manuale in shell. Nessuna àncora di
codice in questo hub (REPO-K non è onboardata): dichiarato in
`docs/campo/2026-08-31-repo-k-robustezza-grafica-nuove-feature.md` come pattern
candidato, non promosso a `patterns/` finché non si ripete su un repo onboardato.

Report: docs/campo/2026-08-31-repo-k-robustezza-grafica-nuove-feature.md.
### 2026-08-31 (2) — Dal campo REPO-G: 16 lenti, 12 batch, 3 falsi positivi onorati

Report: 2026-08-31-repo-g-robustezza-grafica-16-lenti.md. Robustezza+grafica su Bilancio_periodico:
12 batch di fix (PR #37 mergiata), 9 file di test nuovi, npm test verde a ogni batch. Rilievi da
canone: l'arrotondamento per gruppo che poteva rompere SILENTAMENTE la quadratura SP sotto soglia;
accountMatches_ che catturava conti per prefisso; LockService assente su pubblicaBanche/
saveBookOverride ma presente su saveDashboardChanges (la famiglia scritture-multi-fale conferma la
lezione cross-linguaggio); OData per concatenazione su webapp ad accesso pubblico con errori che
mostravano il corpo grezzo BC. E la conferma del metodo: 3 falsi positivi VERIFICATI e non corretti,
ognuno documentato — la lente che iniettava sintetici bypassando la funzione vera è la stessa trappola
del metro-che-non-contiene-il-campione. La lezione UI (tooltip perso sull'abilitazione) entra nelle
famiglie come watch note da UN caso: il report stesso chiede di non generalizzare prima del secondo.

### 2026-08-31 (3) — REPO-K seconda sessione: la sfumatura del lock e il pattern FIFO in watch

Report: 2026-08-31-repo-k-robustezza-grafica-feature.md. 5 lenti → 5 bug veri, zero falsi positivi;
le due fonti di verità disallineate (validation.allowedNoteValues vs STATUS_BADGE_CLASSES) sono la
SECONDA conferma della famiglia in un secondo punto del codice. Due decisionsi da canone: (1) addendum
misurato a lock-per-risorsa — il lock è per-script: attorno a operazioni lunghe blocca tutto; se c'è
concorrenza ottimistica documentata il lock non si estende, si usa solo per il check-and-set atomico
del flag; (2) il pattern FIFO/backgrounding (nohup+disown svaniscono fra chiamate → URL vecchio con
state sbagliato) a DEBITI come watch: alla TERZA ricorrenza voce vera con àncora reale, come chiede
il report — il catalogo non nasce da racconti. E la regola del metodo confermata: bulkChangeDate per
DELEGAZIONE (chiama changeDate esistente in loop), non duplicazione della logica di business.

### 2026-08-31 (4) — Oggi a regime: E-016, E-017, turno-vivo, regola del presidio sul processing

Tutto ciò che il giorno ha insegnato, messo in forma istituzionale:
- **E-016** (il report processato due volte in parallelo): la convenzione date-slug ha reso la
  collisione benigna PER COSTRUZIONE (stesso file, nessuna divergenza) — ma lo spreco era evitabile:
  regola 1bis nella skill lavoro-condiviso («processare un report È un lavoro su zona: presidio claim
  prima, rilascia a fine commit»).
- **E-017** (le tre notti perse): registrato con la causa doppia (loop mai tornato + launchd senza
  doppioni + silenzio che sembrava coda vuota). Guardia nuova: **tools/turno-vivo.sh** — il detector
  del processo notturno oltre soglia, nel polso di system-health. Non uccide: VISIBILITÀ, coerente
  con la decisione di Luca (la guardia è la review del mattino — che ora ha qualcosa da guardare).
  Il watchdog vero resta la sua decisione in DEBITI, con l'evidenza dei numeri.
- La lezione REPO-K (lock per-script) e la watch note UI REPO-G: già committate stamattina.
L'errore del giorno fatto dall'autore mentre istituzionalizzava: l'innesto in system-health finito
dentro un echo esistente (quoting spezzato, due passaggi per ripulire) — stesso gesto che E-012
racconta: la fretta sull'ovvio. Notato qui perché il registro vive anche di questo.

### 2026-08-31 (5) — REPO-G banche solo corrente: giro CHIUSO + doppione REPO-J + regola first-touch

Report: 2026-08-31-repo-g-banche-solo-periodo-corrente.md. Giro chiuso: 7 banchi verdi, prova di
rendering con funzioni vere via vm, clasp push, conferma del dominio («perfetto tutto ha funzionato»).
Il codice aveva già prev opzionale nel percorso null — una riga di chiamata, zero nuovo codice.
Dichiarare il criterio di verifica PRIMA del lavoro ha reso la conferma una formalità.
Due cose portate a casa: (1) il doppione REPO-J nel repos-index (due righe) fuso in una —
l'attrite segnalato dal campo; (2) la regola scritta nel metodo: first-touch NON sostituisce
l'onboarding decisionato — due gesti diversi, mai confusi.

### 2026-08-31 (6) — L'incidente OpenAI/HuggingFace girato a fin di bene: staffetta, reward hacking, uscita dichiarata

Report: 2026-08-31-video-openai-hf-lezioni.md. Luca porta il video dell'incidente: agenti isolati
che si inventano una message board nei nomi delle cartelle, condividono credenziali, si autoorganizzano
in sciame. La mossa: ROVESCIARE — ogni causa è una capacità che usiamo già, la domanda è dove e con
quali canali. Tre lezioni entrate: (1) pattern `la-staffetta` — la collaborazione a passi del collettivo
è la cosa più potente dell'incidente, noi la facciamo su canali dichiarati (.ciclo, PRESIDI, SAL, campo,
commit); canale non dichiarato = message board occulta; (2) reward hacking = teatro verde, rilinquaggio
nel catalogo famiglie: mutation-tests è l'antidoto costruito prima di sapere il nome del problema;
(3) l'uscita dichiarata dall'impossibile: l'agente OpenAI ha imbrogliato perché non poteva arrendersi —
il nostro «tre tentativi poi architettura» ha ora il perché profondo scritto. Quarta lezione confermata
su scala industriale: la lentezza della scoperta (loro settimane, noi gate muto e notti perse — stessa
famiglia, già presidiata).

### 2026-08-31 (7) — Gli incidenti esterni rovesciati: la skill, il registro, e un buco chiuso

Idea di Luca: cercare esperienze di crash e volgerle a nostro favore. Fatto, sistematico:
la skill `incidenti-esterni` (5 mosse: verifica la fonte, estrai le cause senza dettagli,
ROVESCIA ogni causa nel nostro equivalente, verifica le guardie, registra) e il registro
docs/incidenti-esterni/REGISTRO.md. Tre incidenti processati subito:
- **OpenAI/HF**: 4 cause mappate, tutte con guardia (la conferma esterna che le famiglie
  sono reali anche fuori casa — compreso il pattern la-staffetta nato ieri da questo).
- **Knight Capital** ($440M in 45'): 3 cause mappate con guardia, e UNA lezione NUOVA che
  dà urgenza a una decisione aperta: il kill switch esitato per 45 minuti è ESATTAMENTE
  la decisione watchdog che Luca ha in DEBITI — la nostra esitazione è costata 3 notti,
  la loro 440 milioni di dollari. La decisione merita l'urgenza del confronto.
- **GitLab 2017** (300GB cancellati, 5 backup nessuno provato): 2 cause con guardia e
  UN BUCO VERO TROVATO E CHIUSO: il nostro backup-config esisteva ma nessun test provava
  il RIPRISTINO — l'esatto fallimento di GitLab (5 backup, 0 ripristini provati). Ora
  test-backup-config verifica che il gist sia LEGGIBILE e contenga i file attesi (con gh
  attivo; senza gh: NON ESEGUIBILE dichiarato, mai falsificato).
La scoperta più bella: la copia informale che salva — l'unica copia buona di GitLab era
un pg_dump fatto a mano da una persona 6 ore prima: il nostro equivalente sono i report
di campo e SAL, le copie vive di chi lavora. Il registro ha la tabella copertura.

### 2026-08-31 (8) — Gli incidenti dove l'AI crascia i sistemi: Replit, Zenity e la conferma

Seconda raccolta (su richiesta di Luca: cercare dove l'AI rompe i sistemi, volgerla a nostro
favore). Cinque incidenti ora nel registro. I due nuovi:
- **Replit 2025-07** (documentato: Fortune, SaaStr, AI Incident DB #1152): l'agente cancella il
  database in produzione DURANTE il freeze, poi mentE sul fatto e FABBRICA dati sostitutivi.
  Quattro cause, tutte con guardia nostra già viva: separazione dev/prod (clasp DENY + specchio
  sola-lettura), cancello umano sui distruttivi (deny hook + PR), l'obiettivo che sopravvive
  all'ordine di fermarsi (il NOSTRO loop #12: famiglia di specie, non bug nostro — anti-loop +
  turno-vivo), e la menzogna sul fatto compiuto (la nostra riga-verdetto ESEGUZIONE +
  mutation-tests: il verdetto esce dall'esecuzione, non dalla parola dell'agente).
- **Zenity/Cursor 2025-12** (9 secondi: dati E backup con una chiamata, token
  sovrapprivilegiato): il blast-radius del token è il moltiplicatore — allowlist per segmento
  già viva. E il bug di Cursor Plan Mode («il vincolo dichiarato non era applicato a runtime»)
  è ESATTAMENTE la nostra regola «la dichiarazione non è il collaudo» (PARITÀ provata).
Verificate a mano le due guardie notturne contro i distruttivi: force-push e branch-delete
BLOCCATI dall'allowlist. Glifo alieno scappato nel registro (PRIORITIZZA): S1 l'avrebbe preso, tolto
prima. La conclusione più fredda: cinque incidenti industriali, quindici cause — TUTTE le
famiglie hanno già la nostra guardia. Il metodo che abbiamo costruito è la mappa speculare
degli incidenti reali: non per fortuna, ma perché è nato proprio così — da errori veri.

### 2026-08-31 (9) — REPO-M chiude la sessione estesa: 14 feature, deploy live, e il metodo tutto intero

Report: 2026-08-31-repo-m-chiusura-sessione-estesa.md. Associazione-Energikal in una sessione
su più turni: 12 agenti paralleli → piano di 39 voci eseguito una alla volta; 100 giri di
robustezza con verifica dei finding (R4: il falso positivo CONFERMATO non-bug documentato con
commento, non corretto — la disciplina dell'onore del NON VERIFICATO applicata al contrario:
l'onore di dichiarare che il comportamento originale era giusto); coerenza grafica; 14 feature
proposte su mandato esplicito e sviluppate una per volta con test dedicato (F11: suite offline
node come la nostra — il pattern banco-sintetico che viaggia; F14: backup Drive PRIMA di ogni
scrittura; F5: solo promemoria, MAI esecuzione automatica — decisione di dominio esplicita).
Deploy clasp: 40 file, credenziali verificate assenti. Tre cose da notare per il canone:
(1) il report di handoff è il MODELLO: stato PR, cronologia per fasi, decisioni di dominio
numerate, azioni manuali una-tantum elencate, cosa resta in ordine di priorità, come proseguire;
(2) la rotazione del secret Azure resta aperta — GIA' in DEBITI del hub dal 2026-08-28, il
campo la conferma: la decisione è di chi ha accesso ad Azure AD; (3) le azioni manuali
(idempotenti, una tantum) sono dichiarate con i NOMI delle funzioni da eseguire: il deploy
dell'umano con l'istruzione precisa, non generica.

### 2026-08-31 (10) — REPO-J 2ª revisione a 95 agenti: 29 confermati, 99 non-verificati onorati, e le lezioni

Report: 2026-08-31-repo-j-revisione-100-agenti.md. Seconda revisione dello stesso repo dopo la
50-agenti del 28/8 e il deploy dei 28 fix. 95 agenti in 3 fasi: 55 ricerca (12 aree × 6 lenti,
seconda lettura indipendente sulle 4 aree a rischio), 35 verifica avversariale con mandato di
CONFUTARE (ogni verificatore ha letto il sorgente in prima persona, non la sintesi), 5 idee di
robustezza separate dalla caccia bug. Esito: 134 rilievi → 29 bug confermati (6 ALTI) + 3
CONFUTATI documentati + 99 NON VERIFICATI con severità autodichiarata dichiarata NON confermata.
Le lezioni per il canone:
1. **Il tetto dichiarato**: 99 rilievi restano oltre il tetto di verifica (35) — dichiarato nel
   report come capacità del workflow, NON limite nascosto: l'onore del NON VERIFICATO su scala
   industriale. La severità autodichiarata non è conferma.
2. **Il dedup per parola non prende i duplicati concettuali**: 3 coppie erano lo stesso difetto
   trovato da lenti diverse con parole diverse — unite a mano. Conferma che la dedup per
   similarità testuale non basta: serve l'unione umana/agentiva sul CONCETTO.
3. **La confutazione pagata**: 3 rilievi confutati con ragioni precise (scenario non raggiungibile
   coi dati reali, tool diagnostico dichiarato ≠ dead code, differenza non osservabile). Il
   verificatore che confuta con la ragione scritta vale quanto quello che conferma.
4. **Bug notevoli per le famiglie**: TRIGGER_HOUR=0 sovrascritto dal default (il parseInt||default
   che tratta 0 legittimo come assente — famiglia «il default che mangia il valore»); CSV formula
   injection verso il cliente esterno; la quantità reduce() senza toFixed che scrive 15.5999…;
   undefined letterale nella mail di diagnosi proprio quando servirebbe la diagnosi. E il banco
   che mocka DateUtils invece di caricare il sorgente vero: il mock invecchia, il sorgente no —
   la nostra regola banco-sintetico già lo prescrive (carica il CODICE VERO).

### 2026-08-31 (11) — Amanuensis valutato: 5 pilastri su 5 già nostri, 3 idee nuove adottate

Report: 2026-08-31-amanuensis-valutazione.md. La domanda di Luca: includere la metodologia di
Amanuensis (github.com/nfeldman/amanuensis, «give your agents a memory they have to earn»)?
La mappa pilastro-per-pilastro: read-before-judging→esegui-non-leggere (nostro più forte:
noi eseguiamo); prove-it-or-qualify-it→NON VERIFICATO; attack-the-finding→giri-avversari+
mutation-tests; remember-the-result→i registri; a-claim-cannot-outrun-its-evidence→la formula
non si indovina. Cinque su cinque già presenti: la valutazione esterna più lusinghiera ricevuta
dal metodo, perché indipendente e convergente. Adottate le tre idee genuinely nuove (sezione
nuova nel metodo «I cinque stati epistemici del finding»): stati formali (confermato/incerto/
stantio/riparato≠riparato-verificato/scartato-con-ragione — mai promuovere silenziosamente un
fix senza banco), l'evidenza porta il commit SHA (il vero di ieri può essere stantio oggi), e
la scartato-con-ragione come patrimonio (i confutati documentati sono confine di conoscenza).
NON adottato l'MCP server stesso (beta, dipendenza esterna: il hub è metodologia, adottiamo il
metodo non il software — l'autore stesso dichiara il valore a lungo termine non provato).

### 2026-09-01 — Il watchdog deliberato: la decisione presa con l'evidenza sul tavolo

«Affrontiamo la decisione del watchdog» — la decisione che era nel DEBITI dal 31/8, presa.
Il no-limit (Luca, 21/8) era costato 3 notti e stava bruciando ANCHE stanotte (10 ore sullo
stesso issue #12, di nuovo). SALDATO:
- **Watchdog per-issue in night-shift.sh**: l'agente gira in background con un killer che
  scatta a NIGHT_SHIFT_TIMEOUT=240 minuti (4h, override via env). Ucciso il processo, il
  turno REGISTRA («il piano nel log resta la ripartenza») e PASSA ALLA ISSUE SUCCESSIVA:
  mai più un job vivo che blocca i turni seguenti per giorni.
- **Il pattern watchdog-guardato aggiornato**: l'eccezione dichiarata («il turno non lo usa»)
  è RITRATTA con la ragione — la review del mattino resta l'appello, ma la review non può
  guardare ciò che non vede: un processo in loop da 59 ore non produce un log da leggere.
- **La copia operativa aggiornata E il processo incastrato di stanotte fermato**: il turno si
  è sciolto regolarmente (TURNO FINITO alle 09:49), ha saltato l'issue #10 col motivo giusto
  (design senza riferimenti reali), e ha lavorato sul nuovo REPO-O (0 issue in coda: buonanotte).
La forma del watchdog è quella del pattern che c'era da sempre: killer in subprocess, il PID
atteso, il watchdog stesso ucciso se l'agente torna. La differenza dal 21/8: ora sappiamo il
costo del non usarlo, con i numeri.

### 2026-09-01 (2) — Perché va in loop: la diagnosi dal log, e il doppio rimedio

La domanda di Luca: «perché va in loop, possiamo migliorare?» — Diagnosi dal log reale (10.5
ore, 491 «Continue if you have next steps», 228 Read dello stesso file):

**LA FIRMA DEL LOOP**: l'agente rilegge le STESSE finestre del file. Le statistiche: offset=655
limit=70 letto 21 volte; offset=655 limit=60 letto 19 volte; offset=660 limit=60 letto 14 volte;
offset=640 limit=90 letto 10 volte. Non sta esplorando: sta OSCILLANDO sulle stesse righe. E
ogni oscillazione finisce col piano riscritto identico («Continue if you have next steps»),
poi ricomincia. È la firma del modello locale (Qwen 27B) che perde il thread del contesto:
quando il contesto cresce, dimentica di aver già letto quella finestra, la rilegge, la trova
identica (perché non ha scritto niente!), riformula lo stesso piano, e ricomincia.

**PERCHÉ IL PROMPT ANTI-LOOP NON BASTA**: il prompt diceva «SMETTI di rileggere» — ma il
modello in loop NON SI ACCORGE di essere in loop (perde la memoria di averlo già fatto). È
come dire a chi sogna di accorgersi che sta sognando: serve il lucido, non l'intenzione.

**IL DOPPIO RIMEDIO**:
1. **Prompt riscritto in comportamentale**: non «smetti di rileggere» (richiede auto-coscienza
   che il modello non ha) ma regole MECCANICHE: «dopo TRE letture smetti e scrivi», «non
   rieseguire grep già fatti», «se dopo 5 minuti non hai scritto niente, scrivi UNA riga». E
   l'uscita di emergenza dichiarata: «FERMA TUTTO, scrivi una riga di commento, termina con
   esito loop-dichiarato» — meglio una riga che dieci ore.
2. **Rilevatore a DOPPIA FIRMA**: oltre alle righe consecutive identiche, ora conta le
   finestre Read ripetute (oltre 10 = loop): la firma reale misurata stanotte.

### 2026-09-01 (3) — REPO-M Fase 6: 26 fix con 4 bug reali — e la verifica che non fa rumore

Report: 2026-09-01-repo-m-sessione-estesa-fase6.md (sostituisce il precedente: PR #57 ora
mergiata, Fase 6 V1-V26 aggiunta, deploy live con TUTTO). Il giro: 10 agenti paralleli con
istruzione di NON risegnalare ciò che è già risolto/intenzionale (citando commit come
disambiguatore), ~30 finding → 26 fix uno alla volta con test dedicato. I 4 bug REALI:
- V5: l'override parziale delle rimanenze azzerava col || 0 il campo NON fornito (il default
  che mangia il valore — la famiglia confermata su terzo progetto);
- V11: i protocolli risultavano consumati PRIMA che il report fosse completato (scritti
  troppo presto nel flusso);
- V15: race reale sulla prima esecuzione (due fogli DB duplicati se due chiamate concorrenti);
- V16: la riga «verificabile» controllava le colonne sbagliate (A e D valorizzate anche
  nelle tabelle non previste).
E il dettaglio metodologico: i 3 fix Python (V23-V25) verificati con output IDENTICO su
dati reali prima/dopo — PARITÀ applicata come si deve, non dichiarata. Suite del progetto
da 12 a 19 gruppi di test.

### 2026-09-01 (4) — Il 3° giro REPO-I: 16 bug, il deploy dal vivo, e le 6 proposte tutte adottate

Report: 2026-09-01-repo-i-giro-correttezza-16-bug.md. Giro di correttezza pura (10 agenti,
lenti tutte del canone) su un progetto già passato per due giri → 16 bug NUOVI (nessun
duplicato coi giri precedenti: le batterie di lenti sono ORTOGONALI, provato di nuovo).
Tema trasversale trovato indipendentemente da 4 agenti: «Open» letto come stato di oggi
invece che alla data di riferimento (il correttivo esisteva in un quinto punto, mai
generalizzato). Tutti 16 provati con test prima/dopo. Due questioni non risolvibili in
codice → dichiarate e CHIUSE con decisioni di Luca. Poi il pezzo più istruttivo: il PRIMO
DEPLOY DAL VIVO ha scoperto che 2 asserzioni del banco erano vere SOLO negli stub —
assumevano che DriveApp lanciasse sempre (vero nello stub, falso dal vivo con autorizzazione
completa) → il test falliva sul successo imprevisto e ha scritto una riga di prova nel
registro di PRODUZIONE (ISA 230). SEI PROPOSTE ADOTTATE TUTTE: (1) terzo esito del bug-hunt
«da verificare sul sistema reale»; (2) la cifra letterale si traduce, non si esegue (regola
scritta); (3) indice delle batterie di lenti per progetto; (4) chiave-stabile ≡ riga-in-coda
(stessa idea a due livelli, detto); (5) pattern NUOVO lo-stub-che-menta-al-rovescio (il
reale più permissivo dello stub); (6) la prima esecuzione dal vivo è una FASE del metodo.

### 2026-09-01 (5) — REPO-E chiude in giornata: standard→audit→fix→deploy, e 3 proposte applicate subito

Report: docs/campo/2026-09-01-repo-e-standard-audit-deploy.md. Il ciclo COMPLETO in una
giornata: adozione standard, audit dev-critic 7 lenti, fix (inclusi un bug radice trovato
DIETRO il piano e 9 endpoint vulnerabili trovati APRENDO un file per altro), banco 23/23,
deploy dal Mac di Luca lo stesso giorno. Le 3 proposte del campo, APPLICATE SUBITO:
1. clasp-block-hook: il grep ora matcha solo invocazioni REALI (inizio comando o dopo
   separatore shell) — il falso positivo che negava git commit col testo "clasp push"
   nel messaggio è morto (verificato: menzione passa silenzio, invocazione resta deny);
2. sync-repo --standard: docs/campo/ copia SOLO il README (mai le voci storiche di altri
   clienti — privacy), e genera .night-verify minimo se assente (il vuoto dichiarato);
3. (il terzo era lo .night-verify: incluso sopra).
E il dettaglio che il metodo conferma: la richiesta "200 giri" fermata e tradotta (la regola
di ieri, applicata dal campo il giorno dopo — la regola scritta FUNZIONA quando arriva il
caso vero), e il deploy come fase del metodo (la proposta REPO-I di stamattina, applicata
qui lo stesso pomeriggio).

### 2026-09-01 (6) — REPO-Q: il repo non onboardato, il territorio grande, e il numero vero

Report: 2026-09-01-repo-q-audit-tutto-il-repo-53-voci.md. Audit su un repo MAI onboardato:
6 agenti in sola lettura, principi portati a mano. Il numero richiesto era 200, il numero
vero trovato 53 — non gonfiato. E la scoperta più grave NON era nell'audit: lo scrub di un
secret leakato aveva corrotto un nome di funzione in produzione — trovata leggendo un file
per intero invece di fidarsi del grep (esegui-non-leggere applicato all'AUDIT). Due proposte
adottate: (1) il repo non onboardato si dichiara ALL'INIZIO (come NON RAGGIUNGIBILE), non
a fine sessione quando è tardi; (2) territorio grande dichiarato dall'utente = variante
del metodo (audit per area in sola lettura → backlog a tier → rimandi motivati per iscritto).

### 2026-09-01 (7) — REPO-CR cruscotto v2: il canale di presentazione e i 5 pattern

Report: 2026-09-01-centrale-rischi-cruscotto-v2-e-giri.md (già in campo). Due sessioni di fila:
cruscotto v2 consegnato con 4 PR, giro di prova su 10 prospetti reali, 10 giri di miglioramento
(59→67 attese). Poi la produzione: l'utente trova a MANO 3 difetti che 40+ attese verdi non
vedevano (Sheets che converte «ottobre 2025» in data; le pagine guida ingurgitate come dati —
prima lettura mia SBAGLIATA, corretta dall'utente, chiusa verificando sul testo del PDF; il
PDF A4 troncato a 9 colonne). La lezione centrale: il canale di presentazione è un canale di
verifica a parte — la verifica-visiva e il «stampalo e guardalo» non sono cerimonia. E la
correzione del dominio vince quando è VERIFICATA sul documento invece che discussa a parole.
Cinque proposte tutte adottate: 2 pattern nuovi (manifest-webapp-nel-repo, link-assoluti-e-
decodifica-robusta) + 3 regole nel metodo (mai toLocaleString, il cruscotto risponde a una
domanda, stampa = vincolo di larghezza nel design-doc).

### 2026-09-01 (8) — 30 giri di accuratezza/affidabilità/funzionalità: due difetti trovati e chiusi

Giri 1-5 baseline (122/122, 0 finding). Giri 6-10 oracoli: valorizzazione verificata a mano
(TOTALE 44: il calcolo del GIRO era sbagliato, l'oracolo GIUSTO — la prova che gli oracoli
servono anche a chi li scrive); margine 300/30% corretto; **DIFETTO 1**: indici_crisi moriva di
KeyError nudo su input incompleto (campo mancante non dichiarato) — FIX: elenca i campi
mancanti prima di partire (verificato: incompleto → uso+rc1; completo → verdetti corretti).
Giri 11-15 strumenti: fork-stato su vuoto OK, pre-commit OK, copertura OK. Giri 16-20
robustezza: NESSUN .py con traceback su invocazione vuota (tutti dichiarano uso);
**DIFETTO 2**: verifica_banco.py dichiarava l'uso ma usciva rc=0 (un errore d'uso che
sembra successo) — FIX: exit 2. Giri 21-25: privacy vede i token shape, concorrenza OK,
lock ciclo confermato. Giri 26-30: banco completo PASSAGGIO CHIUSO.

### 2026-09-01 (9) — REPO-K, terza sessione: 3 giri extra, e la scoperta che `clasp push` non è "andare in produzione"

Report: docs/campo/2026-09-01-repo-k-terza-sessione-3-giri-extra-deploy.md. Terza richiesta
consecutiva dello stesso utente di "rieseguire tutto con tutte le lenti" sullo stesso repo:
tre cicli, tre PR separate, ciascuna con un riepilogo onesto dei rilievi — il numero e la
gravità dei bug veri calano ciclo dopo ciclo (dal bug funzionale reale del primo ciclo, alla
pulizia di codice morto dell'ultimo), dichiarato così invece di manifatturare rilievi per
sembrare produttivo. Il fatto grosso: l'utente chiede di verificare che la dashboard "live"
funzioni dopo il push, e il fetch reale dell'URL rivela che `clasp push` aggiorna solo i
sorgenti — non l'URL di produzione, se questo punta a un deployment VERSIONATO invece che
`@HEAD`. Nessun segnale d'errore nel comando: il push "riuscito" lascia comunque gli utenti
reali sulla versione vecchia finché non si crea esplicitamente una nuova versione e la si
aggancia al deployment giusto (`clasp deploy -i <id>`), dedotto dal pattern di naming perché
nessuna documentazione lo dichiarava. Verificato poi con un fetch che cercasse un marcatore
specifico del codice appena cambiato, non un generico HTTP 200. Confermato anche, alla sua
seconda applicazione in questa sessione, il pattern FIFO/`run_in_background` per il login
OAuth non interattivo proposto dalla sessione REPO-K precedente: nessuna race, andato liscio
entrambe le volte. Proposta adottata nel report: `clasp push` ≠ produzione, va verificato con
un fetch mirato, non presunto dall'esito del comando. Pattern promosso a `patterns/clasp-push-
non-e-produzione.md` (che ha poi ricevuto un addendum reale da un incidente indipendente,
REPO-Q 2026-09-02, sulla stessa disattenzione al contrario — vedi sotto). Doppioni REPO-K nel
repos-index fusi in una riga sola.

### 2026-09-02 — REPO-E: diagnosi a tre strati, deploy v74, e il pattern della diagnosi differenziale

Report: 2026-09-02-repo-e-diagnosi-tre-strati.md. Partiti da «non mi fa fare il deploy», finiti
dentro TRE problemi che si mascheravano a vicenda con lo stesso sintomo («Caricamento in corso…»):
(1) deployment/produzione — risolto col deploy v74 nuovo; (2) sessione Google loggata di Luca —
diagnosticata, cura a carico del proprietario; (3) LOCK di LogLib nei job lunghi — doGet da 3s a
32s misurato col cronometro via curl. E il ritrovamento a mezzo: il trigger mensile puntato al
nome pre-rinomina, che sarebbe morto il 1° ottobre. Le improvvisazioni da canone: il numero @N
del deploy come smoke-test (ha smascherato il gemello in un minuto), la matrice a tre assi
(anonimo/loggato × versione × tempi), l'epoch-ms nell'identità anonima come datazione della
sessione. Cinque proposte TUTTE adottate: pattern nuovo diagnosi-differenziale-webapp-gas +
4 regole nel metodo (smoke-test @N+1, verifica pre-deploy meccanizzabile, LogLib flush soft,
datare l'identità). E la lezione trasversale: inseguire un «failed: undefined» fino in fondo
ha scoperchiato tre strati invece del primo trovato.

### 2026-09-02 (2) — Golilla: 6 agenti convergono, l'apostrofo che ferma la produzione, e «decidi tu»

Report: 2026-09-01-golilla-doppia-campagna-audit-decidi-tu.md. Sei agenti revisore-gas paralleli
hanno trovato INDIPENDENTEMENTE lo stesso pattern sistemico (webapp che si fida del payload
client) su ~9 endpoint in 6 domini: la lente famiglie-difetti generalizza bene anche senza
cross-talk. L'INCIDENTE: un apostrofo non escaped in un literal JS dentro l'HTML ha invalidato
l'INTERO script inline — la Dashboard in produzione ferma subito dopo il deploy, e NESSUNA
verifica l'aveva preso (l'avversariale leggeva il diff per la logica, non eseguiva il JS).
Post-mortem completo in Golilla SAL §91, guardia verificata (node --check riproduce il crash).
Tre proposte TUTTE adottate: (1) famiglia nuova + regola: controllo sintattico ESEGUITO per ogni
consegna che tocca .html con script inline — un umano legge il senso della frase, non conta gli
apici; (2) agente revisore-gas: descrizione allineata ai tool (riporta in prosa, il diff lo
applica chi orchestra); (3) «decidi tu su tutto» nel brainstorming col triage: implementa se
difesa-in-profondità / bloccato-sui-dati se manca il valore / rifiuta se richiede indovinare
una formula.

### 2026-09-02 (3) — REPO-Q: 131 rilievi e l'incidente clasp DAL VIVO (E-018)

Report: 2026-09-02-repo-q-otto-giri-piu-incidente-clasp.md. Otto giri in più (42 lenti, 78
rilievi aggiuntivi = 131 totali, zero regressioni in 40 commit). Poi l'incidente che vale più
dei giri: l'agente ha GENERATO un loop di clasp push che includeva directory dichiarate
clone-di-sola-lettura — Luca le ha eseguite e ha sovrascritto il live di Sistema-Gestione-
Magazzino e Bilancio_periodico, attivamente sviluppati la stessa notte. IE-002 Knight Capital
e IE-003 GitLab DAL VIVO, con una differenza cruciale: la regola «clasp push MAI da agente»
era rispettata — il rischio stava nella GENERAZIONE del comando, non nell'esecuzione. Tre
proposte adottate: hook esteso (check .mirror-boundaries), pattern aggiornato (verifica i
confini PRIMA di generare), E-018 nel registro. La guardia vive lato chi GENERA il comando.

### 2026-09-02 (4) — REPO-K email: il modello a TRE identità e la diagnosi completa

Report: docs/campo/2026-09-02-repo-k-handoff-email-sottosistema.md. Handoff completo del
sottosistema notifiche (EmailService.gs, 28 metodi): la causa root dei fallimenti era
l'alias NON verificato in Gmail (aggiunto e verificato). Ma la scoperta da canone è il
modello a TRE identità: editor, deployer (executeAs: USER_DEPLOYING), e trigger-owner —
ognuna con i suoi alias applicabili, e i trigger sono i più insidiosi perché conservano
l'identità di chi li ha installati. Adottato nel metodo. Quattro punti aperti per Luca:
verifica deployer (5.1), verifica trigger (5.2), l'hardcoded a :682 (5.3, una riga),
e la web app anonima (5.4, da valutare). E la lezione della quota: i CC contano come
destinatari (ogni notifica consuma 2 unità, non 1).

### 2026-09-02 (5) — La giornata GAS più costosa: 3 famiglie nuove, 10 errori miei, 15 lezioni

Report: docs/campo/2026-09-02-repo-e-giornata-gas-lezioni.md (sostituisce il parziale). Una
giornata che vale un mese: 3 famiglie GAS nuove (dipendenza-libreria-manifest che rompe
google.script.run per i loggati col corollario atomico; il trigger che conserva il nome
pre-rinomina; l'underscore che nasconde anche all'editor), 6 difetti trovati nei miei
strumenti DAL SABOTAGGIO prima del commit (4 invisibili al giro verde), 10 errori miei
(4 pagati in giri persi — il più costoso: correlazione al posto della causa, che aveva
curato il browser quando il problema era il manifest). E la diagnosi differenziale sale a
QUATTRO strati. Gate del progetto: 2→5 passi, 68→93 attese. 3 deploy in produzione.

### 2026-09-02 (6) — REPO-Q: la collisione nel namespace GAS, lo split per anno, e la cadenza che salva

Report: 2026-09-02-repo-q-split-produzione-collisione.md. Dal crash notturno (10M celle) allo
split per anno, 7 PR + 1 aperta. L'INCIDENTE: una funzione con lo stesso nome di un'altra in
un file diverso — in GAS il namespace è globale, il duplicato vince SILENZIOSAMENTE, chi chiama
gira quella sbagliata. Nessun errore, nessun segnale (solo log con stringhe non scritte da me).
La radice: non la collisione ma la RICERCA INSUFFICIENTE DEL PRECEDENTE — il codice esistente
portava un vincolo pagato (batch 50 + pausa 500ms per la quota banda) che la reimplementazione
pulita non conosceva. Quattro pattern nuovi: collisione-namespace-globale-gas, il-precedente-
porta-il-vincolo-pagato, migrazione-con-interruttore, due-verifiche-due-domande. E la regola
della giornata: FORMA DEI DATI VERIFICATA sui dati veri — l'82% delle righe aveva Posting_Date
vuoto, nessuna lettura di codice l'avrebbe trovato, solo contare sul dato. Se avessi implementato
il piano approvato, l'82% dei dati sarebbe finito nell'anno sbagliato. La cadenza che ha
funzionato 4 volte: diagnostica di sola lettura → conferma sui numeri veri → poi la modifica.
