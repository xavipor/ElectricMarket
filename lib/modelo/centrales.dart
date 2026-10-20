import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;

/// Tecnologías del mapa. Los colores siguen los del simulador.
enum TecCentral {
  eolica('Eólica', Color(0xFF2A9D8F), Icons.air),
  solarFv('Solar fotovoltaica', Color(0xFFF2B705), Icons.wb_sunny_outlined),
  solarTermica('Solar térmica', Color(0xFFD9822B), Icons.wb_sunny),
  hidraulica('Hidráulica', Color(0xFF2F6FDE), Icons.water_drop_outlined),
  bombeo('Bombeo hidráulico', Color(0xFF1B3F8B), Icons.water),
  nuclear('Nuclear', Color(0xFF7B5EA7), Icons.bolt),
  cicloCombinado('Ciclo combinado (gas)', Color(0xFFE4572E), Icons.local_fire_department_outlined),
  carbon('Carbón', Color(0xFF5B4B3A), Icons.factory_outlined),
  fuelGas('Fuel y turbinas de gas', Color(0xFFA23B72), Icons.oil_barrel_outlined),
  biomasa('Biomasa y residuos', Color(0xFF6A994E), Icons.eco_outlined),
  baterias('Baterías', Color(0xFF00A6C8), Icons.battery_charging_full);

  const TecCentral(this.nombre, this.color, this.icono);
  final String nombre;
  final Color color;
  final IconData icono;

  static const _claves = {
    'eolica': eolica,
    'solar_fv': solarFv,
    'solar_termica': solarTermica,
    'hidraulica': hidraulica,
    'bombeo': bombeo,
    'nuclear': nuclear,
    'ciclo_combinado': cicloCombinado,
    'carbon': carbon,
    'fuel_gas': fuelGas,
    'biomasa': biomasa,
    'baterias': baterias,
  };

  static TecCentral deClave(String k) => _claves[k]!;
}

enum SistemaElectrico {
  peninsular('Peninsular'),
  baleares('Baleares'),
  ceutaMelilla('Ceuta y Melilla');

  const SistemaElectrico(this.nombre);
  final String nombre;
}

class Central {
  const Central({
    required this.nombre,
    required this.tec,
    required this.mw,
    required this.lat,
    required this.lon,
    this.alta,
    this.baja,
    required this.cerrada,
    required this.sistema,
  });

  final String nombre;
  final TecCentral tec;
  final double mw;
  final double lat;
  final double lon;
  final int? alta;
  final int? baja;
  final bool cerrada;
  final SistemaElectrico sistema;

  /// Fila compacta de assets/centrales.json (ver herramientas/generar_centrales.py).
  factory Central.deFila(List<dynamic> f) => Central(
    nombre: f[0] as String,
    tec: TecCentral.deClave(f[1] as String),
    mw: (f[2] as num).toDouble(),
    lat: (f[3] as num).toDouble(),
    lon: (f[4] as num).toDouble(),
    alta: f[5] as int?,
    baja: f[6] as int?,
    cerrada: f[7] == 1,
    sistema: switch (f[8]) {
      'baleares' => SistemaElectrico.baleares,
      'ceuta_melilla' => SistemaElectrico.ceutaMelilla,
      _ => SistemaElectrico.peninsular,
    },
  );
}

class CatalogoCentrales {
  CatalogoCentrales(this.centrales, this.fuente);
  final List<Central> centrales;
  final String fuente;

  static Future<CatalogoCentrales> cargar() async =>
      CatalogoCentrales.desdeJson(await rootBundle.loadString('assets/centrales.json'));

  factory CatalogoCentrales.desdeJson(String texto) {
    final j = jsonDecode(texto) as Map<String, dynamic>;
    return CatalogoCentrales([
      for (final f in j['centrales'] as List) Central.deFila(f as List),
    ], j['fuente'] as String);
  }

  /// Potencia en servicio por tecnología en el sistema peninsular, en MW.
  Map<TecCentral, double> potenciaPeninsular() {
    final p = <TecCentral, double>{};
    for (final c in centrales) {
      if (c.cerrada || c.sistema != SistemaElectrico.peninsular) continue;
      p[c.tec] = (p[c.tec] ?? 0) + c.mw;
    }
    return p;
  }
}
