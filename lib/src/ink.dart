import 'package:knc/src/ink.g.dart';

extension IOneFileInkDataDocDebug on OneFileInkDataDoc {
  String getDebugString() {
    final str = StringBuffer();
    return str.toString();
  }
}

extension IOneFileInkDataDbfDebug on OneFileInkDataDbf {
  String getDebugString() {
    final str = StringBuffer();
    return str.toString();
  }
}

/// преобразует число из минут в доли градуса
/// - `1.30` в минутах => `1.50` в градусах
double /*?*/ convertAngleMinuts2Gradus(final double /*?*/ val) {
  if (val == null) {
    return null;
  }
  var v = (val % 1.0);
  return val + (v * 10.0 / 6.0) - v;
}

/// проверяет может ли число быть в минутах
bool maybeAngleInMinuts(final double val) => (val % 1.0) < 0.60;

class OneFileInkFin {}
