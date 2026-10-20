import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Tecnologías que ofertan en el modelo simplificado del mercado diario.
enum Tecnologia {
  solar('Solar', Color(0xFFF2B705)),
  eolica('Eólica', Color(0xFF2A9D8F)),
  nuclear('Nuclear', Color(0xFF7B5EA7)),
  otras('Cogeneración y otras', Color(0xFF8D9A6B)),
  hidraulica('Hidráulica', Color(0xFF2F6FDE)),
  carbon('Carbón', Color(0xFF5B4B3A)),
  ciclos('Ciclos combinados (gas)', Color(0xFFE4572E));

  const Tecnologia(this.nombre, this.color);
  final String nombre;
  final Color color;
}

/// Una oferta de venta: un escalón de la curva de oferta.
class Oferta {
  const Oferta(this.tecnologia, this.mw, this.precio, this.coste);
  final Tecnologia tecnologia;
  final double mw;

  /// Precio al que se oferta (€/MWh).
  final double precio;

  /// Coste variable aproximado (€/MWh), para calcular el margen.
  final double coste;
}

/// Una puja de compra: un escalón de la curva de demanda.
class Puja {
  const Puja(this.nombre, this.mw, this.precio);
  final String nombre;
  final double mw;
  final double precio;
}

/// Datos de una hora: previsiones del día anterior y precio real de OMIE.
class Hora {
  const Hora({
    required this.hora,
    required this.precioReal,
    required this.demandaMw,
    required this.solarMw,
    required this.eolicaMw,
  });

  factory Hora.fromJson(Map<String, dynamic> j) => Hora(
        hora: j['hora'] as int,
        precioReal: (j['precioReal'] as num).toDouble(),
        demandaMw: (j['demandaMw'] as num).toDouble(),
        solarMw: (j['solarMw'] as num).toDouble(),
        eolicaMw: (j['eolicaMw'] as num).toDouble(),
      );

  final int hora;
  final double precioReal;
  final double demandaMw;
  final double solarMw;
  final double eolicaMw;
}

/// Parámetros del parque generador y de los combustibles para un día.
///
/// Los de combustibles son referencias aproximadas; hidráulica, otras y
/// exportación están calibrados para que el modelo se parezca al día real.
class Escenario {
  const Escenario({
    required this.gas,
    required this.co2,
    required this.nuclear,
    required this.ciclos,
    required this.hidro,
    required this.fHidro,
    required this.wHidro,
    required this.otras,
    required this.exportacion,
    required this.bExp,
    this.bExp2 = 0,
    this.neg = 0,
    this.pmin = 0,
    this.carbon = 0,
    this.costeCarbon = 0,
    this.topeGas,
    this.factorDemanda = 1,
    this.factorSolar = 1,
    this.factorEolica = 1,
  });

  factory Escenario.fromJson(Map<String, dynamic> j) {
    double n(String k, [double def = 0]) => (j[k] as num?)?.toDouble() ?? def;
    return Escenario(
      gas: n('gas'),
      co2: n('co2'),
      nuclear: n('nuclear'),
      ciclos: n('ciclos'),
      hidro: n('hidro'),
      fHidro: n('fHidro'),
      wHidro: n('wHidro', 1),
      otras: n('otras'),
      exportacion: n('export'),
      bExp: n('bExp', 20),
      bExp2: n('bExp2'),
      neg: n('neg'),
      pmin: n('pmin'),
      carbon: n('carbon'),
      costeCarbon: n('coalCost'),
      topeGas: (j['topeGas'] as num?)?.toDouble(),
    );
  }

  /// Precio del gas (€/MWh térmico) y del CO2 (€/t).
  final double gas, co2;

  /// MW disponibles por tecnología.
  final double nuclear, ciclos, hidro, otras, carbon;

  /// La hidráulica de embalse oferta por coste de oportunidad:
  /// fHidro × coste de un ciclo de referencia, repartido según wHidro.
  final double fHidro, wHidro;

  /// Bombeo y exportaciones: MW que compran si el precio es bajo; la mitad
  /// puja a bExp y la otra mitad a bExp2.
  final double exportacion, bExp, bExp2;

  /// Parte de la eólica y solar que oferta en negativo, hasta pmin.
  final double neg, pmin;

  /// Coste del carbón (€/MWh eléctrico, sin CO2).
  final double costeCarbon;

  /// Tope al gas de la excepción ibérica (null si no aplica).
  final double? topeGas;

  /// Multiplicadores que mueve el usuario sobre los datos reales.
  final double factorDemanda, factorSolar, factorEolica;

  Escenario copyWith({
    double? gas,
    double? co2,
    double? nuclear,
    double? factorDemanda,
    double? factorSolar,
    double? factorEolica,
    double? Function()? topeGas,
  }) =>
      Escenario(
        gas: gas ?? this.gas,
        co2: co2 ?? this.co2,
        nuclear: nuclear ?? this.nuclear,
        ciclos: ciclos,
        hidro: hidro,
        fHidro: fHidro,
        wHidro: wHidro,
        otras: otras,
        exportacion: exportacion,
        bExp: bExp,
        bExp2: bExp2,
        neg: neg,
        pmin: pmin,
        carbon: carbon,
        costeCarbon: costeCarbon,
        topeGas: topeGas != null ? topeGas() : this.topeGas,
        factorDemanda: factorDemanda ?? this.factorDemanda,
        factorSolar: factorSolar ?? this.factorSolar,
        factorEolica: factorEolica ?? this.factorEolica,
      );

  /// Gas con el que ofertan los ciclos (topado si hay excepción ibérica).
  double get gasOferta => topeGas == null ? gas : math.min(gas, topeGas!);
}

/// Rendimientos de los seis bloques de ciclos combinados, del más eficiente
/// al menos eficiente.
const rendimientosCiclos = [0.58, 0.56, 0.54, 0.52, 0.50, 0.46];

/// Coste variable de un ciclo combinado (€/MWh eléctrico):
/// gas / rendimiento + CO2 × 0,202 t/MWh térmico / rendimiento + 3 € de O&M.
double costeCiclo(double gas, double co2, double rendimiento) =>
    gas / rendimiento + co2 * 0.202 / rendimiento + 3.0;

/// Construye las curvas de oferta y demanda de una hora.
(List<Oferta>, List<Puja>) construirCurvas(Hora h, Escenario e) {
  final ofertas = <Oferta>[];
  final referencia = costeCiclo(e.gasOferta, e.co2, 0.54);

  void renovable(Tecnologia t, double mw) {
    ofertas.add(Oferta(t, mw * (1 - e.neg), 0, 0));
    for (var i = 0; i < 5; i++) {
      ofertas.add(Oferta(t, mw * e.neg / 5, e.pmin * (i + 1) / 5, 0));
    }
  }

  renovable(Tecnologia.solar, h.solarMw * e.factorSolar);
  renovable(Tecnologia.eolica, h.eolicaMw * e.factorEolica);
  ofertas.add(Oferta(Tecnologia.nuclear, e.nuclear, 0, 5));
  ofertas.add(Oferta(Tecnologia.otras, e.otras, 5, 5));
  if (e.carbon > 0) {
    final c = e.costeCarbon + e.co2 * 0.95 + 3;
    ofertas.add(Oferta(Tecnologia.carbon, e.carbon, c, c));
  }
  for (final m in const [-0.3, -0.1, 0.1, 0.3]) {
    ofertas.add(Oferta(Tecnologia.hidraulica, e.hidro / 4,
        e.fHidro * (1 + e.wHidro * m) * referencia, 0));
  }
  for (final r in rendimientosCiclos) {
    ofertas.add(Oferta(Tecnologia.ciclos, e.ciclos / rendimientosCiclos.length,
        costeCiclo(e.gasOferta, e.co2, r), costeCiclo(e.gas, e.co2, r)));
  }
  ofertas.sort((a, b) => a.precio.compareTo(b.precio));

  final pujas = [
    Puja('Demanda nacional', h.demandaMw * e.factorDemanda, 4000),
    Puja('Bombeo y exportación', e.exportacion * 0.5, e.bExp),
    Puja('Bombeo y exportación', e.exportacion * 0.5, e.bExp2),
  ];
  return (ofertas, pujas);
}

/// Resultado de la casación de una hora.
class Casacion {
  Casacion({
    required this.precio,
    required this.mwCasados,
    required this.ofertas,
    required this.pujas,
    required this.despacho,
    required this.marginal,
    required this.demandaCubierta,
  });

  final double precio;
  final double mwCasados;
  final List<Oferta> ofertas;
  final List<Puja> pujas;

  /// MW casados por tecnología.
  final Map<Tecnologia, double> despacho;

  /// Quién fija el precio: una tecnología o la demanda flexible.
  final String marginal;
  final bool demandaCubierta;

  /// Ingreso, coste y margen por tecnología en esta hora (€).
  Map<Tecnologia, ({double mw, double ingreso, double coste})> get cuentas {
    final out = <Tecnologia, ({double mw, double ingreso, double coste})>{};
    for (final t in Tecnologia.values) {
      final mw = despacho[t] ?? 0;
      if (mw <= 0) continue;
      var coste = 0.0;
      var restante = mw;
      for (final o in ofertas.where((o) => o.tecnologia == t)) {
        final q = math.min(o.mw, restante);
        coste += q * o.coste;
        restante -= q;
        if (restante <= 0) break;
      }
      out[t] = (mw: mw, ingreso: mw * precio, coste: coste);
    }
    return out;
  }
}

/// Casación marginalista: el primer precio en que la oferta acumulada
/// cubre la demanda dispuesta a pagar ese precio.
Casacion casar(List<Oferta> ofertas, List<Puja> pujas) {
  double oferta(double p) =>
      ofertas.where((o) => o.precio <= p).fold(0, (s, o) => s + o.mw);
  double demanda(double p) =>
      pujas.where((b) => b.precio >= p).fold(0, (s, b) => s + b.mw);
  double demandaPorEncima(double p) =>
      pujas.where((b) => b.precio > p).fold(0, (s, b) => s + b.mw);

  final candidatos = {
    for (final o in ofertas)
      if (o.mw > 0) o.precio,
    for (final b in pujas)
      if (b.mw > 0) b.precio,
  }.toList()
    ..sort();

  var precio = candidatos.last;
  var cubierta = false;
  // Las curvas se cruzan en p cuando la oferta hasta p cubre a quienes pagan
  // más que p; si una puja está justo en p, puede quedar casada en parte.
  for (final p in candidatos) {
    if (oferta(p) + 1e-6 >= demandaPorEncima(p)) {
      precio = p;
      cubierta = true;
      break;
    }
  }
  final total = ofertas.fold<double>(0, (s, o) => s + o.mw);
  final q = cubierta ? math.min(oferta(precio), demanda(precio)) : total;

  // Despacho: todo lo ofertado por debajo del precio, y a prorrata lo
  // ofertado justo al precio marginal.
  final despacho = <Tecnologia, double>{};
  final bajo = ofertas.where((o) => o.precio < precio).toList();
  final enPrecio = ofertas.where((o) => o.precio == precio).toList();
  final mwBajo = bajo.fold<double>(0, (s, o) => s + o.mw);
  final mwEnPrecio = enPrecio.fold<double>(0, (s, o) => s + o.mw);
  final parte =
      mwEnPrecio > 0 ? ((q - mwBajo) / mwEnPrecio).clamp(0.0, 1.0) : 0.0;
  for (final o in bajo) {
    despacho[o.tecnologia] = (despacho[o.tecnologia] ?? 0) + o.mw;
  }
  for (final o in enPrecio) {
    despacho[o.tecnologia] = (despacho[o.tecnologia] ?? 0) + o.mw * parte;
  }

  String marginal;
  if (!cubierta) {
    marginal = 'Falta oferta: demanda sin cubrir';
  } else if (enPrecio.isNotEmpty && parte > 0 && parte < 1) {
    final techs = enPrecio.map((o) => o.tecnologia.nombre).toSet();
    marginal = techs.join(' y ');
  } else if (pujas.any((b) => b.precio == precio && b.precio < 4000)) {
    marginal = 'Demanda flexible (bombeo y exportación)';
  } else if (enPrecio.isNotEmpty) {
    marginal = enPrecio.map((o) => o.tecnologia.nombre).toSet().join(' y ');
  } else {
    marginal = 'Demanda flexible (bombeo y exportación)';
  }

  return Casacion(
    precio: precio,
    mwCasados: q,
    ofertas: ofertas,
    pujas: pujas,
    despacho: despacho,
    marginal: marginal,
    demandaCubierta: cubierta,
  );
}

/// Atajo: construye las curvas de una hora y las casa.
Casacion simularHora(Hora h, Escenario e) {
  final (o, p) = construirCurvas(h, e);
  return casar(o, p);
}
