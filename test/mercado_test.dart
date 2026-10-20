import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mercado_electrico/modelo/datos.dart';
import 'package:mercado_electrico/modelo/mercado.dart';

void main() {
  group('casación marginalista', () {
    test('todas cobran el precio de la última oferta necesaria', () {
      final r = casar(
        const [
          Oferta(Tecnologia.eolica, 100, 0, 0),
          Oferta(Tecnologia.nuclear, 50, 0, 5),
          Oferta(Tecnologia.ciclos, 100, 90, 90),
        ],
        const [Puja('Demanda', 200, 4000)],
      );
      expect(r.precio, 90);
      expect(r.mwCasados, 200);
      expect(r.despacho[Tecnologia.ciclos], 50);
      expect(r.cuentas[Tecnologia.eolica]!.ingreso, 100 * 90);
    });

    test('si lo que oferta a 0 € cubre la demanda, el precio es 0 €', () {
      final r = casar(
        const [
          Oferta(Tecnologia.solar, 300, 0, 0),
          Oferta(Tecnologia.ciclos, 100, 90, 90),
        ],
        const [Puja('Demanda', 200, 4000)],
      );
      expect(r.precio, 0);
      expect(r.despacho[Tecnologia.ciclos], isNull);
      expect(r.despacho[Tecnologia.solar], 200);
    });

    test('la demanda flexible puede fijar el precio', () {
      final r = casar(
        const [
          Oferta(Tecnologia.solar, 250, 0, 0),
          Oferta(Tecnologia.ciclos, 100, 90, 90),
        ],
        const [Puja('Demanda', 200, 4000), Puja('Bombeo', 100, 20)],
      );
      expect(r.precio, 20);
      expect(r.mwCasados, 250);
      expect(r.marginal, contains('Demanda flexible'));
    });
  });

  test('coste de un ciclo: gas 35, CO2 70, rendimiento 55 % ≈ 92 €/MWh', () {
    expect(costeCiclo(35, 70, 0.55), closeTo(92.3, 0.5));
  });

  test('el motor Dart reproduce el precio del modelo calibrado en Python', () {
    final j = jsonDecode(File('assets/dias_representativos.json')
        .readAsStringSync()) as Map<String, dynamic>;
    for (final dj in j['dias'] as List) {
      final dia = Dia.fromJson(dj as Map<String, dynamic>);
      final horas = (dj['horas'] as List).cast<Map<String, dynamic>>();
      for (var i = 0; i < 24; i++) {
        final p = simularHora(dia.horas[i], dia.escenario).precio;
        expect(p, closeTo((horas[i]['precioModelo'] as num).toDouble(), 0.02),
            reason: '${dj['fecha']} hora $i');
      }
    }
  });
}
