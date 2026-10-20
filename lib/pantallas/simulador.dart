import 'package:flutter/material.dart';

import '../modelo/datos.dart';
import '../modelo/mercado.dart';
import '../widgets/curva_oferta.dart';
import '../widgets/formato.dart';
import '../widgets/grafico_dia.dart';

/// Estado compartido del simulador, para que otras pantallas puedan
/// abrirlo en un día y una hora concretos.
class EstadoSimulador extends ChangeNotifier {
  EstadoSimulador(this.datos, {int dia = 0, int hora = 20}) {
    _cargarDia(dia.clamp(0, datos.dias.length - 1), hora.clamp(0, 23));
  }

  final DatosMercado datos;
  late int diaIndice;
  late int hora;
  late Escenario escenario;

  Dia get dia => datos.dias[diaIndice];

  void _cargarDia(int i, int h) {
    diaIndice = i;
    hora = h;
    escenario = datos.dias[i].escenario;
  }

  void elegirDia(int i, {int? hora}) {
    _cargarDia(i, hora ?? this.hora);
    notifyListeners();
  }

  void elegirHora(int h) {
    hora = h;
    notifyListeners();
  }

  void cambiar(Escenario e) {
    escenario = e;
    notifyListeners();
  }

  void restablecer() => elegirDia(diaIndice);

  bool get modificado => !identical(escenario, dia.escenario);
}

class PantallaSimulador extends StatelessWidget {
  const PantallaSimulador({super.key, required this.estado});
  final EstadoSimulador estado;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: estado,
      builder: (context, _) {
        final dia = estado.dia;
        final e = estado.escenario;
        final simulado = simularDia(dia.horas, e);
        final casaciones = simulado.casaciones;
        final base = simularDia(dia.horas, dia.escenario).casaciones;
        final c = casaciones[estado.hora];
        final horaDatos = dia.horas[estado.hora];

        final controles = _Controles(estado: estado);
        final grafico = _Tarjeta(
          titulo: 'Precio hora a hora',
          subtitulo: 'Pulsa o arrastra sobre el gráfico para elegir la hora',
          child: Column(children: [
            SizedBox(
              height: 200,
              child: GraficoDia(
                real: [for (final h in dia.horas) h.precioReal],
                modelo: [for (final b in base) b.precio],
                escenario: [for (final x in casaciones) x.precio],
                mostrarEscenario: estado.modificado,
                horaSeleccionada: estado.hora,
                alElegirHora: estado.elegirHora,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(spacing: 16, runSpacing: 4, children: [
              Leyenda('Precio real (OMIE)', Theme.of(context).colorScheme.onSurface),
              Leyenda('Modelo calibrado', Theme.of(context).colorScheme.outline,
                  grosor: 2),
              if (estado.modificado)
                Leyenda('Tu escenario', Theme.of(context).colorScheme.primary),
            ]),
          ]),
        );
        final curva = _Tarjeta(
          titulo: 'Casación de las ${hora(estado.hora)}',
          subtitulo:
              'Ofertas de venta ordenadas de más barata a más cara; la línea negra es la demanda',
          child: Column(children: [
            SizedBox(
                height: 340,
                child: CurvaOferta(
                    casacion: c, precioReal: horaDatos.precioReal)),
            const SizedBox(height: 8),
            Wrap(spacing: 12, runSpacing: 4, children: [
              for (final t in Tecnologia.values)
                if (c.ofertas.any((o) => o.tecnologia == t && o.mw > 0))
                  _Chip(t),
            ]),
          ]),
        );
        final resultado = _Resultado(
            dia: dia, casacion: c, horaDatos: horaDatos, escenario: e,
            simulado: simulado);

        return LayoutBuilder(builder: (context, lc) {
          final ancho = lc.maxWidth >= 1000;
          final cabecera = _Cabecera(estado: estado);
          if (ancho) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                cabecera,
                const SizedBox(height: 12),
                Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  SizedBox(width: 340, child: controles),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(children: [
                      grafico,
                      const SizedBox(height: 16),
                      Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Expanded(flex: 3, child: curva),
                        const SizedBox(width: 16),
                        Expanded(flex: 2, child: resultado),
                      ]),
                    ]),
                  ),
                ]),
              ]),
            );
          }
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              cabecera,
              const SizedBox(height: 12),
              grafico,
              const SizedBox(height: 12),
              curva,
              const SizedBox(height: 12),
              resultado,
              const SizedBox(height: 12),
              controles,
            ],
          );
        });
      },
    );
  }
}

class _Cabecera extends StatelessWidget {
  const _Cabecera({required this.estado});
  final EstadoSimulador estado;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final dia = estado.dia;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(children: [
          for (var i = 0; i < estado.datos.dias.length; i++)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                label: Text(estado.datos.dias[i].titulo),
                selected: i == estado.diaIndice,
                onSelected: (_) => estado.elegirDia(i),
              ),
            ),
        ]),
      ),
      const SizedBox(height: 12),
      Text('${dia.titulo} · ${fechaLarga(dia.fecha)}', style: t.titleLarge),
      const SizedBox(height: 4),
      Text(dia.descripcion, style: t.bodyMedium),
      const SizedBox(height: 4),
      Text(
        'Precio medio real ${euros(dia.precioMedioReal)} €/MWh · '
        'error medio del modelo ${euros(dia.errorModelo, decimales: 1)} €/MWh',
        style: t.bodySmall!.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
      ),
    ]);
  }
}

class _Controles extends StatelessWidget {
  const _Controles({required this.estado});
  final EstadoSimulador estado;

  @override
  Widget build(BuildContext context) {
    final e = estado.escenario;
    final h = estado.dia.horas[estado.hora];
    return _Tarjeta(
      titulo: 'Cambia el escenario',
      subtitulo: 'Parte del día real; mueve los controles y mira qué pasa',
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        _Deslizador(
          etiqueta: 'Hora',
          valor: estado.hora.toDouble(),
          min: 0, max: 23, divisiones: 23,
          texto: hora(estado.hora),
          alCambiar: (v) => estado.elegirHora(v.round()),
        ),
        const Divider(height: 24),
        _Deslizador(
          etiqueta: 'Demanda',
          valor: e.factorDemanda, min: 0.7, max: 1.3, divisiones: 60,
          texto: '${_pct(e.factorDemanda)} · ${gw(h.demandaMw * e.factorDemanda)}',
          alCambiar: (v) => estado.cambiar(e.copyWith(factorDemanda: v)),
        ),
        _Deslizador(
          etiqueta: 'Sol',
          valor: e.factorSolar, min: 0, max: 2.5, divisiones: 50,
          texto: '${_pct(e.factorSolar)} · ${gw(h.solarMw * e.factorSolar)}',
          alCambiar: (v) => estado.cambiar(e.copyWith(factorSolar: v)),
        ),
        _Deslizador(
          etiqueta: 'Viento',
          valor: e.factorEolica, min: 0, max: 2.5, divisiones: 50,
          texto: '${_pct(e.factorEolica)} · ${gw(h.eolicaMw * e.factorEolica)}',
          alCambiar: (v) => estado.cambiar(e.copyWith(factorEolica: v)),
        ),
        _Deslizador(
          etiqueta: 'Precio del gas',
          valor: e.gas, min: 0, max: 300, divisiones: 60,
          texto: '${euros(e.gas, decimales: 0)} €/MWh',
          alCambiar: (v) => estado.cambiar(e.copyWith(gas: v)),
        ),
        _Deslizador(
          etiqueta: 'Precio del CO2',
          valor: e.co2, min: 0, max: 150, divisiones: 30,
          texto: '${euros(e.co2, decimales: 0)} €/t',
          alCambiar: (v) => estado.cambiar(e.copyWith(co2: v)),
        ),
        _Deslizador(
          etiqueta: 'Nuclear disponible',
          valor: e.nuclear, min: 0, max: 7100, divisiones: 71,
          texto: gw(e.nuclear),
          alCambiar: (v) => estado.cambiar(e.copyWith(nuclear: v)),
        ),
        _Deslizador(
          etiqueta: 'Baterías',
          valor: e.bateriaMw, min: 0, max: 20000, divisiones: 40,
          texto: gw(e.bateriaMw),
          alCambiar: (v) => estado.cambiar(e.copyWith(bateriaMw: v)),
        ),
        if (e.bateriaMw > 0)
          _Deslizador(
            etiqueta: 'Duración de las baterías',
            valor: e.bateriaHoras, min: 1, max: 8, divisiones: 7,
            texto: '${e.bateriaHoras.round()} h',
            alCambiar: (v) => estado.cambiar(e.copyWith(bateriaHoras: v)),
          ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Tope al gas (excepción ibérica)'),
          subtitle: const Text('Los ciclos ofertan con el gas a 40 €/MWh'),
          value: e.topeGas != null,
          onChanged: (v) => estado.cambiar(e.copyWith(topeGas: () => v ? 40 : null)),
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: estado.modificado ? estado.restablecer : null,
          icon: const Icon(Icons.restart_alt),
          label: const Text('Volver al día real'),
        ),
      ]),
    );
  }

  static String _pct(double f) => '${(f * 100).round()} %';
}

class _Resultado extends StatelessWidget {
  const _Resultado({
    required this.dia,
    required this.casacion,
    required this.horaDatos,
    required this.escenario,
    required this.simulado,
  });

  final Dia dia;
  final Casacion casacion;
  final Hora horaDatos;
  final Escenario escenario;
  final DiaSimulado simulado;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final esquema = Theme.of(context).colorScheme;
    final c = casacion;
    final cuentas = c.cuentas;
    final casaciones = simulado.casaciones;
    final h = horaDatos.hora;
    final medio = casaciones.fold<double>(0, (s, x) => s + x.precio) / 24;
    double capturado(Tecnologia tec) {
      var mwh = 0.0, ingreso = 0.0;
      for (final x in casaciones) {
        final q = x.despacho[tec] ?? 0;
        mwh += q;
        ingreso += q * x.precio;
      }
      return mwh > 0 ? ingreso / mwh : 0;
    }

    return _Tarjeta(
      titulo: 'Resultado',
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('${euros(c.precio)} €/MWh',
            style: t.displaySmall!.copyWith(color: esquema.primary, fontWeight: FontWeight.w700)),
        Text('Precio simulado a las ${hora(horaDatos.hora)} · real ${euros(horaDatos.precioReal)} €/MWh',
            style: t.bodySmall),
        const SizedBox(height: 12),
        Text(_explicacion(c, escenario), style: t.bodyMedium),
        if (simulado.carga[h] > 0 || simulado.descarga[h] > 0) ...[
          const SizedBox(height: 8),
          Text(
            simulado.carga[h] > 0
                ? 'A esta hora las baterías compran ${gw(simulado.carga[h])} para cargar: '
                    'son demanda extra y sostienen el precio de las horas baratas.'
                : 'A esta hora las baterías venden ${gw(simulado.descarga[h])}: '
                    'desplazan a las centrales más caras y bajan el precio de la punta.',
            style: t.bodyMedium,
          ),
        ],
        if (escenario.topeGas != null && escenario.gas > escenario.topeGas!) ...[
          const SizedBox(height: 8),
          Text(
            'Con el tope, los ciclos ofertan como si el gas costara '
            '${euros(escenario.topeGas!, decimales: 0)} €/MWh. Su coste real es mayor; '
            'la diferencia se les pagaba aparte (el "ajuste"), así que su margen negativo '
            'aquí no era una pérdida real.',
            style: t.bodySmall,
          ),
        ],
        const SizedBox(height: 16),
        Text('Quién gana dinero en esta hora', style: t.titleSmall),
        const SizedBox(height: 4),
        Table(
          columnWidths: const {0: FlexColumnWidth(2.2), 1: FlexColumnWidth(1), 2: FlexColumnWidth(1.3)},
          children: [
            TableRow(children: [
              _celda(context, 'Tecnología', cabecera: true),
              _celda(context, 'Casado', cabecera: true, derecha: true),
              _celda(context, 'Margen €/h', cabecera: true, derecha: true),
            ]),
            for (final entry in cuentas.entries.where((e) => e.value.mw >= 50))
              TableRow(children: [
                Row(children: [
                  Container(width: 10, height: 10, color: entry.key.color),
                  const SizedBox(width: 6),
                  Flexible(child: _celda(context, entry.key.nombre)),
                ]),
                _celda(context, gw(entry.value.mw), derecha: true),
                _celda(context, euros(entry.value.ingreso - entry.value.coste, decimales: 0),
                    derecha: true),
              ]),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          'Margen = (precio − coste variable) × MW. La hidráulica tiene coste variable casi '
          'nulo, pero oferta por el valor de guardar el agua para otra hora.',
          style: t.bodySmall!.copyWith(color: esquema.onSurfaceVariant),
        ),
        const Divider(height: 28),
        Text('En todo el día', style: t.titleSmall),
        const SizedBox(height: 4),
        _fila(context, 'Precio medio del escenario', '${euros(medio)} €/MWh'),
        _fila(context, 'Precio capturado por la solar', '${euros(capturado(Tecnologia.solar))} €/MWh'),
        _fila(context, 'Precio capturado por la eólica', '${euros(capturado(Tecnologia.eolica))} €/MWh'),
        if (escenario.bateriaMw > 0) ...[
          _fila(context, 'Horas de carga y descarga de las baterías',
              '${simulado.carga.where((x) => x > 0).length} y '
                  '${simulado.descarga.where((x) => x > 0).length}'),
          _fila(context, 'Margen de las baterías en el día',
              '${euros(simulado.margenBaterias / 1000, decimales: 0)} mil €'),
        ],
        const SizedBox(height: 4),
        Text(
          'Si la solar captura menos que la media es porque produce justo cuando hunde el '
          'precio: es la canibalización. Añade baterías y mira cómo se acerca a la media.',
          style: t.bodySmall!.copyWith(color: esquema.onSurfaceVariant),
        ),
      ]),
    );
  }

  static String _explicacion(Casacion c, Escenario e) {
    if (!c.demandaCubierta) {
      return 'No hay oferta suficiente para cubrir la demanda: en la realidad saltaría el '
          'precio máximo y REE tendría que tirar de reservas o importar.';
    }
    if (c.precio < 0) {
      return 'Sobra energía: parte de la eólica y la solar acepta pagar por producir '
          '(PPAs, garantías de origen, costes de parar) y el precio cae a ${euros(c.precio)} €/MWh.';
    }
    if (c.precio == 0) {
      return 'Lo que oferta a 0 € (sol, viento, nuclear y agua que no se puede guardar) '
          'basta para cubrir la demanda, así que el precio es 0 €. Ninguna central '
          'recupera su inversión en esta hora.';
    }
    if (c.marginal.startsWith('Demanda flexible')) {
      return 'Casi todo se cubre con energía barata y el precio lo fija la demanda flexible: '
          'el bombeo y las exportaciones, que solo compran si el precio es bajo.';
    }
    return 'Para cubrir la demanda hace falta ${c.marginal.toLowerCase()}, así que todas las '
        'centrales casadas cobran ${euros(c.precio)} €/MWh. Una eólica o una solar, sin coste '
        'variable, se lleva ese precio entero como margen.';
  }

  Widget _fila(BuildContext context, String a, String b) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(children: [
          Expanded(child: Text(a, style: Theme.of(context).textTheme.bodyMedium)),
          Text(b, style: Theme.of(context).textTheme.bodyMedium!.copyWith(fontWeight: FontWeight.w600)),
        ]),
      );

  Widget _celda(BuildContext context, String s, {bool cabecera = false, bool derecha = false}) =>
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Text(s,
            textAlign: derecha ? TextAlign.right : TextAlign.left,
            style: cabecera
                ? Theme.of(context).textTheme.labelMedium
                : Theme.of(context).textTheme.bodySmall),
      );
}

class _Deslizador extends StatelessWidget {
  const _Deslizador({
    required this.etiqueta,
    required this.valor,
    required this.min,
    required this.max,
    required this.divisiones,
    required this.texto,
    required this.alCambiar,
  });

  final String etiqueta, texto;
  final double valor, min, max;
  final int divisiones;
  final ValueChanged<double> alCambiar;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Row(children: [
        Expanded(child: Text(etiqueta, style: t.labelLarge)),
        Text(texto, style: t.labelMedium),
      ]),
      Slider(
        value: valor.clamp(min, max),
        min: min,
        max: max,
        divisions: divisiones,
        label: texto,
        onChanged: alCambiar,
      ),
    ]);
  }
}

class _Chip extends StatelessWidget {
  const _Chip(this.t);
  final Tecnologia t;

  @override
  Widget build(BuildContext context) => Row(mainAxisSize: MainAxisSize.min, children: [
        Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(color: t.color, borderRadius: BorderRadius.circular(3))),
        const SizedBox(width: 6),
        Text(t.nombre, style: Theme.of(context).textTheme.labelMedium),
      ]);
}

class _Tarjeta extends StatelessWidget {
  const _Tarjeta({required this.titulo, this.subtitulo, required this.child});
  final String titulo;
  final String? subtitulo;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Text(titulo, style: t.titleMedium),
          if (subtitulo != null) ...[
            const SizedBox(height: 2),
            Text(subtitulo!,
                style: t.bodySmall!.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant)),
          ],
          const SizedBox(height: 12),
          child,
        ]),
      ),
    );
  }
}
