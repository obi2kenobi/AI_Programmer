# Task da operaio

La rendicontazione non quadra: `ripartisci(10001, [33.33, 33.33, 33.34])` torna righe
la cui somma è diversa da 10001. Lo stesso con `ripartisci(100, [33.3, 33.3, 33.4])`
può dare 99 o 101 invece di 100.

1. Trova la causa e correggila in `spese.py`, con il diff più piccolo possibile.
2. Aggiungi UN test di regressione in `test_spese.py` (somma esatta + caso noto).
3. Lancia i test con `python3 test_spese.py` finché sono tutti verdi.
4. Non toccare `consuntivo_per_voce`, non aggiungere dipendenze, non rifattorizzare.

Chiudi il report con: cosa hai saltato o non verificato, e i rischi residui.
