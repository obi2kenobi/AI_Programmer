#!/bin/bash
# help.sh — IL MENU DEI VERBI (trucco di scopribilità, 100 giri assurdi
# 2026-08-29): l'hub ha 19 tool di shell e 16 python, e chi arriva non sa cosa
# può chiedere al sistema. Questo elenco è la porta d'ingresso operativa —
# lo stesso principio del README per i documenti, applicato ai comandi.
set -uo pipefail
HERE="$(cd "$(dirname "$0")/.." && pwd)"

# Il menu è organizzato per MOMENTO D'USO, non per alfabeto: chi chiude un
# passaggio guarda la prima sezione, chi studia un progetto nuovo la terza.
# Ogni voce è un comando eseguibile così com'è: nessuna configurazione richiesta
# (quelle poche che esistono sono dichiarate nella voce stessa, tipo NOOPEN=1).
# L'elenco degli ORACOLI resta abbreviato: le formule complete stanno nella
# mappa di dominio, qui il menu non duplicherebbe altro che rischierebbe
# di invecchiare (i numeri nei menu marciscono come tutti i numeri).

cat <<MENU
AI_Programmer — i verbi del sistema (bash tools/<nome>)

ALLA CHIUSURA DI UN PASSAGGIO (il banco che decide se hai finito)
  banco-passaggio.sh          i 7 banchi, verdetto su una riga (--veloce salta avversari/mutazioni)
  banco-passaggio.sh --solo-copertura   solo: ogni file di codice cambiato è presidiato da un test?

LE BATTERIE (le tre pair di occhi del sistema)
  giri-ignoranti.sh           12 sonde scortesi: caratteri alieni, numeri claims, teatri, orfani...
  giri-avversari.sh           95 attacchi: forzare le regole, aggirare le difese, imbrogliare le lenti
  mutation-tests.sh           neutralizza ogni tool: i suoi test DEVONO arrossire
  ciclo-vivo.sh               un giro a livello crescente (1→5→CUORE→1: il battito)

LO STUDIO (prima di toccare un progetto di destinazione)
  polilivello.sh <dir>        scaffold a 6 livelli: cosa fa / come / come meglio
  fork-stato.sh <copie...>    la deriva fra repo/fork/GAS-vivo e la base di lavoro giusta
  presidio.sh claim/lista/rilascia   chi sta toccando cosa ADESSO (multiutenza sul repo)
  privacy-check.sh            nessun nome privato nei file né nella storia git

IL DIARIO E LA MEMORIA
  sal-indice.sh               rigenera l'indice del SAL (dopo ogni voce nuova)
  sal-archivia.sh [giorni]    ruota le voci vecchie all'archivio (append-only)
  campo-triage.sh             quanti report dal campo non sono ancora processati

LA PROPAGAZIONE (portare il metodo altrove)
  sync-repo.sh <owner/repo> --standard    PR col sistema intero nel repo target
  onboard-repo.sh / bootstrap-app.sh      le altre due strade

GLI ALTRI
  system-health.sh            Ollama, Wayfinder, prerequisiti
  status-page.sh              la pagina HTML dello stato (NOOPEN=1 senza browser)
  bc_index.py / bc_map.py / bc_tipi_metadata.py    il censimento Business Central
  gas_qualita.py <dir>        il rilevatore delle famiglie di difetti GAS
  verifica_banco.py <file>    il giudice dell'uscita di un banco GAS
  help.sh                     questo menu

E gli oracoli (16, formula minata dal codice reale, mai inventata):
  valorizzazione_magazzino · margine_documento · rating_dso_clienti · scadenzario_aging
  accuratezza_fatture_acquisto · leasing_amministrativo · bilancio_bu · rollforward_cespiti
  indici_crisi · scostamento_standard_effettivo · riconciliazione_magazzino ...
  (l'elenco con le formule: docs/mappa-dominio-gas-src.md)
MENU
