"""Ripartizione spese su voci di budget (specchio semplificato di Dashboard_Bandi)."""


def ripartisci(totale_cent, quote_pct):
    """Ripartisce totale_cent (int, centesimi) sulle quote percentuali.

    Ritorna una lista di int (centesimi), una per quota.
    VINCOLO: la somma delle righe deve essere ESATTAMENTE totale_cent,
    altrimenti la rendicontazione SIMEST non quadra.
    """
    righe = []
    somma_parc = 0
    for i, q in enumerate(quote_pct):
        parziale = round(totale_cent * q / 100)
        righe.append(parziale)
        somma_parc += parziale
    # Aggiusta l'ultima voce per rendere la somma esatta
    righe[-1] += totale_cent - somma_parc
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
