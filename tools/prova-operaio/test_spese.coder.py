from spese import ripartisci, consuntivo_per_voce


def test_ripartisci_pari():
    assert ripartisci(10000, [50, 50]) == [5000, 5000]


def test_consuntivo():
    spese = [{"voce": "1", "cent": 100}, {"voce": "2", "cent": 50}, {"voce": "1", "cent": 25}]
    assert consuntivo_per_voce(spese) == {"1": 125, "2": 50}


def test_ripartisci_somma_esatta():
    # Somma esatta per ogni input noto (regressione)
    assert sum(ripartisci(10001, [33.33, 33.33, 33.34])) == 10001
    assert sum(ripartisci(100, [33.3, 33.3, 33.4])) == 100


if __name__ == "__main__":
    test_ripartisci_pari()
    test_consuntivo()
    print("test esistenti verdi")
