import 'structs.dart';

extension LasCurveExt on LasCurve {
  String get debugString =>
      '$name : from strt [$strt] to stop [$stop] with step [$step] ($length.$precison)';
}

extension LasLineAsciiExt on LasLineAscii {
  String rewrited(double nan) {
    final str = StringBuffer();
    final _l = values.length;

    for (var i = 0; i < _l; i++) {
      str.write((values[i].isFinite ? values[i] : nan)
          .toStringAsFixed(precison[i])
          .padLeft(length[i] + precison[i] + 2));
    }

    return str.toString();
  }
}

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
    str.writeln('==> NULL'.padRight(12) + '$wNull');
    return str.toString();
  }

  String get debugStringCurves {
    final str = StringBuffer();
    for (var curve in curves) {
      str.writeln('==> ~C ${curve.debugString}$lineFeed');
    }
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
      debugStringHead + debugStringNotes + debugStringCurves + debugStringLines;

  String getViaString(
      {String /*?*/ lineFeed,
      bool rewriteAscii = false,
      bool addComments = false,
      bool deleteEmptyLines = false}) {
    lineFeed ??= this.lineFeed;
    final str = StringBuffer();
    if (addComments) {
      str.write('# Modifided By Atom735$lineFeed');
      for (var note in notes) {
        str.write('# ${note.debugString}$lineFeed');
      }
      for (var curve in curves) {
        str.write('# ~C ${curve.debugString}$lineFeed');
      }
    }
    final _l = lines.length;
    for (var i = 0; i < _l; i++) {
      final line = lines[i];
      if (line.mnem.isEmpty && deleteEmptyLines) {
        continue;
      }
      if (line is LasLineAscii && rewriteAscii) {
        str.write('${line.rewrited(wNull)}$lineFeed');
      } else {
        str.write('${line.getLineString(this)}$lineFeed');
      }
    }

    return str.toString();
  }
}
