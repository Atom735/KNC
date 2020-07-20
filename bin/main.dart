import 'dart:io';
import 'dart:typed_data';

import 'package:knc/errors.dart';
import 'package:knc/ink.dart';
import 'package:knc/knc.dart';
import 'package:knc/web.dart';
import 'package:path/path.dart' as p;

import 'package:knc/las.dart';

Future main(List<String> args) async {
  /// настройки
  final ss = KncSettings();
  await Future.wait(
      [ss.loadCharMaps(), ss.loadLasIgnore(), ss.serchPrograms()]);

  final server = MyServer(Directory(r'web'));
  final tasks = <Future>[];
  final tasks2 = <Future>[];
  Future workEnd;

  void errorAdd(final String txt) {
    ss.errorsOut.writeln(txt);
    server.sendMsg('#ERROR:$txt');
  }

  Future Function(FileSystemEntity entity, String relPath) listFilesGet(
          final int iArchDepth, final String pathToArch) =>
      (final FileSystemEntity entity, final String relPath) async {
        // [pathToArch] - путь к вскрытому архиву
        // [relPath] - путь относительный архива
        // Вне архива, [relPath]- содержит полный путь
        // а [pathToArch] - пустая строка, но не `null`
        if (entity is File) {
          final ext = p.extension(entity.path).toLowerCase();
          // == UNZIPPER ==
          if (ss.ssFileExtAr.contains(ext)) {
            try {
              if (ss.ssArMaxSize > 0) {
                // если максимальный размер архива установлен
                if (await entity.length() < ss.ssArMaxSize &&
                    (ss.ssArMaxDepth == -1 || iArchDepth < ss.ssArMaxDepth)) {
                  // вскрываем архив если он соотвествует размеру и мы не привысили глубину вложенности
                  await ss.unzipper.unzip(entity.path,
                      listFilesGet(iArchDepth + 1, pathToArch + relPath));
                  return;
                } else {
                  // отбрасываем большой архив
                  return;
                }
              } else if (ss.ssArMaxDepth == -1 ||
                  iArchDepth < ss.ssArMaxDepth) {
                // если не указан размер, и мы не превысили вложенность
                await ss.unzipper.unzip(entity.path,
                    listFilesGet(iArchDepth + 1, pathToArch + relPath));
                return;
              } else {
                // игнорируем из за вложенности
                return;
              }
            } catch (e) {
              // Ошибка архиватора
              errorAdd('+UNZIPPER: ${entity.path}');
              errorAdd('\t$e');
              errorAdd(''.padRight(20, '='));
            }
            return;
          } // == UNZIPPER == End

        }
      };

  Future listFiles(final FileSystemEntity entity, final String relPath) async {
    if (entity is File) {
      // print(entity);
      final ext = p.extension(entity.path).toLowerCase();
      if (ss.ssFileExtAr.contains(ext)) {
        try {
          await ss.unzipper.unzip(entity.path, listFiles);
        } catch (e) {
          errorAdd('+UNZIPPER: ${entity.path}');
          errorAdd('\t$e');
          errorAdd(''.padRight(20, '='));
        }
        return;
      }
      if (ss.ssFileExtLas.contains(ext)) {
        final data = LasData(
            UnmodifiableUint8ListView(await entity.readAsBytes()),
            ss.ssCharMaps);
        if (data.listOfErrors.isEmpty) {
          // No error
          final newPath = await getOutPathNew(
              ss.pathOutLas, data.wWell + '___' + p.basename(entity.path));

          server.sendMsg('#LAS:+"${entity.path}"');
          server.sendMsg('#LAS:\t"${entity.path}" => "${newPath}"');
          for (final c in data.curves) {
            server.sendMsg('#LAS:\t${c.mnem}: ${c.strtN} <=> ${c.stopN}');
          }
          server.sendMsg('#LAS:' + ''.padRight(20, '='));
          try {
            await entity.copy(newPath);
          } catch (e) {
            errorAdd('+FILE_COPY: ${entity.path} => $newPath');
            errorAdd('\t$e');
            errorAdd(''.padRight(20, '='));
          }
        } else {
          // On Error
          final newPath =
              await getOutPathNew(ss.pathOutErrors, p.basename(entity.path));
          errorAdd('+LAS("${entity.path}")');
          errorAdd('\t"${entity.path}" => "${newPath}"');
          for (final err in data.listOfErrors) {
            errorAdd('\tСтрока ${err.line}: ${kncErrorStrings[err.err]}');
          }
          errorAdd(''.padRight(20, '='));
          try {
            await entity.copy(newPath);
          } catch (e) {
            errorAdd('+FILE_COPY: ${entity.path} => $newPath');
            errorAdd('\t$e');
            errorAdd(''.padRight(20, '='));
          }
          return;
        }
      }
      if (ss.ssFileExtInk.contains(ext)) {
        final bytes = UnmodifiableUint8ListView(await entity.readAsBytes());
        if (bytes.length <= 30) return;
        var spaces = 0;
        InkData ink;
        for (var i = 0; i < 30; i++) {
          if (bytes[i] == 20) {
            spaces += 1;
          }
        }
        if (spaces > 10) {
          ink = InkData.txt(bytes, ss.ssCharMaps);
        } else {
          var b = true;
          const signatureDoc = [0xD0, 0xCF, 0x11, 0xE0, 0xA1, 0xB1, 0x1A, 0xE1];
          for (var i = 0; i < signatureDoc.length && b; i++) {
            b = bytes[i] == signatureDoc[i];
          }

          if (b) {
            final newPath = await getOutPathNew(
                ss.pathOutInk, p.basename(entity.path) + '.docx');
            await ss.runDoc2X(entity.path, newPath);
            try {
              await ss.unzipper.unzip(newPath,
                  (final FileSystemEntity entity2, final String relPath) async {
                if (entity2 is File &&
                    p.dirname(entity2.path) == 'word' &&
                    p.basename(entity2.path) == 'document.xml') {
                  ink = InkData.docx(entity2.openRead());
                  await ink.future;
                  if (ink.listOfErrors.isEmpty) {
                    // No error
                    final newPath = await getOutPathNew(
                        ss.pathOutInk,
                        ink.well +
                            '___' +
                            p.basenameWithoutExtension(entity.path) +
                            '.txt');

                    server.sendMsg('#INK:+"${entity.path}"');
                    server.sendMsg('#INK:\t"${entity.path}" => "${newPath}"');
                    server.sendMsg('#INK:' + ''.padRight(20, '='));
                    final io =
                        File(newPath).openWrite(mode: FileMode.writeOnly);
                    io.writeln(ink.well);
                    for (final item in ink.list) {
                      io.writeln(
                          '${item.depthN}\t${item.angleN}\t${item.azimuthN}');
                    }
                    await io.flush();
                    await io.close();
                  } else {
                    // On Error
                    final newPath = await getOutPathNew(
                        ss.pathOutErrors, p.basename(entity.path));
                    errorAdd('+INK("${entity.path}")');
                    errorAdd('\t"${entity.path}" => "${newPath}"');
                    for (final err in ink.listOfErrors) {
                      errorAdd('\t$err');
                    }
                    errorAdd(''.padRight(20, '='));
                    try {
                      await entity.copy(newPath);
                    } catch (e) {
                      errorAdd('+FILE_COPY: ${entity.path} => $newPath');
                      errorAdd('\t$e');
                      errorAdd(''.padRight(20, '='));
                    }
                  }
                }
              });
            } catch (e) {
              errorAdd('+UNZIPPER: ${entity.path}');
              errorAdd('\t$e');
              errorAdd(''.padRight(20, '='));
            }
            try {
              await File(newPath).delete();
            } catch (e) {
              errorAdd('+FILE_DELETE: ${entity.path}');
              errorAdd('\t$e');
              errorAdd(''.padRight(20, '='));
            }
          }

          const signatureZip = [
            [0x50, 0x4B, 0x03, 0x04],
            [0x50, 0x4B, 0x05, 0x06],
            [0x50, 0x4B, 0x07, 0x08]
          ];

          for (var j = 0; j < signatureZip.length && b; j++) {
            b = true;
            for (var i = 0; i < signatureZip[j].length && b; i++) {
              b = bytes[i] == signatureZip[j][i];
            }
            if (b) {
              await ss.unzipper.unzip(entity.path,
                  (final FileSystemEntity entity2, final String relPath) async {
                if (entity2 is File &&
                    p.dirname(entity2.path) == 'word' &&
                    p.basename(entity2.path) == 'document.xml') {
                  ink = InkData.docx(entity2.openRead());
                  await ink.future;
                  if (ink.listOfErrors.isEmpty) {
                    // No error
                    final newPath = await getOutPathNew(
                        ss.pathOutInk,
                        ink.well +
                            '___' +
                            p.basenameWithoutExtension(entity.path) +
                            '.txt');

                    server.sendMsg('#INK:+"${entity.path}"');
                    server.sendMsg('#INK:\t"${entity.path}" => "${newPath}"');
                    server.sendMsg('#INK:' + ''.padRight(20, '='));
                    final io =
                        File(newPath).openWrite(mode: FileMode.writeOnly);
                    io.writeln(ink.well);
                    for (final item in ink.list) {
                      io.writeln(
                          '${item.depthN}\t${item.angleN}\t${item.azimuthN}');
                    }
                    await io.flush();
                    await io.close();
                  } else {
                    // On Error
                    final newPath = await getOutPathNew(
                        ss.pathOutErrors, p.basename(entity.path));
                    errorAdd('+INK("${entity.path}")');
                    errorAdd('\t"${entity.path}" => "${newPath}"');
                    for (final err in ink.listOfErrors) {
                      errorAdd('\t$err');
                    }
                    errorAdd(''.padRight(20, '='));
                    try {
                      await entity.copy(newPath);
                    } catch (e) {
                      errorAdd('+FILE_COPY: ${entity.path} => $newPath');
                      errorAdd('\t$e');
                      errorAdd(''.padRight(20, '='));
                    }
                  }
                }
              });
            }
          }
        }
      }
    }
  }

  Future onWorkEnd() async {
    print('Work Ended');
    server.sendMsg('#DONE!');
  }

  Future<bool> reqWhileWork(
      HttpRequest req, String content, MyServer serv) async {
    final response = req.response;
    response.headers.contentType = ContentType.html;
    response.statusCode = HttpStatus.ok;
    await response.addStream(File(r'web/action.html').openRead());
    await response.flush();
    await response.close();
    return true;
  }

  Future<bool> reqBeforeWork(
      HttpRequest req, String content, MyServer serv) async {
    if (content.isEmpty) {
      await ss.servSettings(req.response);
      return true;
    } else {
      serv.handleRequest = reqWhileWork;
      ss.updateByMultiPartFormData(parseMultiPartFormData(content));
      await ss.initializing();
      ss.pathInList.forEach((element) {
        if (element.isNotEmpty) {
          print('pathInList => $element');
          tasks.add(FileSystemEntity.type(element).then((value) => value ==
                  FileSystemEntityType.file
              ? listFilesGet(0, '')(File(element), element)
              : value == FileSystemEntityType.directory
                  ? Directory(element)
                      .list(recursive: true)
                      .listen((entity) =>
                          tasks2.add(listFilesGet(0, '')(entity, entity.path)))
                      .asFuture()
                  : null));
        }
      });

      workEnd = Future.wait(tasks)
          .then((_) => Future.wait(tasks2).then((_) => onWorkEnd()));
      return reqWhileWork(req, content, serv);
    }
  }

  server.handleRequest = reqBeforeWork;
  await server.bind(4040);
  if (ss.errorsOut != null) {
    await ss.errorsOut.flush();
    await ss.errorsOut.close();
  }
}
