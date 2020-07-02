import 'dart:convert';
import 'dart:io';

import 'dart:math';

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
        File(r'data/xls/' + path).copy(dir.path + r'/' + path);
    Future<Directory> copyDir(final String path) =>
        Directory(dir.path + r'/' + path).create(recursive: true);

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
              File(dir.path + r'\xl\worksheets\sheet1.xml')
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
		<col min="1" max="4" width="9.140625" style="1"/>
		<col min="5" max="5" width="11.42578125" style="1" customWidth="1"/>
		<col min="6" max="16384" width="9.140625" style="1"/>
	</cols>
	<sheetData>''');
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
