import 'dart:math';

import 'structs.dart';

extension DbfExt on Dbf {
  /// Получает отладочную информацию
  String get debugString {
    final str = StringBuffer();
    str.writeln('Сигнатура:'.padRight(32) + '($signature) $signatureName');
    str.writeln('Последняя модификация:'.padRight(32) +
        '$lastUpdateDD.$lastUpdateMM.$lastUpdateYY');
    str.writeln('Количество записей:'.padRight(32) + '$numberOfRecords');
    str.writeln('Длина заголовка:'.padRight(32) + '$lengthOfHeader');
    str.writeln('Длина одной записи:'.padRight(32) + '$lengthOfEachRecord');
    str.writeln('Зарезервировано (всегда 0)'.padRight(32) + '$r12');
    str.writeln(
        'Незавершенная транзакция:'.padRight(32) + '$incompleteTransac');
    str.writeln('Флаг шифрования таблицы:'.padRight(32) + '$ecryptionFlag');
    str.writeln('Зарезервированная область:'.padRight(32) + '$r16');
    str.writeln('Зарезервированная область:'.padRight(32) + '$r20');
    str.writeln('Зарезервированная область:'.padRight(32) + '$r24');
    str.writeln('Флаг MDX-файла:'.padRight(32) + '$mdxFlag');
    str.writeln('Кодовая страница:'.padRight(32) +
        '($laguageDriverId) $laguageDriverIdName');
    str.writeln('Зарезервировано (всегда 0):'.padRight(32) + '$r30');
    return str.toString();
  }

  String get debugStringFields {
    final str = StringBuffer();
    str.writeln(''.padRight(64, '-'));
    for (var field in fields) {
      str.write(field.debugString);
      str.writeln(''.padRight(64, '-'));
    }
    return str.toString();
  }

  String get debugStringRecords {
    if (records.isEmpty) {
      return '';
    }
    final str = StringBuffer();
    str.writeln(''.padRight(64, '='));
    str.writeln(records.first.debugString(fields, true));
    for (var record in records) {
      str.writeln(record.debugString(fields));
    }
    str.writeln(''.padRight(64, '='));
    return str.toString();
  }

  String get debugStringFull =>
      debugString + debugStringFields + debugStringRecords;
}

extension DbfFieldExt on DbfField {
  /// Получает отладочную информацию
  String get debugString {
    final str = StringBuffer();
    str.writeln('Имя поля:'.padRight(32) + '$name');
    str.writeln('Тип поля:'.padRight(32) + '$type - $typeName');
    str.writeln('Смещение поля в записи:'.padRight(32) + '$address');
    str.writeln('Полная длина поля:'.padRight(32) + '$length');
    str.writeln('Число десятичных разрядов:'.padRight(32) + '$decimalCount');
    str.writeln(
        'Field flags:'.padRight(32) + flags.toRadixString(16).padLeft(2, '0'));
    // str.writeln(
    //     'Autoincrement Next value:'.padRight(32) + '$autoincrementNextVal');
    // str.writeln(
    //     'Autoincrement Step value:'.padRight(32) + '$autoincrementStepVal');
    // str.writeln('Зарезервировано:'.padRight(32) + '$r24');
    // str.writeln('Зарезервировано:'.padRight(32) + '$r28');
    return str.toString();
  }
}

extension DbfRecordExt on DbfRecord {
  String debugString(final List<DbfField> fields, [bool head = false]) {
    final str = StringBuffer();
    final _filedsLength = fields.length;
    if (head) {
      str.write('#');
      for (var i = 0; i < _filedsLength; i++) {
        str.write('|' +
            fields[i]
                .name
                .padRight(max(fields[i].name.length, fields[i].length)));
      }
    } else {
      str.write(String.fromCharCode(byteData.getUint8(0)));
      for (var i = 0; i < _filedsLength; i++) {
        final _type = fields[i].type;
        switch (_type) {
          case 'N':
            str.write('|' +
                (value(fields[i]) as double)
                    .toStringAsFixed(fields[i].decimalCount)
                    .padRight(max(fields[i].name.length, fields[i].length)));
            break;
          default:
            str.write('|' +
                value(fields[i])
                    .toString()
                    .padRight(max(fields[i].name.length, fields[i].length)));
        }
      }
    }

    return str.toString();
  }
}
