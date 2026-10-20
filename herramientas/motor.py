# Motor de casación simplificado (espejo del motor Dart de la app)
def clear(offers, bids):
    """offers/bids: lista de (precio, mw). Devuelve (precio, mw casados)."""
    cands = sorted(set([p for p, q in offers if q > 0] + [p for p, q in bids if q > 0]))
    for p in cands:
        s = sum(q for pp, q in offers if pp <= p)
        d_above = sum(q for pp, q in bids if pp > p)
        if s + 1e-6 >= d_above:
            return p, min(s, sum(q for pp, q in bids if pp >= p))
    return cands[-1], sum(q for _, q in offers)

def ccgt_cost(gas, co2, eff):
    return gas / eff + co2 * 0.202 / eff + 3.0

EFFS = [0.58, 0.56, 0.54, 0.52, 0.50, 0.46]

def build(h, P):
    """h: dict hora (load, solar, wind). P: parámetros."""
    offers = []
    gas = min(P['gas'], P.get('topeGas') or 1e9)
    ref = ccgt_cost(gas, P['co2'], 0.54)
    ren = h['solar'] * P.get('kSolar', 1) + h['wind'] * P.get('kWind', 1)
    s = P.get('neg', 0.0); pmin = P.get('pmin', 0.0)
    offers.append((0.0, ren * (1 - s)))
    for i in range(5):
        offers.append((pmin * (i + 1) / 5, ren * s / 5))
    offers.append((0.0, P['nuclear']))
    offers.append((P.get('pOtras', 5.0), P['otras']))
    if P.get('carbon', 0) > 0:
        offers.append((P['coalCost'] + P['co2'] * 0.95 + 3, P['carbon']))
    w = P.get('wHidro', 1.0)
    for m in [-0.3, -0.1, 0.1, 0.3]:
        offers.append((P['fHidro'] * (1 + w * m) * ref, P['hidro'] / 4))
    for e in EFFS:
        offers.append((ccgt_cost(gas, P['co2'], e), P['ciclos'] / len(EFFS)))
    bids = [(4000.0, h['load']), (P.get('bExp', 20.0), P['export'] * 0.5), (P.get('bExp2', 0.0), P['export'] * 0.5)]
    return offers, bids
