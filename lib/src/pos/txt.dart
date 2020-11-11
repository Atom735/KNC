import 'abstract.dart';

/// Контейнер текста
class TxtCntainer {
  /// Указатель на данные
  final String data;

  /// Длина данных
  final int length;

  TxtCntainer(this.data) : length = data.length;
}

/// Указатель позиции текста
class TxtPos extends AbstractPos {
  /// Контейнер текста
  @override
  final TxtCntainer data;

  /// Создаёт указатель из контенера и перемещает его на [i] символов вперёд
  TxtPos(this.data, [final int i = 0]) : super(data) {
    skipSymbolsCount(i);
  }

  /// Создаёт указатель
  TxtPos.a(this.data, [int s = 0, int l = 0, int c = 0]) : super(data, s, l, c);

  /// Создаёт копию указателя из другого указателя
  factory TxtPos.copy(final TxtPos _) => TxtPos.a(_.data, _.s, _.l, _.c);

  /// Предудыщий символ
  ///
  /// Возвращает пустую строку если невозможно получить символ
  @override
  String get prev => s >= 1 ? data.data[s - 1] : '';

  /// Следующий символ
  ///
  /// Возвращает пустую строку если невозможно получить символ
  @override
  String get next => s < dataLength - 1 ? data.data[s + 1] : '';

  /// Настоящий символ, куда указывает указатель
  ///
  /// Возвращает пустую строку если невозможно получить символ
  @override
  String get symbol => s < dataLength ? data.data[s] : '';

  /// Получить символ который находится на отступе
  ///
  /// Возвращает пустую строку если невозможно получить символ
  @override
  String symbolAt(final int i) =>
      s + i < dataLength && s + i >= 0 ? data.data[s + i] : '';

  /// Количество символов в контейнере
  @override
  int get dataLength => data.length;

  /// Возвращает подстроку длины [_len]
  @override
  String substring(final int _len) => data.data.substring(s, s + _len);

  /// Переход к следующему символу, возвращает этот следующий символ
  @override
  String nextSymbol() {
    if (symbol == null) {
      return null;
    }
    s++;
    c++;
    final _s = symbol;
    if (_s.isEmpty) {
      return _s;
    } else if (_s == '\n' || _s == '\r') {
      l++;
      c = -1;
      if (s >= 1 && _s == '\n' && prev == '\r') {
        // коррекция на Windows перевод строки
        l--;
      }
    }
    return _s;
  }

  /// Пропуск [_i] символов, возвращает символ находящийся на расстоянии [_i]
  /// символов от настоящего
  @override
  String skipSymbolsCount(final int _i) {
    var _s = symbol;
    for (var i = 0; i < _i && _s.isNotEmpty; ++i) {
      _s = nextSymbol();
    }
    return _s;
  }

  /// Пропуск всех символов содержащихся в [_a], возвращает первый символ не из
  /// [_a]
  String skipSymbolsInString(final String _a) {
    var _s = symbol;
    while (_a.contains(_s)) {
      _s = nextSymbol();
    }
    return _s;
  }

  /// Пропуск всех символов не содержащихся в [_a], возвращает первый
  /// встретившийся символ из [_a]
  String skipSymbolsOutString(final String _a) {
    var _s = symbol;
    while (_s.isNotEmpty && !_a.contains(_s)) {
      _s = nextSymbol();
    }
    return _s;
  }

  /// Пропуск пробелов, возвращает первый непробельный символ
  @override
  String skipWhiteSpaces() {
    var _s = symbol;
    while (_s.isNotEmpty &&
        (_s == ' ' || _s == '\t' || _s == '\n' || _s == '\r')) {
      _s = nextSymbol();
    }
    return _s;
  }

  /// Пропуск пробелов до новой линии, возвращает первый непробельный символ,
  /// либо символ новой строки
  @override
  String skipWhiteSpacesOrToEndOfLine() {
    var _s = symbol;
    while (_s.isNotEmpty && (_s == ' ' || _s == '\t')) {
      _s = nextSymbol();
    }
    return _s;
  }

  /// Переход к концу линии
  @override
  void skipToEndOfLine() {
    var _s = symbol;
    while (_s.isNotEmpty && _s != '\n' && _s != '\r') {
      _s = nextSymbol();
    }
  }

  /// Переход к следующей линии, возвращает первый символ линии
  @override
  String skipToNextLine() {
    skipToEndOfLine();
    var _s = nextSymbol();
    // Если перевод строки как в Windows, то пропускаем второй символ
    if (_s == '\n' && prev == '\r') {
      return nextSymbol();
    }
    return _s;
  }
}
