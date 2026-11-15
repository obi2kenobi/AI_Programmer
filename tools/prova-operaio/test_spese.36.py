from spese import ripartisci, consuntivo_per_voce


def test_ripartisci_somma_esatta():
    """La somma dei centesimi deve essere ESATTAMENTE il totale per ogni input."""
    for totale, quote in [
        (10001, [33.33, 33.33, 33.34]),
        (100, [33.3, 33.3, 33.4]),
        (9999, [10, 20, 70]),
        (1000, [33.33, 33.33, 33.34]),
        (1000000, [0.1, 0.2, 99.7]),
    ]:
        righe = ripartisci(totale, quote)
        assert sum(righe) == totale, (
            f"somma {sum(righe)} != {totale} per quote {quote}"
        )


def test_ripartisci_caso_noto():
    assert ripartisci(10001, [33.33, 33.33, 33.34]) == [3333, 3333, 3335]
    assert ripartisci(100, [33.3, 33.3, 33.4]) == [33, 33, 34]
    assert ripartisci(10000, [50, 50]) == [5000, 5000]


def test_consuntivo():
    spese = [{"voce": "1", "cent": 100}, {"voce": "2", "cent": 50}, {"voce": "1", "cent": 25}]
    assert consuntivo_per_voce(spese) == {"1": 125, "2": 50}


if __name__ == "__main__":
    test_ripartisci_somma_esatta()
    test_ripartisci_caso_noto()
    test_consuntivo()
    print("tutti i test verdi")
