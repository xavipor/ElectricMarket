import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../modelo/centrales.dart';
import '../modelo/tiempo_real.dart';
import '../widgets/formato.dart';

class PantallaMapa extends StatefulWidget {
  const PantallaMapa({super.key, this.servicio});

  /// Se puede inyectar en tests para no salir a la red.
  final ServicioRee? servicio;

  @override
  State<PantallaMapa> createState() => _PantallaMapaState();
}

class _PantallaMapaState extends State<PantallaMapa> {
  late final Future<CatalogoCentrales> _catalogo = CatalogoCentrales.cargar();
  late final ServicioRee _ree = widget.servicio ?? ServicioRee();
  final _mapa = MapController();

  final Set<TecCentral> _visibles = TecCentral.values.toSet();
  bool _cerradas = false;
  double _zoom = 5.6;
  Central? _elegida;

  MixAhora? _mix;
  Object? _errorMix;
  bool _cargandoMix = false;
  Timer? _refresco;

  @override
  void initState() {
    super.initState();
    _catalogo.then((c) {
      _cargarMix(c);
      _refresco = Timer.periodic(const Duration(minutes: 15), (_) => _cargarMix(c));
    });
  }

  @override
  void dispose() {
    _refresco?.cancel();
    super.dispose();
  }

  Future<void> _cargarMix(CatalogoCentrales c) async {
    if (_cargandoMix) return;
    setState(() => _cargandoMix = true);
    try {
      final m = await _ree.cargar(c.potenciaPeninsular());
      if (mounted) {
        setState(() {
          _mix = m;
          _errorMix = null;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _errorMix = e);
    } finally {
      if (mounted) setState(() => _cargandoMix = false);
    }
  }

  List<Central> _filtradas(CatalogoCentrales c) => [
    for (final x in c.centrales)
      if (_visibles.contains(x.tec) && (_cerradas || !x.cerrada)) x,
  ];

  double _radio(Central c) {
    final escala = math.pow(1.35, _zoom - 6).clamp(0.6, 4.0);
    return math.max(2.0, (1.5 + math.sqrt(c.mw) * 0.3) * escala);
  }

  void _tocar(LatLng punto, List<Central> visibles) {
    final cam = _mapa.camera;
    final toque = cam.latLngToScreenOffset(punto);
    Central? mejor;
    var distMejor = double.infinity;
    for (final c in visibles) {
      final d = (cam.latLngToScreenOffset(LatLng(c.lat, c.lon)) - toque).distance;
      // Margen de 10 px para poder tocar los puntos pequeños con el dedo.
      if (d <= _radio(c) + 10 && d < distMejor) {
        mejor = c;
        distMejor = d;
      }
    }
    setState(() => _elegida = mejor);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<CatalogoCentrales>(
      future: _catalogo,
      builder: (context, snap) {
        if (snap.hasError) {
          return Center(child: Text('No se pudo cargar el mapa: ${snap.error}'));
        }
        if (!snap.hasData) return const Center(child: CircularProgressIndicator());
        final catalogo = snap.data!;
        final visibles = _filtradas(catalogo);
        final mapa = _Mapa(
          controlador: _mapa,
          centrales: visibles,
          elegida: _elegida,
          radio: _radio,
          alMoverse: (z) {
            if ((z - _zoom).abs() > 0.05) setState(() => _zoom = z);
          },
          alTocar: (p) => _tocar(p, visibles),
        );
        final panel = _Panel(
          catalogo: catalogo,
          visibles: _visibles,
          cerradas: _cerradas,
          elegida: _elegida,
          mix: _mix,
          errorMix: _errorMix,
          cargandoMix: _cargandoMix,
          alCambiarTec: (t, si) => setState(() => si ? _visibles.add(t) : _visibles.remove(t)),
          alCambiarCerradas: (v) => setState(() => _cerradas = v),
          alCerrarFicha: () => setState(() => _elegida = null),
          alRecargar: () => _cargarMix(catalogo),
          alSoloUna: (t) => setState(
            () => _visibles
              ..clear()
              ..add(t),
          ),
          alTodas: () => setState(() => _visibles.addAll(TecCentral.values)),
        );
        return LayoutBuilder(
          builder: (context, c) {
            if (c.maxWidth >= 900) {
              return Row(
                children: [
                  Expanded(child: mapa),
                  const VerticalDivider(width: 1),
                  SizedBox(width: 360, child: panel),
                ],
              );
            }
            return Column(
              children: [
                SizedBox(height: math.max(320, c.maxHeight * 0.55), child: mapa),
                const Divider(height: 1),
                Expanded(child: panel),
              ],
            );
          },
        );
      },
    );
  }
}

class _Mapa extends StatelessWidget {
  const _Mapa({
    required this.controlador,
    required this.centrales,
    required this.elegida,
    required this.radio,
    required this.alMoverse,
    required this.alTocar,
  });

  final MapController controlador;
  final List<Central> centrales;
  final Central? elegida;
  final double Function(Central) radio;
  final ValueChanged<double> alMoverse;
  final ValueChanged<LatLng> alTocar;

  @override
  Widget build(BuildContext context) {
    final oscuro = Theme.of(context).brightness == Brightness.dark;
    final borde = oscuro ? Colors.black : Colors.white;
    return FlutterMap(
      mapController: controlador,
      options: MapOptions(
        initialCameraFit: CameraFit.bounds(
          bounds: LatLngBounds(const LatLng(35.2, -9.4), const LatLng(43.8, 4.4)),
          padding: const EdgeInsets.all(12),
        ),
        minZoom: 4,
        maxZoom: 16,
        backgroundColor: oscuro ? const Color(0xFF262626) : const Color(0xFFE8ECEF),
        interactionOptions: const InteractionOptions(
          flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
        ),
        onMapReady: () => alMoverse(controlador.camera.zoom),
        onPositionChanged: (cam, _) => alMoverse(cam.zoom),
        onTap: (_, p) => alTocar(p),
      ),
      children: [
        TileLayer(
          urlTemplate:
              'https://{s}.basemaps.cartocdn.com/${oscuro ? 'dark_all' : 'light_all'}/{z}/{x}/{y}{r}.png',
          subdomains: const ['a', 'b', 'c', 'd'],
          retinaMode: RetinaMode.isHighDensity(context),
          userAgentPackageName: 'io.github.xavipor.mercado_electrico',
        ),
        CircleLayer(
          circles: [
            // Las grandes van primero (el catálogo viene ordenado) y quedan debajo.
            for (final c in centrales)
              CircleMarker(
                point: LatLng(c.lat, c.lon),
                radius: radio(c),
                color: c.cerrada
                    ? c.tec.color.withValues(alpha: 0.25)
                    : c.tec.color.withValues(alpha: 0.8),
                borderColor: borde.withValues(alpha: 0.7),
                borderStrokeWidth: 0.6,
              ),
            if (elegida != null)
              CircleMarker(
                point: LatLng(elegida!.lat, elegida!.lon),
                radius: radio(elegida!) + 4,
                color: Colors.transparent,
                borderColor: oscuro ? Colors.white : Colors.black,
                borderStrokeWidth: 2.5,
              ),
          ],
        ),
        const SimpleAttributionWidget(
          source: Text('OpenStreetMap · CARTO · powerplantmatching'),
        ),
      ],
    );
  }
}

class _Panel extends StatelessWidget {
  const _Panel({
    required this.catalogo,
    required this.visibles,
    required this.cerradas,
    required this.elegida,
    required this.mix,
    required this.errorMix,
    required this.cargandoMix,
    required this.alCambiarTec,
    required this.alCambiarCerradas,
    required this.alCerrarFicha,
    required this.alRecargar,
    required this.alSoloUna,
    required this.alTodas,
  });

  final CatalogoCentrales catalogo;
  final Set<TecCentral> visibles;
  final bool cerradas;
  final Central? elegida;
  final MixAhora? mix;
  final Object? errorMix;
  final bool cargandoMix;
  final void Function(TecCentral, bool) alCambiarTec;
  final ValueChanged<bool> alCambiarCerradas;
  final VoidCallback alCerrarFicha;
  final VoidCallback alRecargar;
  final ValueChanged<TecCentral> alSoloUna;
  final VoidCallback alTodas;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final cuenta = <TecCentral, (int, double)>{};
    for (final c in catalogo.centrales) {
      if (c.cerrada && !cerradas) continue;
      final (n, mw) = cuenta[c.tec] ?? (0, 0.0);
      cuenta[c.tec] = (n + 1, mw + c.mw);
    }
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (elegida != null) ...[
          _Ficha(central: elegida!, mix: mix, alCerrar: alCerrarFicha),
          const SizedBox(height: 16),
        ] else ...[
          Text('Centrales de generación', style: t.titleLarge),
          const SizedBox(height: 4),
          Text(
            'Cada punto es una central; el tamaño indica su potencia. Toca uno para ver '
            'su ficha. Haz zoom con la rueda, pellizcando o con doble clic.',
            style: t.bodySmall,
          ),
          const SizedBox(height: 16),
        ],
        _TarjetaMix(mix: mix, error: errorMix, cargando: cargandoMix, alRecargar: alRecargar),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: Text('Tecnologías', style: t.titleMedium)),
            TextButton(onPressed: alTodas, child: const Text('Todas')),
          ],
        ),
        for (final tec in TecCentral.values)
          if (cuenta[tec] != null)
            CheckboxListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              value: visibles.contains(tec),
              onChanged: (v) => alCambiarTec(tec, v ?? false),
              title: Row(
                children: [
                  CircleAvatar(radius: 6, backgroundColor: tec.color),
                  const SizedBox(width: 8),
                  Expanded(child: Text(tec.nombre)),
                ],
              ),
              subtitle: Text('${cuenta[tec]!.$1} centrales · ${gw(cuenta[tec]!.$2)}'),
              secondary: IconButton(
                tooltip: 'Ver solo ${tec.nombre.toLowerCase()}',
                icon: const Icon(Icons.filter_center_focus, size: 20),
                onPressed: () => alSoloUna(tec),
              ),
            ),
        SwitchListTile(
          dense: true,
          contentPadding: EdgeInsets.zero,
          value: cerradas,
          onChanged: alCambiarCerradas,
          title: const Text('Mostrar centrales cerradas'),
          subtitle: const Text('Por ejemplo, las térmicas de carbón cerradas desde 2020'),
        ),
        const SizedBox(height: 8),
        Text(
          'Ubicaciones y potencias: ${catalogo.fuente}, que combina registros abiertos '
          '(ENTSO-E, OpenStreetMap, GEM, JRC…). Puede faltar alguna central pequeña '
          'o haber datos desfasados. La producción viene de Red Eléctrica (REData).',
          style: t.bodySmall,
        ),
      ],
    );
  }
}

class _TarjetaMix extends StatelessWidget {
  const _TarjetaMix({
    required this.mix,
    required this.error,
    required this.cargando,
    required this.alRecargar,
  });
  final MixAhora? mix;
  final Object? error;
  final bool cargando;
  final VoidCallback alRecargar;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final m = mix;
    final filas = <(String, double, TecCentral?)>[
      if (m != null)
        for (final e in m.mw.entries)
          if (e.value > 0) (e.key, e.value, tecDeRee(e.key)),
    ]..sort((a, b) => b.$2.compareTo(a.$2));
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(child: Text('Producción ahora (península)', style: t.titleMedium)),
                if (cargando)
                  const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                else
                  IconButton(
                    tooltip: 'Actualizar',
                    onPressed: alRecargar,
                    icon: const Icon(Icons.refresh),
                  ),
              ],
            ),
            if (m == null && error != null)
              Text(
                'No se pudo leer la API de Red Eléctrica desde tu navegador. '
                'El mapa funciona igual; vuelve a probar más tarde.',
                style: t.bodySmall,
              )
            else if (m == null)
              Text('Consultando Red Eléctrica…', style: t.bodySmall)
            else ...[
              Text(
                m.mediaDiaria
                    ? 'Media del ${fechaLarga(m.momento)} (REE aún no da el dato horario)'
                    : 'Hora ${hora(m.momento.hour)} del ${fechaLarga(m.momento)} · '
                          '${gw(m.total)} en total',
                style: t.bodySmall,
              ),
              const SizedBox(height: 8),
              for (final (titulo, mw, tec) in filas)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(child: Text(titulo, style: t.bodyMedium)),
                          Text(gw(mw), style: t.bodyMedium),
                          SizedBox(
                            width: 52,
                            child: Text(
                              m.total > 0 ? '${euros(100 * mw / m.total, decimales: 0)} %' : '',
                              textAlign: TextAlign.right,
                              style: t.bodySmall,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      LinearProgressIndicator(
                        value: m.total > 0 ? mw / m.total : 0,
                        color: tec?.color ?? Colors.grey,
                        backgroundColor: Colors.transparent,
                        minHeight: 4,
                      ),
                    ],
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Ficha extends StatelessWidget {
  const _Ficha({required this.central, required this.mix, required this.alCerrar});
  final Central central;
  final MixAhora? mix;
  final VoidCallback alCerrar;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final c = central;
    final factor = mix?.factorCarga(c.tec);
    final estimable = factor != null && !c.cerrada && c.sistema == SistemaElectrico.peninsular;
    String mwTexto(double v) => '${euros(v, decimales: v < 10 ? 1 : 0)} MW';
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  backgroundColor: c.tec.color,
                  foregroundColor: Colors.white,
                  child: Icon(c.tec.icono, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(c.nombre, style: t.titleMedium),
                      Text(c.tec.nombre, style: t.bodySmall),
                    ],
                  ),
                ),
                IconButton(tooltip: 'Cerrar', onPressed: alCerrar, icon: const Icon(Icons.close)),
              ],
            ),
            const SizedBox(height: 12),
            _Dato('Potencia', mwTexto(c.mw)),
            if (c.alta != null) _Dato('En servicio desde', '${c.alta}'),
            if (c.cerrada)
              _Dato('Estado', c.baja != null ? 'Cerrada en ${c.baja}' : 'Cerrada')
            else if (c.baja != null)
              _Dato('Cierre previsto', '${c.baja}'),
            _Dato('Sistema', c.sistema.nombre),
            _Dato(
              'Coordenadas',
              '${c.lat.toStringAsFixed(3).replaceAll('.', ',')}, ${c.lon.toStringAsFixed(3).replaceAll('.', ',')}',
            ),
            if (estimable) ...[
              const Divider(height: 24),
              Text('Producción estimada ahora: ${mwTexto(c.mw * factor)}', style: t.titleSmall),
              const SizedBox(height: 4),
              LinearProgressIndicator(value: factor, color: c.tec.color, minHeight: 6),
              const SizedBox(height: 6),
              Text(
                'Estimación: la ${c.tec.nombre.toLowerCase()} peninsular funciona ahora al '
                '${euros(100 * factor, decimales: 0)} % de su potencia, y se aplica ese '
                'porcentaje a esta central. Red Eléctrica no publica en abierto la '
                'producción de cada central en tiempo real.',
                style: t.bodySmall,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Dato extends StatelessWidget {
  const _Dato(this.etiqueta, this.valor);
  final String etiqueta;
  final String valor;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          SizedBox(width: 140, child: Text(etiqueta, style: t.bodySmall)),
          Expanded(child: Text(valor, style: t.bodyMedium)),
        ],
      ),
    );
  }
}
