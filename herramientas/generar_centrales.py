"""Genera assets/centrales.json a partir de powerplantmatching (PyPSA).

Fuente: https://github.com/PyPSA/powerplantmatching (powerplants.csv, CC BY 4.0).
Uso: python3 generar_centrales.py powerplants.csv assets/centrales.json
"""
import csv, json, sys

SRC = sys.argv[1] if len(sys.argv) > 1 else 'powerplants.csv'
OUT = sys.argv[2] if len(sys.argv) > 2 else 'assets/centrales.json'
ANIO_DATOS = 2026  # bajas con fecha anterior a este año se marcan como cerradas


def tecnologia(fuel, tec):
    if fuel == 'Wind':
        return 'eolica'
    if fuel == 'Solar':
        return 'solar_termica' if tec.lower() == 'csp' else 'solar_fv'
    if fuel == 'Hydro':
        return 'bombeo' if tec == 'Pumped Storage' else 'hidraulica'
    if fuel == 'Nuclear':
        return 'nuclear'
    if fuel == 'Natural Gas':
        return 'ciclo_combinado' if tec == 'CCGT' else 'fuel_gas'
    if fuel == 'Oil':
        return 'fuel_gas'
    if fuel in ('Hard Coal', 'Lignite'):
        return 'carbon'
    if fuel in ('Solid Biomass', 'Waste'):
        return 'biomasa'
    if fuel == 'Battery':
        return 'baterias'
    # 'Heat Storage' son los tanques de sales de las termosolares (ya listadas)
    # y 'Hydrogen Storage' son proyectos piloto: se descartan.
    return None


def sistema(lat, lon):
    if lat < 36.0:
        return 'ceuta_melilla'
    if 38.5 < lat < 40.2 and lon > 1.1:
        return 'baleares'
    return 'peninsular'


def anio(s):
    return int(float(s)) if s else None


centrales = []
for x in csv.DictReader(open(SRC, encoding='utf-8')):
    if x['Country'] != 'Spain' or not x['Capacity'] or not x['lat']:
        continue
    tec = tecnologia(x['Fueltype'], x['Technology'])
    alta, baja = anio(x['DateIn']), anio(x['DateOut'])
    if tec is None or (alta and alta > ANIO_DATOS):
        continue
    lat, lon = float(x['lat']), float(x['lon'])
    centrales.append([
        x['Name'].strip(), tec, round(float(x['Capacity']), 1),
        round(lat, 4), round(lon, 4), alta, baja,
        1 if baja and baja < ANIO_DATOS else 0, sistema(lat, lon),
    ])

centrales.sort(key=lambda c: -c[2])  # las grandes primero (se dibujan debajo)
json.dump({
    'fuente': 'powerplantmatching (PyPSA), CC BY 4.0',
    'url': 'https://github.com/PyPSA/powerplantmatching',
    'campos': ['nombre', 'tecnologia', 'mw', 'lat', 'lon', 'alta', 'baja',
               'cerrada', 'sistema'],
    'centrales': centrales,
}, open(OUT, 'w', encoding='utf-8'), ensure_ascii=False, separators=(',', ':'))
print(len(centrales), 'centrales ->', OUT)
