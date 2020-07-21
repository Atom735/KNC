enum KncError {
  /// 0
  ok,

  /// 1
  lasErrorsNotEmpty,

  /// 2
  lasAllDataNotCorrect,

  /// 3
  lasUnknownSection,

  /// 4
  lasNumberParseError,

  /// 5
  lasTooManyNumbers,

  /// 6
  lasSectionIsNull,

  /// 7
  lasHaventDot,

  /// 8
  lasHaventDoubleDot,

  /// 9
  lasHaventSpaceAfterDot,

  /// 10
  lasVersionError,

  /// 11
  lasLineWarpError,

  /// 12
  lasUncknownMnemInVSection,

  /// 13
  lasUncorrectNumber,

  /// 14
  lasCantGetWell,

  /// 15
  lasDotAfterDoubleDot,

  /// 16
  lasEmptyData,
}

const kncErrorStrings = [
  /// 0
  null,

  /// 1
  r'Невозможно перейти к разбору ASCII данных с ошибками',

  /// 2
  r'Не все данные корректны для продолжения парсинга',

  /// 3
  r'Неизвестная секция',

  /// 4
  r'Ошибка в разборе числа',

  /// 5
  r'Слишком много чисел в линии',

  /// 6
  r'Отсутсвует секция',

  /// 7
  r'Отсутсвует точка',

  /// 8
  r'Отсутсвует двоеточие',

  /// 9
  r'После точки должен быть пробел',

  /// 10
  r'Ошибка в версии файла',

  /// 11
  r'Ошибка в значении многострочности',

  /// 12
  r'Неизвестная мнемоника в секции ~V',

  /// 13
  r'Некорректное число',

  /// 14
  r'Невозможно получить номер скважины по полю WELL',

  /// 15
  r'Точка найдена после двоеточия',

  /// 16
  r'Отсутвуют данные',
];

class ErrorOnLine {
  final int err;
  final int line;
  final String txt;

  ErrorOnLine(final KncError err, this.line, this.txt) : err = err.index;
}
