"""Controlli nascosti del banco prova-operaio (MAI mostrarli al candidato).

Uso: python3 controlli_nascosti.py <file_spese_del_candidato>
Esce 0 solo se TUTTI i casi passano: somma esatta, equita' (max 1 cent di
scostamento dal valore ideale), nessuna riga negativa — anche con quote
che non sommano a 100 (il vincolo della docstring non lo esclude).
"""
import importlib.util
import sys

spec = importlib.util.spec_from_file_location("m", sys.argv[1])
m = importlib.util.module_from_spec(spec)
spec.loader.exec_module(m)
r = m.ripartisci

CASI = [
    (10001, [33.33, 33.33, 33.34]),
    (100, [33.3, 33.3, 33.4]),
    (10000, [50, 50]),
    (999, [25, 25, 25, 25]),
    (1, [33.33, 33.33, 33.34]),
    (7, [50, 50, 50]),
    (123456, [12.5, 37.5, 50.0]),
    (100, [100]),
    (0, [50, 50]),
]

rossi = 0
for tot, q in CASI:
    out = r(tot, q)
    somma_ok = sum(out) == tot
    equo = all(abs(o - tot * p / 100) < 1.0 for o, p in zip(out, q))
    neg = any(o < 0 for o in out)
    if not (somma_ok and equo and not neg):
        rossi += 1
        print(f"KO  tot={tot} q={q} -> {out} somma={sum(out)} equo={equo} negativi={neg}")
print("ESITO:", "VERDE" if rossi == 0 else f"{rossi} ROSSI")
sys.exit(0 if rossi == 0 else 1)
