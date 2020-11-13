import 'dart:convert';
import 'dart:typed_data';

import '../pos/index.dart';
import '../mymath.dart';

class LasLineWithMnem extends LasLine {
  final Uint8List mnemUnit;
  final Uint8List mnemData;
  final Uint8List mnemDesc;

  LasLineWithMnem(Uint8List data, Uint8List mnem, this.mnemUnit, this.mnemData,
      this.mnemDesc)
      : super.a(data, mnem);
}

class LasLine {
  /// Сырые данные линии
  final Uint8List data;

  /// Мнемоника линии
  /// - `` - Пустая строка
  /// - `#` - комментарий
  /// - `~{S}` - начало секции
  /// - `~~O` - из секции `Other`
  /// - `~~A` - из секции `Ascii`
  /// - `~~{S}` - из секции незивестного типа
  /// - `{S}{MNEM}` - Мнемоника, где первый символ символ секции
  final Uint8List mnem;

  LasLine.a(this.data, this.mnem);

  /// Возвращает строку в текстовом представлении
  String getLineString(final Las las) {
    return getLineStringRaw(las);
  }

  /// Возвращает сырую строку в текстовом представлении
  String getLineStringRaw(final Las las) => las.encoding.decode(data);

  factory LasLine(final BytePos p, final int i0, final int sec, final int ver,
      final List<TxtNote> notes) {
    final data = Uint8List.sublistView(p.data, i0, p.s);
    final _l = p.s - i0;
    final pLine = BytePos.copy(p)
      ..s = 0
      ..c -= _l;
    final _p = BytePos(data);
    final _b = _p.skipWhiteSpacesOrToEndOfLine();
    // Если конец символа, то строка пустая
    if (_b == -1) {
      return LasLine.a(data, Uint8List(0));
    }
    // Если символ начала секции
    // ~
    if (_b == 0x7E && _p.next != -1) {
      return LasLine.a(
          data, Uint8List.fromList([0x7E, byteAlphaToUpperCase(_p.next)]));
    }
    // Если символ начала комментария
    // #
    if (_b == 0x23) {
      return LasLine.a(data, Uint8List.fromList([0x23]));
    }
    // Оставляем обработку на потом
    // A || O && !V && !W && !P && !C
    if (((sec == 0x41 || sec == 0x4F) ||
        (sec != 0x56 && sec != 0x57 && sec != 0x50 && sec != 0x43))) {
      return LasLine.a(data, Uint8List.fromList([0x7E, 0x7E, sec]));
    }

    final _iPoint = _p.data.indexOf(0x2E);
    if (_iPoint == -1) {
      notes.add(TxtNote.error(pLine, 'Отсутсвует точка в строке', _l));
      return LasLine.a(data, Uint8List.fromList([0x7E, 0x7E, sec]));
    }
    final _iSpace = _p.data.indexOf(0x20, _iPoint + 1);
    if (_iSpace == -1) {
      notes.add(TxtNote.error(pLine, 'Отсутсвует пробел после точки', _l));
      return LasLine.a(data, Uint8List.fromList([0x7E, 0x7E, sec]));
    }
    final _iPoint2 = ver == 0
        ? _p.data.indexOf(0x3A, _iSpace + 1)
        : _p.data.lastIndexOf(0x3A);
    if (_iPoint2 < _iSpace) {
      notes.add(TxtNote.error(pLine, 'Отсутсвует двоеточкие после точки', _l));
      return LasLine.a(data, Uint8List.fromList([0x7E, 0x7E, sec]));
    }

    return LasLineWithMnem(
      data,
      Uint8List.fromList([sec, ...bytesTrim(_p.substring(_iPoint - _p.s))]),
      bytesTrim(Uint8List.sublistView(_p.data, _iPoint + 1, _iSpace)),
      bytesTrim(Uint8List.sublistView(_p.data, _iSpace, _iPoint2)),
      bytesTrim(Uint8List.sublistView(_p.data, _iPoint2 + 1)),
    );
  }
}

class Las {
  final Uint8List data;
  final List<LasLine> lines;
  final Encoding encoding;
  final String lineFeed;
  final List<TxtNote> notes;

  final String well;
  final int vers;
  final bool wrap;
  final List<String> curvesNames;

  Las._(this.data, this.lines, this.encoding, this.lineFeed, this.notes,
      this.well, this.vers, this.wrap, this.curvesNames);

  factory Las(Uint8List data) {
    final _p = BytePos(data);
    final _encoding = _p.getEncoding();
    final p = BytePos(data);
    final lines = <LasLine>[];
    final notes = <TxtNote>[];
    var i0 = 0;
    var sec = 0;
    var _ver = true;
    var ver = 0;
    var _wrap = true;
    var wrap = false;
    var _well = true;
    var well = '';
    var asciiBeginIndex = -1;
    final nums = <double>[];
    var curvesNames = <String>[];
    var wNull = -999.0;
    var _wNull = true;
    final _qErr = 0.0001;

    while ((p..skipToEndOfLine()).symbol != -1) {
      final line = LasLine(p, i0, sec, ver, notes);
      final mnem = line.mnem;

      /// ~~
      if (mnem.length >= 2 && mnem[0] == 0x7E && mnem[1] != 0x7E) {
        sec = mnem[1];
      }

      /// VVERS
      if (_ver &&
          line is LasLineWithMnem &&
          mnem.length == 5 &&
          mnem[0] == 0x56 &&
          byteAlphaToUpperCase(mnem[1]) == 0x56 &&
          byteAlphaToUpperCase(mnem[2]) == 0x45 &&
          byteAlphaToUpperCase(mnem[3]) == 0x52 &&
          byteAlphaToUpperCase(mnem[4]) == 0x53) {
        if (line.mnemUnit.isNotEmpty) {
          ver = line.mnemUnit[0] - 0x30;
        } else if (line.mnemData.isNotEmpty) {
          ver = line.mnemData[0] - 0x30;
        }
        _ver = false;
      }

      /// VWRAP
      if (_wrap &&
          line is LasLineWithMnem &&
          mnem.length == 5 &&
          mnem[0] == 0x56 &&
          byteAlphaToUpperCase(mnem[1]) == 0x57 &&
          byteAlphaToUpperCase(mnem[2]) == 0x52 &&
          byteAlphaToUpperCase(mnem[3]) == 0x41 &&
          byteAlphaToUpperCase(mnem[4]) == 0x50) {
        if (line.mnemUnit.isNotEmpty) {
          wrap = line.mnemUnit[0] == 0x59 || line.mnemUnit[0] == 0x79;
        } else if (line.mnemData.isNotEmpty) {
          wrap = line.mnemData[0] == 0x59 || line.mnemData[0] == 0x79;
        }
        _wrap = false;
      }

      /// WWELL
      if (_well &&
          line is LasLineWithMnem &&
          mnem.length == 5 &&
          mnem[0] == 0x57 &&
          byteAlphaToUpperCase(mnem[1]) == 0x57 &&
          byteAlphaToUpperCase(mnem[2]) == 0x45 &&
          byteAlphaToUpperCase(mnem[3]) == 0x4C &&
          byteAlphaToUpperCase(mnem[4]) == 0x4C) {
        well = ver == 2
            ? _encoding.decode(line.mnemData)
            : _encoding.decode(line.mnemDesc);
        _well = false;
      }

      /// WNULL
      if (_well &&
          line is LasLineWithMnem &&
          mnem.length == 5 &&
          mnem[0] == 0x57 &&
          byteAlphaToUpperCase(mnem[1]) == 0x4E &&
          byteAlphaToUpperCase(mnem[2]) == 0x55 &&
          byteAlphaToUpperCase(mnem[3]) == 0x4C &&
          byteAlphaToUpperCase(mnem[4]) == 0x4C) {
        wNull = double.tryParse(_encoding.decode(line.mnemData)) ?? double.nan;
        _wNull = false;
      }

      /// ~~A
      if (asciiBeginIndex == -1 &&
          mnem.length >= 3 &&
          mnem[0] == 0x7E &&
          mnem[1] == 0x7E &&
          mnem[2] == 0x41) {
        asciiBeginIndex = lines.length;
      }

      if (asciiBeginIndex != -1 &&

          /// ~~A
          !(mnem.length >= 3 &&
              mnem[0] == 0x7E &&
              mnem[1] == 0x7E &&
              mnem[2] == 0x41) &&

          /// ~A
          !(mnem.length == 2 && mnem[0] == 0x7E && mnem[1] == 0x41) &&

          /// #
          !(mnem.length == 1 && mnem[0] == 0x23) &&
          mnem.isNotEmpty) {
        break;
      }

      /// ~~C
      if (line is LasLineWithMnem && mnem.isNotEmpty && mnem[0] == 0x43) {
        curvesNames.add(_encoding.decode(mnem).substring(1));
      }

      lines.add(line);
      p.skipToNextLine();
      i0 = p.s;
    }
    lines.add(LasLine(p, i0, sec, ver, notes));
    final _lLines = lines.length;
    if (asciiBeginIndex != -1) {
      if (wrap == false) {
        for (var i = asciiBeginIndex; i < _lLines; i++) {
          final line = lines[i];
          final mnem = line.mnem;

          /// ~~A
          if (mnem.length >= 3 &&
              mnem[0] == 0x7E &&
              mnem[1] == 0x7E &&
              mnem[2] == 0x41) {
            final lineNums = (String.fromCharCodes(line.data).split(' ')
                  ..removeWhere((e) => e.isEmpty))
                .map((e) => double.tryParse(e) ?? double.nan)
                .toList(growable: false);
            if (lineNums.length == curvesNames.length) {
              nums.addAll(
                  lineNums.map((e) => doubleEqual(e, wNull) ? double.nan : e));
            } else {}
          }
        }
      }
    }

    return Las._(data, lines, _encoding, _p.getLineFeed(), notes, well, ver,
        wrap, curvesNames);
  }

  static bool validate(Uint8List data) {
    final _l = data.lengthInBytes;
    if (_l <= 32) {
      return false;
    }
    var bV = false;
    var bW = false;
    var bC = false;
    var bA = false;
    for (var i = 0; i < _l - 1; i++) {
      final _i = data[i];
      // Если нашли управляющий символ ASCII, то это не текстовый файл
      // и соответсвенно он не может быть корректным LAS файлом
      if ((_i < 0x20 && _i != 0x09 && _i != 0x0A && _i != 0x0D) || _i == 0x7F) {
        return false;
      }
      // Так-же пытаемся обнаружить начала секций
      if (_i == 0x7E) {
        final _i2 = data[i + 1];
        bV |= _i2 == 0x56 || _i2 == 0x76;
        bW |= _i2 == 0x57 || _i2 == 0x77;
        bC |= _i2 == 0x43 || _i2 == 0x63;
        bA |= _i2 == 0x41 || _i2 == 0x61;
      }
    }
    // Это LAS файл если секции были обнаружены
    return bV && bW && bC && bA;
  }
}
