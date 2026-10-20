/// Factura anual de un hogar con la tarifa de acceso 2.0TD (hasta 15 kW).
///
/// Peajes de 2026: Resolución de la CNMC de 18 de diciembre de 2025.
/// Cargos de 2026: Orden TED/1524/2025. Ambos publicados por el MITECO en
/// https://www.miteco.gob.es/ca/energia/energia-electrica/electricidad/peajes.html
library;

/// Peajes y cargos del término de energía por periodo (€/kWh): P1, P2, P3.
const peajesEnergia = [0.033261, 0.016409, 0.000077];
const cargosEnergia = [0.064292, 0.012858, 0.003215];

/// Peajes y cargos del término de potencia (€/kW y año): P1, P2.
const peajesPotencia = [23.324952, 0.443770];
const cargosPotencia = [4.379461, 0.281653];

/// Impuesto especial sobre la electricidad y IVA.
const impuestoElectrico = 0.0511269632;
const iva = 0.21;

/// Alquiler habitual de un contador digital (€/mes).
const alquilerContador = 0.81;

class SupuestosFactura {
  const SupuestosFactura({
    this.consumoKwh = 3000,
    this.potenciaKw = 4.6,
    this.precioMayorista = 65,
    this.ajustes = 15,
    this.perdidas = 0.15,
    this.margen = 10,
    this.reparto = const [0.30, 0.25, 0.45],
  });

  /// Consumo anual (kWh) y potencia contratada en P1 y P2 (kW).
  final double consumoKwh, potenciaKw;

  /// Precio medio del mercado diario (€/MWh).
  final double precioMayorista;

  /// Servicios de ajuste, pago por capacidad y otros costes (€/MWh).
  final double ajustes;

  /// Pérdidas de las redes: por cada kWh en casa se compra algo más en barras
  /// de central.
  final double perdidas;

  /// Margen de la comercializadora (€/MWh).
  final double margen;

  /// Parte del consumo en punta (P1), llano (P2) y valle (P3).
  final List<double> reparto;

  SupuestosFactura copyWith({
    double? consumoKwh,
    double? potenciaKw,
    double? precioMayorista,
    double? margen,
    double? valle,
  }) {
    var r = reparto;
    if (valle != null) {
      // El resto se reparte entre punta y llano en la misma proporción.
      final resto = reparto[0] + reparto[1];
      r = [
        (1 - valle) * reparto[0] / resto,
        (1 - valle) * reparto[1] / resto,
        valle,
      ];
    }
    return SupuestosFactura(
      consumoKwh: consumoKwh ?? this.consumoKwh,
      potenciaKw: potenciaKw ?? this.potenciaKw,
      precioMayorista: precioMayorista ?? this.precioMayorista,
      ajustes: ajustes,
      perdidas: perdidas,
      margen: margen ?? this.margen,
      reparto: r,
    );
  }
}

/// Una línea de la factura anual (€), antes o después de impuestos.
typedef LineaFactura = ({String concepto, String detalle, double euros});

/// Desglose anual de la factura (€/año).
List<LineaFactura> calcularFactura(SupuestosFactura s) {
  final mwhComprados = s.consumoKwh * (1 + s.perdidas) / 1000;
  final energia = mwhComprados * s.precioMayorista;
  final ajustes = mwhComprados * s.ajustes;
  final margen = s.consumoKwh / 1000 * s.margen;
  var peajes = 0.0, cargos = 0.0;
  for (var i = 0; i < 3; i++) {
    peajes += s.consumoKwh * s.reparto[i] * peajesEnergia[i];
    cargos += s.consumoKwh * s.reparto[i] * cargosEnergia[i];
  }
  peajes += s.potenciaKw * (peajesPotencia[0] + peajesPotencia[1]);
  cargos += s.potenciaKw * (cargosPotencia[0] + cargosPotencia[1]);
  final iee = (energia + ajustes + margen + peajes + cargos) * impuestoElectrico;
  final contador = alquilerContador * 12;
  final baseIva = energia + ajustes + margen + peajes + cargos + iee + contador;
  return [
    (
      concepto: 'Energía en el mercado mayorista',
      detalle: 'Precio de OMIE, incluidas las pérdidas de la red',
      euros: energia
    ),
    (
      concepto: 'Servicios de ajuste y otros',
      detalle: 'Restricciones, balance, capacidad (REE)',
      euros: ajustes
    ),
    (concepto: 'Margen de la comercializadora', detalle: 'Mercado libre', euros: margen),
    (
      concepto: 'Peajes de redes',
      detalle: 'Transporte y distribución (CNMC)',
      euros: peajes
    ),
    (
      concepto: 'Cargos del sistema',
      detalle: 'Renovables antiguas, islas, déficit (Ministerio)',
      euros: cargos
    ),
    (concepto: 'Impuesto eléctrico', detalle: '5,11 %', euros: iee),
    (concepto: 'Alquiler del contador', detalle: '0,81 €/mes', euros: contador),
    (concepto: 'IVA', detalle: '21 %', euros: baseIva * iva),
  ];
}

double totalFactura(SupuestosFactura s) =>
    calcularFactura(s).fold(0, (t, l) => t + l.euros);
