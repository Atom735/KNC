import 'package:knc/knc.dart';
import 'package:xml/xml.dart';
import 'package:xml/xml_events.dart';
import 'dart:io';
import 'package:path/path.dart' as p;

import 'TaskIso.dart';

/// преобразует число из минут в доли градуса
/// - `1.30` в минутах => `1.50` в градусах
double convertAngleMinuts2Gradus(final double val) {
  var v = (val % 1.0);
  return val + (v * 10.0 / 6.0) - v;
}

/// Возвращает разобраный тип данных угла
/// - `true` - минуты
/// - `false` - градусы
/// - `null` - неудалось разобрать
bool /*?*/ parseAngleType(final String txt) {
  // 11.30 град'мин.
  var k = txt.indexOf("'");
  if (k == -1) {
    return null;
  }
  switch (txt[k + 1].toLowerCase()) {
    case 'м':
      return true;
    case 'г':
      return false;
    default:
      return null;
  }
}

final list = <String>[];

Future<JOneFileData /*?*/ > parserFileDocx(
    final TaskIso kncTask, final JOneFileData fileData, final String data,
    {final Map<String, String> mapWells = const {},
    final Map<String, String> mapCurves = const {}}) async {
  final _notes = <JOneFileLineNote>[];
  final document = XmlDocument.parse(data);

  var bNewLine = true;
  var iSymbol = 0;
  var iLine = 1;
  var iColumn = 1;

  var _noteWarnings = 0;
  var _noteErrors = 0;

  void _addNoteError(final String _text, [final String /*?*/ _data]) {
    _notes.add(JOneFileLineNote.error(iLine, iColumn, _text, _data));
    _noteErrors++;
  }

  void _addNoteWarning(final String _text, [final String /*?*/ _data]) {
    _notes.add(JOneFileLineNote.warn(iLine, iColumn, _text, _data));
    _noteWarnings++;
  }

  void _addNoteParsed(final List<String> _text, [final String /*?*/ _data]) {
    _notes.add(JOneFileLineNote.parse(
        iLine, iColumn, _text.join(msgRecordSeparator), _data));
  }

  // File('test.xml').writeAsStringSync(document.toString());
  final text = document.innerText.toLowerCase();
  var raiting = 0;
  if (text.contains('утверждаю')) {
    raiting += 1;
  }
  if (text.contains('инклинометрия')) {
    raiting += 5;
  }
  if (text.contains('замер кривизны')) {
    raiting += 5;
  }
  if (text.contains('заказчик')) {
    raiting += 3;
  }
  if (text.contains('скважина n')) {
    raiting += 10;
  }
  if (text.contains('площадь')) {
    raiting += 3;
  }
  if (text.contains('диаметр')) {
    raiting += 3;
  }
  if (text.contains('глубина')) {
    raiting += 8;
  }
  if (text.contains('угол')) {
    raiting += 8;
  }
  if (text.contains('альтитуда')) {
    raiting += 3;
  }
  if (text.contains('забой')) {
    raiting += 3;
  }
  if (text.contains('азимут')) {
    raiting += 8;
  }
  if (text.contains('удлинение')) {
    raiting += 3;
  }
  if (text.contains('смещение')) {
    raiting += 3;
  }

  if (raiting >= 35) {
    final _fName = p.basenameWithoutExtension(fileData.origin);
    final _fExt = p.extension(fileData.path);
    var newName = '$_fName$_fExt';
    var j = 0;
    while (list.contains(newName)) {
      newName = '${_fName}_$j$_fExt';
      j += 1;
    }

    final path = p.join('.ignore', 'test', newName);

    File(fileData.path).copySync(path);
    File(path + '.xml').writeAsStringSync(data);

    var xmlParagraphCount = 0;
    var xmlParagraph = '';
    var oWell = '';
    var oSquare = '';
    var oDiametr = '';
    var oDepth = '';
    var oAngleTxt = '';
    num oAngleN;
    bool oAngleM;
    var oAltitude = '';
    var oZaboy = '';

    void setAngleTxt(String txt) {
      oAngleTxt = txt;
      oAngleM = parseAngleType(txt);
      if (oAngleM == null) {
        _addNoteError('Некорректный тип угла', txt);
      } else {
        var i0 = 0;
        i0 = txt.indexOf(' ');
        if (i0 == -1) {
          i0 = txt.indexOf('г');
        }
        if (i0 == -1) {
          oAngleN = double.tryParse(txt);
        } else {
          oAngleN = double.tryParse(txt.substring(0, i0));
        }
        if (oAngleN == null) {
          _addNoteError('Неполучилось разобрать число угла', txt);
        } else if (oAngleM) {
          oAngleN = convertAngleMinuts2Gradus(oAngleN.toDouble());
        }
      }
    }

    bool parseBodyPararaph() {
      final line = xmlParagraph;
      if (line.startsWith(r'Скважина')) {
        var i0 = line.indexOf(r'N', 8);
        if (i0 == -1) {
          iLine = xmlParagraphCount;
          _addNoteError('Невозможно получить номер скважины');
          return true;
        }
        var i1 = line.indexOf(r'Площадь', i0);
        if (i1 == -1) {
          oWell = line.substring(i0 + 1).trim();
          return false;
        }
        oWell = line.substring(i0 + 1, i1).trim();
        var i2 = line.indexOf(r':', i1 + 7);
        if (i2 == -1) {
          return false;
        }
        oSquare = line.substring(i2 + 1).trim();
        return false;
      } else if (line.startsWith(r'Диаметр')) {
        var i0 = line.indexOf(r':', 8);
        if (i0 == -1) {
          return false;
        }
        var i1 = line.indexOf(r'Глубина', i0 + 1);
        if (i1 == -1) {
          oDiametr = line.substring(i0 + 1).trim();
          return false;
        }
        oDiametr = line.substring(i0 + 1, i1).trim();
        var i2 = line.indexOf(r':', i0 + 1);
        if (i2 == -1) {
          return false;
        }
        oDepth = line.substring(i2 + 1).trim();
      } else if (line.startsWith(r'Угол')) {
        var i0 = line.indexOf(r':', 8);
        if (i0 == -1) {
          iLine = xmlParagraphCount;
          _addNoteError('Невозможно разобрать угол склонения');
          return true;
        }
        var i1 = line.indexOf(r'Альтитуда', i0 + 1);
        if (i1 == -1) {
          setAngleTxt(line.substring(i0 + 1).trim());
          if (oAngleN == null) {
            _addNoteError('Невозможно разобрать угол склонения');
            return true;
          }
          return false;
        }
        setAngleTxt(line.substring(i0 + 1, i1).trim());
        if (oAngleN == null) {
          _addNoteError('Невозможно разобрать угол склонения');
          return true;
        }
        var i2 = line.indexOf(r':', i0 + 1);
        if (i2 == -1) {
          return false;
        }
        var i3 = line.indexOf(r'Забой', i2 + 1);
        if (i3 == -1) {
          oAltitude = line.substring(i2 + 1).trim();
          return false;
        }
        oAltitude = line.substring(i2 + 1, i3).trim();
        var i4 = line.indexOf(r':', i2 + 1);
        if (i4 == -1) {
          return false;
        }
        oZaboy = line.substring(i4 + 1).trim();
      }
      return false;
    }

    bool Function(XmlEvent) funcParse;
    bool Function(XmlEvent) funcParseBody;

    bool parseTbl1(XmlEvent e) {
      if (e is XmlEndElementEvent) {
        if (e.name == 'w:tbl') {
          funcParse = funcParseBody;
        }
      }
      return false;
    }

    var tbl2RowCount = 0;
    var tbl2CellCount = 0;

    var tbl2Head = <String>[];
    var tbl2_oDepth = -1;
    var tbl2_oAngle = -1;
    var tbl2_oAzimuth = -1;
    bool tbl2_oAngleM;
    bool tbl2_oAzimuthM;
    final tbl2_Depth = <num>[];
    final tbl2_Angle = <num>[];
    final tbl2_Azimuth = <num>[];

    bool parseTbl2Paragraph() {
      if (tbl2RowCount == 1) {
        if (tbl2Head.length < tbl2CellCount) {
          tbl2Head.length = tbl2CellCount;
        }
        tbl2Head[tbl2CellCount - 1] = xmlParagraph;
        if (tbl2_oDepth < 0 && xmlParagraph.contains('Глубина')) {
          tbl2_oDepth = tbl2CellCount - 1;
        } else if (tbl2_oAngle < 0 && xmlParagraph.contains('Угол')) {
          tbl2_oAngle = tbl2CellCount - 1;
          tbl2_oAngleM = parseAngleType(xmlParagraph);
          if (tbl2_oAngleM == null) {
            _addNoteError(
                'Некорректный тип угла в загаловке таблицы', xmlParagraph);
          }
        } else if (tbl2_oAzimuth < 0 && xmlParagraph.contains('Азимут')) {
          tbl2_oAzimuth = tbl2CellCount - 1;
          tbl2_oAzimuthM = parseAngleType(xmlParagraph);
          if (tbl2_oAzimuthM == null) {
            _addNoteError(
                'Некорректный тип угла в загаловке таблицы', xmlParagraph);
          }
        }
      } else if (tbl2RowCount == 2) {
        if (tbl2CellCount == tbl2_oDepth + 1) {
          final i = num.tryParse(xmlParagraph);
          if (i == null) {
            iColumn = tbl2RowCount;
            _addNoteError('Неудалось разобрать число', xmlParagraph);
          }
          tbl2_Depth.add(i);
        } else if (tbl2CellCount == tbl2_oAngle + 1) {
          final line = xmlParagraph.trim().startsWith('*')
              ? xmlParagraph.trim().substring(1)
              : xmlParagraph.trim();
          final i = num.tryParse(line);
          if (i == null) {
            iColumn = tbl2RowCount;
            _addNoteError('Неудалось разобрать число', xmlParagraph);
          }
          tbl2_Angle
              .add(tbl2_oAngleM ? convertAngleMinuts2Gradus(i.toDouble()) : i);
        } else if (tbl2CellCount == tbl2_oAzimuth + 1) {
          final line = xmlParagraph.trim().startsWith('*')
              ? xmlParagraph.trim().substring(1)
              : xmlParagraph.trim();
          final i = num.tryParse(line);
          if (i == null) {
            iColumn = tbl2RowCount;
            _addNoteError('Неудалось разобрать число', xmlParagraph);
          }
          tbl2_Azimuth.add(
              tbl2_oAzimuthM ? convertAngleMinuts2Gradus(i.toDouble()) : i);
        }
      }
      return false;
    }

    bool parseTbl2(XmlEvent e) {
      if (e is XmlTextEvent) {
        xmlParagraph += e.text;
      } else if (e is XmlStartElementEvent) {
        if (e.name == 'w:p') {
          xmlParagraph = '';
          xmlParagraphCount++;
          if (e.isSelfClosing) {
            return parseTbl2Paragraph();
          }
        }
        if (e.name == 'w:tr') {
          tbl2RowCount++;
          tbl2CellCount = 0;
        }
        if (e.name == 'w:tc') {
          tbl2CellCount++;
        }
      } else if (e is XmlEndElementEvent) {
        if (e.name == 'w:p') {
          return parseTbl2Paragraph();
        }
        if (e.name == 'w:tbl') {
          funcParse = funcParseBody;
        }
      }
      return false;
    }

    var tblCount = 0;
    bool parseBody(XmlEvent e) {
      if (e is XmlTextEvent) {
        xmlParagraph += e.text;
      } else if (e is XmlStartElementEvent) {
        if (e.name == 'w:tbl') {
          tblCount++;
          if (tblCount == 1) {
            funcParse = parseTbl1;
          } else if (tblCount == 2) {
            funcParse = parseTbl2;
          }
        }
        if (e.name == 'w:p') {
          xmlParagraph = '';
          xmlParagraphCount++;
          if (e.isSelfClosing) {
            return parseBodyPararaph();
          }
        }
      } else if (e is XmlEndElementEvent) {
        if (e.name == 'w:p') {
          return parseBodyPararaph();
        }
      }
      return false;
    }

    funcParseBody = funcParse = parseBody;

    final xml = parseEvents(data);
    for (var e in xml) {
      if (funcParse(e)) {
        break;
      }
    }
    if (tbl2_Depth.isEmpty || tbl2_Azimuth.isEmpty || tbl2_Angle.isEmpty) {
      _addNoteError('Таблица не разобрана');
      return JOneFileData(
          fileData.path, fileData.origin, NOneFileDataType.docx, fileData.size,
          // curves: curves,
          // encode: 'DOCX',
          notes: _notes,
          notesError: _noteErrors,
          notesWarnings: _noteWarnings);
    } else {
      while (tbl2_Depth.isNotEmpty && tbl2_Depth.last == null) {
        tbl2_Depth.removeLast();
      }
    }
    final curves = <JOneFilesDataCurve>[];
    var strt = tbl2_Depth.first;
    var stop = tbl2_Depth.last;
    num step = 0;
    final dataDepth = <num>[];
    final dataAngle = <num>[];
    final dataAzimuth = <num>[];

    num oAltitiudeN;
    {
      var i0 = oAltitude.indexOf(' ');
      if (i0 == -1) {
        i0 = oAltitude.indexOf('г');
      }
      if (i0 == -1) {
        oAltitiudeN = double.tryParse(oAltitude);
      } else {
        oAltitiudeN = double.tryParse(oAltitude.substring(0, i0));
      }
    }

    curves.add(JOneFilesDataCurve(
        oWell, '.ink.data', 0, 0, 0, [oAngleN, oAltitiudeN]));
    curves.add(
        JOneFilesDataCurve(oWell, '.ink.depth', strt, stop, step, dataDepth));
    curves.add(
        JOneFilesDataCurve(oWell, '.ink.angle', strt, stop, step, dataAngle));
    curves.add(JOneFilesDataCurve(
        oWell, '.ink.azimuth', strt, stop, step, dataAzimuth));
    final _l = tbl2_Depth.length;
    for (var i = 0; i < _l; i++) {
      dataDepth.add(tbl2_Depth[i]);
      dataAngle.add(tbl2_Angle[i]);
      dataAzimuth.add(tbl2_Azimuth[i]);
    }

    return JOneFileData(fileData.path, fileData.origin,
        NOneFileDataType.ink_docx, fileData.size,
        curves: curves,
        // encode: 'DOCX',
        notes: _notes,
        notesError: _noteErrors,
        notesWarnings: _noteWarnings);

    // File(path + '.txt').writeAsStringSync(_list.join('\n'));
  }

  return JOneFileData(
      fileData.path, fileData.origin, NOneFileDataType.docx, fileData.size,
      // curves: curves,
      // encode: 'DOCX',
      notes: _notes,
      notesError: _noteErrors,
      notesWarnings: _noteWarnings);
  // TODO: вернуть обработанный файл
}
