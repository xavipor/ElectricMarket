import 'package:flutter/material.dart';

import 'modelo/datos.dart';
import 'pantallas/aprende.dart';
import 'pantallas/datos_pantalla.dart';
import 'pantallas/mapa.dart';
import 'pantallas/factura.dart';
import 'pantallas/simulador.dart';

void main() {
  // Flutter reescribe la URL (#/) al arrancar, así que el enlace se lee antes.
  _enlace = _leerEnlace(Uri.base);
  runApp(const AppMercado());
}

/// Enlaces directos: ?pestana=1&dia=5&hora=15, o con ancla #dia5-hora15,
/// #aprende, #entrevista, #datos, #mapa o #factura (para alojamientos que no pasan la query).
Map<String, String> _enlace = const {};

Map<String, String> _leerEnlace(Uri uri) {
  final p = Map<String, String>.of(uri.queryParameters);
  final ancla = uri.fragment.replaceFirst('/', '');
  final m = RegExp(r'dia(\d+)(?:-hora(\d+))?').firstMatch(ancla);
  if (m != null) {
    p['dia'] = m.group(1)!;
    if (m.group(2) != null) p['hora'] = m.group(2)!;
  }
  if (ancla == 'aprende') p['pestana'] = '1';
  if (ancla == 'datos') p['pestana'] = '2';
  if (ancla == 'mapa') p['pestana'] = '3';
  if (ancla == 'factura') p['pestana'] = '4';
  if (ancla == 'entrevista') {
    p['pestana'] = '1';
    p['vista'] = 'entrevista';
  }
  return p;
}

class AppMercado extends StatelessWidget {
  const AppMercado({super.key});

  @override
  Widget build(BuildContext context) {
    const semilla = Color(0xFF1F5FBF);
    return MaterialApp(
      title: 'Mercado eléctrico español',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(colorSchemeSeed: semilla, useMaterial3: true, fontFamily: 'Roboto'),
      darkTheme: ThemeData(
          colorSchemeSeed: semilla,
          brightness: Brightness.dark,
          useMaterial3: true,
          fontFamily: 'Roboto'),
      home: const Inicio(),
    );
  }
}

class Inicio extends StatefulWidget {
  const Inicio({super.key});

  @override
  State<Inicio> createState() => _InicioState();
}

class _InicioState extends State<Inicio> {
  late final Future<DatosMercado> _datos = DatosMercado.cargar();
  EstadoSimulador? _estado;
  bool _mapaAbierto = false;

  final _parametros = _enlace;

  late int _pestana = (int.tryParse(_parametros['pestana'] ?? '') ?? 0).clamp(0, 4);

  static const _destinos = [
    (Icons.tune, 'Simulador'),
    (Icons.school_outlined, 'Aprende'),
    (Icons.bar_chart, 'Datos'),
    (Icons.map_outlined, 'Mapa'),
    (Icons.receipt_long, 'Factura'),
  ];

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<DatosMercado>(
      future: _datos,
      builder: (context, snap) {
        if (snap.hasError) {
          return Scaffold(
              body: Center(child: Text('No se pudieron cargar los datos: ${snap.error}')));
        }
        if (!snap.hasData) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        final estado = _estado ??= EstadoSimulador(
          snap.data!,
          dia: int.tryParse(_parametros['dia'] ?? '') ?? 0,
          hora: int.tryParse(_parametros['hora'] ?? '') ?? 20,
        );
        final paginas = [
          PantallaSimulador(estado: estado),
          PantallaAprende(
              entrevista: _parametros['vista'] == 'entrevista',
              abrirSimulador: (dia, hora) {
            estado.elegirDia(dia, hora: hora);
            setState(() => _pestana = 0);
          }),
          PantallaDatos(datos: snap.data!),
          // El mapa se crea al abrirlo por primera vez: así no se consulta a REE
          // ni se descargan teselas si nadie entra en la pestaña.
          if (_mapaAbierto |= _pestana == 3) const PantallaMapa() else const SizedBox(),
          const PantallaFactura(),
        ];

        return LayoutBuilder(builder: (context, c) {
          final ancho = c.maxWidth >= 720;
          final cuerpo = IndexedStack(index: _pestana, children: paginas);
          return Scaffold(
            appBar: AppBar(title: const Text('Mercado eléctrico español')),
            body: ancho
                ? Row(children: [
                    NavigationRail(
                      selectedIndex: _pestana,
                      labelType: NavigationRailLabelType.all,
                      onDestinationSelected: (i) => setState(() => _pestana = i),
                      destinations: [
                        for (final d in _destinos)
                          NavigationRailDestination(icon: Icon(d.$1), label: Text(d.$2)),
                      ],
                    ),
                    const VerticalDivider(width: 1),
                    Expanded(child: cuerpo),
                  ])
                : cuerpo,
            bottomNavigationBar: ancho
                ? null
                : NavigationBar(
                    selectedIndex: _pestana,
                    onDestinationSelected: (i) => setState(() => _pestana = i),
                    destinations: [
                      for (final d in _destinos)
                        NavigationDestination(icon: Icon(d.$1), label: d.$2),
                    ],
                  ),
          );
        });
      },
    );
  }
}
