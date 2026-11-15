"""Ripartizione spese su voci di budget (specchio semplificato di Dashboard_Bandi)."""


def ripartisci(totale_cent, quote_pct):
    """Ripartisce totale_cent (int, centesimi) sulle quote percentuali.

    Ritorna una lista di int (centesimi), una per quota.
    VINCOLO: la somma delle righe deve essere ESATTAMENTE totale_cent,
    altrimenti la rendicontazione SIMEST non quadra.
    """
    n = len(quote_pct)
    righe = [0] * n
    interi = [0] * n
    fraz = [0.0] * n
    resto = totale_cent
    for i, q in enumerate(quote_pct):
        val = totale_cent * q / 100
        interi[i] = int(val)
        fraz[i] = val - interi[i]
        righe[i] = interi[i]
        resto -= interi[i]
    indici = sorted(range(n), key=lambda i: fraz[i], reverse=True)
    for i in indici:
        if resto <= 0:
            break
        righe[i] += 1
        resto -= 1
    return righe


def consuntivo_per_voce(spese):
    """Somma gli importi (cent) per voce. spese: lista di dict con voce e cent."""
    per_voce = {}
    for s in spese:
        voce = s["voce"]
        if voce in per_voce:
            per_voce[voce] += s["cent"]
        else:
            per_voce[voce] = s["cent"]
    return per_voce
