# Studio a fondo: deepseek-harness — cosa rubiamo davvero

(hub: obi2kenobi/AI_Programmer — integrazione delle idee, NON del software: e' developer
preview senza audit di sicurezza, nodo/pnpm, e il turno non affida la produzione a un preview)

## I sei furti (in ordine di valore per noi)

### 1. CATALOGO EVENTI (da event-producer-consumer.md)
Il loro documento elenca ogni evento: chi lo produce, chi lo consuma. Il nostro equivalente
sono le firme di log: "DELIBERA:", "TRASFORMATORE deterministico", "gate BOCCIA",
"MIGLIORIA pronta", "AGENTE FALLITO", "Ollama wedged", ecc. L'audit-2 ha dimostrato che
una firma senza consumatori = contatore cieco per mesi. Il catalogo:
  docs/eventi.md: firma -> chi la scrive (file:riga) -> chi la legge (dashboard.py:riga,
  cervello-impara.sh:NN, turno NN) -> se ha guardia (test che verifica il flusso)
Guardiano: test-eventi.sh — per ogni firma nel catalogo, verifica che il produttore esista
ancora e abbia almeno un consumatore vero.

### 2. REPEAT-TOOL-REMINDER (da guard/repeat-tool-reminder)
Il loro guard osserva quando il modello ripete l'identica chiamata a tool e glielo ricorda
("cambia approccio o finisci"). Il nostro agente.sh: l'agente puo' fare 8 turni di edit
sullo stesso file senza che nessuno gli dica niente — la "non-convergenza sui bersagli
debito" che abbiamo visto. La cura: nel loop dell'agente, se l'azione N e' IDENTICA
all'azione N-1 (stesso JSON), il RESULT porta un avviso: "hai ripetuto la stessa identica
azione: cambia approccio o dichiara finish". Zero costo, azzerabile via env.

### 3. GOAL DURABLE (da packages/goal)
Loro: un objective per sessione che sopravvive a restart, resume e fork, con tools
create/get/update e il comando umano /goal. Il nostro equivalente mancante: una issue
lunga puo' attraversare 5 cicli del turno e nessuno ricorda QUAL'E' l'obiettivo. Il
nostro adattamento bash: .git/goal-issue-N (file di stato nel repo di lavoro, come
caccia-registro): l'agente ce l'ha nel prompt (obiettivo + cosa gia' fatta), il censore
lo vede ("questa PR serve al goal #N?"), la dashboard lo mostra. Per le issue lunghe.

### 4. LEZIONI POSTMORTEM (da postmortem/0003)
Il loro postmortem 0003 e' esattamente la nostra classe E-038: l'agente ha "verificato"
un server diverso da quello dell'utente perche' non sapeva QUALE fosse il suo ambiente.
La lezione da portare nel nostro REGISTRO come E-039:
  "L'agente deve conoscere i prerequisiti nascosti del runtime: la modalita' di avvio
  e' contesto dell'applicazione, non sapere tribale. Verifica CONTRO lo stato esterno,
  non contro il self-report."

### 5. VERIFY THE WORLD, NOT THE SELF-REPORT (da testing.md)
La loro regola di test piu' preziosa: "un'e2e assertion RIesEGUE il comando o RIlegge il
file esternamente; una keyword probe sull'output dell'agente lascia passare un agente
che bara. Assert che i file non toccati siano byte-identici."
Il nostro banco deploy-assistito lo fa gia' (verifica STORICO + pacchetto consumato);
generalizziamo la regola nel metodo: ogni banco che verifica un lavoro dell'agente deve
guardare il MONDO dopo, non l'output dell'agente.

### 6. PROFILO UNICO DEL TURNO (da profiles/bundles)
Tutta la configurazione dichiarata in un punto e ricomposta a avvio. Il nostro equiv:
profiles/notturno.conf letto a inizio ciclo (il nostro exec-per-ciclo = HMR gratis):
modello, timeout, budget agenti, rotazione lenti. Sostituisce i default sparsi in 7 file.

## Cosa NON prendiamo (e perche', dichiarato)

- Il software stesso: developer preview, no audit, breaking changes annunciati; il
  turno e' 24/7 incustodito. SAFETY.md loro: "must not be treated as secure or
  production-ready".
- Compaction automatica: il nostro agente ha num_ctx fisso e turni brevi per design;
  la conversazione non cresce abbastanza da giustificarla.
- Agent teams / spawn_teammate: il turno e' seriale per design (lock per repo);
  il parallelismo e' il modo piu' veloce di creare contese GPU su 24GB.
- Browser-use / computer-use: nessun caso d'uso notturno; il browser lo usa il giorno.
