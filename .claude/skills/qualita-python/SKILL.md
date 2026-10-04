---
name: qualita-python
description: La procedura di revisione qualità del codice Python OLTRE la sintassi — quando l'utente chiede una revisione Python approfondita, un audit qualità su un repo o modulo .py, «controlla docstring/type hints/dead code/import», o prima di fondere codice Python delicato. py-gate ferma la sintassi; qui si cerca ciò che il compilatore non vede. Completata dal ruolo revisore-python (il canone); questa è la procedura operativa coi comandi.
---

# qualita-python — oltre la sintassi, con i comandi

Ruolo di riferimento: `revisore-python` (le sette famiglie e i confini: lui
non corregge, dichiara). Qui la procedura REPLICABILE: ogni passata un
comando o una lettura dichiarata, ogni rilievo con file:riga e prova.

## 0. L'inventario (un comando, prima di giudicare)

```bash
find . -name '*.py' -not -path './.git/*' | xargs wc -l | tail -1   # volume
grep -rn "def \|class " --include='*.py' . | wc -l                  # firme
ls tests/ test/ 2>/dev/null || echo "NESSUNA CARTELLA TEST"         # banco
```

Il repo senza tests/ è il primo rilievo (gravità alta: il parco conta i test
finti tra i difetti più diffusi — 55 su 80 progetti GAS con test che non
possono fallire; Python non è immune).

## 1. Le eccezioni inghiottite (la famiglia peggiore)

```bash
grep -rn --include='*.py' -E "except.*:\s*$" -A1 . | grep -B1 -E "pass|continue|return None" | head -30
```

Ogni occorrenza letta NEL CONTESTO (il grep trova i candidati, la lettura
decide): `except: pass` attorno a UNA riga di log tollerabile è diverso da
quello attorno al calcolo. La domanda per ogni candidato: «quando questo
fallisce, chi se ne accorge?».

## 2. I confini dei dati (dove Python incontra BC)

I file che caricano dati (csv, json, BC) si leggono per intero cercando:

- `float(x)`/`int(x)` su campi che possono essere vuoti o None
- confronti con stringhe sentinella (`"0001-01-01"`, `""`)
- funzioni che ritornano `[]` sia per «vuoto» sia per «errore già loggato»

## 3. Le firme dei confini (type hints dove conta)

NON ovunque: sulle funzioni PUBBLICHE e sui loader/parser. La prova è la
domanda: «chi chiama da fuori sa cosa entra e cosa torna?». Il rilievo è per
la firma del confine, non per ogni variabile interna.

## 4. Docstring sui pubblici

La barra è quella del progetto (gli oracoli tools/*.py del parco sono
documentati). Il censimento:

```bash
python3 - <<'PY'
import ast, glob
for f in glob.glob('**/*.py', recursive=True):
    if '.git' in f: continue
    t = ast.parse(open(f, errors='ignore').read())
    for n in ast.walk(t):
        if isinstance(n, (ast.FunctionDef, ast.AsyncFunctionDef)) and not n.name.startswith('_'):
            if not ast.get_docstring(n):
                print(f"{f}:{n.lineno} {n.name}() pubblica senza docstring")
PY
```

## 5. Import e dead code

```bash
python3 -m pyflakes . 2>/dev/null || pipx run pyflakes . 2>/dev/null || echo "pyflakes assente: censimento manuale"
```

pyflakes assente NON blocca: si dichiara assente e si censce a occhio a occhio gli
import dei moduli principali. Il dead code (funzioni mai chiamate) SI DICHIARA
nel SAL come candidato alla rimozione — non si cancella in revisione
(cattura-prima: la menzione non è l'uso).

## 6. I test che non possono fallire

Per ogni file di test, la domanda discriminante per OGNI test: «cosa devo
rompere perché diventi rosso?». I segni del test finto: assert dentro try che
li cattura, confronto della funzione con una sua copia incollata nel test,
fixture che riproducono il codice. La PROVA: una mutazione piccola (cambiare
un operatore, una costante) e via di test — se resta verde, non è un test.

## 7. L'uscita

Tabella: `file:riga · famiglia · gravità · prova (comando o mutazione) · cura
in una frase`. In coda: le famiglie che NON hanno morsicato (dichiarate), e il
verdetto VERIFICATO/LETTO. I rilievi numerici citano il ricalcolo fatto al
volo, con l'input usato.
