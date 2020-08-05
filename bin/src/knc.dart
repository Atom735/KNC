import 'dart:async';
import 'dart:io';
import 'dart:isolate';
import 'dart:convert';
import 'dart:typed_data';

import 'package:knc/ArchiverOtput.dart';
import 'package:knc/errors.dart';
import 'package:knc/www.dart';
import 'package:path/path.dart' as p;
import 'package:knc/SocketWrapper.dart';

import 'ink.dart';
import 'knc.main.dart';
import 'las.dart';

const msgTaskUpdateState = 'taskstate;';
const msgTaskUpdateErrors = 'taskerrors;';
const msgTaskUpdateFiles = 'taskfiles;';
const msgDoc2x = 'doc2x;';
const msgZip = 'zip;';
const msgUnzip = 'unzip;';

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

class KncTask extends KncTaskSpawnSets {
  /// Порт для получение сообщений этим изолятом
  final ReceivePort receivePort = ReceivePort();
  final SocketWrapper wrapper;

  /// Путь к конечным данным
  final String pathOut;

  final String pathOutLas;
  final PathNewer newerOutLas;

  final String pathOutInk;
  final PathNewer newerOutInk;

  final String pathOutErr;
  final PathNewer newerOutErr;

  final IOSink errorsOut;

  final lasDB = LasDataBase();
  dynamic lasIgnore;

  final inkDB = InkDataBase();
  dynamic inkDbfMap;

  final lasCurvesNameOriginals = <String>[];

  int _state = 0;
  set state(final int i) {
    if (i == null || _state == i) {
      return;
    }
    _state = i;
    wrapper.send(0, '$msgTaskUpdateState$_state');
  }

  int _errors = 0;
  set errors(final int i) {
    if (i == null || _errors == i) {
      return;
    }
    _errors = i;
    wrapper.send(0, '$msgTaskUpdateErrors$_errors');
  }

  int _files = 0;
  set files(final int i) {
    if (i == null || _files == i) {
      return;
    }
    _files = i;
    wrapper.send(0, '$msgTaskUpdateFiles$_files');
  }

  final listOfErrors = <CErrorOnLine>[];
  final listOfFiles = <C_File>[];

  static void entryPoint(final KncTaskSpawnSets sets) async {
    final pathOut = (await Directory('temp').createTemp('task.')).absolute.path;
    await KncTask(sets, pathOut).entryPointInClass();
  }

  Future entryPointInClass() async {
    await Future.wait([
      Directory(pathOutLas).create(recursive: true),
      Directory(pathOutInk).create(recursive: true),
      Directory(pathOutErr).create(recursive: true)
    ]);
    state = 1;
    final fs = <Future>[];
    final func = listFilesGet(0, '');
    path.forEach((element) {
      if (element.isNotEmpty) {
        print('task[$id] scan $element');
        fs.add(FileSystemEntity.type(element).then((value) =>
            value == FileSystemEntityType.file
                ? func(File(element), element)
                : value == FileSystemEntityType.directory
                    ? func(Directory(element), element)
                    : null));
      }
    });
  }

  Future handleFile(final File file, final String origin) async {
    final ext = p.extension(file.path).toLowerCase();
    try {
      if (ssFileExtLas.contains(ext)) {
        // == LAS FILES == Begin
        final las = LasData(UnmodifiableUint8ListView(await file.readAsBytes()),
            charMaps, lasIgnore);
        las.origin = origin;
        if (las.listOfErrors.isEmpty) {
          // Данные корректны
          final newPath =
              await newerOutLas.lock(las.wWell + '___' + p.basename(file.path));
          final originals = lasDB.addLasData(las);
          for (var i = 1; i < las.curves.length; i++) {
            final item = las.curves[i];
            if (!lasCurvesNameOriginals.contains(item.mnem)) {
              lasCurvesNameOriginals.add(item.mnem);
            }
          }
          try {
            if (originals.any((e) => e.added)) {
              await file.copy(newPath);
            }
          } catch (e) {
            listOfErrors.add(CErrorOnLine(
                origin, newPath, [ErrorOnLine(KncError.exception, 0, e)]));
            errors = listOfErrors.length;
            print(e);
          }
          listOfFiles.add(CLasFile(origin, newPath, las.wWell, originals));
          files = listOfFiles.length;
          // TODO: обработка LAS файла
          await newerOutLas.unlock(newPath);
        } else {
          // Ошибка в данных файла
          final newPath = await newerOutErr.lock(p.basename(file.path));
          listOfErrors.add(CErrorOnLine(origin, newPath, las.listOfErrors));
          errors = listOfErrors.length;
          try {
            await file.copy(newPath);
          } catch (e) {
            listOfErrors.add(CErrorOnLine(
                origin, newPath, [ErrorOnLine(KncError.exception, 0, e)]));
            errors = listOfErrors.length;
            print(e);
          }
          // TODO: обработка ошибок LAS файла
          await newerOutErr.unlock(newPath);
        }
      } // == LAS FILES == End
      else if (ssFileExtInk.contains(ext)) {
        // == INK FILES == Begin
        final inks = await InkData.loadFile(file, this);
        if (inks != null) {
          for (final ink in inks) {
            if (ink != null) {
              ink.origin = origin;
              if (ink.listOfErrors.isEmpty) {
                // Данные корректны
                final newPath = await newerOutInk.lock(ink.well +
                    '___' +
                    p.basenameWithoutExtension(file.path) +
                    '.txt');
                final original = inkDB.addInkData(ink);

                try {
                  if (original) {
                    final io =
                        File(newPath).openWrite(mode: FileMode.writeOnly);
                    io.writeln(ink.well);
                    final dat = ink.inkData;
                    for (final item in dat.data) {
                      io.writeln(
                          '${item.depth}\t${item.angle}\t${item.azimuth}');
                    }
                    await io.flush();
                    await io.close();
                  }
                } catch (e) {
                  listOfErrors.add(CErrorOnLine(origin, newPath,
                      [ErrorOnLine(KncError.exception, 0, e)]));
                  errors = listOfErrors.length;
                  print(e);
                }
                listOfFiles.add(CInkFile(
                    origin, newPath, ink.well, ink.strt, ink.stop, original));
                files = listOfFiles.length;
                // TODO: обработка INK файла
                await newerOutInk.unlock(newPath);
              } else {
                // Ошибка в данных файла
                final newPath = await newerOutErr.lock(p.basename(file.path));
                try {
                  await file.copy(newPath);
                } catch (e) {
                  listOfErrors.add(CErrorOnLine(origin, newPath,
                      [ErrorOnLine(KncError.exception, 0, e)]));
                  errors = listOfErrors.length;
                  print(e);
                }
                listOfErrors
                    .add(CErrorOnLine(origin, newPath, ink.listOfErrors));
                errors = listOfErrors.length;
                // TODO: бработка ошибок INK файла
                await newerOutErr.unlock(newPath);
              }
            }
          }
        }
        return;
      } // == INK FILES == End
    } catch (e) {
      // TODO: обработка исключений
    }

    // TODO: обработка файла
  }

  /// Получает новый экземляр функции для обхода по файлам
  /// с настоящими настройками
  /// [pathToArch] - путь к вскрытому архиву или папке
  /// [relPath] - путь относительный архива или папки
  /// Вне архива или папки, [relPath] - содержит полный путь
  /// а [pathToArch] - пустая строка, но не `null`
  Future Function(FileSystemEntity entity, String relPath) listFilesGet(
          final int iArchDepth, final String pathToArch) =>
      (final FileSystemEntity entity, final String relPath) async {
        if (entity is File) {
          if (p.basename(entity.path).toLowerCase().startsWith(r'~$')) {
            return;
          }
          final ext = p.extension(entity.path).toLowerCase();
          // == UNZIPPER == Begin
          if (ssFileExtAr.contains(ext)) {
            if ((ssArMaxSize <= 0 || await entity.length() < ssArMaxSize) &&
                (ssArMaxDepth == -1 || iArchDepth < ssArMaxDepth)) {
              // вскрываем архив если он соотвествует размеру если он установлен и мы не привысили глубину вложенности
              final arch = await unzip(entity.path);
              if (arch.exitCode == 0) {
                await listFilesGet(iArchDepth + 1, pathToArch + relPath)(
                    Directory(arch.pathOut), '');
                // TODO: удалить вскрытый архив
              } else {
                // TODO: обработка ошибки
                errors = _errors + 1;
              }
            } else {
              // отбрасываем большой архив или бОльшую глубину вложенности
              return;
            }
          } // == UNZIPPER == End
          return handleFile(entity, pathToArch + relPath);
        } // entity is File
        else if (entity is Directory) {
          final func = listFilesGet(iArchDepth, pathToArch + relPath);
          final fs = <Future>[];
          final pl = entity.path.length;
          await entity.list(recursive: true).listen((event) {
            if (event is File) {
              fs.add(func(event, event.path.substring(pl)));
            }
          }).asFuture();
          await Future.wait(fs);
        }
      };

  /// Преобразует данные
  Future<int> doc2x(final String path2doc, final String path2out) => wrapper
      .requestOnce('$msgDoc2x$path2doc$msgRecordSeparator$path2out')
      .then((msg) => int.tryParse(msg));

  /// Запекает данные в zip архиф с помощью 7zip
  Future<ArchiverOutput> zip(
          final String pathToData, final String pathToOutput) =>
      wrapper
          .requestOnce('$msgZip$pathToData$msgRecordSeparator$pathToOutput')
          .then((value) => ArchiverOutput.fromWrapperMsg(value));

  /// Распаковывает архив [pathToArchive]
  Future<ArchiverOutput> unzip(final String pathToArchive) => wrapper
      .requestOnce('$msgUnzip$pathToArchive')
      .then((value) => ArchiverOutput.fromWrapperMsg(value));

  KncTask._init(final KncTaskSpawnSets sets, this.pathOut)
      : pathOutLas = p.join(pathOut, 'las'),
        newerOutLas = PathNewer(p.join(pathOut, 'las')),
        pathOutInk = p.join(pathOut, 'ink'),
        newerOutInk = PathNewer(p.join(pathOut, 'ink')),
        pathOutErr = p.join(pathOut, 'errors'),
        newerOutErr = PathNewer(p.join(pathOut, 'errors')),
        errorsOut = File(p.join(pathOut, 'errors.txt'))
            .openWrite(encoding: utf8, mode: FileMode.writeOnly)
              ..writeCharCode(unicodeBomCharacterRune),
        wrapper = SocketWrapper((msg) => sets.sendPort.send([sets.id, msg])),
        super.clone(sets) {
    print('KncTask created: $hashCode');
    receivePort.listen((final msg) {
      if (msg is String) {
        wrapper.recv(msg);
        return;
      }
      print('task[$id]: recieved unknown msg {$msg}');
    });
    sendPort.send([id, receivePort.sendPort, pathOut]);
  }
  static KncTask _instance;
  factory KncTask([final KncTaskSpawnSets sets, final String pathOut]) =>
      _instance ?? (_instance = KncTask._init(sets, pathOut));

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
}
