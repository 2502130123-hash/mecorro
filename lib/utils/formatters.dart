/// Utilidades de formato (sin depender de intl).
class Formatters {
  Formatters._();

  static const _monthsShort = [
    'ene', 'feb', 'mar', 'abr', 'may', 'jun', 'jul', 'ago', 'sep', 'oct', 'nov', 'dic'
  ];
  static const _monthsLong = [
    'enero', 'febrero', 'marzo', 'abril', 'mayo', 'junio', 'julio', 'agosto',
    'septiembre', 'octubre', 'noviembre', 'diciembre'
  ];
  static const _weekdays = [
    'lunes', 'martes', 'miércoles', 'jueves', 'viernes', 'sábado', 'domingo'
  ];

  static String two(int n) => n.toString().padLeft(2, '0');

  /// 12345 -> "12,345"
  static String thousands(int n) {
    final s = n.abs().toString();
    final buffer = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buffer.write(',');
      buffer.write(s[i]);
    }
    return n < 0 ? '-$buffer' : buffer.toString();
  }

  /// 3725 -> "01:02:05"
  static String duration(int totalSeconds) {
    final h = totalSeconds ~/ 3600;
    final m = (totalSeconds % 3600) ~/ 60;
    final s = totalSeconds % 60;
    return '${two(h)}:${two(m)}:${two(s)}';
  }

  static String dateTime(DateTime d) =>
      '${d.day} ${_monthsShort[d.month - 1]} ${d.year} · ${two(d.hour)}:${two(d.minute)}';

  static String shortDate(DateTime d) => '${d.day} ${_monthsShort[d.month - 1]}';

  static String longDate(DateTime d) =>
      '${_weekdays[d.weekday - 1]}, ${d.day} de ${_monthsLong[d.month - 1]}';

  static String weekdayInitial(DateTime d) => _weekdays[d.weekday - 1][0].toUpperCase();

  /// Llave diaria para SharedPreferences: 2026-11-24
  static String dateKey(DateTime d) => '${d.year}-${two(d.month)}-${two(d.day)}';

  static double? parseDouble(String? text) =>
      double.tryParse((text ?? '').trim().replaceAll(',', '.'));

  /// 70.0 -> "70"   |   70.5 -> "70.5"
  static String number(double v) =>
      v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toStringAsFixed(1);
}