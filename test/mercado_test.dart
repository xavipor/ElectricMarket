import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:mercado_electrico/modelo/datos.dart';
import 'package:mercado_electrico/modelo/factura.dart';
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

  test('las baterías estrechan el diferencial y suben el precio capturado de la solar', () {
    final j = jsonDecode(File('assets/dias_representativos.json')
        .readAsStringSync()) as Map<String, dynamic>;
    final dia = Dia.fromJson((j['dias'] as List)[6] as Map<String, dynamic>);
    final sin = simularDia(dia.horas, dia.escenario);
    final con = simularDia(dia.horas, dia.escenario.copyWith(bateriaMw: 10000));
    List<double> precios(DiaSimulado d) => [for (final c in d.casaciones) c.precio];
    double capturado(DiaSimulado d) {
      var mwh = 0.0, ingreso = 0.0;
      for (final c in d.casaciones) {
        final q = c.despacho[Tecnologia.solar] ?? 0;
        mwh += q;
        ingreso += q * c.precio;
      }
      return ingreso / mwh;
    }

    final ps = precios(sin), pc = precios(con);
    expect(pc.reduce(math.max), lessThan(ps.reduce(math.max)));
    expect(pc.reduce(math.min), greaterThanOrEqualTo(ps.reduce(math.min)));
    expect(capturado(con), greaterThan(capturado(sin)));
    expect(con.margenBaterias, greaterThan(0));
    expect(con.carga.where((x) => x > 0).length, greaterThan(0));
  });

  test('factura de un hogar típico: unos 700 €/año y +44 € por cada 10 €/MWh de OMIE', () {
    const s = SupuestosFactura();
    expect(totalFactura(s), closeTo(712, 5));
    final sube = totalFactura(s.copyWith(precioMayorista: 75)) - totalFactura(s);
    // 3.000 kWh × 1,15 de pérdidas × 10 €/MWh, con impuesto eléctrico e IVA.
    expect(sube, closeTo(3.45 * 10 * 1.0511 * 1.21, 0.01));
    final r = s.copyWith(valle: 0.6).reparto;
    expect(r.reduce((a, b) => a + b), closeTo(1, 1e-9));
  });
}
