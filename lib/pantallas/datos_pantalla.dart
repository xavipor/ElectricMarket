import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../modelo/datos.dart';
import '../widgets/formato.dart';

class PantallaDatos extends StatelessWidget {
  const PantallaDatos({super.key, required this.datos});
  final DatosMercado datos;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final esquema = Theme.of(context).colorScheme;
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 900),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text('Diez años de precios', style: t.headlineSmall),
            const SizedBox(height: 8),
            Text(
              'Precio medio anual del mercado diario en España y horas a 0 € o menos, '
              'calculados con los precios horarios de OMIE de 2015 a septiembre de 2025.',
              style: t.bodyMedium,
            ),
            const SizedBox(height: 16),
            _TarjetaBarras(
              titulo: 'La crisis del gas multiplicó por cinco el precio entre 2020 y 2022',
              subtitulo: 'Precio medio anual, €/MWh',
              valores: {for (final a in datos.anios) a.anio: a.precioMedio},
              etiqueta: (v) => euros(v, decimales: 0),
              destacar: 2022,
              color: esquema.primary,
            ),
            const SizedBox(height: 16),
            _TarjetaBarras(
              titulo: 'Las horas a 0 € o menos aparecen con la solar masiva',
              subtitulo: 'Horas al año con precio de 0 €/MWh o negativo',
              valores: {for (final a in datos.anios) a.anio: a.horasCeroOMenos.toDouble()},
              etiqueta: (v) => miles(v.round().toString()),
              destacar: 2024,
              color: const Color(0xFFF2B705),
            ),
            const SizedBox(height: 16),
            Card(
              margin: EdgeInsets.zero,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Tabla por año', style: t.titleMedium),
                  const SizedBox(height: 8),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      columnSpacing: 20,
                      headingTextStyle: t.labelMedium,
                      dataTextStyle: t.bodySmall,
                      columns: const [
                        DataColumn(label: Text('Año')),
                        DataColumn(label: Text('Medio'), numeric: true),
                        DataColumn(label: Text('Mínimo'), numeric: true),
                        DataColumn(label: Text('Máximo'), numeric: true),
                        DataColumn(label: Text('Horas ≤ 0 €'), numeric: true),
                        DataColumn(label: Text('Negativas'), numeric: true),
                      ],
                      rows: [
                        for (final a in datos.anios)
                          DataRow(cells: [
                            DataCell(Text(a.nota.isEmpty ? '${a.anio}' : '${a.anio}*')),
                            DataCell(Text(euros(a.precioMedio))),
                            DataCell(Text(euros(a.minimo))),
                            DataCell(Text(euros(a.maximo))),
                            DataCell(Text('${a.horasCeroOMenos}')),
                            DataCell(Text('${a.horasNegativas}')),
                          ]),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text('* 2015 empieza el 7 de enero y 2025 termina el 30 de septiembre. '
                      'Precios en €/MWh.', style: t.bodySmall),
                ]),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              margin: EdgeInsets.zero,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Fuentes y notas', style: t.titleMedium),
                  const SizedBox(height: 8),
                  Text(datos.fuente, style: t.bodyMedium),
                  const SizedBox(height: 8),
                  for (final n in datos.notas)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text('• $n', style: t.bodySmall),
                    ),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TarjetaBarras extends StatelessWidget {
  const _TarjetaBarras({
    required this.titulo,
    required this.subtitulo,
    required this.valores,
    required this.etiqueta,
    required this.destacar,
    required this.color,
  });

  final String titulo, subtitulo;
  final Map<int, double> valores;
  final String Function(double) etiqueta;
  final int destacar;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final esquema = Theme.of(context).colorScheme;
    final maximo = valores.values.reduce(math.max);
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(titulo, style: t.titleMedium),
          Text(subtitulo, style: t.bodySmall!.copyWith(color: esquema.onSurfaceVariant)),
          const SizedBox(height: 16),
          SizedBox(
            height: 200,
            child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
              for (final e in valores.entries)
                Expanded(
                  child: Tooltip(
                    message: '${e.key}: ${etiqueta(e.value)}',
                    child: Column(mainAxisAlignment: MainAxisAlignment.end, children: [
                      FittedBox(
                        child: Text(etiqueta(e.value),
                            style: t.labelSmall!.copyWith(
                                fontWeight: e.key == destacar ? FontWeight.w700 : null)),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        height: maximo == 0 ? 0 : 150 * e.value / maximo,
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        decoration: BoxDecoration(
                          color: e.key == destacar ? color : color.withValues(alpha: 0.45),
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(3)),
                        ),
                      ),
                      const SizedBox(height: 4),
                      FittedBox(child: Text("'${e.key % 100}", style: t.labelSmall)),
                    ]),
                  ),
                ),
            ]),
          ),
        ]),
      ),
    );
  }
}
