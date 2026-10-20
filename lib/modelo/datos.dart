import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

import 'mercado.dart';

/// Un día real con sus 24 horas y los parámetros calibrados del modelo.
class Dia {
  Dia({
    required this.fecha,
    required this.titulo,
    required this.descripcion,
    required this.precioMedioReal,
    required this.errorModelo,
    required this.escenario,
    required this.horas,
  });

  factory Dia.fromJson(Map<String, dynamic> j) => Dia(
        fecha: DateTime.parse(j['fecha'] as String),
        titulo: j['titulo'] as String,
        descripcion: j['descripcion'] as String,
        precioMedioReal: (j['precioMedioReal'] as num).toDouble(),
        errorModelo: (j['errorModeloRmse'] as num).toDouble(),
        escenario:
            Escenario.fromJson(j['parametros'] as Map<String, dynamic>),
        horas: [
          for (final h in j['horas'] as List)
            Hora.fromJson(h as Map<String, dynamic>)
        ],
      );

  final DateTime fecha;
  final String titulo;
  final String descripcion;
  final double precioMedioReal;

  /// Error cuadrático medio del modelo frente al precio real (€/MWh).
  final double errorModelo;
  final Escenario escenario;
  final List<Hora> horas;
}

/// Estadísticas de un año de precios del mercado diario.
class Anio {
  const Anio({
    required this.anio,
    required this.precioMedio,
    required this.minimo,
    required this.maximo,
    required this.horasCeroOMenos,
    required this.horasNegativas,
    required this.nota,
  });

  final int anio;
  final double precioMedio, minimo, maximo;
  final int horasCeroOMenos, horasNegativas;
  final String nota;
}

class DatosMercado {
  DatosMercado(this.dias, this.anios, this.fuente, this.notas);

  final List<Dia> dias;
  final List<Anio> anios;
  final String fuente;
  final List<String> notas;

  static Future<DatosMercado> cargar() async {
    final j = jsonDecode(
            await rootBundle.loadString('assets/dias_representativos.json'))
        as Map<String, dynamic>;
    final csv =
        await rootBundle.loadString('assets/estadisticas_anuales.csv');
    final anios = <Anio>[];
    for (final linea in const LineSplitter().convert(csv).skip(1)) {
      if (linea.trim().isEmpty) continue;
      final c = linea.split(',');
      anios.add(Anio(
        anio: int.parse(c[0]),
        precioMedio: double.parse(c[2]),
        minimo: double.parse(c[4]),
        maximo: double.parse(c[5]),
        horasCeroOMenos: int.parse(c[6]),
        horasNegativas: int.parse(c[7]),
        nota: c.length > 8 ? c[8] : '',
      ));
    }
    return DatosMercado(
      [for (final d in j['dias'] as List) Dia.fromJson(d as Map<String, dynamic>)],
      anios,
      j['fuente'] as String,
      [for (final n in j['notas'] as List) n as String],
    );
  }
}
