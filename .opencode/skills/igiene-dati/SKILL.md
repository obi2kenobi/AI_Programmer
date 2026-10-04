---
name: igiene-dati
description: La procedura per verificare la QUALITÀ dei DATI (non del codice che li processa) — CSV ed export fogli, campioni, fixture: encoding, separatori, date, duplicati, sentinelle, campi vuoti contro campi mai raccolti. Quando l'utente chiede «controlla questo CSV/esportazione», «perché i numeri non tornano?», prima di costruire un banco su dati di provenienza incerta, o dopo l'importazione di un dump nuovo. Nata dall'incidente del 23/9 (dati personali veri nei campioni) e dalla famiglia confronto-non-vuoto: i dati sporchi avvelenano il banco più in silenzio del codice sbagliato.
---

# igiene-dati — i dati si guardano PRIMA di crederci

Il codice si testa; i DATI si ispezionano. Un banco verde su dati sporchi
certifica lo sbagliato con l'autorevolezza del verde. Questa skill ispeziona
un file di dati in passate piccole, ciascuna con un comando e un esito
dichiarato.

## 1. La provenienza (prima di tutto)

Tre domande, risposta nel report SEMPRE:

1. Da dove viene il file (chi lo ha esportato, quando, con che filtro)?
2. Cosa CONTIENE in linea di principio (quali campi dovrebbe avere)?
3. **Cosa contiene che NON DEVE** — la domanda dell'incidente: nomi veri,
   email, telefoni, PII. Il campione di lavoro si bonifica PRIMA di usarlo
   (`tools/anonimizza.py`, `tools/anonimizza-aziendale.sh`); il file con PII
   non si committa, non si incolla, non si manda. Il presidio è fail-closed.

## 2. La forma (un comando per domanda)

```python
file dati.csv
# encoding dichiarato
head -c 400 dati.csv | od -c | head -5
# BOM, separatori, ritorni a capo
python3 - <<'PY'
import csv, collections
with open('dati.csv', encoding='utf-8-sig', newline='') as f:
    campione = f.read(65536)
    f.seek(0)
    sep = csv.Sniffer().sniff(campione).delimiter
    r = csv.reader(f, delimiter=sep)
    # il separatore si annusa, non si indovina
    righe = list(r)
print("righe:", len(righe), "colonne prima riga:", len(righe[0]))
larghezze = collections.Counter(len(x) for x in righe)
print("larghezze (conteggio):", larghezze)
# righe storte visibili subito
PY
```

Le larghezze disuguali non sono sempre un errore (virgole nei campi quote),
ma vanno SPIEGATE prima di procedere, non scoperte dal traceback.

## 3. Le date (la famiglia che morde di più)

```python
python3 - <<'PY'
import csv, collections, re
with open('dati.csv', encoding='utf-8-sig', newline='') as f:
    righe = list(csv.DictReader(f))
# per ogni campo col nome che contiene data/date/giorno:
for campo in righe[0]:
    if re.search('dat|giorn|scad', campo, re.I):
        formati = collections.Counter()
        for r in righe:
            v = (r.get(campo) or '').strip()
            if not v: formati['<VUOTO>'] += 1; continue
            if re.match(r'^\d{4}-\d{2}-\d{2}', v): formati['ISO'] += 1
            elif re.match(r'^\d{2}/\d{2}/\d{4}', v): formati['IT'] += 1
            elif v.startswith('0001-01-01'): formati['SENTINELLA'] += 1
            else: formati['ALTRO:'+v[:12]] += 1
        print(campo, dict(formati))
PY
```

Esiti che sono rilievi: più di un formato nello stesso campo; la sentinella
`0001-01-01` contata e dichiarata (truthy! il filtro `if data` la fa
passare); `<VUOTO>` in campo data (vuoto ≠ assente).

## 4. Duplicati e chiavi

```python
python3 - <<'PY'
import csv, collections
with open('dati.csv', encoding='utf-8-sig', newline='') as f:
    righe = list(csv.DictReader(f))
# prova la chiave naturale CANDIDATA (es. numero documento + riga)
CHIAVE = ['numero', 'riga']
try:
    c = collections.Counter(tuple(r[k] for k in CHIAVE) for r in righe)
    dopp = {k: n for k, n in c.items() if n > 1}
    print("duplicati su", CHIAVE, ":", len(dopp), list(dopp.items())[:3])
except KeyError as e:
    print("CHIAVE candidata assente:", e, "— colonne:", list(righe[0]))
PY
```

La chiave candidata che duplica NON è una condanna del file (il documento
può avere più righe): è la scoperta della VERA chiave. La si dichiara:
«la chiave è documento+riga, non documento».

## 5. I vuoti e i mai-raccolti (confronto-non-vuoto)

Per ogni colonna: conteggio vuoti vs totale. La distinzione che vale:

- campo vuoto N volte su N → forse il campo NON ESISTE in questa esportazione
  (filtro sbagliato, sorgente che non lo manda più)
- campo pieno con buchi → buchi VERI da dichiarare

Un `count == len(righe) == 0` non significa «zero»: significa «mai
raccolto». Il banco che filtra `if valore` confonde i due e conta male.

## 6. L'uscita

Il REPORT D'IGIENE (breve, nel repo accanto al dato o nel report di sessione):

- provenienza e PII: bonifica dichiarata o assenza certificata
- forma: encoding, separatore, righe, larghezze e le anomalie spiegate
- date: formati contati, sentinelle contate
- chiave: quella vera, scoperta o confermata
- vuoti vs mai-raccolti: le colonne sospette

Il banco che nasce dopo parte da qui: le attese del banco CITANO l'igiene
(«righe attese 1234 dal censimento del CSV, sentinelle 12 già escluse»).
