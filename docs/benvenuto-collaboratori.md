# Benvenuto in AI_Programmer — come si usa dal primo giorno

> La mail tipo per i collaboratori. La verità pratica: se la tua repo è a
> standard, NON serve invocare nulla — il metodo entra da solo a ogni sessione
> e a ogni tuo prompt (hook). Se non lo è ancora, bastano le tre frasi sotto.

## Le tre frasi (repo non ancora a standard)

1. **All'avvio della sessione**: «Lavora col metodo AI_Programmer
   (github.com/obi2kenobi/AI_Programmer): leggi AGENTS.md prima di iniziare.»
2. **Prima di ogni calcolo contabile**: «Prima l'oracolo in tools/*.py e il
   censimento in docs/bc/endpoints/ — la formula non si indovina.»
3. **Alla chiusura**: «Scrivi il report dal campo in docs/campo/ di oggi
   (tre righe bastano; "nessuna proposta" dichiarata conta).»

## Se il progetto esiste in più copie (repo, fork, GAS vivo)

Prima mossa OBBLIGATORIA: skill `allineamento-fork` — si decide la base di
lavoro PRIMA di toccare un file, e per i GAS vale che **il vivo è definitivo,
in produzione, mai un'ipotesi**: si legge con clasp, non si immagina.
`bash tools/fork-stato.sh <copie...>` misura la deriva e dice il da farsi.

## Le cinque regole che ti tutelano (il resto sta in METHOD.md)

1. Esegui, non dedurre — ogni ipotesi si prova col comando, riportandolo.
2. Oracolo prima della formula — mai inventare logica di business.
3. Banco prima della correzione — e la domanda di dominio in cima.
4. Segreti mai in chat; `clasp push` mai (il deploy è dell'umano).
5. Scarto mai silenzioso — ogni riga esclusa porta il motivo.

## Per portare la TUA repo a standard

Chiedi a Luca `tools/sync-repo.sh <owner/repo> --standard`: una PR porta
CLAUDE.md, skill, agenti, hook e formato report. Da lì, non dici più niente:
il metodo è semplicemente in opera.
