void Function(dynamic error, StackTrace stackTrace) getErrorFunc(
        final String txt) =>
    (error, StackTrace stackTrace) {
      print(txt);
      print(error);
      print('StackTrace:');
      print(stackTrace);
    };

enum KncError {
  /// 0
  exception,

  /// 1
  lasErrorsNotEmpty,

  /// 2
  lasAllDataNotCorrect,

  /// 3
  lasUnknownSection,

  /// 4
  parseNumber,

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

  /// 17
  inkTitleEnd,

  /// 18
  inkTitleWellCantGet,

  /// 19
  inkTitleAngleCantGet,

  /// 20
  inkCantGoToFirstTbl,

  /// 21
  inkUncorrectAngleType,

  /// 22
  inkUncorrectSecondTableSeparator,

  /// 23
  inkUncorrectTableColumnCount,

  /// 24
  inkCantGoToSecondTblData,

  /// 25
  inkArgumentNotTable,

  /// 26
  inkTableRowCount,
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

  /// 17
  r'Заголовок закончился без общих данных инклинометрии',

  /// 18
  r'Невозможно получить наименование скважины',

  /// 19
  r'Невозможно получить угол склонения',

  /// 20
  r'Невозможно приступить к разбору первой таблицы без корректных данных',

  /// 21
  r'Некорректный тип для значения градусов/минуты',

  /// 22
  r'Неожиданный разделитель для второй таблицы',

  /// 23
  r'Несовпадает количество столбцов',

  /// 24
  r'Неудалось установить в каких столбцах находятся данные',

  /// 25
  r'Аргумент функции не является таблицей',

  /// 26
  r'Количество строк в колонках таблицы несовпадает',
];

class ErrorOnLine {
  final int err;
  final int line;
  final String txt;

  ErrorOnLine(final KncError err, this.line, this.txt) : err = err.index;

  ErrorOnLine.fromJson(final dynamic json)
      : err = json['err'],
        line = json['line'],
        txt = json['txt'];
  dynamic toJson() => {
        'err': err,
        'line': line,
        'txt': txt ?? '',
      };
}
