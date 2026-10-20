import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../modelo/mercado.dart';
import 'formato.dart';

/// Curva de oferta escalonada (coloreada por tecnología), curva de demanda
/// y el punto de casación de una hora.
class CurvaOferta extends StatelessWidget {
  const CurvaOferta({super.key, required this.casacion, this.precioReal});

  final Casacion casacion;
  final double? precioReal;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Curva de oferta y demanda. Precio de casación '
          '${euros(casacion.precio)} por MWh.',
      child: CustomPaint(
        painter: _Pintor(casacion, precioReal, Theme.of(context)),
        size: Size.infinite,
      ),
    );
  }
}

class _Pintor extends CustomPainter {
  _Pintor(this.c, this.precioReal, this.tema);

  final Casacion c;
  final double? precioReal;
  final ThemeData tema;

  static const _izq = 52.0, _abajo = 34.0, _arriba = 26.0, _der = 30.0;

  @override
  void paint(Canvas canvas, Size size) {
    final esquema = tema.colorScheme;
    final ofertas = c.ofertas.where((o) => o.mw > 0).toList();
    final totalMw = ofertas.fold<double>(0, (s, o) => s + o.mw);
    final demandaMax = c.pujas.fold<double>(0, (s, b) => s + b.mw);
    final xMax = (math.max(totalMw, demandaMax) / 5000).ceil() * 5000.0;

    final minOferta = ofertas.map((o) => o.precio).fold<double>(0, math.min);
    final yMin = minOferta < 0 ? (minOferta / 10).floor() * 10.0 - 10 : 0.0;
    final referencia = math.max(c.precio, precioReal ?? 0);
    final yMax = _redondeo(math.max(referencia * 1.5, 120));

    final ancho = size.width - _izq - _der;
    final alto = size.height - _arriba - _abajo;
    double x(double mw) => _izq + mw / xMax * ancho;
    double y(double p) =>
        _arriba + (1 - (p.clamp(yMin, yMax) - yMin) / (yMax - yMin)) * alto;

    final ejes = Paint()
      ..color = esquema.outlineVariant
      ..strokeWidth = 1;
    final texto = tema.textTheme.labelSmall!
        .copyWith(color: esquema.onSurfaceVariant);

    // Rejilla horizontal y etiquetas de precio.
    final paso = _redondeo(yMax / 5);
    for (var p = (yMin / paso).ceil() * paso; p <= yMax; p += paso) {
      canvas.drawLine(Offset(_izq, y(p)), Offset(size.width - _der, y(p)),
          ejes..color = esquema.outlineVariant.withValues(alpha: p == 0 ? 1 : 0.4));
      _texto(canvas, '${p.round()}', Offset(_izq - 6, y(p)), texto,
          alinear: _Alinear.derecha);
    }
    // Etiquetas de MW.
    for (var mw = 0.0; mw <= xMax; mw += 10000) {
      _texto(canvas, '${(mw / 1000).round()}', Offset(x(mw), size.height - _abajo + 6),
          texto, alinear: _Alinear.centroArriba);
    }
    _texto(canvas, 'GW', Offset(size.width - 2, size.height - _abajo + 6), texto,
        alinear: _Alinear.derechaArriba);
    _texto(canvas, '€/MWh', const Offset(4, 0), texto,
        alinear: _Alinear.izquierdaArriba);

    // Escalones de oferta.
    var acumulado = 0.0;
    for (final o in ofertas) {
      final x0 = x(acumulado), x1 = x(acumulado + o.mw);
      final casada = acumulado < c.mwCasados - 1;
      final relleno = Paint()
        ..color = o.tecnologia.color.withValues(alpha: casada ? 0.85 : 0.3);
      final rect = Rect.fromLTRB(x0, math.min(y(o.precio), y(0)), x1,
          math.max(y(o.precio), y(0)));
      if (rect.height < 2) {
        canvas.drawRect(
            Rect.fromLTRB(x0, y(o.precio) - 1.5, x1, y(o.precio) + 1.5), relleno);
      } else {
        canvas.drawRect(rect, relleno);
      }
      acumulado += o.mw;
    }

    // Curva de demanda escalonada (de más a menos disposición a pagar).
    final pujas = [...c.pujas]..sort((a, b) => b.precio.compareTo(a.precio));
    final demanda = Path()..moveTo(x(0), y(yMax));
    var mw = 0.0;
    for (final b in pujas) {
      demanda.lineTo(x(mw), y(b.precio));
      mw += b.mw;
      demanda.lineTo(x(mw), y(b.precio));
    }
    demanda.lineTo(x(mw), y(yMin));
    canvas.drawPath(
        demanda,
        Paint()
          ..color = esquema.onSurface
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5);

    // Precio real (referencia) y precio de casación.
    if (precioReal != null) {
      _discontinua(canvas, Offset(_izq, y(precioReal!)),
          Offset(size.width - _der, y(precioReal!)), esquema.onSurfaceVariant);
      _texto(canvas, 'real ${euros(precioReal!)}',
          Offset(size.width - _der - 4, y(precioReal!) - 3), texto,
          alinear: _Alinear.derechaAbajo);
    }
    final punto = Offset(x(c.mwCasados), y(c.precio));
    canvas.drawLine(Offset(_izq, punto.dy), punto,
        Paint()
          ..color = esquema.primary
          ..strokeWidth = 1.5);
    canvas.drawCircle(punto, 6, Paint()..color = esquema.primary);
    canvas.drawCircle(punto, 3, Paint()..color = esquema.surface);
    _texto(
        canvas,
        '${euros(c.precio)} €/MWh',
        punto + const Offset(-10, -10),
        tema.textTheme.labelLarge!.copyWith(
            color: esquema.primary, fontWeight: FontWeight.w700),
        alinear: _Alinear.derechaAbajo);
  }

  static double _redondeo(double v) {
    if (v <= 0) return 10;
    final e = math.pow(10, (math.log(v) / math.ln10).floor()).toDouble();
    for (final m in [1, 2, 2.5, 5, 10]) {
      if (m * e >= v) return m * e;
    }
    return 10 * e;
  }

  void _discontinua(Canvas canvas, Offset a, Offset b, Color color) {
    final p = Paint()
      ..color = color
      ..strokeWidth = 1.2;
    const trazo = 6.0, hueco = 4.0;
    final largo = (b - a).distance;
    final dir = (b - a) / largo;
    for (var d = 0.0; d < largo; d += trazo + hueco) {
      canvas.drawLine(a + dir * d, a + dir * math.min(d + trazo, largo), p);
    }
  }

  void _texto(Canvas canvas, String s, Offset o, TextStyle estilo,
      {_Alinear alinear = _Alinear.izquierdaArriba}) {
    final tp = TextPainter(
        text: TextSpan(text: s, style: estilo),
        textDirection: TextDirection.ltr)
      ..layout();
    final d = switch (alinear) {
      _Alinear.derecha => Offset(-tp.width, -tp.height / 2),
      _Alinear.derechaAbajo => Offset(-tp.width, -tp.height),
      _Alinear.derechaArriba => Offset(-tp.width, 0),
      _Alinear.centroArriba => Offset(-tp.width / 2, 0),
      _Alinear.izquierdaArriba => Offset.zero,
    };
    tp.paint(canvas, o + d);
  }

  @override
  bool shouldRepaint(_Pintor old) =>
      old.c != c || old.precioReal != precioReal || old.tema != tema;
}

enum _Alinear { derecha, derechaAbajo, derechaArriba, centroArriba, izquierdaArriba }
