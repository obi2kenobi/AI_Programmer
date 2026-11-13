# Documentazione viva — la chiave delle modifiche oneste (13/11/2026)

Principio: il documento falso è peggio del documento assente — l'assente si
cerca, il falso si crede. Tre livelli, tre cancelletti.

## I tre livelli

1. DIARIO (già vivo): MIGLIORAMENTI.md, digest, SAL — la cronologia. Regola
   già in opera: la fine del turno si dichiara a guardia verde.
2. INVENTARIO DEL CODICE (da costruire, costo zero sul mini): un file
   INVENTARIO.md per repo, generato dal pass semantico: per ogni file, una
   riga (cosa fa, hot-path sì/no, chi lo chiama). Il grafo tiene la
   struttura; l'inventario la dice a parole. Rigenerato a ogni pass,
   committato col grafo (stessa PR night/grafo-*).
3. MODULO (per area critica): 5-10 righe in testa ai file caldi — già
   vero in Golilla (i commenti di AddressParser/dedup sono documentazione
   eccellente: spiegano il PERCHÉ con le date). Da prescrivere: ogni file
   toccato da un'ottimizzazione si porta a casa la riga che lo dichiara.

## Le tre regole nuove (revisione 16)

R1. NESSUN DIFF SENZA LA SUA RIGA DI DOCUMENTO: ogni modifica accettata
    tocca codice + diario (già regola) +, se cambia comportamento visibile,
    la riga d'inventario o il commento di modulo. Il commit message NON è
    documentazione: muore nello scroll.
R2. LA DOCUMENTAZIONE SI VERIFICA COME IL CODICE: verifica-doc.sh — i file
    citati nel diario esistono; le funzioni citate nell'inventario esistono
    nel codice (grep della prova); le voci "scagionato" portano la riga
    citata. Documento senza prova = nota, non verità.
R3. IL DOCUMENTO GENERATO DICHIARA LA PROPRIA FONTE: ogni pezzo generato dal
    modello (inventario, riassunti) porta il timbro "generato il <data> da
    <modello> — verificare col codice". La fonte non si nasconde, si firma.

## Il circolo che si chiude
grafo (struttura) + semantica gratis (comprensione) + documentazione viva
(memoria dichiarata) = il contesto che l'agente PUÒ credere. E llmwiki, se
nascerà, nasce da qui: la wiki non si scrive — SI GENERA da codice verificato
e si guarda col metodo prima di entrarci.
