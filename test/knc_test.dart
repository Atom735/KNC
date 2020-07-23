import 'dart:async';
import 'dart:cli';
import 'dart:collection';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:knc/async.dart';
import 'package:knc/dbf.dart';
import 'package:knc/ink.dart';
import 'package:knc/knc.dart';
import 'package:knc/las.dart';
import 'package:knc/mapping.dart';
import 'package:knc/unzipper.dart';
import 'package:knc/xls.dart';
import 'package:test/test.dart';

import 'package:path/path.dart' as p;

void main() {
  test('Async Queue', () async {
    final sw = Stopwatch();
    final q = AsyncTaskQueue();
    sw.start();
    final list = <Future>[];
    for (var i = 0; i < 30; i++) {
      print('${sw.elapsedMilliseconds.toString().padLeft(32)} strt $i');
      list.add(q.addTask(() {
        print('${sw.elapsedMilliseconds.toString().padLeft(32)} work $i');
        return Future.delayed(Duration(milliseconds: 200));
      }).then((value) =>
          print('${sw.elapsedMilliseconds.toString().padLeft(32)} stop $i')));
    }
    q.pause = false;
    await Future.wait(list);
    sw.stop();
  }, timeout: Timeout.factor(10));

  test('WordConv returncode', () async {
    final ss = KncSettings();
    await Future.wait(
        [ss.loadCharMaps(), ss.loadLasIgnore(), ss.serchPrograms()]);

    var a = await ss.runDoc2X(
        r'test\ink\Пример_инклинометра_1240_1_239.doc', r'.ignore\1.docx');
    print('${a.exitCode}');
    a = await ss.runDoc2X(
        r'test\ink\Пример_инклинометра_1240_1_239.doc', r'.ignore\1.docx');
    print('${a.exitCode}');
    a = await ss.runDoc2X(
        r'test\ink\Пример_инклинометра_1240_1_239.docx', r'.ignore\2.docx');
    print('${a.exitCode}');
    a = await ss.runDoc2X(
        r'test\ink\Пример_инклинометра_1240_1_239.docx', r'.ignore\2.docx');
    print('${a.exitCode}');
    a = await ss.runDoc2X(
        r'test\ink\Пример_инклинометра_1240_1_239.s', r'.ignore\3.docx');
    print('${a.exitCode}');
    a = await ss.runDoc2X(
        r'test\ink\Пример инклинометра_2255_1_141.txt', r'.ignore\3.docx');
    print('${a.exitCode}');
    a = await ss.runDoc2X(r'test\ink\Пример_инклинометра_1240_1_239.doc',
        r'.ignore\notFolder\1.docx');
    print('${a.exitCode}');
  });

  test('KncXls las test', () async {
    final ss = KncSettings();
    await Future.wait(
        [ss.loadCharMaps(), ss.loadLasIgnore(), ss.serchPrograms()]);

    ss.pathInList = [r'\\NAS\Public\common\Gilyazeev\ГИС\Искринское м-е\2003г'];
    await ss.initializing();

    await ss.startWork(
      handleErrorCatcher: (e) async {
        print(e);
      },
      handleOkLas: (las, file, newPath, originals) async {
        print('OK: $originals $file');
      },
      handleErrorLas: (las, file, newPath) async {
        print('ERROR: $file');
      },
    );

    for (var a in ss.lasCurvesNameOriginals) {
      print(a);
    }

    final dir = Directory(p.join('test', 'xls', 'zzz')).absolute;
    final xls = await KncXlsBuilder.start(dir, true);
    xls.addDataBases(ss.lasDB);
    await xls.rewriteSharedStrings();
    await xls.rewriteSheet1();
    final outPath = dir.path + '.xlsx';
    if (await File(outPath).exists()) {
      await File(outPath).delete();
    }
    await ss.unzipper.zip(dir.path, dir.path + '.xlsx');
  }, timeout: Timeout.factor(10));
  test('KncXls start test', () async {
    final ss = KncSettings();
    await Future.wait(
        [ss.loadCharMaps(), ss.loadLasIgnore(), ss.serchPrograms()]);
    await ss.initializing();
    final dir = Directory(p.join('test', 'xls', 'zzz')).absolute;
    final xls = await KncXlsBuilder.start(dir, true);
    xls.sharedStrings.add('<hehe>&to4ka! "C:/path" \'or not=!@\$#\'');
    await xls.rewriteSharedStrings();
    await xls.rewriteSheet1();
    final outPath = dir.path + '.xlsx';
    if (await File(outPath).exists()) {
      await File(outPath).delete();
    }
    await ss.unzipper.zip(dir.path, dir.path + '.xlsx');
  });

  test('dbf parse', () async {
    await for (var file in Directory(r'.ignore/dbf').list()) {
      if (file is File) {
        final bytes = await file.readAsBytes();
        final dbf = DbfFile();
        if (dbf.loadByByteData(ByteData.view(bytes.buffer))) {
          print('${p.basename(file.path)} OK');
          print('\tDate: ' +
              '${dbf.lastUpdateDD}.${dbf.lastUpdateMM}.${dbf.lastUpdateYY}'
                  .padRight(12) +
              'Records: ${dbf.numberOfRecords}'.padRight(20) +
              'Fields: ${dbf.fields.length}');
          for (var i = 0; i < dbf.fields.length; i++) {
            print('\t' +
                dbf.fields[i].name.padRight(12) +
                ':[${dbf.fields[i].type}] (0x' +
                dbf.fields[i].address
                    .toRadixString(16)
                    .toLowerCase()
                    .padLeft(8, '0') +
                ') size: ' +
                dbf.fields[i].length.toString() +
                ' dec: ' +
                dbf.fields[i].decimalCount.toString());
          }

          for (var i = 0;
              i < ((10 < dbf.records.length) ? 10 : dbf.records.length);
              i++) {
            print('\t' + dbf.records[i].join('|'));
          }
          final inks = InkData.getByDbf(dbf);
          if (inks != null) {
            for (final ink in inks) {
              print('Well: ${ink.well} with ${ink.data.length} Points');
              for (final line in ink.data) {
                print(
                    '\t${line.depthN.toStringAsPrecision(4)}\t${line.angleN.toStringAsPrecision(4)}\t${line.azimuthN.toStringAsPrecision(4)}');
              }
            }
          }
        } else {
          print('${p.basename(file.path)} ERROR');
        }
      }
    }
  });

  test('dbf first bytes', () async {
    await for (var file in Directory(r'.ignore/dbf').list()) {
      if (file is File) {
        final bytes = await file.readAsBytes();
        final str = bytes
            .sublist(0, 20)
            .map((e) => e.toRadixString(16).toUpperCase().padLeft(2, '0'))
            .join(' ');
        print('${str} | ${p.basename(file.path)}');
      }
    }
  });

  test('las db load and print', () async {
    final db = LasDataBase();
    await db.load(r'out/las/.db.bin');
    db.db.forEach((key, value) {
      value.sort((a, b) => a.name.compareTo(b.name));
      value.forEach((element) {
        final f = element.toString().split(';');
        print('${key.padLeft(20)}: ${f[0]}');
        print(
            '${''.padLeft(20)}: ${f[2].padRight(10)} | ${element.strt} | ${element.stop}');
      });
    });
  });

  test('las db save/load', () async {
    const path = r'test\6280___rk_1.las';
    final entity = File(path);
    final charMaps = await loadMappings('mappings');
    final las1 = LasData(
        UnmodifiableUint8ListView(await entity.readAsBytes()), charMaps);
    final las2 = LasData(
        UnmodifiableUint8ListView(await entity.readAsBytes()), charMaps);
    final db = LasDataBase();
    print(db.addLasData(las1));
    print(db.addLasData(las2));
    las2.origin = 'hehe';
    las2.wWell = 'sec';
    print(db.addLasData(las2));
    await db.save(r'test/las.db.out');
    final db2 = LasDataBase();
    await db2.load(r'test/las.db.out');

    var s1 = '';
    var s2 = '';

    db.db.forEach((key, value) {
      s1 += '$key:$value,';
    });
    db2.db.forEach((key, value) {
      s2 += '$key:$value,';
    });

    print(s1);
    print(s2);
  });

  test('las files test', () async {
    const path = r'test\6280___rk_1.las';
    final entity = File(path);
    final charMaps = await loadMappings('mappings');
    final las1 = LasData(
        UnmodifiableUint8ListView(await entity.readAsBytes()), charMaps);
    final las2 = LasData(
        UnmodifiableUint8ListView(await entity.readAsBytes()), charMaps);
    final db = LasDataBase();
    print(db.addLasData(las1));
    print(db.addLasData(las2));
  });

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

  // test('Las files', () async {
  //   final charMaps = await loadMappings(r'mappings');
  //   final tasks = <Future>[];
  //   await Directory(r'.ag47/').list(recursive: true).listen((e) {
  //     if (e is File && e.path.toLowerCase().endsWith('.las')) {
  //       tasks.add(e.readAsBytes().then((final bytes) =>
  //           LasData(UnmodifiableUint8ListView(bytes), charMaps)));
  //     }
  //   }).asFuture();
  //   final outData = await Future.wait(tasks);
  //   for (final i in outData) {
  //     print((i as LasData).listOfErrors);
  //   }
  // });

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
        if (a.isInk < 3) {
          continue;
        }

        if (a.listOfErrors.isEmpty) {
          sink.writeln('''
---------------------------------------OK---------------------------------------
Кодировка у оригинала ${a.encode}
Скважина N ${a.well}
Диаметр скважины: ${a.diametr} Глубина башмака: ${a.depth}
Угол склонения: ${a.angle} (${a.angleN}) Альтитуда: ${a.altitude} Забой: ${a.zaboy}''');
          for (var line in a.data) {
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
            .then((bytes) => InkData.getByDocx(bytes)));
      }
    }).asFuture();
    final outData = await Future.wait(tasks);
    var sink = File(r'test/ink.docx.out')
        .openWrite(encoding: utf8, mode: FileMode.writeOnly);
    sink.writeCharCode(unicodeBomCharacterRune);
    for (final i in outData) {
      if (i is InkData) {
        var a = await i;
        if (a.isInk < 3) {
          continue;
        }
        if (a.listOfErrors.isEmpty) {
          sink.writeln('''
---------------------------------------OK---------------------------------------
Кодировка у оригинала ${a.encode}
Скважина N ${a.well}
Диаметр скважины: ${a.diametr} Глубина башмака: ${a.depth}
Угол склонения: ${a.angle} (${a.angleN}) Альтитуда: ${a.altitude} Забой: ${a.zaboy}''');
          for (var line in a.data) {
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

  test('ZipFile', () async {
    Future<ProcessResult> Function(String path2arch, String path2out)
        createUnzipperFunc(final String path2bin_7z) =>
            (final String path2arch, final String path2out) =>
                Process.run(path2bin_7z, ['x', '-o$path2out', path2arch]);

    final unzipper = createUnzipperFunc(r'C:\Program Files\7-Zip\7z.exe');

    final dirZip = Directory(r'test/zip');
    if (dirZip.existsSync()) {
      dirZip.deleteSync(recursive: true);
    }
    dirZip.createSync(recursive: true);

    await dirZip.createTemp().then((dirTemp) {
      print('temp created $dirTemp');
      return unzipper(r'test/zip.zip', dirTemp.path).then((procResult) {
        if (procResult.exitCode == 0) {
          print('unzipper = ok');
          final tasks = <Future>[];
          return dirTemp
              .list(recursive: true, followLinks: false)
              .listen((entityInZip) {
                if (entityInZip is File) {
                  print('entity in zip $entityInZip');
                  final ext = p.extension(entityInZip.path).toLowerCase();
                  if (ext == '.zip') {
                    // GoTo Recursion
                    print('2 archive on archive ${entityInZip}');
                    tasks.add(dirZip.createTemp().then((dirTemp) {
                      print('2 temp created $dirTemp');
                      return unzipper(entityInZip.path, dirTemp.path)
                          .then((procResult) {
                        if (procResult.exitCode == 0) {
                          print('2 unzipper = ok');
                          final tasks = <Future>[];
                          return dirTemp
                              .list(recursive: true, followLinks: false)
                              .listen((entityInZip) {
                                if (entityInZip is File) {
                                  print('2 entity in zip $entityInZip');
                                }
                              })
                              .asFuture(tasks)
                              .then((taskList) {
                                print('2 all files listed');
                                return dirTemp
                                    .delete(recursive: true)
                                    .then((value) {
                                  print('2 temp deleted $dirTemp');
                                });
                              });
                        } else {
                          print('2 unzipper = error ${procResult.exitCode}');
                          return Future.error(
                              '2 unzipper = error ${procResult.exitCode}');
                        }
                      });
                    }));
                    // End of Recursion
                  }
                }
              })
              .asFuture(tasks)
              .then((taskList) {
                print('all files listed');
                print('waiting for tasks withl listed files');
                return Future.wait(taskList).then((taskListEnded) {
                  print('all tasks was ended');
                  return dirTemp.delete(recursive: true).then((value) {
                    print('temp deleted $dirTemp');
                  });
                });
              });
        } else {
          print('unzipper = error ${procResult.exitCode}');
          return Future.error('unzipper = error ${procResult.exitCode}');
        }
      });
    });
  });

  test('Unzzipper Lib', () async {
    var unzipper = Unzipper(r'test/zip', r'C:\Program Files\7-Zip\7z.exe');

    Future listFiles(FileSystemEntity entity, String relPath) async {
      if (entity is File) {
        print(entity);
        final ext = p.extension(entity.path).toLowerCase();
        if (ext == '.zip') {
          return unzipper.unzip(entity.path, listFiles, (list) async {
            print(list);
          });
        }
      }
    }

    await unzipper.clear();
    print(await unzipper.unzip(r'test/zip.zip', listFiles, (list) async {
      print(list);
    }));
  });

  test('Unzzipper Lib Debug', () async {
    var unzipper = Unzipper(r'test/zip', r'C:\Program Files\7-Zip\7z.exe');

    Future Function(FileSystemEntity entity, String relPath) listFilesGet(
            int i, String path) =>
        (FileSystemEntity entity, String relPath) async {
          if (entity is File) {
            print('$i: $entity');
            print('\t$relPath');
            print('\t$path');
            final ext = p.extension(entity.path).toLowerCase();
            if (ext == '.zip') {
              return unzipper
                  .unzip(entity.path, listFilesGet(i + 1, path + relPath),
                      (list) async {
                print('$i: $list');
              });
            }
          }
        };

    await unzipper.clear();
    print(await unzipper
        .unzip(r'test/zip.zip', listFilesGet(1, r'test/zip.zip'), (list) async {
      print(list);
    }));
  });

  test('Las ignore', () async {
    var map = {
      'W~WELL': ['WELL', 'Well']
    };
    var io = File(r'data\las.ignore.json')
        .openWrite(encoding: utf8, mode: FileMode.writeOnly);
    io.writeCharCode(unicodeBomCharacterRune);
    var json = JsonCodec();
    io.write(json.encode(map));
    await io.flush();
    await io.close();
  });
}
