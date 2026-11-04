# 2026-11-03 — revisione degli errori della night-shift (log 2-3/11, 11.960 righe)
**Autore**: sessione Claude con Luca

## Cosa ho usato
il log della console della night-shift (fuori dal repo), `night-shift/lib.sh`, `night-shift/night-shift.sh`, `night-shift/agente.sh`, prove dirette su Ollama (`/api/chat`, `/api/ps`), `vm_stat`, `sysctl`.

## Cosa ho improvvisato
Il gate dei banchi non aveva un test sulla propria lettura del TOTALE: l'ho scritto (`tests/test-gate-totale-letto.sh`, esegue la riga vera di `night-shift/night-shift.sh`).

## Cosa ha retto / ostacolato
- Ostacolato: `night-shift/night-shift.sh:648` leggeva `FAIL_T` con tutto il resto della riga («0 (di cui ambra-flaky: 0)»): `[ "$FAIL_T" -eq 0 ]` era sempre falso, ogni auto-fix BOCCIATO (17 volte, 32 errori «integer expression expected»).
- Ostacolato: 254 «AGENTE FALLITO / risposta vuota» e 264 «VERIFICA ROSSA»: il Mac ha 24 GB, il modello `gemma4:26b-notturno` ne tiene ~15 wired, swap 14,5/15 GB: una richiesta «Say OK» non risponde in 120 s.
- Rumore: 384 «riallineo NON riuscito» (sostituirebbe il CLAUDE.md, una decisione umana ripetuta a ogni ciclo).
- Retto: `night-shift/agente.sh:133` dichiara la risposta vuota invece di dire «niente trovato».

## Proposta al canone
Un guasto che si ripete a ogni ciclo senza cambiare va detto UNA volta (con il contatore), non a ogni ciclo. Modello più leggero o niente turno quando lo swap supera una soglia: da decidere con Luca.
