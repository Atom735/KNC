import 'dart:async';
import 'dart:cli';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:knc/ink.dart';
import 'package:knc/knc.dart';
import 'package:knc/las.dart';
import 'package:knc/mapping.dart';
import 'package:knc/xls.dart';
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

  test('doc parse + xlsx', () async {
    const pathBin_zip = r'C:\Program Files\7-Zip\7z.exe';
    // final pathBin_doc2x = r'D:\ARGilyazeev\doc2x_r649\doc2x.exe';
    const pathBin_doc2x =
        r'C:\Program Files (x86)\Microsoft Office\root\Office16\Wordconv.exe';
    const path2doc = r'test/test.doc';
    const path2out = r'test/doc/test.docx';
    const path2outDir = r'test/doc/docx';
    const path2outTxt = r'test/doc/test.txt';

    await Future.wait([
      File(path2out)
          .exists()
          .then((b) => b ? File(path2out).delete(recursive: true) : null),
      File(path2outTxt)
          .exists()
          .then((b) => b ? File(path2outTxt).delete(recursive: true) : null),
      Directory(path2outDir).exists().then(
          (b) => b ? Directory(path2outDir).delete(recursive: true) : null),
    ]);

    await Process.run(pathBin_doc2x, ['-oice', '-nme', path2doc, path2out]);
    await Process.run(pathBin_zip, ['x', '-o$path2outDir', path2out]);

    final data = [];
    String paragraph;
    List<List<List<String>>> data_tbl;

    final out =
        File(path2outTxt).openWrite(encoding: utf8, mode: FileMode.writeOnly);
    out.writeCharCode(unicodeBomCharacterRune);

    final xls = XlsBuilder(Directory('test/xls/test'));

    await for (final e in File('$path2outDir/word/document.xml')
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
            await xls.future;
            xls.write(data_tbl);
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
    await xls.complete(pathBin_zip);
    await out.flush();
    await out.close();
  });

  test('Las files', () async {
    final charMaps = await loadMappings(r'mappings');
    final tasks = <Future>[];
    await Directory(r'.ag47/').list(recursive: true).listen((e) {
      if (e is File && e.path.toLowerCase().endsWith('.las')) {
        tasks.add(e.readAsBytes().then((final bytes) =>
            LasData(UnmodifiableUint8ListView(bytes), charMaps)));
      }
    }).asFuture();
    final outData = await Future.wait(tasks);
    for (final i in outData) {
      print((i as LasData).listOfErrors);
    }
  });

  test('parse double', () {
    print(double.tryParse(r'132.4123 exasd'));
  });

  test('Ink.txt files', () async {
    final charMaps = await loadMappings(r'mappings');
    final tasks = <Future>[];
    await Directory(r'test/ink').list(recursive: true).listen((e) {
      if (e is File && e.path.toLowerCase().endsWith('.txt')) {
        tasks.add(e.readAsBytes().then((final bytes) =>
            InkData.txt(UnmodifiableUint8ListView(bytes), charMaps)));
      }
    }).asFuture();
    final outData = await Future.wait(tasks);
    var sink = File(r'test/ink.txt.out')
        .openWrite(encoding: utf8, mode: FileMode.writeOnly);
    sink.writeCharCode(unicodeBomCharacterRune);
    for (final i in outData) {
      if (i is InkData) {
        var a = i;
        if (a.bInkFile != true) {
          continue;
        }

        if (a.listOfErrors.isEmpty) {
          sink.writeln('''
---------------------------------------OK---------------------------------------
Кодировка у оригинала ${a.encode}
Скважина N ${a.well}
Диаметр скважины: ${a.diametr} Глубина башмака: ${a.depth}
Угол склонения: ${a.angle} (${a.angleN}) Альтитуда: ${a.altitude} Забой: ${a.zaboy}''');
          for (var line in a.list) {
            sink.writeln(
                '\t${line.depthN}\t${line.angleN}\t${line.azimuthN}\t${line.depth}\t${line.angle}\t${line.azimuth}');
          }
        } else {
          sink.writeln('''
-------------------------------------ERROR--------------------------------------
Кодировка у оригинала ${a.encode}
Скважина N ${a.well}
Диаметр скважины: ${a.diametr} Глубина башмака: ${a.depth}
Угол склонения: ${a.angle} (${a.angleN}) Альтитуда: ${a.altitude} Забой: ${a.zaboy}''');
          for (var line in a.listOfErrors) {
            sink.writeln('\t${line}');
          }
        }
        sink.writeln(
            '================================================================================');
      }
    }
    await sink.flush();
    await sink.close();
  });
  test('Ink.docx files', () async {
    final tasks = <Future>[];
    await Directory(r'test/ink').list(recursive: true).listen((e) {
      if (e is File &&
          e.path.toLowerCase().endsWith('.docx') &&
          !e.path.startsWith(r'~$')) {
        const pathBin_zip = r'C:\Program Files\7-Zip\7z.exe';
        const path2out = r'test/ink/docx';

        tasks.add(Directory(path2out)
            .exists()
            .then((b) => b ? Directory(path2out).delete(recursive: true) : null)
            .then((_) => Process.run(pathBin_zip, ['x', '-o$path2out', e.path]))
            .then((_) => File('$path2out/word/document.xml').openRead())
            .then((bytes) => InkData.docx(bytes)));
      }
    }).asFuture();
    final outData = await Future.wait(tasks);
    var sink = File(r'test/ink.docx.out')
        .openWrite(encoding: utf8, mode: FileMode.writeOnly);
    sink.writeCharCode(unicodeBomCharacterRune);
    for (final i in outData) {
      if (i is InkData) {
        var a = i;
        await a.future;
        if (a.bInkFile != true) {
          continue;
        }
        if (a.listOfErrors.isEmpty) {
          sink.writeln('''
---------------------------------------OK---------------------------------------
Кодировка у оригинала ${a.encode}
Скважина N ${a.well}
Диаметр скважины: ${a.diametr} Глубина башмака: ${a.depth}
Угол склонения: ${a.angle} (${a.angleN}) Альтитуда: ${a.altitude} Забой: ${a.zaboy}''');
          for (var line in a.list) {
            sink.writeln(
                '\t${line.depthN}\t${line.angleN}\t${line.azimuthN}\t${line.depth}\t${line.angle}\t${line.azimuth}');
          }
        } else {
          sink.writeln('''
-------------------------------------ERROR--------------------------------------
Кодировка у оригинала ${a.encode}
Скважина N ${a.well}
Диаметр скважины: ${a.diametr} Глубина башмака: ${a.depth}
Угол склонения: ${a.angle} (${a.angleN}) Альтитуда: ${a.altitude} Забой: ${a.zaboy}''');
          for (var line in a.listOfErrors) {
            sink.writeln('\t${line}');
          }
        }
        sink.writeln(
            '================================================================================');
      }
    }
    await sink.flush();
    await sink.close();
  });
}
