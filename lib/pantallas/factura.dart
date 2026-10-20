import 'package:flutter/material.dart';

import '../modelo/factura.dart';
import '../widgets/formato.dart';

/// Del precio de OMIE a la factura de un hogar.
class PantallaFactura extends StatefulWidget {
  const PantallaFactura({super.key});

  @override
  State<PantallaFactura> createState() => _PantallaFacturaState();
}

class _PantallaFacturaState extends State<PantallaFactura> {
  var _s = const SupuestosFactura();

  static const _colores = [
    Color(0xFFE4572E), // energía
    Color(0xFFF2A541), // ajustes
    Color(0xFF8D9A6B), // margen
    Color(0xFF2F6FDE), // peajes
    Color(0xFF7B5EA7), // cargos
    Color(0xFF5B4B3A), // impuesto eléctrico
    Color(0xFF9E9E9E), // contador
    Color(0xFF455A64), // IVA
  ];

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final esquema = Theme.of(context).colorScheme;
    final lineas = calcularFactura(_s);
    final total = lineas.fold<double>(0, (a, l) => a + l.euros);
    // El IVA también grava la energía: su peso real incluye su parte de impuestos.
    final pesoMercado = lineas[0].euros / total * (1 + impuestoElectrico) * (1 + iva);
    final sube10 = totalFactura(_s.copyWith(precioMayorista: _s.precioMayorista + 10)) - total;

    final controles = _Tarjeta(
      titulo: 'Tu caso',
      subtitulo: 'Un hogar con tarifa 2.0TD en el mercado libre',
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        _Control(
          etiqueta: 'Precio medio del mercado diario',
          texto: '${euros(_s.precioMayorista, decimales: 0)} €/MWh',
          valor: _s.precioMayorista, min: 0, max: 250, divisiones: 50,
          alCambiar: (v) => setState(() => _s = _s.copyWith(precioMayorista: v)),
        ),
        Wrap(spacing: 8, children: [
          for (final (nombre, precio) in const [
            ('2020', 33.96),
            ('2022', 167.54),
            ('2024', 63.03),
            ('2025', 65.28),
          ])
            ActionChip(
              label: Text('$nombre: ${euros(precio, decimales: 0)} €'),
              onPressed: () => setState(() => _s = _s.copyWith(precioMayorista: precio)),
            ),
        ]),
        const SizedBox(height: 8),
        _Control(
          etiqueta: 'Consumo al año',
          texto: '${miles(_s.consumoKwh.round().toString())} kWh',
          valor: _s.consumoKwh, min: 1000, max: 8000, divisiones: 35,
          alCambiar: (v) => setState(() => _s = _s.copyWith(consumoKwh: v)),
        ),
        _Control(
          etiqueta: 'Potencia contratada',
          texto: '${euros(_s.potenciaKw, decimales: 1)} kW',
          valor: _s.potenciaKw, min: 2.3, max: 10, divisiones: 77,
          alCambiar: (v) => setState(() => _s = _s.copyWith(potenciaKw: v)),
        ),
        _Control(
          etiqueta: 'Consumo en valle (P3)',
          texto: '${(_s.reparto[2] * 100).round()} %',
          valor: _s.reparto[2], min: 0.2, max: 0.8, divisiones: 12,
          alCambiar: (v) => setState(() => _s = _s.copyWith(valle: v)),
        ),
        _Control(
          etiqueta: 'Margen de la comercializadora',
          texto: '${euros(_s.margen, decimales: 0)} €/MWh',
          valor: _s.margen, min: 0, max: 50, divisiones: 50,
          alCambiar: (v) => setState(() => _s = _s.copyWith(margen: v)),
        ),
      ]),
    );

    final resultado = _Tarjeta(
      titulo: 'Tu factura al año',
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('${euros(total, decimales: 0)} €/año',
            style: t.displaySmall!.copyWith(color: esquema.primary, fontWeight: FontWeight.w700)),
        Text(
          '${euros(total / 12, decimales: 0)} €/mes · '
          '${euros(total / _s.consumoKwh, decimales: 3)} €/kWh de media',
          style: t.bodySmall,
        ),
        const SizedBox(height: 16),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: SizedBox(
            height: 22,
            child: Row(children: [
              for (var i = 0; i < lineas.length; i++)
                Expanded(
                  flex: (lineas[i].euros * 100).round().clamp(1, 1 << 30),
                  child: Tooltip(
                    message: lineas[i].concepto,
                    child: Container(color: _colores[i]),
                  ),
                ),
            ]),
          ),
        ),
        const SizedBox(height: 12),
        for (var i = 0; i < lineas.length; i++)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 3),
            child: Row(children: [
              Container(width: 10, height: 10, color: _colores[i]),
              const SizedBox(width: 8),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(lineas[i].concepto, style: t.bodyMedium),
                  Text(lineas[i].detalle,
                      style: t.bodySmall!.copyWith(color: esquema.onSurfaceVariant)),
                ]),
              ),
              Text('${euros(lineas[i].euros, decimales: 0)} €',
                  style: t.bodyMedium!.copyWith(fontWeight: FontWeight.w600)),
              SizedBox(
                width: 48,
                child: Text('${(lineas[i].euros / total * 100).round()} %',
                    textAlign: TextAlign.right, style: t.bodySmall),
              ),
            ]),
          ),
        const Divider(height: 24),
        Text(
          'El mercado mayorista pesa un ${(pesoMercado * 100).round()} % de la factura '
          '(con sus impuestos). Si OMIE sube 10 €/MWh, pagas '
          '${euros(sube10, decimales: 0)} € más al año.',
          style: t.bodyMedium,
        ),
      ]),
    );

    final notas = _Tarjeta(
      titulo: 'Cómo leerlo',
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        for (final p in const [
          'Peajes y cargos dependen de la hora. Punta (P1): laborables de 10 a 14 y de 18 a 22. '
              'Llano (P2): de 8 a 10, de 14 a 18 y de 22 a 24. Valle (P3): de 0 a 8 y fines de semana. '
              'Con tanta solar, la energía más barata es la del mediodía, que cae en punta: '
              'la estructura de peajes se diseñó antes del boom fotovoltaico.',
          'El término de potencia se paga aunque no consumas: en un hogar típico es más de la '
              'mitad de peajes y cargos. Por eso ajustar la potencia contratada ahorra tanto.',
          'Los servicios de ajuste se estiman dividiendo su coste de 2025 (3.812 millones, según REE) '
              'entre la demanda: unos 15 €/MWh. En 2025 subieron un 43 %, en buena parte por la operación '
              'reforzada tras el apagón.',
          'El PVPC (tarifa regulada, hasta 10 kW) no tiene margen y, desde 2024, su energía mezcla '
              'el diario con futuros: 25 % en 2024, 40 % en 2025 y 55 % en 2026. Así se suaviza la volatilidad.',
          'Simplificaciones: pérdidas del 15 % para todos los periodos, sin bono social ni descuentos, '
              'y la comercializadora repercute los costes sin cobertura. Peajes y cargos son los de 2026.',
        ])
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(p, style: t.bodyMedium),
          ),
      ]),
    );

    return LayoutBuilder(builder: (context, c) {
      final ancho = c.maxWidth >= 1000;
      final cabecera = Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Del precio de OMIE a tu factura', style: t.headlineSmall),
        const SizedBox(height: 8),
        Text(
          'El precio del mercado diario es solo una parte de lo que paga un hogar. '
          'Mueve el precio mayorista y mira cuánto cambia el total.',
          style: t.bodyMedium,
        ),
        const SizedBox(height: 16),
      ]);
      if (ancho) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            cabecera,
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              SizedBox(width: 340, child: controles),
              const SizedBox(width: 16),
              Expanded(child: resultado),
              const SizedBox(width: 16),
              Expanded(child: notas),
            ]),
          ]),
        );
      }
      return ListView(padding: const EdgeInsets.all(16), children: [
        cabecera,
        resultado,
        const SizedBox(height: 12),
        controles,
        const SizedBox(height: 12),
        notas,
      ]);
    });
  }
}

class _Control extends StatelessWidget {
  const _Control({
    required this.etiqueta,
    required this.texto,
    required this.valor,
    required this.min,
    required this.max,
    required this.divisiones,
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
