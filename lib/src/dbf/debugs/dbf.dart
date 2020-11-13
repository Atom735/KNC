import '../structs.dart';
import 'field.dart';
import 'record.dart';

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
