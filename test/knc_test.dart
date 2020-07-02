import 'dart:async';
import 'dart:cli';
import 'dart:convert';
import 'dart:io';

import 'package:knc/knc.dart';
import 'package:test/test.dart';

import 'package:xml/xml_events.dart';

void main() {
  test('calculate', () {
    expect(calculate(), 42);
  });

  test('string split', () {
    final str =
        '  1111.111  2222    444 333.412 666   809123.213 123       1923 81 94.3';
    print(str.split(' '));
    var i = 0;
    str.split(' ').forEach((e) {
      if (e.isNotEmpty) {
        i += 1;
        print('$i: "$e"');
      }
    });
  });

  test('futures', () {
    final f1 = Future.value(42);
    final f2 = f1.then((e) {
      print('f1 begin');
      return Future.delayed(Duration(milliseconds: 300), () {
        print('f1 begin inner 1');
        return Future.delayed(Duration(milliseconds: 333), () {
          print('f1 begin inner 2');
          return 'end';
        });
      });
    });
    final f3 = Future.delayed(Duration(milliseconds: 166), () {
      print('f3 complete');
      final f4 = Future.delayed(Duration(milliseconds: 666), () {
        print('f4');
        return Future.delayed(Duration(milliseconds: 33), () {
          print('f4 inner');
          return 'e2';
        });
      });
      print('f4 created');
      return f4;
    });
    final f5 = Future.wait([f1, f2, f3]).then((value) {
      print(value);
      print('its all');
    });
    print('test end');
    print(waitFor(f5));
  });

  test('file path test', () {
    print(r'\\NAS\Public\common\Gilyazeev\Ð“Ð˜Ð¡\?1\2006Ð³\?2\las1\GZ3.las'
        .split(r'/')
        .expand((e) => e.split(r'\'))
        .toList());
  });

  test('doc parse', () async {
    final pathBin_zip = r'C:\Program Files\7-Zip\7z.exe';
    // final pathBin_doc2x = r'D:\ARGilyazeev\doc2x_r649\doc2x.exe';
    final pathBin_doc2x =
        r'C:\Program Files (x86)\Microsoft Office\root\Office16\Wordconv.exe';
    final path2doc = r'test/test.doc';
    final path2out = r'test/test.docx';

    if (await File(path2out).exists()) {
      await File(path2out).deleteSync(recursive: true);
    }
    if (await Directory('test/test_doc').exists()) {
      await Directory('test/test_doc').deleteSync(recursive: true);
    }
    if (await File('test/test_doc.txt').exists()) {
      await File('test/test_doc.txt').deleteSync(recursive: true);
    }

    await Process.run(pathBin_doc2x, ['-oice', '-nme', path2doc, path2out]);
    await Process.run(pathBin_zip, ['x', '-otest/test_doc', path2out]);

    final data = [];
    String paragraph;
    List<List<List<String>>> data_tbl;

    final out = File('test/test_doc.txt')
        .openWrite(encoding: utf8, mode: FileMode.writeOnly);
    out.writeCharCode(unicodeBomCharacterRune);

    await for (final e in File('test/test_doc/word/document.xml')
        .openRead()
        .transform(Utf8Decoder(allowMalformed: true))
        .transform(XmlEventDecoder())) {
      for (final i in e) {
        if (i is XmlStartElementEvent) {
          if (i.name == 'w:tbl') {
            data_tbl = <List<List<String>>>[];
            data.add(data_tbl);
            // data_tbl = data.last;
          }
          if (data_tbl == null) {
            if (i.name == 'w:p') {
              paragraph = '^';
              if (i.isSelfClosing) {
                paragraph += r'$';
                data.add(paragraph);
                out.writeln(paragraph);
                paragraph = null;
              }
            }
          } else {
            if (i.name == 'w:tr') {
              data_tbl.add([]);
            }
            if (i.name == 'w:tc') {
              data_tbl.last.add([]);
            }
            if (i.name == 'w:p') {
              paragraph = '^';
              if (i.isSelfClosing) {
                paragraph += r'$';
                data_tbl.last.last.add(paragraph);
                paragraph = null;
              }
            }
          }
        } else if (i is XmlEndElementEvent) {
          if (i.name == 'w:tbl') {
            final tblRowHeight = List.filled(data_tbl.length, 0);
            var cells_max = 0;
            for (var r in data_tbl) {
              if (cells_max < r.length) cells_max = r.length;
            }
            final tblCellWidth = List.filled(cells_max, 0);

            for (var ir = 0; ir < data_tbl.length; ir++) {
              final row = data_tbl[ir];
              for (var ic = 0; ic < row.length; ic++) {
                final cell = row[ic];
                if (tblRowHeight[ir] < cell.length) {
                  tblRowHeight[ir] = cell.length;
                }
                for (final p in cell) {
                  if (tblCellWidth[ic] < p.length) {
                    tblCellWidth[ic] = p.length;
                  }
                }
              }
            }
            var tblWidth = 0;
            for (var i in tblCellWidth) {
              tblWidth += i + 3;
            }
            out.write(r'╔');
            for (var icc = 0; icc < cells_max; icc++) {
              out.write(''.padRight(tblCellWidth[icc] + 2, r'═'));
              if (icc < cells_max - 1) {
                out.write(r'╦');
              } else {
                out.writeln(r'╗');
              }
            }
            for (var ir = 0; ir < data_tbl.length; ir++) {
              final row = data_tbl[ir];
              for (var i = 0; i < tblRowHeight[ir]; i++) {
                out.write('║');
                for (var ic = 0; ic < row.length; ic++) {
                  out.write(' ');
                  final cell = row[ic];
                  if (i < cell.length) {
                    out.write(cell[i].padRight(tblCellWidth[ic]));
                  } else {
                    out.write(''.padRight(tblCellWidth[ic]));
                  }
                  out.write(' ║');
                }
                out.writeln();
              }
              if (ir < data_tbl.length - 1) {
                out.write(r'╠');
                for (var icc = 0; icc < cells_max; icc++) {
                  out.write(''.padRight(tblCellWidth[icc] + 2, r'═'));
                  if (icc < cells_max - 1) {
                    out.write(r'╬');
                  } else {
                    out.writeln(r'╣');
                  }
                }
              } else {
                out.write(r'╚');
                for (var icc = 0; icc < cells_max; icc++) {
                  out.write(''.padRight(tblCellWidth[icc] + 2, r'═'));
                  if (icc < cells_max - 1) {
                    out.write(r'╩');
                  } else {
                    out.writeln(r'╝');
                  }
                }
              }
            }

            data_tbl = null;
          }
          if (data_tbl == null) {
            if (i.name == 'w:p') {
              paragraph += r'$';
              data.add(paragraph);
              out.writeln(paragraph);
              paragraph = null;
            }
          } else {
            if (i.name == 'w:p') {
              paragraph += r'$';
              data_tbl.last.last.add(paragraph);
              paragraph = null;
            }
          }
        } else if (i is XmlTextEvent) {
          if (paragraph == null) {
            data.add(i.text);
          } else {
            paragraph += i.text;
          }
        }
      }
    }
    await out.flush();
    await out.close();
  });
}
