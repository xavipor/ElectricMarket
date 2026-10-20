import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'formato.dart';

/// Precio de las 24 horas: real, modelo calibrado y escenario del usuario.
/// Pulsar o arrastrar sobre el gráfico elige la hora.
class GraficoDia extends StatelessWidget {
  const GraficoDia({
    super.key,
    required this.real,
    required this.modelo,
    required this.escenario,
    required this.horaSeleccionada,
    required this.alElegirHora,
    this.mostrarEscenario = true,
  });

  final List<double> real, modelo, escenario;
  final int horaSeleccionada;
  final ValueChanged<int> alElegirHora;
  final bool mostrarEscenario;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    return LayoutBuilder(builder: (context, c) {
      void elegir(Offset p) {
        final ancho = c.maxWidth - _PintorDia.izq - _PintorDia.der;
        final h = ((p.dx - _PintorDia.izq) / ancho * 24).floor().clamp(0, 23);
        if (h != horaSeleccionada) alElegirHora(h);
      }

      return GestureDetector(
        onTapDown: (d) => elegir(d.localPosition),
        onHorizontalDragUpdate: (d) => elegir(d.localPosition),
        child: CustomPaint(
          size: Size(c.maxWidth, c.maxHeight),
          painter: _PintorDia(real, modelo, mostrarEscenario ? escenario : null,
              horaSeleccionada, tema),
        ),
      );
    });
  }
}

class _PintorDia extends CustomPainter {
  _PintorDia(this.real, this.modelo, this.escenario, this.hora, this.tema);

  final List<double> real, modelo;
  final List<double>? escenario;
  final int hora;
  final ThemeData tema;

  static const izq = 44.0, der = 8.0, arriba = 10.0, abajo = 22.0;

  @override
  void paint(Canvas canvas, Size size) {
    final esquema = tema.colorScheme;
    final todos = [...real, ...modelo, ...?escenario];
    var yMin = math.min(0.0, todos.reduce(math.min));
    var yMax = math.max(10.0, todos.reduce(math.max));
    final paso = _paso((yMax - yMin) / 4);
    yMin = (yMin / paso).floor() * paso;
    yMax = (yMax / paso).ceil() * paso;

    final ancho = size.width - izq - der;
    final alto = size.height - arriba - abajo;
    double x(num h) => izq + (h + 0.5) / 24 * ancho;
    double y(double p) => arriba + (1 - (p - yMin) / (yMax - yMin)) * alto;
    final texto =
        tema.textTheme.labelSmall!.copyWith(color: esquema.onSurfaceVariant);

    // Hora seleccionada.
    canvas.drawRect(
        Rect.fromLTRB(izq + hora / 24 * ancho, arriba,
            izq + (hora + 1) / 24 * ancho, arriba + alto),
        Paint()..color = esquema.primary.withValues(alpha: 0.12));

    for (var p = yMin; p <= yMax + 0.01; p += paso) {
      canvas.drawLine(
          Offset(izq, y(p)),
          Offset(size.width - der, y(p)),
          Paint()
            ..color = esquema.outlineVariant
                .withValues(alpha: p == 0 ? 1 : 0.4));
      _texto(canvas, '${p.round()}', Offset(izq - 6, y(p)), texto, derecha: true);
    }
    for (var h = 0; h < 24; h += 3) {
      _texto(canvas, '${h}h', Offset(x(h), size.height - abajo + 6), texto,
          centro: true);
    }

    void linea(List<double> v, Color color, double grosor, {bool puntos = false}) {
      final path = Path()..moveTo(x(0), y(v[0]));
      for (var h = 1; h < 24; h++) {
        path.lineTo(x(h), y(v[h]));
      }
      canvas.drawPath(
          path,
          Paint()
            ..color = color
            ..style = PaintingStyle.stroke
            ..strokeWidth = grosor
            ..strokeJoin = StrokeJoin.round);
      if (puntos) {
        canvas.drawCircle(Offset(x(hora), y(v[hora])), 4, Paint()..color = color);
      }
    }

    linea(modelo, esquema.outline, 1.5);
    linea(real, esquema.onSurface, 2.5, puntos: true);
    if (escenario != null) linea(escenario!, esquema.primary, 2.5, puntos: true);
  }

  static double _paso(double v) {
    if (v <= 0) return 10;
    final e = math.pow(10, (math.log(v) / math.ln10).floor()).toDouble();
    for (final m in [1, 2, 2.5, 5, 10]) {
      if (m * e >= v) return m * e;
    }
    return 10 * e;
  }

  void _texto(Canvas canvas, String s, Offset o, TextStyle estilo,
      {bool derecha = false, bool centro = false}) {
    final tp = TextPainter(
        text: TextSpan(text: s, style: estilo),
        textDirection: TextDirection.ltr)
      ..layout();
    final dx = derecha ? -tp.width : (centro ? -tp.width / 2 : 0.0);
    final dy = derecha ? -tp.height / 2 : 0.0;
    tp.paint(canvas, o + Offset(dx, dy));
  }

  @override
  bool shouldRepaint(_PintorDia old) => true;
}

/// Leyenda compacta de una serie.
class Leyenda extends StatelessWidget {
  const Leyenda(this.texto, this.color, {super.key, this.grosor = 3});
  final String texto;
  final Color color;
  final double grosor;

  @override
  Widget build(BuildContext context) => Row(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 16, height: grosor, color: color),
        const SizedBox(width: 6),
        Text(texto, style: Theme.of(context).textTheme.labelMedium),
      ]);
}

String resumenHora(int h, double p) => '${hora(h)} · ${euros(p)} €/MWh';
