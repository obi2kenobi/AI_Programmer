# Terzo ventaglio — giri 21-25 (2026-09-24)

I primi due ventagli (docs/giri/2026-09-23-notte/) hanno letto per aree e per lenti trasversali:
~70 rilievi curati, dettaglio nel SAL (voce 18°). Questo ventaglio guarda cio' che nessuno dei due ha
messo alla prova: il turno intero eseguito, i banchi come giudici, le skill come istruzioni, il
tempo, il catalogo dei pattern.

## Lenti
| # | Lente | La domanda |
|---|---|---|
| V1 | Il turno eseguito | `night-shift/night-shift.sh` gira per un ciclo intero con gh, ollama, opencode FINTI (su `PATH`, in una HOME finta): ogni ramo (caccia, issue, cascata agente, censore, parere, scopa dei rami, banco veloce, restart) fa quello che il log dice? Cosa si rompe eseguendo, che nessun banco a pezzi vede? |
| V2 | I banchi come giudici | Per un campione di banchi di `tests/`: si sabota la riga di codice che il banco dichiara di presidiare (una per banco, scelta leggendo il commento del banco). Il banco diventa rosso? Dove resta verde, il banco non giudica. `tools/mutation-tests.sh` esiste: usalo o dichiara perché no. |
| V3 | Le skill come istruzioni | Ogni `.claude/skills/*/SKILL.md` prescrive comandi, percorsi, procedure. Si eseguono davvero (in un clone): quali comandi non esistono piu', quali percorsi mancano, quali procedure contraddicono il codice di oggi? |
| V4 | Tempo e budget | La suite dura 200-300 s su un budget di 540 (`.night-verify`, riga `@540`), e il Mac del turno e' piu' lento. Misura il tempo di ogni banco; quali dormono senza motivo, quali rifanno lavoro di altri; qual e' il rischio di sforare, e cosa succede quando si sfora. |
| V5 | Il catalogo dei pattern | Ogni `patterns/*.md` e' ancorato a codice. L'ancora esiste ancora, e il codice ancorato fa ancora cio' che il pattern afferma? Un pattern la cui ancora e' viva ma dice altro e' peggio di un'ancora morta. |

## Regole
- Clone: `git clone -q /home/user/AI_Programmer <scratchpad>/clone-V<n>` e lavora LI'. Il codice del repo
  vero non si tocca.
- Il rapporto si scrive PRIMA di rispondere, DENTRO il repo vero ma in una cartella ignorata da git:
  `/home/user/AI_Programmer/docs/giri/2026-09-24-terzo/V<n>.md` (E-044: lo scratchpad in /tmp puo'
  sparire). E' l'unico file che il giro scrive fuori dal clone.
- Ogni rilievo: Oggi (file:riga letti davvero) · Provato eseguendo (comando e uscita vera) · Manca ·
  Proposta. Un rilievo non provato si dichiara «non provato».
- Tetto 6 rilievi per lente, in ordine di gravita'. «Nulla in questa lente» e' un esito valido.
- Niente segreti: mai stampare valori di chiavi o token, nemmeno finti presi da file veri.
- Mai `clasp push`/`clasp deploy`; mai `rm -rf` su una variabile che non hai creato tu con mktemp nello
  stesso script (E-044).
