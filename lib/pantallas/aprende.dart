import 'package:flutter/material.dart';

/// Un concepto explicado, con un enlace opcional al simulador.
class Concepto {
  const Concepto(this.titulo, this.resumen, this.parrafos,
      {this.dia, this.hora, this.accion});
  final String titulo, resumen;
  final List<String> parrafos;
  final int? dia, hora;
  final String? accion;
}

const conceptos = [
  Concepto(
    'Cómo se fija el precio',
    'Una subasta marginalista: todos cobran el precio de la última oferta necesaria.',
    [
      'Cada día, antes de las 12:00, generadores y compradores envían a OMIE sus ofertas para cada periodo del día siguiente: cuántos MWh y a qué precio.',
      'OMIE ordena las ventas de más barata a más cara (el "orden de mérito") y las compras de más cara a más barata. Donde se cruzan las dos curvas sale un precio único para ese periodo.',
      'Todas las centrales casadas cobran ese precio, aunque hayan ofertado a 0 €, y todos los compradores pagan lo mismo. No es "pago según oferta".',
    ],
    dia: 4, hora: 20, accion: 'Ver una hora de invierno',
  ),
  Concepto(
    'OMIE casa, REE opera',
    'OMIE gestiona el mercado (lo económico); Red Eléctrica, el sistema (lo físico).',
    [
      'OMIE es el operador del mercado: recibe las ofertas, las casa y publica precios y programas.',
      'Red Eléctrica es el operador del sistema y el transportista: comprueba que lo casado sea físicamente viable (restricciones técnicas), mantiene el equilibrio segundo a segundo con las reservas de balance y liquida los desvíos.',
      'Esos servicios de ajuste se pagan aparte del precio de OMIE. Un día a 0 € en el diario puede tener costes altos de restricciones si REE tiene que arrancar ciclos combinados para controlar la tensión.',
    ],
  ),
  Concepto(
    'Por qué las renovables ofertan a 0 €',
    'Su coste marginal es casi cero y cobran el precio de casación, no su oferta.',
    [
      'Producir un MWh más con sol o viento no cuesta casi nada. Ofertar a 0 € les garantiza entrar en la casación sin renunciar a ingresos, porque cobran el precio marginal.',
      'La nuclear también oferta a 0 € o cerca: no puede subir y bajar potencia con rapidez y parar le cuesta mucho.',
      'Lo que cada central gana por MWh (precio menos su coste) es su renta infra-marginal. Con ella paga la inversión. En el simulador lo ves en la tabla "Quién gana dinero".',
    ],
    dia: 6, hora: 13, accion: 'Ver un mediodía soleado',
  ),
  Concepto(
    '¿Por qué no se vende todo a 0 €?',
    'Porque lo que oferta a 0 € no cubre toda la demanda en todas las horas.',
    [
      'De noche, sin viento o en invierno hace falta generación con coste variable (gas, agua embalsada, importaciones), y esa es la que fija el precio.',
      'Solo cuando lo que oferta a 0 € basta para cubrir toda la demanda (incluidos bombeo y exportaciones) el precio cae a 0 €.',
      'El 16 de junio de 2025 es el ejemplo perfecto: casi 0 € al mediodía y 210 €/MWh a las 21:00, cuando se pone el sol. Es la "curva de pato".',
    ],
    dia: 6, hora: 21, accion: 'Ver la puesta de sol',
  ),
  Concepto(
    'Por qué el gas marca el precio',
    'El gas genera poca energía pero es marginal en muchas horas.',
    [
      'Un ciclo combinado oferta a su coste: gas / rendimiento + CO2 + operación. Con gas a 35 €/MWh, rendimiento del 55 % y CO2 a 70 €/t sale en torno a 92 €/MWh.',
      'La hidráulica de embalse no oferta a su coste (el agua es gratis) sino a su coste de oportunidad, que está ligado al gas. Por eso, aunque el gas genere un 14 % de la electricidad, arrastra el precio de muchas horas.',
      'El 8 de marzo de 2022, con el gas por encima de 200 €/MWh, el precio medio del día fue de 545 €/MWh, el más alto de la serie.',
    ],
    dia: 1, hora: 19, accion: 'Ver el récord de marzo de 2022',
  ),
  Concepto(
    'La excepción ibérica',
    'De junio de 2022 a 2023, los ciclos ofertaron con el gas topado a 40 €/MWh.',
    [
      'El Real Decreto-ley 10/2022 limitó el precio del gas usado para generar electricidad. Los ciclos ofertaban más barato y el precio marginal bajaba.',
      'La diferencia con su coste real se les compensaba con un "ajuste" que pagaban los consumidores beneficiados. El ahorro medio estimado fue del 14 % en el primer año.',
      'Críticas: abarató la electricidad exportada a Francia y aumentó el consumo de gas. Prueba a quitar el tope en el simulador para ver el precio sin él.',
    ],
    dia: 2, hora: 20, accion: 'Ver un día con tope al gas',
  ),
  Concepto(
    'Precios cero y negativos',
    'Cuando sobra energía, hay quien paga por producir.',
    [
      'El primer precio negativo en España fue el 1 de abril de 2024 (-0,01 €/MWh). En 2025 el mínimo llegó a -15 €/MWh.',
      'Una planta acepta un precio negativo si parar le cuesta más: PPAs que cobran por MWh producido, garantías de origen o costes de parada y arranque.',
      'En España los negativos son pequeños porque pocas plantas cobran ayudas por MWh producido; en Alemania son mucho más profundos.',
    ],
    dia: 5, hora: 15, accion: 'Ver un domingo con negativos',
  ),
  Concepto(
    'Canibalización solar',
    'Toda la solar produce a la vez y hunde el precio justo cuando vende.',
    [
      'El precio capturado de una tecnología es la media del precio ponderada por su producción. El de la solar cae más rápido que la media del mercado: 42 €/MWh en 2024 y 36 €/MWh en 2025.',
      'Se mitiga con baterías y bombeo (compran a 0 € y venden por la tarde), demanda flexible, interconexiones, hibridación con eólica y PPAs baseload.',
      'En el simulador, sube el sol de un día de primavera y mira cómo baja el "precio capturado por la solar".',
    ],
    dia: 3, hora: 13, accion: 'Ver un día a 0 €',
  ),
  Concepto(
    'Después del diario: intradiario y ajustes',
    'El diario casa casi toda la energía, pero no es el último mercado.',
    [
      'El intradiario sirve para corregir posiciones cuando cambia la previsión. Desde junio de 2024 hay tres subastas europeas (IDA) y un mercado continuo (SIDC) abierto casi hasta la entrega.',
      'Después, REE gestiona restricciones técnicas, reservas de balance (aFRR, mFRR, RR) y desvíos. Todo eso se suma a la factura.',
      'Desde el 1 de octubre de 2025 el diario casa periodos de 15 minutos: 96 precios al día en lugar de 24. Los datos de esta app son horarios y terminan en septiembre de 2025.',
    ],
  ),
  Concepto(
    'Futuros y PPAs',
    'A plazo se cubre el riesgo de un precio diario muy volátil.',
    [
      'Los futuros (OMIP, EEX) fijan hoy el precio de un mes, trimestre o año y se liquidan contra el precio de OMIE.',
      'Un PPA es un contrato de 5 a 15 años o más entre un productor y un comprador. Es lo que financia la mayoría de renovables nuevas.',
      'Si casi toda la energía de un generador está vendida a plazo, el precio diario solo afecta a su margen residual.',
    ],
  ),
  Concepto(
    'Qué simplifica este simulador',
    'Es un modelo educativo, calibrado para parecerse a días reales.',
    [
      'Usa demanda, solar y eólica reales (previsiones del día anterior) y precios reales de OMIE, pero las ofertas de cada tecnología son una aproximación: no son las curvas reales de OMIE.',
      'Solo representa España: no incluye Portugal, las interconexiones ni las ofertas complejas. El gas y el CO2 de cada día son valores de referencia aproximados.',
      'Hidráulica, cogeneración, bombeo y exportaciones están calibrados para cada día. Por eso el modelo acierta en un día a 0 € y se queda corto en el récord de marzo de 2022, cuando las ofertas reales subieron muy por encima del coste del gas.',
    ],
  ),
];

class PantallaAprende extends StatelessWidget {
  const PantallaAprende({super.key, required this.abrirSimulador});

  /// Abre el simulador en un día y una hora.
  final void Function(int dia, int hora) abrirSimulador;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 820),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text('Cómo funciona el mercado eléctrico español', style: t.headlineSmall),
            const SizedBox(height: 8),
            Text(
              'Once ideas para entender de dónde sale el precio de la luz. '
              'Las que tienen un botón se pueden ver en el simulador con datos reales.',
              style: t.bodyMedium,
            ),
            const SizedBox(height: 16),
            for (final c in conceptos)
              Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ExpansionTile(
                  shape: const Border(),
                  title: Text(c.titulo, style: t.titleMedium),
                  subtitle: Text(c.resumen),
                  childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  expandedCrossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (final p in c.parrafos)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Text(p, style: t.bodyMedium),
                      ),
                    if (c.dia != null)
                      FilledButton.tonalIcon(
                        onPressed: () => abrirSimulador(c.dia!, c.hora!),
                        icon: const Icon(Icons.play_arrow),
                        label: Text(c.accion!),
                      ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
