import 'dart:convert';

import 'package:http/http.dart' as http;

import 'centrales.dart';

/// Generación por tecnología del sistema peninsular según la API pública de
/// Red Eléctrica (REData, apidatos.ree.es). No hay datos públicos en tiempo
/// real por central: lo más cercano es el total nacional por tecnología, que
/// la app reparte entre las centrales en proporción a su potencia.
class MixAhora {
  MixAhora({
    required this.momento,
    required this.mw,
    required this.instalada,
    required this.mediaDiaria,
  });

  /// Inicio de la hora (o día) al que corresponden los datos.
  final DateTime momento;

  /// MW medios por tecnología con el nombre que usa REE (incluye las que no
  /// están en el mapa, como la cogeneración).
  final Map<String, double> mw;

  /// Potencia instalada peninsular por tecnología del mapa, en MW.
  final Map<TecCentral, double> instalada;

  /// true si REE no dio datos horarios y se usa la media del día anterior.
  final bool mediaDiaria;

  /// MW medios de una tecnología del mapa (suma de las series REE que la forman).
  double mwDe(TecCentral t) {
    var s = 0.0;
    mw.forEach((titulo, v) {
      if (tecDeRee(titulo) == t) s += v;
    });
    return s;
  }

  /// Fracción de su potencia instalada a la que funciona cada tecnología (0-1).
  double? factorCarga(TecCentral t) {
    final p = instalada[t];
    if (p == null || p <= 0) return null;
    return (mwDe(t) / p).clamp(0.0, 1.0);
  }

  double get total => mw.values.where((v) => v > 0).fold(0.0, (a, b) => a + b);
}

/// Tecnología del mapa que corresponde a una serie de REE, o null si no hay.
TecCentral? tecDeRee(String titulo) => switch (titulo.toLowerCase().trim()) {
  'eólica' => TecCentral.eolica,
  'solar fotovoltaica' => TecCentral.solarFv,
  'solar térmica' => TecCentral.solarTermica,
  'hidráulica' => TecCentral.hidraulica,
  'turbinación bombeo' => TecCentral.bombeo,
  'nuclear' => TecCentral.nuclear,
  'ciclo combinado' => TecCentral.cicloCombinado,
  'carbón' => TecCentral.carbon,
  'fuel + gas' || 'motores diésel' || 'turbina de gas' || 'turbina de vapor' => TecCentral.fuelGas,
  'otras renovables' || 'residuos renovables' => TecCentral.biomasa,
  'entrega baterías' => TecCentral.baterias,
  _ => null,
};

/// REE da la hora de Madrid con su desfase (2026-10-20T10:00:00.000+02:00).
/// Se guarda la hora tal cual, sin pasarla a UTC ni a la zona del navegador.
DateTime _horaPeninsular(String s) => DateTime.parse(s.length >= 19 ? s.substring(0, 19) : s);

/// Series de una respuesta REData: título -> lista de (fecha, valor).
/// Algunos indicadores anidan las series en attributes.content.
Map<String, List<(DateTime, double)>> leerSeriesRee(String cuerpo) {
  final j = jsonDecode(cuerpo) as Map<String, dynamic>;
  final out = <String, List<(DateTime, double)>>{};
  void leer(Map<String, dynamic> e) {
    final a = e['attributes'] as Map<String, dynamic>? ?? const {};
    final contenido = a['content'];
    if (contenido is List) {
      for (final c in contenido) {
        leer(c as Map<String, dynamic>);
      }
      return;
    }
    final titulo = (a['title'] ?? e['type']) as String?;
    final valores = a['values'];
    if (titulo == null || valores is! List) return;
    out[titulo] = [
      for (final v in valores)
        (_horaPeninsular(v['datetime'] as String), (v['value'] as num).toDouble()),
    ];
  }

  for (final e in (j['included'] as List? ?? const [])) {
    leer(e as Map<String, dynamic>);
  }
  return out;
}

/// Toma el último instante en que hay datos de casi todas las series y devuelve
/// el valor de cada una en ese instante.
(DateTime, Map<String, double>)? ultimoInstante(Map<String, List<(DateTime, double)>> series) {
  final cuenta = <DateTime, int>{};
  for (final s in series.values) {
    for (final (f, _) in s) {
      cuenta[f] = (cuenta[f] ?? 0) + 1;
    }
  }
  if (cuenta.isEmpty) return null;
  final maximo = cuenta.values.reduce((a, b) => a > b ? a : b);
  final validos = cuenta.entries.where((e) => e.value >= maximo * 0.8).map((e) => e.key);
  final momento = validos.reduce((a, b) => a.isAfter(b) ? a : b);
  final valores = <String, double>{};
  series.forEach((titulo, s) {
    for (final (f, v) in s) {
      if (f == momento) valores[titulo] = v;
    }
  });
  return (momento, valores);
}

class ServicioRee {
  ServicioRee({http.Client? cliente}) : _cliente = cliente ?? http.Client();
  final http.Client _cliente;

  static const _base = 'https://apidatos.ree.es/es/datos';
  static const _geo = 'geo_trunc=electric_system&geo_limit=peninsular&geo_ids=8741';

  static String _f(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  // Sin cabeceras propias: así el navegador hace una petición CORS simple.
  Future<Map<String, List<(DateTime, double)>>> _series(
    String ruta,
    String desde,
    String hasta,
    String trunc,
  ) async {
    final url =
        '$_base/$ruta?start_date=${desde}T00:00&end_date=${hasta}T23:59'
        '&time_trunc=$trunc&$_geo';
    final r = await _cliente.get(Uri.parse(url)).timeout(const Duration(seconds: 20));
    if (r.statusCode != 200) throw Exception('REE respondió ${r.statusCode}');
    return leerSeriesRee(utf8.decode(r.bodyBytes));
  }

  /// Último dato horario de hoy; si REE no lo da, la media de ayer.
  /// [respaldo] es la potencia del catálogo, por si falla la de REE.
  Future<MixAhora> cargar(Map<TecCentral, double> respaldo, {DateTime? ahora}) async {
    final hoy = ahora ?? DateTime.now();
    final ayer = hoy.subtract(const Duration(days: 1));

    (DateTime, Map<String, double>)? dato;
    var mediaDiaria = false;
    try {
      dato = ultimoInstante(
        await _series('generacion/estructura-generacion', _f(ayer), _f(hoy), 'hour'),
      );
    } catch (_) {
      dato = null;
    }
    if (dato == null) {
      final dia = ultimoInstante(
        await _series('generacion/estructura-generacion', _f(ayer), _f(ayer), 'day'),
      );
      if (dia == null) throw Exception('REE no devolvió datos');
      dato = (dia.$1, {for (final e in dia.$2.entries) e.key: e.value / 24});
      mediaDiaria = true;
    }

    var instalada = Map<TecCentral, double>.of(respaldo);
    try {
      final inicioAnio = DateTime(hoy.year - 1, 1, 1);
      final pot = ultimoInstante(
        await _series('generacion/potencia-instalada', _f(inicioAnio), _f(hoy), 'month'),
      );
      if (pot != null) {
        final deRee = <TecCentral, double>{};
        pot.$2.forEach((titulo, v) {
          final t = tecDeRee(titulo);
          if (t != null) deRee[t] = (deRee[t] ?? 0) + v;
        });
        instalada = {...instalada, ...deRee};
      }
    } catch (_) {
      // Se queda la potencia del catálogo.
    }

    final mw = {
      for (final e in dato.$2.entries)
        if (!e.key.toLowerCase().contains('total')) e.key: e.value,
    };
    return MixAhora(momento: dato.$1, mw: mw, instalada: instalada, mediaDiaria: mediaDiaria);
  }
}
