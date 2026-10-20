import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mercado_electrico/modelo/centrales.dart';
import 'package:mercado_electrico/modelo/tiempo_real.dart';

/// Respuesta con la forma de REData: una serie por tecnología en `included`.
String respuestaRee(Map<String, List<(String, double)>> series) => jsonEncode({
  'data': {'type': 'Generación'},
  'included': [
    for (final e in series.entries)
      {
        'type': e.key,
        'attributes': {
          'title': e.key,
          'values': [
            for (final (f, v) in e.value) {'value': v, 'percentage': 0, 'datetime': f},
          ],
        },
      },
  ],
});

http.Response utf8Ok(String cuerpo) => http.Response.bytes(utf8.encode(cuerpo), 200);

void main() {
  group('catálogo de centrales', () {
    final catalogo = CatalogoCentrales.desdeJson(File('assets/centrales.json').readAsStringSync());

    test('tiene las grandes tecnologías con potencias razonables', () {
      final p = catalogo.potenciaPeninsular();
      expect(catalogo.centrales.length, greaterThan(2500));
      // España tiene 7 reactores nucleares (unos 7,1-7,4 GW).
      expect(catalogo.centrales.where((c) => c.tec == TecCentral.nuclear && !c.cerrada).length, 7);
      expect(p[TecCentral.nuclear], inInclusiveRange(7000, 7600));
      expect(p[TecCentral.eolica], greaterThan(20000));
      expect(p[TecCentral.cicloCombinado], greaterThan(20000));
    });

    test('todas las centrales caen dentro de España', () {
      for (final c in catalogo.centrales) {
        expect(c.lat, inInclusiveRange(35, 44.5), reason: c.nombre);
        expect(c.lon, inInclusiveRange(-9.5, 4.5), reason: c.nombre);
      }
    });
  });

  group('datos de Red Eléctrica', () {
    test('lee la última hora con datos de casi todas las series', () {
      final s = leerSeriesRee(
        respuestaRee({
          'Eólica': [
            ('2026-10-20T10:00:00.000+02:00', 8000),
            ('2026-10-20T11:00:00.000+02:00', 9000),
          ],
          'Nuclear': [
            ('2026-10-20T10:00:00.000+02:00', 7000),
            ('2026-10-20T11:00:00.000+02:00', 7000),
          ],
          'Solar fotovoltaica': [('2026-10-20T10:00:00.000+02:00', 12000)],
          'Generación total': [('2026-10-20T10:00:00.000+02:00', 27000)],
        }),
      );
      final (momento, valores) = ultimoInstante(s)!;
      expect(momento, DateTime(2026, 10, 20, 10));
      expect(valores['Solar fotovoltaica'], 12000);
    });

    test('el factor de carga reparte la producción entre la potencia instalada', () {
      final m = MixAhora(
        momento: DateTime(2026, 10, 20, 10),
        mw: {'Eólica': 8000, 'Turbina de gas': 50, 'Fuel + Gas': 50, 'Cogeneración': 1500},
        instalada: {TecCentral.eolica: 32000, TecCentral.fuelGas: 1000},
        mediaDiaria: false,
      );
      expect(m.factorCarga(TecCentral.eolica), 0.25);
      expect(m.mwDe(TecCentral.fuelGas), 100);
      expect(m.factorCarga(TecCentral.nuclear), isNull);
      expect(m.total, 9600);
    });

    test('si no hay datos horarios usa la media de ayer', () async {
      final pedidas = <Uri>[];
      final cliente = MockClient((r) async {
        pedidas.add(r.url);
        final trunc = r.url.queryParameters['time_trunc'];
        if (r.url.path.endsWith('potencia-instalada')) {
          return utf8Ok(
            respuestaRee({
              'Eólica': [('2026-09-01T00:00:00.000+02:00', 32000)],
            }),
          );
        }
        if (trunc == 'hour') return http.Response('{"errors":[]}', 500);
        return utf8Ok(
          respuestaRee({
            'Eólica': [('2026-10-19T00:00:00.000+02:00', 24 * 16000)],
          }),
        );
      });
      final m = await ServicioRee(cliente: cliente)
          .cargar({TecCentral.eolica: 30000}, ahora: DateTime(2026, 10, 20, 12));
      expect(m.mediaDiaria, isTrue);
      expect(m.mwDe(TecCentral.eolica), 16000);
      expect(m.factorCarga(TecCentral.eolica), 0.5);
      // Petición CORS simple: sin cabeceras propias.
      expect(pedidas.first.host, 'apidatos.ree.es');
      expect(pedidas.first.queryParameters['geo_limit'], 'peninsular');
    });
  });
}
