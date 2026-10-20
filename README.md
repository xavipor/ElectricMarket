# Mercado eléctrico español: simulador de casación

**Demo:** https://xavipor.github.io/ElectricMarket/

App web en Flutter que explica cómo se fija el precio de la electricidad en España. Reproduce la casación marginalista del mercado diario de OMIE hora a hora, con siete días reales, y deja cambiar la demanda, el sol, el viento, el gas, el CO2, la nuclear o el tope al gas para ver qué pasa con el precio y con quién gana dinero.

## Qué tiene

- **Simulador.** Curva de oferta escalonada por tecnología, curva de demanda y punto de casación. Precio real de OMIE frente al modelo y frente a tu escenario, tecnología marginal, margen de cada tecnología y precio capturado por la solar y la eólica.
- **Aprende.** Once conceptos (subasta marginalista, OMIE y REE, por qué las renovables ofertan a 0 €, por qué no se vende todo a 0 €, gas, excepción ibérica, precios negativos, canibalización, intradiario, futuros y PPAs). Cada uno abre el simulador en el día y la hora que lo ilustran.
- **Datos.** Precio medio y horas a 0 € o menos de cada año entre 2015 y 2025.
- **Mapa.** Unas 3.000 centrales de España (eólica, solar, hidráulica, bombeo, nuclear, ciclos, carbón, fuel, biomasa y baterías) sobre un mapa con zoom. Cada punto abre su ficha (potencia, año, estado). Al lado, la producción por tecnología de la última hora que publica Red Eléctrica y, en la ficha, una estimación de lo que produce esa central ahora (su potencia por el porcentaje al que funciona su tecnología).

Enlaces directos: `?dia=6&hora=21` (o `#dia6-hora21`), `#aprende`, `#datos`, `#mapa`.

## Los siete días

| Día | Qué muestra |
|---|---|
| 16-ene-2019 | Invierno normal antes de la crisis |
| 8-mar-2022 | Récord de la crisis del gas (545 €/MWh de media) |
| 20-jul-2022 | Verano con excepción ibérica |
| 5-abr-2024 | Primavera con precio cero casi todo el día |
| 22-ene-2025 | Invierno de 2025 |
| 11-may-2025 | Domingo con precios negativos |
| 16-jun-2025 | Curva de pato: 0 € al mediodía, 210 € a las 21:00 |

## Cómo funciona el modelo

Cada hora se construye una curva de oferta con:

- **Solar y eólica:** previsión real del día anterior, a 0 € (o en negativo una parte, los días con precios negativos).
- **Nuclear** a 0 €, **cogeneración y otras** a 5 €/MWh.
- **Carbón:** coste del carbón + 0,95 t/MWh × CO2.
- **Hidráulica de embalse:** por coste de oportunidad, en cuatro escalones alrededor del coste de un ciclo de referencia.
- **Ciclos combinados:** seis bloques con rendimientos del 46 % al 58 %; coste = gas / rendimiento + CO2 × 0,202 / rendimiento + 3 €.

La demanda es la previsión real del día anterior (inelástica) más un bloque flexible de bombeo y exportación. El precio es el primer escalón en que la oferta acumulada cubre la demanda dispuesta a pagar más. El motor está en `lib/modelo/mercado.dart` y tiene tests en `test/mercado_test.dart`.

Hidráulica, otras, bombeo y exportación se calibran por día (`herramientas/calibrar.py`) para que el modelo se parezca al precio real. El error medio va de 0,7 €/MWh (abril de 2024) a 107 €/MWh (récord de marzo de 2022, cuando las ofertas reales quedaron muy por encima del coste del gas).

## Datos y fuentes

- Precios: ficheros `marginalpdbc` de OMIE.
- Demanda, solar y eólica: previsiones D-1 de ENTSO-E Transparency.
- Unidos en [cesar-tatto/mibel-dayahead-dataset](https://github.com/cesar-tatto/mibel-dayahead-dataset) (MIT).
- Gas y CO2 de cada día: valores de referencia aproximados.
- Centrales: [powerplantmatching](https://github.com/PyPSA/powerplantmatching) de PyPSA (CC BY 4.0), que cruza ENTSO-E, OpenStreetMap, GEM, JRC y otros registros. Se convierte con `herramientas/generar_centrales.py`.
- Producción en directo: API pública REData de Red Eléctrica (`apidatos.ree.es`), consultada desde el navegador. Si no hay dato horario se usa la media del día anterior. REE no publica en abierto la producción de cada central en tiempo real, así que la cifra por central es una estimación.
- Mapa base: © OpenStreetMap, teselas de CARTO.

Limitaciones: solo España (sin Portugal ni interconexiones), sin ofertas complejas y con datos horarios hasta septiembre de 2025 (desde octubre de 2025 el diario es cuartohorario).

## Ejecutar

```bash
flutter pub get
flutter test
flutter run -d chrome
flutter build web --release --no-web-resources-cdn
```

Cada pull request pasa los tests y compila la web; cada push a `main` además la publica en GitHub Pages (`.github/workflows/pages.yml`).

Para regenerar los datos: `python3 herramientas/calibrar.py ES.csv` y `python3 herramientas/generar_datos.py ES.csv assets/`, con `ES.csv` del repositorio de datos citado arriba. Para las centrales: `python3 herramientas/generar_centrales.py powerplants.csv assets/centrales.json`.

Hecho con Flutter 3.47. Fuente Roboto (Apache 2.0) incluida en `assets/fonts`.
