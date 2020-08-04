import 'dart:async';
import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';
import 'dart:convert';

import 'package:path/path.dart' as p;
import 'package:knc/errors.dart';
import 'package:knc/www.dart';
import 'package:knc/SocketWrapper.dart';

import 'ink.dart';
import 'las.dart';
import 'xls.dart';

const msgTaskPathOutSets = 'pathout;';
const msgTaskUpdateState = 'taskstate;';

class PathNewer {
  /// Путь именно к существующей папке, в которой будет подбираться имя
  final String prePath;

  /// Список зарезервированных имён файлов/папок
  final _reserved = <String>[];

  /// [prePath] - это путь именно к существующей папке
  PathNewer(this.prePath);

  /// Подбирает новое имя для файла, если он уже существует в папке [prePath]
  /// И резервирует его
  Future<String> lock(final String name) async {
    var n = p.basename(name);
    var o = p.join(prePath, n);
    if (!_reserved.contains(n) &&
        await FileSystemEntity.type(o) == FileSystemEntityType.notFound) {
      // Если имя не зарезрвированно и файла с таким именем не существует
      _reserved.add(p.basename(name));
      return o;
    } else {
      final fn = p.basenameWithoutExtension(name);
      final fe = p.extension(name);
      var i = 0;
      do {
        n = '${fn}_${i}${fe}';
        o = p.join(prePath, n);
        i += 1;
      } while (_reserved.contains(n) ||
          await FileSystemEntity.type(o) != FileSystemEntityType.notFound);
      _reserved.add(n);
      return o;
    }
  }

  /// Отменить резервацию файла
  bool unlock(final String name) => _reserved.remove(p.basename(name));
}

class CompleterWithUID<T> {
  final Completer<T> completer;
  final int uID;
  final String desc;

  CompleterWithUID(this.completer, this.uID, [this.desc]);
}

class KncTask extends KncSettingsInternal {
  /// Порт для передачи данных главному изоляту
  SendPort sendPort;

  /// Порт для получение сообщений этим изолятом
  ReceivePort receivePort;

  String pathOutLas;
  String pathOutInk;
  String pathOutErr;
  IOSink errorsOut;

  PathNewer newerOutLas;
  PathNewer newerOutInk;
  PathNewer newerOutErr;

  SocketWrapper wrapper;

  /// Кодировки
  Map<String, List<String>> ssCharMaps;

  final lasDB = LasDataBase();
  dynamic lasIgnore;

  final inkDB = InkDataBase();
  dynamic inkDbfMap;

  final lasCurvesNameOriginals = <String>[];

  var _completersNewUID = 0;
  final _completers = <CompleterWithUID>[];

  CompleterWithUID<T> completerAdd<T>([final String desc]) {
    final o = CompleterWithUID<T>(Completer(), _completersNewUID += 1, desc);
    _completers.add(o);
    return o;
  }

  void completerComplite<T>(final int uID, final T value) => _completers.remove(
      _completers.singleWhere((e) => e.uID == uID)..completer.complete(value));

  KncTask();

  @override
  set iState(KncTaskState state) {
    if (super.iState == state) {
      return;
    }

    super.iState = state;
    wrapper.send(0, '$msgTaskUpdateState${super.iState.index}');
  }

  @override
  set pathToTable(String path) {
    super.pathToTable = path;
    sendMsg('$wwwKncTaskUpdateXlsTable${pathToTable}');
  }

  void sendMsg(final String txt) {
    lastWsMsg = txt;
    sendPort.send([uID, txt]);
  }

  void errorAdd(final String txt) {
    errorsOut.writeln(txt);
    sendMsg('$wwwMsgError$txt');
  }

  /// Обработчик исключений
  Future handleErrorCatcher(dynamic e) async {
    errorsOut.writeln(e.toString());
    sendMsg('$wwwMsgException${e.toString()}');
  }

  /// Обработчик готовых Las данных
  Future handleOkLas(
      LasData las, File file, String newPath, int originals) async {
    try {
      if (originals > 0) {
        await file.copy(newPath);
        sendMsg('${wwwMsgLasBegin}"${las.origin}"');
        sendMsg('${wwwMsgLas}В базу добавлено ${originals} кривых');
        sendMsg('${wwwMsgLas}"${file.path}" => "${newPath}"');
        sendMsg('${wwwMsgLas}"Well: ${las.wWell}');
        for (final c in las.curves) {
          sendMsg('${wwwMsgLas}${c.mnem}: ${c.strtN} <=> ${c.stopN}');
        }
        sendMsg(wwwMsgLasEnd);
      }
    } catch (e) {
      await handleErrorCatcher(e);
    }
  }

  /// Обработчик ошибочных Las данных
  Future handleErrorLas(LasData las, File file, String newPath) async {
    try {
      await file.copy(newPath);
    } catch (e) {
      await handleErrorCatcher(e);
    }
    errorAdd('+${wwwMsgLasBegin}${las.origin}');
    errorAdd('\t"${file.path}" => "${newPath}"');
    for (final err in las.listOfErrors) {
      errorAdd('\tСтрока ${err.line}: ${kncErrorStrings[err.err]}');
    }
    errorAdd(''.padRight(20, '='));
  }

  /// Обработчик готовых Ink данных
  Future handleOkInk(
      InkData ink, File file, String newPath, bool original) async {
    try {
      if (original) {
        sendMsg('${wwwMsgInkBegin}"${ink.origin}"');
        sendMsg('${wwwMsgInk}"${file.path}" => "${newPath}"');
        sendMsg('${wwwMsgInk}Well: ${ink.well}');
        sendMsg('${wwwMsgInk}${ink.strt} <=> ${ink.stop}');
        sendMsg(wwwMsgInkEnd);
        final io = File(newPath).openWrite(mode: FileMode.writeOnly);
        io.writeln(ink.well);
        final dat = ink.inkData;
        for (final item in dat.data) {
          io.writeln('${item.depth}\t${item.angle}\t${item.azimuth}');
        }
        await io.flush();
        await io.close();
      }
    } catch (e) {
      await handleErrorCatcher(e);
    }
  }

  /// Обработчик ошибочных Ink данных
  Future handleErrorInk(InkData ink, File file, String newPath) async {
    try {
      await file.copy(newPath);
    } catch (e) {
      await handleErrorCatcher(e);
    }
    errorAdd('+${wwwMsgInkBegin}${ink.origin}');
    errorAdd('\t"${file.path}" => "${newPath}"');
    for (final err in ink.listOfErrors) {
      errorAdd('\tСтрока ${err.line}: ${kncErrorStrings[err.err]}');
    }
    errorAdd(''.padRight(20, '='));
  }

  /// Точка входа для нового изолята
  static void isolateEntryPoint(KncTask task) => task.isolateEntryPointThis();

  void isolateEntryPointThis() async {
    receivePort = ReceivePort();
    wrapper = SocketWrapper((msg) => sendPort.send([uID, msg]));

    receivePort.listen((final msg) {
      if (msg is String) {
        wrapper.recv(msg);
        return;
      }
      // Прослушивание сообщений полученных от главного изолята
      if (msg is List) {
        if (msg[0] is String) {
          switch (msg[0]) {
            case 'unzip':
            case 'zip':
              completerComplite(msg[1], msg[2] as String);
              return;
            case 'doc2x':
              completerComplite(msg[1], msg[2] as int);
              return;
          }
        }
      }
      print('task[$uID]: recieved unknown msg {$msg}');
    });

    sendPort.send([uID, receivePort.sendPort]);

    print('task[$uID]: Work Init');
    await initializing();
    print('task[$uID]: Work Begin');

    await startWork(
        handleErrorCatcher: handleErrorCatcher,
        handleOkLas: handleOkLas,
        handleErrorLas: handleErrorLas,
        handleOkInk: handleOkInk,
        handleErrorInk: handleErrorInk);

    print('task[$uID]: Work End');
  }

  /// Преобразует данные
  Future<int> doc2x(final String path2doc, final String path2out) {
    final c = completerAdd<int>('doc2x $path2doc => $path2out');
    // отправляем запрос на распаковку
    sendPort.send([uID, 'doc2x', c.uID, path2doc, path2out]);
    return c.completer.future;
  }

  /// Запекает данные в zip архиф с помощью 7zip
  Future<String> zip(final String pathToData, final String pathToOutput) {
    final c = completerAdd<String>('zip $pathToData => $pathToOutput');
    // отправляем запрос на распаковку
    sendPort.send([uID, 'zip', c.uID, pathToData, pathToOutput]);
    return c.completer.future;
  }

  /// Распаковывает архив [pathToArchive]
  /// Отправляет сообщение главному потоку который как раз и занимается разархивированием
  Future unzip(String pathToArchive,
      [Future Function(FileSystemEntity entity, String relPath) funcEntity,
      Future Function(dynamic taskListEnded) funcEnd]) async {
    final c = completerAdd<String>('unzip $pathToArchive => ???');
    // отправляем запрос на распаковку
    sendPort.send([uID, 'unzip', c.uID, pathToArchive]);
    // Ожидаем распаковку
    final err = await c.completer.future;
    final i0 = err.indexOf(':', 1);
    final i1 = err.indexOf('#', i0 + 1);
    final i2 = err.indexOf('"', i1 + 1);
    final i3 = err.indexOf('"', i2 + 1);
    // final i4 = err.indexOf('^!@#\$', i3 + 1);
    // final eCode = err.substring(i0+1, i1);
    final eOutPut = err.substring(i2 + 1, i3);
    // final eStdOut = err.substring(i3 + 1, i4);
    // final eStdErr = err.substring(i4 + 5);
    if (err[0] == 'O') {
      // Если успешно распокавали
      final tasks = <Future>[];
      final dir = Directory(eOutPut).absolute;
      await dir
          .list(recursive: true, followLinks: false)
          .listen((entity) {
            if (funcEntity != null) {
              tasks.add(
                  funcEntity(entity, entity.path.substring(dir.path.length)));
            }
          })
          .asFuture(tasks)
          .then((taskList) => Future.wait(taskList).then((taskListEnded) =>
              funcEnd != null
                  ? funcEnd(taskListEnded)
                      .then((_) => dir.delete(recursive: true))
                  : dir.delete(recursive: true)));
    } else {
      await handleErrorCatcher(err);
    }
  }

  KncTask.fromSettings(final KncSettingsInternal ss) {
    uID = ss.uID;
    ssTaskName = ss.ssTaskName;
    ssPathOut = ss.ssPathOut;
    ssFileExtAr = [];
    ssFileExtAr.addAll(ss.ssFileExtAr);
    ssFileExtLas = [];
    ssFileExtLas.addAll(ss.ssFileExtLas);
    ssFileExtInk = [];
    ssFileExtInk.addAll(ss.ssFileExtInk);
    pathInList = [];
    pathInList.addAll(ss.pathInList);
    ssArMaxSize = ss.ssArMaxSize;
    ssArMaxDepth = ss.ssArMaxDepth;
  }

  /// Загрузкить все данные
  Future get loadAll => Future.wait([loadLasIgnore(), loadInkDbfMap()]);

  /// Загружает таблицу игнорирования полей LAS файла
  Future loadLasIgnore() => File(r'data/las.ignore.json')
      .readAsString(encoding: utf8)
      .then((buffer) => lasIgnore = json.decode(buffer));

  /// Загружает таблицу переназначения полей DBF для инклинометрии
  Future loadInkDbfMap() => File(r'data/ink.dbf.map.json')
      .readAsString(encoding: utf8)
      .then((buffer) => inkDbfMap = json.decode(buffer));

  /// Очищает папки, подготавливает распаковщик,
  /// открывает файл с ошибками для записи
  Future<void> initializing() async {
    if (ssPathOut == null || ssPathOut.isEmpty) {
      ssPathOut = (await Directory('temp').createTemp('task.')).absolute.path;
    } else {
      final dirOut = Directory(ssPathOut).absolute;
      if (await dirOut.exists()) {
        await dirOut.delete(recursive: true);
      }
      await dirOut.create(recursive: true);
      if (dirOut.isAbsolute == false) {
        ssPathOut = dirOut.absolute.path;
      }
    }

    Future f = wrapper.requestOnce('$msgTaskPathOutSets$ssPathOut');

    pathOutLas = p.join(ssPathOut, 'las');
    pathOutInk = p.join(ssPathOut, 'ink');
    pathOutErr = p.join(ssPathOut, 'errors');

    await Future.wait([
      Directory(pathOutLas).create(recursive: true),
      Directory(pathOutInk).create(recursive: true),
      Directory(pathOutErr).create(recursive: true)
    ]);

    newerOutLas = PathNewer(pathOutLas);
    newerOutInk = PathNewer(pathOutInk);
    newerOutErr = PathNewer(pathOutErr);

    errorsOut = File(p.join(pathOutErr, '.errors.txt'))
        .openWrite(encoding: utf8, mode: FileMode.writeOnly);
    errorsOut.writeCharCode(unicodeBomCharacterRune);

    return f;
  }

  /// Начинает обработку файлов с настоящими настройками
  /// - [handleErrorCatcher] (opt) - обработчик ошибки от архиватора
  /// - [handleOkLas] (opt) - обработчик разобранного Las файла
  /// - [handleErrorLas] (opt) - обработчик ошибок разобранного Las файла
  /// - [handleOkLas] (opt) - обработчик разобранного Ink файла
  /// - [handleErrorLas] (opt) - обработчик ошибок разобранного Ink файла
  ///
  /// возвращает Future который завершится по обработке всех файлов
  Future startWork({
    final Future Function(dynamic e) handleErrorCatcher,
    final Future Function(LasData las, File file, String newPath, int originals)
        handleOkLas,
    final Future Function(LasData las, File file, String newPath)
        handleErrorLas,
    final Future Function(InkData ink, File file, String newPath, bool original)
        handleOkInk,
    final Future Function(InkData ink, File file, String newPath)
        handleErrorInk,
  }) async {
    iState = KncTaskState.work;
    final tasks = <Future>[];
    final tasks2 = <Future>[];
    pathInList.forEach((element) {
      if (element.isNotEmpty) {
        print('pathInList => $element');
        tasks.add(FileSystemEntity.type(element).then((value) => value ==
                FileSystemEntityType.file
            ? listFilesGet(0, '',
                handleErrorCatcher: handleErrorCatcher,
                handleOkLas: handleOkLas,
                handleErrorLas: handleErrorLas,
                handleOkInk: handleOkInk,
                handleErrorInk: handleErrorInk)(File(element), element)
            : value == FileSystemEntityType.directory
                ? Directory(element)
                    .list(recursive: true)
                    .listen((entity) => tasks2.add(listFilesGet(0, '',
                        handleErrorCatcher: handleErrorCatcher,
                        handleOkLas: handleOkLas,
                        handleErrorLas: handleErrorLas,
                        handleOkInk: handleOkInk,
                        handleErrorInk: handleErrorInk)(entity, entity.path)))
                    .asFuture()
                : null));
      }
    });
    await Future.wait(tasks).then((_) => Future.wait(tasks2)).then((_) async {
      // iState = KncTaskState.savesDatas;
      lasCurvesNameOriginals.sort((a, b) => a.compareTo(b));
      await Future.wait([
        File(p.join(pathOutLas, '.cs.txt'))
            .writeAsString(lasCurvesNameOriginals.join('\r\n')),
        lasDB.save(p.join(pathOutLas, '.db.bin')),
        inkDB.save(p.join(pathOutInk, '.db.bin'))
      ]);
      if (errorsOut != null) {
        await errorsOut.flush();
        await errorsOut.close();
        errorsOut = null;
      }
      iState = KncTaskState.generateTable;
      pathToTable = await createXlTable();
      iState = KncTaskState.end;
    });
  }

  /// Получает новый экземляр функции для обхода по файлам
  /// с настоящими настройками
  /// - [handleErrorCatcher] (opt) - обработчик ошибки от архиватора
  /// - [handleOkLas] (opt) - обработчик разобранного Las файла
  /// - [handleErrorLas] (opt) - обработчик ошибок разобранного Las файла
  /// - [handleOkLas] (opt) - обработчик разобранного Ink файла
  /// - [handleErrorLas] (opt) - обработчик ошибок разобранного Ink файла
  Future Function(FileSystemEntity entity, String relPath) listFilesGet(
    final int iArchDepth,
    final String pathToArch, {
    final Future Function(dynamic e) handleErrorCatcher,
    final Future Function(LasData las, File file, String newPath, int originals)
        handleOkLas,
    final Future Function(LasData las, File file, String newPath)
        handleErrorLas,
    final Future Function(InkData ink, File file, String newPath, bool original)
        handleOkInk,
    final Future Function(InkData ink, File file, String newPath)
        handleErrorInk,
  }) =>
      (final FileSystemEntity entity, final String relPath) async {
        // [pathToArch] - путь к вскрытому архиву
        // [relPath] - путь относительный архива
        // Вне архива, [relPath]- содержит полный путь
        // а [pathToArch] - пустая строка, но не `null`
        if (entity is File) {
          if (p.basename(entity.path).toLowerCase().startsWith(r'~$')) {
            return;
          }
          final ext = p.extension(entity.path).toLowerCase();
          // == UNZIPPER == Begin
          if (ssFileExtAr.contains(ext)) {
            try {
              if (ssArMaxSize > 0) {
                // если максимальный размер архива установлен
                if (await entity.length() < ssArMaxSize &&
                    (ssArMaxDepth == -1 || iArchDepth < ssArMaxDepth)) {
                  // вскрываем архив если он соотвествует размеру и мы не привысили глубину вложенности
                  await unzip(
                      entity.path,
                      listFilesGet(iArchDepth + 1, pathToArch + relPath,
                          handleErrorCatcher: handleErrorCatcher,
                          handleOkLas: handleOkLas,
                          handleErrorLas: handleErrorLas,
                          handleOkInk: handleOkInk,
                          handleErrorInk: handleErrorInk));
                  return;
                } else {
                  // отбрасываем большой архив
                  return;
                }
              } else if (ssArMaxDepth == -1 || iArchDepth < ssArMaxDepth) {
                // если не указан размер, и мы не превысили вложенность
                await unzip(
                    entity.path,
                    listFilesGet(iArchDepth + 1, pathToArch + relPath,
                        handleErrorCatcher: handleErrorCatcher,
                        handleOkLas: handleOkLas,
                        handleErrorLas: handleErrorLas,
                        handleOkInk: handleOkInk,
                        handleErrorInk: handleErrorInk));
                return;
              } else {
                // игнорируем из за вложенности
                return;
              }
            } catch (e) {
              if (handleErrorCatcher != null) {
                await handleErrorCatcher(e);
              }
            }
            return;
          } // == UNZIPPER == End

          // == LAS FILES == Begin
          if (ssFileExtLas.contains(ext)) {
            try {
              final las = LasData(
                  UnmodifiableUint8ListView(await entity.readAsBytes()),
                  ssCharMaps,
                  lasIgnore);
              las.origin = pathToArch + relPath;
              if (las.listOfErrors.isEmpty) {
                // Данные корректны
                final newPath = await newerOutLas
                    .lock(las.wWell + '___' + p.basename(entity.path));
                final originals = lasDB.addLasData(las);
                for (var i = 1; i < las.curves.length; i++) {
                  final item = las.curves[i];
                  if (!lasCurvesNameOriginals.contains(item.mnem)) {
                    lasCurvesNameOriginals.add(item.mnem);
                  }
                }
                if (handleOkLas != null) {
                  await handleOkLas(las, entity, newPath, originals);
                }
                await newerOutLas.unlock(newPath);
              } else {
                // Ошибка в данных файла
                final newPath = await newerOutErr.lock(p.basename(entity.path));
                if (handleErrorLas != null) {
                  await handleErrorLas(las, entity, newPath);
                }

                await newerOutErr.unlock(newPath);
              }
            } catch (e) {
              if (handleErrorCatcher != null) {
                await handleErrorCatcher(e);
              }
            }
            return;
          } // == LAS FILES == End

          // == INK FILES == Begin
          // if (ssFileExtInk.contains(ext)) {
          //   try {
          //     final inks = await InkData.loadFile(entity, this,
          //         handleErrorCatcher: handleErrorCatcher);
          //     if (inks != null) {
          //       for (final ink in inks) {
          //         if (ink != null) {
          //           ink.origin = pathToArch + relPath;
          //           if (ink.listOfErrors.isEmpty) {
          //             // Данные корректны
          //             final newPath = await newerOutInk.lock(ink.well +
          //                 '___' +
          //                 p.basenameWithoutExtension(entity.path) +
          //                 '.txt');
          //             final original = inkDB.addInkData(ink);
          //             if (handleOkInk != null) {
          //               await handleOkInk(ink, entity, newPath, original);
          //             }
          //             await newerOutInk.unlock(newPath);
          //           } else {
          //             // Ошибка в данных файла
          //             final newPath =
          //                 await newerOutErr.lock(p.basename(entity.path));
          //             if (handleErrorInk != null) {
          //               await handleErrorInk(ink, entity, newPath);
          //             }
          //             await newerOutErr.unlock(newPath);
          //           }
          //         }
          //       }
          //     }
          //   } catch (e) {
          //     if (handleErrorCatcher != null) {
          //       await handleErrorCatcher(e);
          //     }
          //   }
          //   return;
          // } // == INK FILES == End
        }
      };

  /// Создаёт конечную таблицу XLSX и возвращает путь к файлу таблицы
  Future<String> createXlTable() async {
    final dir = Directory(ssPathOut);
    final o = p.join(dir.path, 'table.xlsx');
    final xls =
        await KncXlsBuilder.start(Directory(p.join(dir.path, 'xlsx')), true);
    xls.addDataBases(lasDB, inkDB);
    await Future.wait([xls.rewriteSharedStrings(), xls.rewriteSheet1()]);
    await zip(xls.dir.path, o);
    return o;
  }
}
