import 'dart:io';
import 'dart:typed_data';
import 'package:knc/www.dart';
import 'package:knc/xls.dart';
import 'package:path/path.dart' as p;
import 'dart:convert';

import 'ink.dart';
import 'mapping.dart';
import 'unzipper.dart';
import 'las.dart';

int calculate() {
  return 6 * 7;
}

final _reservedPathNew = <String>[];

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
      } while (_reserved.contains(n) ||
          await FileSystemEntity.type(o) != FileSystemEntityType.notFound);
      _reserved.add(n);
      return o;
    }
  }

  /// Отменить резервацию файла
  bool unlock(final String name) => _reserved.remove(p.basename(name));
}

/// Подбирает новое имя для файла, если он уже существует в папке [prePath]
/// И резервирует его
///
/// [prePath] - это путь именно к существующей папке
///
/// [name] (opt) - это может быть как путь, так и только имя
/// Если он остуствует то резервация снимается со файла
/// указанным в [preParh]
@deprecated
Future<String> getOutPathNew(String prePath, [String name]) async {
  if (name == null) {
    _reservedPathNew.remove(prePath);
    return null;
  }
  var o = p.join(prePath, p.basename(name));
  if (await File(o).exists() || _reservedPathNew.contains(o)) {
    final f0 = p.join(prePath, p.basenameWithoutExtension(name));
    final fe = p.extension(name);
    var i = 0;
    var o = '${f0}_$i$fe';
    while (await File(o).exists() || _reservedPathNew.contains(o)) {
      i++;
      o = '${f0}_$i$fe';
    }
    _reservedPathNew.add(o);
    return o;
  } else {
    _reservedPathNew.add(o);
    return o;
  }
}

class KncSettings extends KncSettingsInternal {
  String pathOutLas;
  String pathOutInk;
  String pathOutErrors;
  IOSink errorsOut;

  final lasDB = LasDataBase();
  dynamic lasIgnore;

  final inkDB = InkDataBase();
  dynamic inkDbfMap;

  Unzipper unzipper;

  final lasCurvesNameOriginals = <String>[];

  /// Загрузкить все данные
  Future get loadAll => Future.wait(
      [loadCharMaps(), loadLasIgnore(), loadInkDbfMap(), serchPrograms()]);

  /// Загружает кодировки и записывает их в настройки
  Future<Map<String, List<String>>> loadCharMaps() =>
      loadMappings('mappings').then((charmap) => ssCharMaps = charmap);

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
    final dirOut = Directory(ssPathOut);
    if (await dirOut.exists()) {
      await dirOut.delete(recursive: true);
    }
    await dirOut.create(recursive: true);
    if (dirOut.isAbsolute == false) {
      ssPathOut = dirOut.absolute.path;
    }

    unzipper = Unzipper(p.join(ssPathOut, 'temp'), ssPath7z);

    pathOutLas = p.join(ssPathOut, 'las');
    pathOutInk = p.join(ssPathOut, 'ink');
    pathOutErrors = p.join(ssPathOut, 'errors');

    await Future.wait([
      unzipper.clear(),
      Directory(pathOutLas).create(recursive: true),
      Directory(pathOutInk).create(recursive: true),
      Directory(pathOutErrors).create(recursive: true)
    ]);

    errorsOut = File(p.join(pathOutErrors, '.errors.txt'))
        .openWrite(encoding: utf8, mode: FileMode.writeOnly);
    errorsOut.writeCharCode(unicodeBomCharacterRune);
  }

  /// Отправляет страницу с натсройками
  Future servSettings(final HttpResponse response) async {
    response.headers.contentType = ContentType.html;
    response.statusCode = HttpStatus.ok;
    response.write(
        updateBufferByThis(await File(r'web/index.html').readAsString()));
    await response.flush();
    await response.close();
  }

  static const _SearchPath_7Zip = [
    r'C:\Program Files\7-Zip\7z.exe',
    r'C:\Program Files (x86)\7-Zip\7z.exe'
  ];

  /// Ищет где находися программа 7Zip
  static Future<String> searchProgram_7Zip() => Future.wait(
      _SearchPath_7Zip.map(
          (e) => File(e).exists().then((exist) => exist ? e : null))).then(
      (list) =>
          list.firstWhere((element) => element != null, orElse: () => null));

  static const _SearchPath_WordConv = [
    r'C:\Program Files\Microsoft Office',
    r'C:\Program Files (x86)\Microsoft Office'
  ];

  /// Ищет где находися программа WordConv
  static Future<String> searchProgram_WordConv() =>
      Future.wait(_SearchPath_WordConv.map((e) => Directory(e).exists().then((exist) => exist
              ? Directory(e).list(recursive: true, followLinks: false).firstWhere(
                  (file) =>
                      file is File &&
                      p.basename(file.path).toLowerCase() == 'wordconv.exe',
                  orElse: () => null)
              : null)))
          .then((list) => list.firstWhere((element) => element != null, orElse: () => null))
          .then((entity) => entity != null ? entity.path : null);

  /// Устанавливает переменные путей программ в найденные,
  /// возвращает список путей к программам
  ///
  /// Переменные установятся только если дождатся обещанного выполнения
  Future<List<String>> serchPrograms() => Future.wait([
        searchProgram_7Zip().then((path) => ssPath7z = path),
        searchProgram_WordConv().then((path) => ssPathWordconv = path),
      ]);

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
      print('Work Ended');
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
          final ext = p.extension(entity.path).toLowerCase();
          // == UNZIPPER == Begin
          if (unzipper != null && ssFileExtAr.contains(ext)) {
            try {
              if (ssArMaxSize > 0) {
                // если максимальный размер архива установлен
                if (await entity.length() < ssArMaxSize &&
                    (ssArMaxDepth == -1 || iArchDepth < ssArMaxDepth)) {
                  // вскрываем архив если он соотвествует размеру и мы не привысили глубину вложенности
                  await unzipper.unzip(
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
                await unzipper.unzip(
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
                final newPath = await getOutPathNew(
                    pathOutLas, las.wWell + '___' + p.basename(entity.path));
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
                await getOutPathNew(newPath);
              } else {
                // Ошибка в данных файла
                final newPath =
                    await getOutPathNew(pathOutErrors, p.basename(entity.path));
                if (handleErrorLas != null) {
                  await handleErrorLas(las, entity, newPath);
                }

                await getOutPathNew(newPath);
              }
            } catch (e) {
              if (handleErrorCatcher != null) {
                await handleErrorCatcher(e);
              }
            }
            return;
          } // == LAS FILES == End

          // == INK FILES == Begin
          if (ssFileExtInk.contains(ext)) {
            try {
              final inks = await InkData.loadFile(entity, this,
                  handleErrorCatcher: handleErrorCatcher);
              if (inks != null) {
                for (final ink in inks) {
                  if (ink != null) {
                    ink.origin = pathToArch + relPath;
                    if (ink.listOfErrors.isEmpty) {
                      // Данные корректны
                      final newPath = await getOutPathNew(
                          pathOutInk,
                          ink.well +
                              '___' +
                              p.basenameWithoutExtension(entity.path) +
                              '.txt');
                      final original = inkDB.addInkData(ink);
                      if (handleOkInk != null) {
                        await handleOkInk(ink, entity, newPath, original);
                      }
                      await getOutPathNew(newPath);
                    } else {
                      // Ошибка в данных файла
                      final newPath = await getOutPathNew(
                          pathOutErrors, p.basename(entity.path));
                      if (handleErrorInk != null) {
                        await handleErrorInk(ink, entity, newPath);
                      }
                      await getOutPathNew(newPath);
                    }
                  }
                }
              }
            } catch (e) {
              if (handleErrorCatcher != null) {
                await handleErrorCatcher(e);
              }
            }
            return;
          } // == INK FILES == End
        }
      };

  /// Создаёт конечную таблицу XLSX в папке `web` и возвращает путь к файлу таблицы
  Future<String> createXlTable() async {
    final dir = (await Directory('web').createTemp()).absolute;
    final o = p.join(dir.path, 'table.xlsx');
    final xls =
        await KncXlsBuilder.start(Directory(p.join(dir.path, 'xlsx')), true);
    xls.addDataBases(lasDB, inkDB);
    await Future.wait([xls.rewriteSharedStrings(), xls.rewriteSheet1()]);
    await unzipper.zip(xls.dir.path, o);
    return o;
  }

  Future<ProcessResult> runDoc2X(
          final String path2doc, final String path2out) =>
      Process.run(ssPathWordconv, ['-oice', '-nme', path2doc, path2out]);
}
