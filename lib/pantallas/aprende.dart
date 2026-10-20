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
      'La casación no es solo española: el algoritmo europeo EUPHEMIA (acoplamiento SDAC) cruza a la vez las ofertas de toda Europa. Si la interconexión con Francia se satura, cosa habitual, España y Francia acaban con precios distintos; con Portugal el precio coincide casi siempre.',
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
    'Servicios de ajuste y el apagón',
    'El precio de OMIE no es el coste real: REE paga aparte por hacer viable el sistema.',
    [
      'Restricciones técnicas: si una zona no tiene suficiente generación síncrona para controlar la tensión, REE obliga a arrancar centrales (casi siempre ciclos combinados) que cobran su oferta, no el precio marginal.',
      'Reservas de balance: la secundaria (aFRR) responde en segundos y la terciaria (mFRR) en minutos para mantener los 50 Hz. Quien se desvía de su programa paga el coste de corregirlo.',
      'El 28 de abril de 2025 toda la península se quedó sin luz hacia las 12:33. El informe de ENTSO-E (marzo de 2026) lo atribuye a oscilaciones, control de tensión insuficiente y desconexiones en cascada por sobretensión. Las plantas con inversores operaban a factor de potencia fijo y no ayudaban a controlar la tensión.',
      'Desde entonces REE aplica una "operación reforzada" con más ciclos acoplados. Los servicios de ajuste costaron 3.812 millones en 2025, un 43 % más que en 2024. Mensaje para entrevista: el problema fue el control de tensión, no las renovables en sí.',
    ],
  ),
  Concepto(
    'Baterías y bombeo',
    'Compran cuando sobra energía y venden en la punta: aplanan la curva de pato.',
    [
      'Una batería carga en las horas baratas (como demanda extra que sostiene el precio) y descarga en las caras (como oferta que desplaza al gas). Gana la diferencia menos las pérdidas, en torno a un 15 %.',
      'Cuanta más solar, más diferencial y más negocio. Pero cada batería que entra estrecha ese diferencial: el almacenamiento también se canibaliza a sí mismo.',
      'Sube el control "Baterías" del simulador en el 16 de junio de 2025: el mediodía deja de estar a 0 €, la punta de la noche baja y el precio capturado por la solar se acerca a la media.',
    ],
    dia: 6, hora: 13, accion: 'Probar con la curva de pato',
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

/// Una pregunta típica de entrevista con su respuesta corta.
class Pregunta {
  const Pregunta(this.pregunta, this.respuesta, {this.dia, this.hora, this.accion});
  final String pregunta, respuesta;
  final int? dia, hora;
  final String? accion;
}

const preguntas = [
  Pregunta(
    '¿Por qué la luz depende del gas si el gas genera solo un 14 % de la electricidad?',
    'Porque el precio lo fija la última tecnología necesaria, y el gas (o la hidráulica, que se '
        'valora frente al gas) es marginal en buena parte de las horas, sobre todo de noche y en '
        'invierno. Su peso en el precio es mucho mayor que su peso en la energía.',
    dia: 4, hora: 20, accion: 'Ver una noche de invierno',
  ),
  Pregunta(
    '¿Por qué una eólica oferta a 0 €?',
    'Porque su coste marginal es casi nulo y cobra el precio de casación, no su oferta. '
        'Ofertar más alto solo le haría perder horas en las que ganaría dinero.',
    dia: 6, hora: 21, accion: 'Ver cuánto gana a las 21:00',
  ),
  Pregunta(
    '¿Quién pierde cuando el precio es 0 €?',
    'Las renovables a mercado (sin PPA) y las nucleares; los consumidores indexados ganan. '
        'Los servicios de ajuste, peajes y cargos se siguen pagando.',
    dia: 3, hora: 13, accion: 'Ver un mediodía a 0 €',
  ),
  Pregunta(
    '¿Qué diferencia a OMIE de REE?',
    'OMIE gestiona el mercado (lo económico); REE opera el sistema (lo físico) y es el '
        'transportista. Lo que OMIE casa, REE lo hace viable y lo equilibra en tiempo real.',
  ),
  Pregunta(
    '¿Qué es la canibalización y cómo se mitiga?',
    'Es la caída del precio capturado de una tecnología a medida que crece su propia '
        'penetración. Se mitiga con almacenamiento, demanda flexible, interconexiones, '
        'hibridación con eólica y PPAs baseload.',
    dia: 6, hora: 13, accion: 'Probar con baterías',
  ),
  Pregunta(
    '¿Funcionó la excepción ibérica?',
    'Bajó el precio para los consumidores indexados (un 14 % de media en su primer año), '
        'pero abarató las exportaciones a Francia y no redujo el consumo de gas.',
    dia: 2, hora: 20, accion: 'Quitar el tope a un día de 2022',
  ),
  Pregunta(
    '¿Por qué no cambiar a pay-as-bid?',
    'Los agentes ofertarían al precio que esperan que salga y no a su coste, así que el precio '
        'no bajaría y el despacho sería menos eficiente. La reforma europea de 2024 prefirió '
        'reforzar los contratos a plazo (PPAs y contratos por diferencias).',
  ),
  Pregunta(
    '¿Qué aprendimos del apagón del 28 de abril de 2025?',
    'Que un sistema con mucha electrónica de potencia necesita control de tensión dinámico, '
        'exigido y remunerado. No es un argumento contra las renovables, sino a favor de cambiar '
        'sus requisitos técnicos.',
  ),
  Pregunta(
    '¿Por qué son rentables las baterías en España?',
    'Por el diferencial entre el mediodía solar (a menudo 0 €) y la punta de la tarde. Cargan '
        'barato y venden caro, y al hacerlo estrechan ese mismo diferencial: cuantas más haya, '
        'menos gana cada una. También cobran por servicios de ajuste.',
    dia: 6, hora: 21, accion: 'Ver la punta de la tarde',
  ),
];

class PantallaAprende extends StatefulWidget {
  const PantallaAprende({super.key, required this.abrirSimulador, this.entrevista = false});

  /// Abre el simulador en un día y una hora.
  final void Function(int dia, int hora) abrirSimulador;

  /// Empieza en el modo entrevista en vez de en los conceptos.
  final bool entrevista;

  @override
  State<PantallaAprende> createState() => _PantallaAprendeState();
}

class _PantallaAprendeState extends State<PantallaAprende> {
  late bool _entrevista = widget.entrevista;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final selector = SegmentedButton<bool>(
      segments: const [
        ButtonSegment(value: false, label: Text('Conceptos'), icon: Icon(Icons.menu_book_outlined)),
        ButtonSegment(
            value: true, label: Text('Modo entrevista'), icon: Icon(Icons.record_voice_over_outlined)),
      ],
      selected: {_entrevista},
      onSelectionChanged: (v) => setState(() => _entrevista = v.first),
    );
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 820),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text('Cómo funciona el mercado eléctrico español', style: t.headlineSmall),
            const SizedBox(height: 12),
            Align(alignment: Alignment.centerLeft, child: selector),
            const SizedBox(height: 12),
            if (!_entrevista) ...[
              Text(
                'Trece ideas para entender de dónde sale el precio de la luz. '
                'Las que tienen un botón se pueden ver en el simulador con datos reales.',
                style: t.bodyMedium,
              ),
              const SizedBox(height: 16),
              for (final c in conceptos)
                _TarjetaDesplegable(
                  titulo: c.titulo,
                  resumen: c.resumen,
                  parrafos: c.parrafos,
                  accion: c.dia == null ? null : c.accion,
                  alPulsar: c.dia == null ? null : () => widget.abrirSimulador(c.dia!, c.hora!),
                ),
            ] else ...[
              Text(
                'Preguntas que salen en entrevistas de analista o trader de energía. '
                'Intenta responder en voz alta antes de abrir la respuesta: cada una cabe en tres frases.',
                style: t.bodyMedium,
              ),
              const SizedBox(height: 16),
              for (var i = 0; i < preguntas.length; i++)
                _TarjetaDesplegable(
                  titulo: '${i + 1}. ${preguntas[i].pregunta}',
                  resumen: 'Ver la respuesta',
                  parrafos: [preguntas[i].respuesta],
                  accion: preguntas[i].dia == null ? null : preguntas[i].accion,
                  alPulsar: preguntas[i].dia == null
                      ? null
                      : () => widget.abrirSimulador(preguntas[i].dia!, preguntas[i].hora!),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

class _TarjetaDesplegable extends StatelessWidget {
  const _TarjetaDesplegable({
    required this.titulo,
    required this.resumen,
    required this.parrafos,
    this.accion,
    this.alPulsar,
  });

  final String titulo, resumen;
  final List<String> parrafos;
  final String? accion;
  final VoidCallback? alPulsar;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        shape: const Border(),
        title: Text(titulo, style: t.titleMedium),
        subtitle: Text(resumen),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        expandedCrossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final p in parrafos)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(p, style: t.bodyMedium),
            ),
          if (alPulsar != null)
            FilledButton.tonalIcon(
              onPressed: alPulsar,
              icon: const Icon(Icons.play_arrow),
              label: Text(accion!),
            ),
        ],
      ),
    );
  }
}
