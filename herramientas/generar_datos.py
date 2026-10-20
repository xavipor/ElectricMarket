import os, csv, json, statistics as st, shutil, sys
sys.path.insert(0, os.path.dirname(__file__))
from motor import clear, build
SRC = sys.argv[1] if len(sys.argv) > 1 else 'ES.csv'
OUT = sys.argv[2] if len(sys.argv) > 2 else 'datos/'
rows = list(csv.DictReader(open(SRC)))
shutil.copy(SRC, OUT + 'omie_es_horario_2015_2025.csv')
# estadísticas anuales
by = {}
for r in rows: by.setdefault(r['datetime'][:4], []).append(float(r['price_es']))
with open(OUT + 'estadisticas_anuales.csv', 'w', newline='') as f:
    w = csv.writer(f); w.writerow(['anio', 'horas', 'precio_medio', 'desviacion', 'minimo', 'maximo', 'horas_0_o_menos', 'horas_negativas', 'nota'])
    for y, v in sorted(by.items()):
        w.writerow([y, len(v), round(sum(v)/len(v), 2), round(st.pstdev(v), 2), min(v), max(v), sum(x <= 0 for x in v), sum(x < 0 for x in v),
                    'parcial: hasta 30-sep' if y == '2025' else ('desde 7-ene' if y == '2015' else '')])
fit = json.load(open(os.path.join(os.path.dirname(__file__), 'calibracion.json')))
META = {
 '2019-01-16': ('Invierno normal antes de la crisis', 'Miércoles de enero de 2019. Gas barato (unos 24 €/MWh) y todavía carbón en el sistema: el precio apenas se mueve entre 61 y 73 €/MWh porque ciclos y carbón marcan precio casi todas las horas.'),
 '2022-03-08': ('Récord de la crisis del gas', 'El día con el precio medio más alto de la serie (545 €/MWh), dos semanas después de la invasión de Ucrania. El gas TTF cerró el 7 de marzo en torno a 227 €/MWh y arrastró a ciclos e hidráulica.'),
 '2022-07-20': ('Verano con excepción ibérica', 'Ola de calor con el tope al gas (40 €/MWh) en vigor. El precio del diario se queda en 140-155 €/MWh, pero no incluye el ajuste que pagaban los consumidores para compensar a los ciclos.'),
 '2024-04-05': ('Primavera con precio cero', 'Viernes de abril de 2024 con embalses llenos, mucho viento y sol: 21 de 24 horas a 0 € o menos y una media de 0,44 €/MWh.'),
 '2025-01-22': ('Invierno de 2025', 'Miércoles de invierno con gas a unos 48 €/MWh y poco sol: el gas vuelve a marcar el precio, entre 104 y 168 €/MWh.'),
 '2025-05-11': ('Domingo con precios negativos', 'Domingo de mayo con demanda baja y mucha solar: precios negativos de 10:00 a 18:00 y el mínimo del año, -15 €/MWh.'),
 '2025-06-16': ('Curva de pato', 'Lunes de junio: casi 0 € al mediodía y 210 €/MWh a las 21:00, cuando se pone el sol y hay que arrancar ciclos y turbinar agua.'),
}
dias = []
for d, (titulo, desc) in META.items():
    P = fit[d]['params']
    horas = []
    for r in rows:
        if not r['datetime'].startswith(d): continue
        h = dict(load=round(float(r['load_forecast_mw'])), solar=round(float(r['solar_forecast_mw'])), wind=round(float(r['wind_onshore_forecast_mw'])))
        sim = clear(*build(h, P))[0]
        horas.append(dict(hora=int(r['datetime'][11:13]), precioReal=float(r['price_es']), demandaMw=round(h['load']), solarMw=round(h['solar']), eolicaMw=round(h['wind']), precioModelo=round(sim, 2)))
    pr = [x['precioReal'] for x in horas]
    dias.append(dict(fecha=d, titulo=titulo, descripcion=desc, precioMedioReal=round(sum(pr)/24, 2), errorModeloRmse=fit[d]['rmse'],
        parametros={k: P[k] for k in ['gas','co2','nuclear','ciclos','hidro','fHidro','wHidro','otras','export','bExp','neg'] } | {k: P[k] for k in ['topeGas','carbon','coalCost','pmin','bExp2'] if k in P},
        horas=horas))
json.dump(dict(
    fuente='Precios: OMIE (marginalpdbc). Demanda, solar y eólica terrestre: previsiones del día anterior de ENTSO-E Transparency. Recopilado en github.com/cesar-tatto/mibel-dayahead-dataset (MIT).',
    notas=['Horas en hora local española; los días de cambio de hora están normalizados a 24 horas.',
           'Demanda, solar y eólica son previsiones D-1 (lo que conocían los agentes al ofertar), no producción real.',
           'Gas (€/MWh térmico) y CO2 (€/t) son valores aproximados de referencia, no cotizaciones exactas del día.',
           'Los parámetros de oferta (hidráulica, otras, exportación) están calibrados para que el modelo simplificado se parezca al precio real; no son datos observados.'],
    dias=dias), open(OUT + 'dias_representativos.json', 'w'), ensure_ascii=False, indent=1)
print('ok', [(x['fecha'], x['precioMedioReal'], x['errorModeloRmse']) for x in dias])
