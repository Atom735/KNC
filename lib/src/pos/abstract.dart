class AbstractPosBase {
  /// Контейнер данных
  final dynamic data;

  /// Номер символа
  int s = 0;

  /// Номер строки
  int l = 0;

  /// Номер стобца
  int c = 0;

  AbstractPosBase(this.data, [this.s = 0, this.l = 0, this.c = 0]);

  @override
  String toString() => '[${l + 1}:${c + 1}]';
}

abstract class AbstractPos extends AbstractPosBase {
  AbstractPos(data, [int s = 0, int l = 0, int c = 0]) : super(data, s, l, c);

  /// Возвращает расстояние между двумя указателями
  AbstractPosBase distance(final AbstractPos _) =>
      AbstractPosBase(data, _.s - s, _.l - l, _.c - c);

  /// Предудыщий символ
  ///
  /// Возвращает `-1` если невозможно получить символ
  dynamic get prev;

  /// Следующий символ
  ///
  /// Возвращает `-1` если невозможно получить символ
  dynamic get next;

  /// Настоящий символ, куда указывает указатель
  ///
  /// Возвращает `-1` если невозможно получить символ
  dynamic get symbol;

  /// Получить символ который находится на отступе
  ///
  /// Возвращает пустую строку если невозможно получить символ
  dynamic symbolAt(final int i);

  /// Количество символов в контейнере
  int get dataLength;

  /// Возвращает подстроку длины [_len]
  dynamic substring(final int _len);

  /// Переход к следующему символу, возвращает этот следующий символ
  dynamic nextSymbol();

  /// Пропуск [_i] символов, возвращает символ находящийся на расстоянии [_i]
  /// символов от настоящего
  dynamic skipSymbolsCount(final int _i);

  /// Пропуск пробелов, возвращает первый непробельный символ
  dynamic skipWhiteSpaces();

  /// Пропуск пробелов до новой линии, возвращает первый непробельный символ,
  /// либо символ новой строки
  dynamic skipWhiteSpacesOrToEndOfLine();

  /// Переход к концу линии
  void skipToEndOfLine();

  /// Переход к следующей линии, возвращает первый символ линии
  dynamic skipToNextLine();
}
