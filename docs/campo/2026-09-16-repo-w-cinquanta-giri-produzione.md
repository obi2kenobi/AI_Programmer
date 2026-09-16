# 2026-09-16 — REPO-W: cinquanta giri in produzione (caccia ai difetti silenziosi)

Autore: sessione remota su REPO-W (fatture fornitore estere GAS+BC), deploy del 16/09.
**In produzione**: 55 file spinti sul vivo col cancello verde 11/11 immediatamente prima;
rilettura completa post-push: tutti i 55 file corrispondono al commit 704db34, zero divergenze.

## Il lavoro: 50 giri sulla categoria che non fa rumore

Ogni giro ha chiuso con una guardia vista rossa prima di essere dichiarata verde: un
controllo mai rosso non prova niente. Il criterio: «cosa può sbagliare senza dirlo, in un
flusso che termina con una registrazione contabile irreversibile».

Esiti esempi (tutti sul sorgente vero): `righeOrdine_` — JSON.parse().value || [] trasformava
un errore BC in array vuoto che apriva le guardie a valle; `valoreDiCella_` — il foglio
coerceva silenziosamente i numeri fattura (0012345 → 12345, non più confrontabile); 
`normalizzaData_` — 3/9/2026 rifiutato e 31/02/2026 accettato (due difetti opposti); 
`valutaDiversa_` — fatture in valuta estera trattate come euro; `chiediOcr_` — schema non
strict + errori passeggeri fatali; `bc_sandbox.py` — ritentativo automatico sulle SCRITTURE
(pericoloso: una registrazione può essere andata a buon mentre la risposta si perde).

## L'apparato di verifica (prima non esisteva NESSUNO di questi)

| Strumento | Cosa prova | Esito |
|---|---|---|
| test_regole.mjs | logica pura | 91/91 |
| test_fase2.mjs | sorgenti reali con doppi | 127/127 |
| --sabotaggi | difetti iniettati | 39/39 |
| sabota_regole.mjs | mutazioni del codice vero | 29/29 |
| coerenza_gas.mjs | 8 lenti statiche | pulito |
| bc_sandbox.py | guardie scritture BC | 21/21 |
| test_emulatore.py | gemello Python | 43/43 |
| --sabotaggi | difetti nel gemello | 23/23 |

`tools/gate.sh` legge `.night-verify`, esegue 11 comandi, esce 1 se uno è rosso. Esiste
perche' incatenare un comando a `git commit` con `&&` non e' una lettura.

## Proposte al canone

1. **IL RITENTATIVO AUTOMATICO E' CORRETTO SU UNA LETTURA, PERICOLOSO SU UNA SCRITTURE**:
   una registrazione puo' essere andata a buon fine mentre la risposta si perde. Solo GET
   e HEAD sono ripetibili; un 200 senza il campo atteso solleva invece di restituire vuoto.
2. **UN CENSIMENTO CHE ATTRAVERSA CARTELLE DI PROVENIENZA IGNOTA DICHIARA SEMPRE IL
   PROPRIETARIO DEL DATO CHE RIPORTA**: git -C su una non-repo risale al genitore e risponde
   per lui — 477 modifiche di un altro repo presentate come misura di questo.
3. **IL COMMIT SU UNA SUITE ESEGUITA E NON LETTA E' UN COMMIT SU NIENTE**: il comando era
   incatenato con &&, il controllo era rosso, non e' stato letto. Da questo nasce gate.sh.
