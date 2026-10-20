/// Formatos numéricos en español (coma decimal, punto de miles).
String euros(double v, {int decimales = 2}) {
  final s = v.toStringAsFixed(decimales);
  final partes = s.split('.');
  return partes.length == 1
      ? miles(partes[0])
      : '${miles(partes[0])},${partes[1]}';
}

String miles(String entero) {
  final negativo = entero.startsWith('-');
  final d = negativo ? entero.substring(1) : entero;
  final b = StringBuffer();
  for (var i = 0; i < d.length; i++) {
    if (i > 0 && (d.length - i) % 3 == 0) b.write('.');
    b.write(d[i]);
  }
  return '${negativo ? '-' : ''}$b';
}

String gw(double mw) => '${euros(mw / 1000, decimales: 1)} GW';

String hora(int h) => '${h.toString().padLeft(2, '0')}:00';

const meses = [
  'enero', 'febrero', 'marzo', 'abril', 'mayo', 'junio', 'julio', 'agosto',
  'septiembre', 'octubre', 'noviembre', 'diciembre'
];

String fechaLarga(DateTime f) => '${f.day} de ${meses[f.month - 1]} de ${f.year}';
