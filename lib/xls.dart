import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as p;
import 'dart:math';

import 'las.dart';
import 'ink.dart';

class XlsCell {
  /// Позиция ячейки (от 0,0)
  final Point<int> id;

  /// Ширина и высота расширения ячеек
  /// - `null` - если он не расширяется
  final Point<int> merge;

  /// Данные ячейки
  /// - `@{num}` - для расшаренных строк
  final String data;

  XlsCell(this.id, this.merge, this.data);
}

class KncXlsBuilder {
  final Directory dir;
  final sharedStrings = <String>[
    r'Скважина',
    r'Год',
    r'X устья',
    r'Y устья',
    r'Альтитуда',
    r'Наличие инклинометра',
    r'Методы ГИС',
  ];

  final cells = <XlsCell>[
    XlsCell(Point(0, 0), Point(0, 1), '@0'),
    XlsCell(Point(1, 0), Point(0, 1), '@1'),
    XlsCell(Point(2, 0), Point(0, 1), '@2'),
    XlsCell(Point(3, 0), Point(0, 1), '@3'),
    XlsCell(Point(4, 0), Point(0, 1), '@4'),
    XlsCell(Point(5, 0), Point(1, 1), '@5'),
  ];

  /// Возвращает название колонки эксель через её порядковый номер
  static String getColumnName(final int i) {
    const _aSize = 26;
    if (i <= _aSize) {
      return String.fromCharCode('A'.codeUnits[0] + i - 1);
    } else if (i <= _aSize * _aSize) {
      return String.fromCharCode('A'.codeUnits[0] + ((i - 1) ~/ _aSize) - 1) +
          String.fromCharCode('A'.codeUnits[0] + (i - 1) % _aSize);
    } else {
      return 'AAA';
    }
  }

  /// Возвращает название колонки эксель через её порядковый номер
  static String getNameByPoint(final Point<int> id) =>
      '${getColumnName(id.x + 1)}${id.y + 1}';

  /// Создаёт таблицу эксель в папке [dir], хранит там временные файлы,
  /// по окнчанию создаёт файл рядом с папкой с названием [dir].xlsx
  KncXlsBuilder(this.dir);

  /// Подготавливает временные файлы для эксель таблицы
  static Future<KncXlsBuilder> start(final Directory dir,
      [final bool reCreate = false]) async {
    if (await dir.exists()) {
      if (reCreate) {
        await dir.delete(recursive: true);
      } else {
        return null;
      }
    }
    await dir.create(recursive: true);
    final dirInitData = Directory(p.join('data', 'xls')).absolute;

    Future _fc(final Directory _dir) async {
      final tasks = <Future>[];
      await for (final entity in _dir.list(recursive: false)) {
        if (entity is File) {
          tasks.add(entity.copy(p.join(
              dir.path, entity.path.substring(dirInitData.path.length + 1))));
        } else if (entity is Directory) {
          tasks.add(Directory(p.join(
                  dir.path, entity.path.substring(dirInitData.path.length + 1)))
              .create(recursive: false)
              .then((value) => _fc(entity)));
        }
      }
      return await Future.wait(tasks);
    }

    await _fc(dirInitData);
    return KncXlsBuilder(dir);
  }

  void addDataBases([final LasDataBase las, final InkDataBase ink]) {
    String prev;
    final wellsNames = ((las != null ? las.db.keys.toList() : <String>[]) +
        (ink != null ? ink.db.keys.toList() : <String>[]))
      ..sort((a, b) => a.compareTo(b))
      ..removeWhere((element) {
        if (element == prev) {
          return true;
        }
        prev = element;
        return false;
      });

    final curvesNames = <String>[];
    las.db.values.forEach((list) {
      list.forEach((curve) {
        if (!curvesNames.contains(curve.name)) {
          curvesNames.add(curve.name);
        }
      });
    });
    curvesNames.sort((a, b) => a.compareTo(b));

    const iInk = 5;
    const iGis = 7;

    cells.add(
        XlsCell(Point(iGis, 0), Point(2 * curvesNames.length - 1, 0), '@6'));

    final iSS = sharedStrings.length;
    sharedStrings.addAll(curvesNames);

    for (var i = 0; i < curvesNames.length; i++) {
      cells.add(XlsCell(Point(iGis + i * 2, 1), Point(1, 0), '@${i + iSS}'));
    }

    var row = 2;
    for (final well in wellsNames) {
      final curves = las != null
          ? las.db[well] ?? <SingleCurveLasData>[]
          : <SingleCurveLasData>[];
      final inks =
          ink != null ? ink.db[well] ?? <SingleInkData>[] : <SingleInkData>[];
      while (curves.isNotEmpty || inks.isNotEmpty) {
        final curvesRow = List<SingleCurveLasData>(curvesNames.length);
        for (var curve in curves) {
          var i0 = curvesNames.indexOf(curve.name);
          if (i0 != -1 && curvesRow[i0] == null) {
            curvesRow[i0] = curve;
          }
        }
        curves.removeWhere((element) => curvesRow.contains(element));
        final inkRow = inks != null && inks.isNotEmpty ? inks.first : null;
        if (inkRow != null) {
          inks.removeAt(0);
        }
        cells.add(XlsCell(Point(0, row), null, well));
        if (inkRow != null) {
          cells.add(XlsCell(Point(iInk, row), null, inkRow.strt.toString()));
          cells
              .add(XlsCell(Point(iInk + 1, row), null, inkRow.stop.toString()));
        }
        for (var i = 0; i < curvesRow.length; i++) {
          if (curvesRow[i] != null) {
            cells.add(XlsCell(
                Point(iGis + i * 2, row), null, curvesRow[i].strt.toString()));
            cells.add(XlsCell(Point(iGis + i * 2 + 1, row), null,
                curvesRow[i].stop.toString()));
          }
        }
        row += 1;
      }
    }
  }

  /// Перезаписывает файл xl/sharedStrings.xml
  Future rewriteSharedStrings() async {
    final io = File(p.join(dir.path, 'xl', 'sharedStrings.xml'))
        .openWrite(encoding: utf8, mode: FileMode.writeOnly);
    io.writeln('<?xml version="1.0" encoding="UTF-8" standalone="yes"?>');
    io.write(
        '<sst xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main" count="${sharedStrings.length}" uniqueCount="${sharedStrings.length}">');
    for (final ss in sharedStrings) {
      io.write('<si><t>${htmlEscape.convert(ss)}</t></si>');
    }
    io.write('</sst>');
    await io.flush();
    await io.close();
  }

  /// Перезаписывает файл xl/sheet1.xml
  Future rewriteSheet1() async {
    final io = File(p.join(dir.path, 'xl', 'worksheets', 'sheet1.xml'))
        .openWrite(encoding: utf8, mode: FileMode.writeOnly);
    io.writeln(r'<?xml version="1.0" encoding="UTF-8" standalone="yes"?>');
    io.write(
        r'<worksheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main"');
    io.write(
        r'    xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships"');
    io.write(
        r'    xmlns:mc="http://schemas.openxmlformats.org/markup-compatibility/2006" mc:Ignorable="x14ac xr xr2 xr3"');
    io.write(
        r'    xmlns:x14ac="http://schemas.microsoft.com/office/spreadsheetml/2009/9/ac"');
    io.write(
        r'    xmlns:xr="http://schemas.microsoft.com/office/spreadsheetml/2014/revision"');
    io.write(
        r'    xmlns:xr2="http://schemas.microsoft.com/office/spreadsheetml/2015/revision2"');
    io.write(
        r'    xmlns:xr3="http://schemas.microsoft.com/office/spreadsheetml/2016/revision3" xr:uid="{00000000-0001-0000-0000-000000000000}">');
    io.write(r'    <dimension ref="A1:A1"/>');
    io.write(r'    <sheetViews>');
    io.write(r'        <sheetView tabSelected="1" workbookViewId="0">');
    io.write(
        r'            <pane ySplit="2" topLeftCell="A3" activePane="bottomLeft" state="frozen"/>');
    io.write(r'            <selection pane="bottomLeft" sqref="A1:A2"/>');
    io.write(r'        </sheetView>');
    io.write(r'    </sheetViews>');
    io.write(
        r'    <sheetFormatPr defaultRowHeight="15" x14ac:dyDescent="0.25"/>');
    io.write(r'    <cols>');
    io.write(
        r'        <col min="1" max="1" width="12" style="1" customWidth="1"/>');
    io.write(r'        <col min="2" max="4" width="9.140625" style="1"/>');
    io.write(
        r'        <col min="5" max="5" width="12" style="1" customWidth="1"/>');
    io.write(r'        <col min="6" max="16384" width="9.140625" style="1"/>');
    io.write(r'    </cols>');
    io.write(r'    <sheetData>');

    /// sheetData

    cells.sort(
        (a, b) => a.id.y - b.id.y == 0 ? a.id.x - b.id.x : a.id.y - b.id.y);

    final mergeList = <XlsCell>[];
    var row = cells[0].id.y;

    io.write('<row r="${row + 1}">');
    for (final cell in cells) {
      if (cell.merge != null && (cell.merge.x != 0 || cell.merge.y != 0)) {
        mergeList.add(cell);
      }

      if (row != cell.id.y) {
        row = cell.id.y;
        io.write('</row><row r="${row + 1}">');
      }
      if (cell.data[0] == '@') {
        io.write(
            '<c r="${getNameByPoint(cell.id)}" s="2" t="s"><v>${cell.data.substring(1)}</v></c>');
      } else {
        io.write(
            '<c r="${getNameByPoint(cell.id)}" s="2"><v>${cell.data}</v></c>');
      }
    }
    io.write('</row></sheetData><mergeCells count="${mergeList.length}">');

    /// mergeCells
    for (final cell in mergeList) {
      io.write(
          '<mergeCell ref="${getNameByPoint(cell.id)}:${getNameByPoint(cell.id + cell.merge)}"/>');
    }

    io.write('    </mergeCells>');
    io.write(
        '    <pageMargins left="0.7" right="0.7" top="0.75" bottom="0.75" header="0.3" footer="0.3"/>');
    io.write('</worksheet>');
    await io.flush();
    await io.close();
  }
}

/**
 * Значение ячейки:
 * [r'$merged', '${iRow}', '${iCell}'] - объединённая с ячейкой
 */
List<String> pathToList(final String path) =>
    path.split(r'\').expand((e) => e.split(r'/')).toList();

class XlsBuilder {
  final Directory dir;
  Future future;
  IOSink out;
  final List<Rectangle<int>> _mergeCeils;
  int _rows;

  XlsBuilder(final Directory dir)
      : dir = dir,
        _mergeCeils = <Rectangle<int>>[],
        _rows = 1 {
    Future<File> copy(final String path) =>
        File(p.join('data', 'xls', path)).copy(p.join(dir.path, path));
    Future<Directory> copyDir(final String path) =>
        Directory(p.join(dir.path, path)).create(recursive: true);

    future = dir
        .exists()
        .then((b) => b ? dir.delete(recursive: true) : dir)
        .then((_) => dir.create(recursive: true))
        .then((_) {
      return Future.wait([
        copy(r'[Content_Types].xml'),
        copyDir(r'_rels').then((_) => copy(r'_rels/.rels')),
        copyDir(r'xl').then((_) => Future.wait([
              copy(r'xl/styles.xml'),
              copy(r'xl/workbook.xml'),
              copy(r'xl/sharedStrings.xml'),
              copyDir(r'xl/_rels')
                  .then((_) => copy(r'xl/_rels/workbook.xml.rels')),
              copyDir(r'xl/theme').then((_) => copy(r'xl/theme/theme1.xml')),
              File(p.join(dir.path, r'xl/worksheets/sheet1.xml'))
                  .create(recursive: true)
                  .then((f) =>
                      f.openWrite(encoding: utf8, mode: FileMode.writeOnly))
                  .then((v) {
                out = v;
                out.write(
                    r'''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<worksheet
	xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main"
	xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships"
	xmlns:mc="http://schemas.openxmlformats.org/markup-compatibility/2006" mc:Ignorable="x14ac xr xr2 xr3"
	xmlns:x14ac="http://schemas.microsoft.com/office/spreadsheetml/2009/9/ac"
	xmlns:xr="http://schemas.microsoft.com/office/spreadsheetml/2014/revision"
	xmlns:xr2="http://schemas.microsoft.com/office/spreadsheetml/2015/revision2"
	xmlns:xr3="http://schemas.microsoft.com/office/spreadsheetml/2016/revision3" xr:uid="{00000000-0001-0000-0000-000000000000}">
	<sheetViews>
		<sheetView tabSelected="1" workbookViewId="0">
			<pane ySplit="2" topLeftCell="A3" activePane="bottomRight" state="frozen"/>
		</sheetView>
	</sheetViews>
	<sheetFormatPr defaultRowHeight="15" x14ac:dyDescent="0.25"/>
	<cols>
		<col min="1" max="1" width="12.0" style="1" customWidth="1"/>
		<col min="2" max="4" width="9.140625" style="1"/>
		<col min="5" max="5" width="12.0" style="1" customWidth="1"/>
		<col min="6" max="16384" width="9.140625" style="1"/>
	</cols>
	<sheetData>
  <row r="1">
  <c r="A1"><v>Скважина</v></c>
  <c r="B1"><v>Год</v></c>
  <c r="C1"><v>X устья</v></c>
  <c r="D1"><v>Y устья</v></c>
  <c r="E1"><v>Альтитуда</v></c>
  <c r="F1"><v>Наличие инклинометра</v></c>
  <c r="H1"><v>Методы ГИС</v></c>
  </row>
  ''');
              })
            ])),
        // copy(r'data\xl\worksheets\sheet1.xml'),
      ]);
    });
  }

  static String getCellName(int i) {
    const _aSize = 26;
    var s = '';
    while (i > 0) {
      s = String.fromCharCode('A'.codeUnits[0] + i % _aSize) + s;
      i ~/= _aSize;
    }
    return s;
  }

  void write(final List<List<List<String>>> rows) {
    for (var iRow = 0; iRow < rows.length; iRow++) {
      out.write('<row r="${_rows + iRow}">');
      for (var iCell = 0; iCell < rows[iRow].length; iCell++) {
        final cell = rows[iRow][iCell];
        if (cell != null) {
          if (cell.length == 3 && cell[0] == r'$merged') {
            // TODO: Merge list update or ignore this if it in merge list
          } else {
            out.write('<c r="${getCellName(iCell)}${_rows + iRow}"><v>');
            for (var iPar = 0; iPar < cell.length; iPar++) {
              out.write(cell[iPar]);
            }
            out.write('</v></c>');
          }
        }
      }
      out.write('</row>');
    }
    _rows += rows.length;
  }

  Future complete(final String pathTo7Zip) {
    out.write('</sheetData><mergeCells>');
    out.writeln('</mergeCells></worksheet>');
    return out.flush().then((_) => out.close().then((_) => Process.run(
            pathTo7Zip, [
          'a',
          '-tzip',
          '${dir.absolute.path}.xlsx',
          '${dir.absolute.path}/*'
        ])));
  }
}
//"C:\Program Files\7-Zip\7z.exe" a -tzip "test.xlsx" "*" -x!test_gen.bat
