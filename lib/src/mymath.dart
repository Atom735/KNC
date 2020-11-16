/// Получить среднее арефметическое списка значений
double getMiddleArithmetic(final List<double> _list) {
  var _o = 0.0;
  final _l = _list.length;
  for (var i = 0; i < _l; i++) {
    _o += (_list[i] - _o) / (i + 1).toDouble();
  }
  return _o;
}

/// Возвращает абсолютное значение
double doubleAbs(final double a) => a < 0.0 ? -a : a;

/// Возвращает равенство с погрешностью
bool doubleEqual(final double a, final double b,
        [final double _err = 0.0001]) =>
    doubleAbs(a - b) <= _err;

/// Получает шаг значение в списке
///
/// `0.0` - в случае если шаг не постоянный
double getStepOfList(final List<double> _list, [final double _q = 0.00000001]) {
  /// Создаём подсисок со значением разницы между соседними элементами
  /// родительского списка
  final _subList = _list.sublist(1);
  final _l = _subList.length;
  for (var i = 0; i < _l; i++) {
    _subList[i] -= _list[i];
  }

  /// ПОлучаем среднюю разность
  final _m = -getMiddleArithmetic(_subList);
  final _q2 = -_q;

  /// Сравниваем среднюю разность с разностью в списке, с допуском ошибки [_q]
  for (var i = 0; i < _l; i++) {
    final _f = _subList[i] + _m;
    if (_f >= _q || _f <= _q2) {
      return 0.0;
    }
  }
  return -_m;
}

/// преобразует число из минут в доли градуса
/// - `1.30` в минутах => `1.50` в градусах
double convertAngleMinuts2Gradus(final double val) {
  if (!val.isFinite) {
    return val;
  }
  var v = (val % 1.0);
  return val + (v * 10.0 / 6.0) - v;
}

/// проверяет может ли число быть в минутах
bool maybeAngleInMinuts(final double val) =>
    !val.isFinite || (val % 1.0) < 0.60;
