import os, csv, json, itertools, sys
sys.path.insert(0, os.path.dirname(__file__))
from motor import clear, build
rows = list(csv.DictReader(open(sys.argv[1] if len(sys.argv) > 1 else 'ES.csv')))
DAYS = {
 '2019-01-16': dict(gas=24, co2=22, nuclear=7100, carbon=5000, coalCost=28, ciclos=20000),
 '2022-03-08': dict(gas=227, co2=70, nuclear=7100, carbon=2500, coalCost=110, ciclos=22000),
 '2022-07-20': dict(gas=150, topeGas=40, co2=85, nuclear=7100, carbon=1500, coalCost=100, ciclos=22000),
 '2024-04-05': dict(gas=27, co2=60, nuclear=5000, ciclos=22000),
 '2025-01-22': dict(gas=48, co2=80, nuclear=7100, ciclos=22000),
 '2025-05-11': dict(gas=35, co2=70, nuclear=4000, ciclos=22000, pmin=-15),
 '2025-06-16': dict(gas=38, co2=73, nuclear=6000, ciclos=22000),
}
out = {}
for d, base in DAYS.items():
    hs = [dict(load=float(r['load_forecast_mw']), solar=float(r['solar_forecast_mw']), wind=float(r['wind_onshore_forecast_mw']), price=float(r['price_es'])) for r in rows if r['datetime'].startswith(d)]
    best = None
    import random
    random.seed(1)
    grid = dict(hidro=list(range(3000, 15001, 1000)), fHidro=[x/20 for x in range(0, 27)], wHidro=[0.5,1,1.5,2], otras=list(range(1000, 10001, 1000)), export=list(range(0, 8001, 1000)), bExp=[0,5,10,20,40,60], neg=[0.0] if 'pmin' not in base else [x/10 for x in range(1,11)])
    if 'pmin' in base: grid['bExp2'] = [0, -3, -6, -9, -12, -15]
    cur = {k: v[len(v)//2] for k, v in grid.items()}
    def ev(c):
        P = dict(base, **c); return (sum((clear(*build(h, P))[0]-h['price'])**2 for h in hs)/24)**0.5
    bestv = ev(cur)
    for it in range(6):
        for k, vs in grid.items():
            for v in vs:
                c = dict(cur, **{k: v}); e = ev(c)
                if e < bestv: bestv, cur = e, c
    for vals in [tuple(cur.values())]:
        P = dict(base, **dict(zip(grid.keys(), vals)))
        err = 0
        for h in hs:
            p, _ = clear(*build(h, P))
            err += (p - h['price']) ** 2
        rmse = (err / 24) ** 0.5
        if best is None or rmse < best[0]:
            best = (rmse, P)
    rmse, P = best
    sim = [round(clear(*build(h, P))[0], 1) for h in hs]
    print(d, round(rmse, 1), {k: P[k] for k in grid}, '\n  real', [round(h['price']) for h in hs], '\n  sim ', [round(x) for x in sim])
    out[d] = dict(params=P, rmse=round(rmse, 1))
json.dump(out, open(os.path.join(os.path.dirname(__file__), 'calibracion.json'), 'w'), indent=1)
