# 2026-10-14 — hasslacher-29289717-piva-non-letta
**Autore**: sessione Claude (con Luca)

## Cosa ho usato
Grep sul codice di Registrazione_Fatture_Acquisto (`gas/AutomazioneSD.gs:734`, `gas/Claude.gs:64`, `gas/Regole.gs:146`) e il comando `tools/debiti-riapertura.sh`. Non c'era il PDF della fattura 29289717: non è raggiungibile da questa sessione.

## Cosa ho improvvisato
Niente di nuovo. Ho dichiarato a Luca che la causa (P.IVA non letta dal modello dal PDF) è un'ipotesi dal codice, non una misura: serve il PDF o la cella `piva_fornitore` della riga. Ho saltato i debiti R1/R2 della riapertura, che riguardano la notte dell'hub e non questa richiesta: dichiarato, non risolto.

## Cosa ha retto / ostacolato
Ha retto: il controllo fail-closed sul fornitore ha fermato la fattura invece di registrarla sull'ordine sbagliato. Ha ostacolato: la mail automatica dice «P.IVA non letta» ma non dice dove stava il numero sul PDF. La fattura è ferma in cartella dal 6/10 e l'ha notato una persona, non il sistema.

## Proposta al canone
Nessuna. Candidata di dominio, in attesa di Luca: la mail a Maurizio con numero, ordine e link al PDF per le fermate che richiedono registrazione a mano.
