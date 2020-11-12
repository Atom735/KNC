import 'structs.dart';

extension LasExt on Las {
  /// Возвращает линию файла текстовой строкой.
  ///
  /// В случае если линии закончились, то возвращает строку с нулевым символом.
  String getLineString(int i) {
    if (i >= lines.length) {
      return '\u0000';
    }
    return lines[i].getLineString(this);
  }

  String get debugStringHead {
    final str = StringBuffer();
    str.writeln('==> VERS'.padRight(12) + '$vers');
    str.writeln('==> WRAP'.padRight(12) + '$wrap');
    str.writeln('==> WELL'.padRight(12) + '$well');
    return str.toString();
  }

  String get debugStringNotes {
    final str = StringBuffer();
    for (final note in notes) {
      str.writeln('==> ${note.debugString}');
    }
    return str.toString();
  }

  String get debugStringLines {
    final str = StringBuffer();
    var s = '';
    for (var i = 0; (s = getLineString(i)) != '\u0000'; i++) {
      str.writeln('==>(${(i + 1).toString().padLeft(8)}) $s');
      str.writeln(lines[i].getLineStringRaw(this));
    }
    return str.toString();
  }

  /// Получает отладочную информацию
  String get debugStringFull =>
      debugStringHead + debugStringNotes + debugStringLines;
}
