import 'dart:async';
import 'dart:io';
import 'dart:isolate';
import 'dart:convert';

import 'package:knc/knc.dart';
import 'package:knc/src/ink.txt.dart';
import 'package:knc/src/las.dart';
import 'package:knc/src/office.word.dart';
import 'package:path/path.dart' as p;

import 'FIleParserLas.dart';
import 'TaskController.dart';
import 'TaskSpawnSets.dart';
import 'misc.dart';
import 'FileParserDocx.dart';

class TaskIso extends SocketWrapper {
  /// Порт для получение сообщений этим изолятом
  final ReceivePort receivePort = ReceivePort();

  /// Данные полученные при спавне задачи
  final TaskSpawnSets sets;

  /// Настройки задачи
  JTaskSettings settings;

  /// Папка со всеми временными файлами (рабочими копиями)
  final Directory dirFiles;

  // final lasDB = LasDataBase();
  // dynamic lasIgnore;

  // final inkDB = InkDataBase();
  // dynamic inkDbfMap;

  // final lasCurvesNameOriginals = <String>[];

  /// Поток для записи иформации об ошибках в файл
  final IOSink errorsOut;

  /// Список всех найденных файлов
  final files = <JOneFileData>[];

  /// Обработанные файлы
  List parsedData;

  /// Состояние задачи
  final JTaskState state;

  /// Полный абсолютный путь к папке задачи
  final String pathAbsolute;

  // final listOfErrors = <CErrorOnLine>[];
  // final listOfFiles = <C_File>[];

  /// Точка входа для изолята
  static Future<void> entryPoint(final TaskSpawnSets sets) async {
    await TaskIso._init(sets, p.join(TaskController.dirTasks.path, sets.id))
        .entryPointInClass();
  }

  /// Точка входа изолята внутри класса
  Future<void> entryPointInClass() async {
    try {
      if (sets.exists) {
        final _fileState = File(p.join(pathAbsolute, 'state.json'));
        if (await _fileState.exists()) {
          final _k = await _fileState.readAsString();
          if (_k.isEmpty) {
            return;
          }
          final _v = jsonDecode(_k);
          state.map.addAll(_v);
          state.mapUpdates.addAll(_v);
          state.update();

          switch (state.state) {
            case NTaskState.searchFiles:
              await runSearchFiles();
              await runWorkFiles();
              break;
            case NTaskState.workFiles:
              await loadSearchFiles();
              await runWorkFiles();
              break;
            case NTaskState.generateTable:
              await loadSearchFiles(true);
              break;
            case NTaskState.completed:
              await loadSearchFiles(true);
              break;
            default:
              await dirFiles.create();
              await runSearchFiles();
              await runWorkFiles();
          }
        }
        await runGenerateTable();
        return;
      }
      await dirFiles.create();
      await runSearchFiles();
      await runWorkFiles();
      await runGenerateTable();
    } catch (e, s) {
      if (errorsOut != null) {
        errorsOut.writeln(DateTime.now().toIso8601String());
        errorsOut.writeln('!Isolate');
        errorsOut.writeln(e);
        errorsOut.writeln(s);
      }
    }
  }

  /// Процедура поиска файлов
  Future<void> runSearchFiles() async {
    /// Смена состояния на поиск файлов
    state.state = NTaskState.searchFiles;
    final fs = <Future>[];
    final func = listFilesGet(0, '');
    settings.path.forEach((element) {
      if (element.isNotEmpty) {
        print('$this scan $element');
        fs.add(FileSystemEntity.type(element)
            .then((value) => value == FileSystemEntityType.file
                ? func(File(element), element)
                : value == FileSystemEntityType.directory
                    ? func(Directory(element), element)
                    : null));
      }
    });
    await Future.wait(fs);
    await File(p.join(pathAbsolute, 'files.txt')).writeAsString(files
        .map((e) =>
            '${e.type.toString().substring(e.type.runtimeType.toString().length)}\n'
            '${e.origin}\n'
            '${p.relative(e.path, from: pathAbsolute)}\n'
            '${e.size}\n')
        .join());
  }

  /// Процедура поиска файлов
  Future<void> loadSearchFiles([bool withWorked = false]) async {
    files.clear();
    final _v = (await File(p.join(pathAbsolute, 'files.txt')).readAsString())
        .split('\n');
    final _vLenght = _v.length ~/ 4;
    for (var i = 0; i < _vLenght; i++) {
      files.add(JOneFileData(p.join(pathAbsolute, _v[i * 4 + 2]), _v[i * 4 + 1],
          NOneFileDataType.unknown, int.parse(_v[i * 4 + 3])));
    }
    if (withWorked) {
      final _fs = <Future>[];
      for (var i = 0; i < _vLenght; i++) {
        final _i = i;
        final _file = File(files[_i].path + '.json');
        _fs.add(_file.exists().then((b) {
          if (b) {
            return _file.readAsString().then((fdata) {
              state.worked = state.worked + 1;
              final fileDataNew = JOneFileData.byJson(jsonDecode(fdata));
              if (fileDataNew /*!*/ .notes != null) {
                if ((fileDataNew.notesError ?? 0) > 0) {
                  state.errors = state.errors + 1;
                }
                if ((fileDataNew.notesWarnings ?? 0) > 0) {
                  state.warnings = state.warnings + 1;
                }
              }
              files[_i] = fileDataNew;
            });
          } else {
            state.worked = state.worked + 1;
            return null;
          }
        }));
      }
      await Future.wait(_fs);
    }
  }

  /// Процедура обработки файлов
  Future<void> runWorkFiles() async {
    state.state = NTaskState.workFiles;
    final _l = files.length;
    parsedData = List(_l);
    await Future.wait(List.generate(_l, (i) => handleFile(i), growable: false));
    // for (var i = 0; i < _l; i++) {
    //   await handleFile(i);
    // }
  }

  /// Генерация таблицы
  Future<void> runGenerateTable() async {
    state.state = NTaskState.generateTable;
    final xlsDataIn = Directory(p.join('data', 'xls')).absolute;
    final xlsDataOut = Directory(p.join(pathAbsolute, 'raport')).absolute;
    await copyDirectoryRecursive(xlsDataIn, xlsDataOut);
    final xlsSheet =
        File(p.join(xlsDataOut.path, 'xl', 'worksheets', 'sheet1.xml'));
    final xlsSharedStrings =
        File(p.join(xlsDataOut.path, 'xl', 'sharedStrings.xml'));
    final xlsSheetTemplate = await xlsSheet.readAsString();
    final xlsSharedStringsTemplate = await xlsSharedStrings.readAsString();

    /// Список всех названий кривых
    final _methods = <String>[];

    /// Список всех названий скважин
    final _wells = <String>[];

    final _addedFiles = <JOneFileData>[];

    /// Заполняем списки названий скважин и кривых
    final _k = files.length;
    for (var k = 0; k < _k; k++) {
      final e = files[k];

      /// Пропускаем файлы без кривых
      if (e.curves == null) {
        continue;
      } else if (e.curves /*!*/ .length >= 2) {
        final _length = e.curves /*!*/ .length;
        for (var i = 0; i < _length; i++) {
          final _name = e.curves /*!*/ [i].name;
          final _well = e.curves /*!*/ [i].well;
          if (_name == '.ignore') {
            continue;
          }
          if (_well == '.ignore') {
            continue;
          }
          if (!_methods.contains(_name)) {
            _methods.add(_name);
          }
          if (!_wells.contains(_well)) {
            _wells.add(_well);
          }
        }
      }
    }

    /// Заполняем строки
    final _rows = <List<String /*?*/ >>[]; // WELL, INK, GISx2...
    final _methodsLength = _methods.length;
    for (var k = 0; k < _k; k++) {
      final e = files[k];

      /// Пропускаем файлы без кривых
      if (e.curves == null) {
        continue;
      }
      final _length = e.curves /*!*/ .length;

      for (var i = 0; i < _length; i++) {
        final _curve = e.curves /*!*/ [i];
        final _name = _curve.name;
        final _well = _curve.well;

        /// Пропускаем игнорируемые кривые
        if (_name == '.ignore') {
          continue;
        }
        if (_well == '.ignore') {
          continue;
        }

        /// Проверяем есть ли совпадения с уже добавленными в таблицу данными
        if (_addedFiles.isNotEmpty &&
            _addedFiles.any((e) => e.curves /*!*/ .any((c) => c == _curve))) {
          continue;
        }

        /// Подбираем номер колонки в зависимости от названия кривой
        final _i = _methods.indexOf(_name) * 2 + 2;

        /// Подбираем строку, чтобы совпадало название скважины
        /// и выбранная колонка была пустая, иначе создаём новую строку
        var _row = _rows.firstWhere((_e) => _e[0] == _well && _e[_i] == null,
            orElse: () {
          _rows.add(List.filled(_methodsLength * 2 + 2, null));
          return _rows.last..[0] = _well;
        });

        /// Записываем значения кривых в эти ячейки
        _row[_i] = e.curves /*!*/ [i].strt.toString();
        _row[_i + 1] = e.curves /*!*/ [i].stop.toString();
      }
    }

    final _length = _methods.length;
    final _sbMethods = StringBuffer();
    final _sbMerge = StringBuffer(
        '<mergeCell ref="H1:${numToXlsAlpha(_length * 2 + 5)}1"/>');
    for (var i = 0; i < _length; i++) {
      _sbMethods.write(
          '<c r="${numToXlsAlpha(i * 2 + 7)}2" s="1" t="inlineStr"><is><t>${_methods[i]}</t></is></c>');
      _sbMerge.write(
          '<mergeCell ref="${numToXlsAlpha(i * 2 + 7)}2:${numToXlsAlpha(i * 2 + 8)}2"/>');
    }

    final _sbRows = StringBuffer();
    final _rowsLength = _rows.length;
    for (var i = 0; i < _rowsLength; i++) {
      final _row = _rows[i];
      _sbRows.write('<row r="${i + 3}" x14ac:dyDescent="0.25">');
      _sbRows.write(
          '<c r="A${i + 3}" s="0" t="inlineStr"><is><t>_${_row[0]}</t></is></c>');
      final _rowLength = _row.length;
      for (var j = 2; j < _rowLength; j++) {
        if (_row[j] != null) {
          _sbRows.write(
              '<c r="${numToXlsAlpha(j + 5)}${i + 3}" s="0" t="n"><v>${_row[j]}</v></c>');
        }
      }
      _sbRows.write('</row>');
    }

    await xlsSharedStrings.writeAsString(xlsSharedStringsTemplate
        .replaceAll(r'$C$', _wells.length.toString())
        .replaceFirst(r'$S$', _wells.map((e) => '<si><t>$e</t></si>').join()));

    await xlsSheet.writeAsString(
        xlsSheetTemplate
            .replaceFirst(r'$METHODS$', _sbMethods.toString())
            .replaceFirst(r'$ROWS$', _sbRows.toString())
            .replaceFirst(r'$MERGE$', _sbMerge.toString()),
        mode: FileMode.writeOnly,
        flush: true);

    final xlsPath = xlsDataOut.path + '.xlsx';
    await zip(xlsDataOut.path, xlsPath);

    final _lFiles = files.length;

    /// Создание архива las файлов
    final lasArchPath = p.join(pathAbsolute, 'lases');
    final lasDir = Directory(lasArchPath);
    if (await lasDir.exists()) {
      await lasDir.delete(recursive: true);
    }
    await lasDir.create();
    final lasCopysFuture = <Future>[];
    final lasCopysNames = <String>[];
    for (var i = 0; i < _lFiles; i++) {
      final oneFile = files[i];
      if (oneFile.type == NOneFileDataType.las) {
        final file = File(oneFile.path);
        var newName = p.join(lasArchPath, p.basename(oneFile.origin));
        if (lasCopysNames.contains(newName)) {
          var j = 0;
          final baseName = p.basenameWithoutExtension(oneFile.origin);
          final ext = p.extension(oneFile.origin);
          do {
            newName = p.join(lasArchPath, '${baseName}_$j$ext');
            j++;
          } while (lasCopysNames.contains(newName));
        }
        lasCopysNames.add(newName);
        lasCopysFuture.add(file.copy(newName));
      }
    }

    await Future.wait(lasCopysFuture);
    await zip(lasArchPath, lasArchPath + '.zip');

    /// Создание архива ink файлов
    final inkArchPath = p.join(pathAbsolute, 'inks');
    final inkDir = Directory(inkArchPath);
    if (await inkDir.exists()) {
      await inkDir.delete(recursive: true);
    }
    await inkDir.create();
    final inkCopysFuture = <Future>[];
    final inkCopysNames = <String>[];
    for (var i = 0; i < _lFiles; i++) {
      final oneFile = files[i];
      if (oneFile.type == NOneFileDataType.ink_docx) {
        var newName = p.join(inkArchPath, oneFile.curves.first.well + '.txt');
        if (inkCopysNames.contains(newName)) {
          var j = 0;
          final baseName = oneFile.curves.first.well;
          final ext = '.txt';
          do {
            newName = p.join(inkArchPath, '${baseName}_$j$ext');
            j++;
          } while (inkCopysNames.contains(newName));
        }
        inkCopysNames.add(newName);
        final file = File(newName);
        final angle = oneFile.curves.first.data[0];
        final alt = oneFile.curves.first.data[1];
        final str = StringBuffer(oneFile.curves.first.well + '\r\n');
        final _dep = oneFile.curves[1].data;
        final _ang = oneFile.curves[2].data;
        final _azi = oneFile.curves[3].data;
        final _l = _dep.length;
        for (var i = 0; i < _l; i++) {
          str.write(_dep[i].toString() +
              '\t' +
              _ang[i].toString() +
              '\t' +
              (_azi[i] + angle).toString() +
              '\r\n');
        }

        inkCopysFuture.add(file.writeAsString(str.toString()));
      }
    }

    await Future.wait(inkCopysFuture);
    await zip(inkArchPath, inkArchPath + '.zip');

    send(0, JMsgTaskRaport(p.relative(xlsPath, from: pathAbsolute)).toString());
    state.raport = true;
    state.state = NTaskState.completed;
  }

  /// Обработка файлов во время поиска всех файлов
  Future<void> handleFileSearch(final File file, final String origin) async {
    final ext = p.extension(file.path).toLowerCase();
    if (settings.ext_files.contains(ext)) {
      /// Если файл необходимого расширения
      final i = state.files;
      state.files = state.files + 1;
      final pathToWorkingCopy =
          p.join(dirFiles.path, i.toRadixString(36).padLeft(8, '0') + ext);

      files.add(JOneFileData(pathToWorkingCopy, origin,
          NOneFileDataType.unknown, await file.length()));

      await tryFunc(() => file.copy(pathToWorkingCopy),
          onError: errorsOut.writeln);
    }
  }

  /// Обрабтчик файлов
  Future<void> handleFile(final int _i) async {
    final fileData = files[_i];
    final file = File(fileData.path);
    final data =
        await tryFunc<List<int>>(() => file.readAsBytes(), onError: (e) {
      errorsOut.writeln(DateTime.now().toIso8601String());
      errorsOut.writeln('!Handle File');
      errorsOut.writeln(e);
      return [];
    });

    /// Если не удалось считать данные файла или файл пустой,
    /// то пропускаем его
    if (data.isEmpty) {
      return;
    }

    JOneFileData /*?*/ fileDataNew;
    // проверка на совпадения сигнатур
    if (signatureBegining(data, signatureDoc)) {
      final _fileDocxPath = file.path + '.docx';
      await doc2x(file.path, _fileDocxPath);
      if (await File(_fileDocxPath).exists()) {
        files[_i] = JOneFileData(
            _fileDocxPath, fileData.origin, fileData.type, fileData.size);
        await handleFile(_i);
      } else {
        state.worked = state.worked + 1;
      }
      return;
    }
    for (final signature in signatureZip) {
      if (signatureBegining(data, signature)) {
        // вскрываем архив если он соотвествует размеру если он установлен и мы не привысили глубину вложенности
        final arch = await unzip(file.path);
        final _dirName = fileData.path + '.dir';
        if (arch.exitCode == 0) {
          final _dir = Directory(arch.pathOut /*!*/);
          await copyDirectoryRecursive(_dir, Directory(_dirName));

          await _dir.delete(recursive: true);

          final doc = OfficeWordDocument.createByXmlString(
              File(p.join(_dirName, 'word', 'document.xml'))
                  .readAsStringSync());
          if (doc != null) {
            final str = StringBuffer();
            str.writeCharCode(unicodeBomCharacterRune);
            str.writeln('РАЗОБРАННЫЙ WORD ФАЙЛ');
            str.writeln('ОРИГИНАЛ: ${fileData.origin}');
            str.writeln(doc.toString());
            final _str = str.toString();
            File(_dirName + '.txt').writeAsStringSync(_str);
            final ink = IOneFileInkDataTxt.createByString(_str);
            if (ink != null) {
              final str = StringBuffer();
              str.writeCharCode(unicodeBomCharacterRune);
              str.writeln('РАЗОБРАННЫЙ WORD ФАЙЛ');
              str.writeln('ОРИГИНАЛ: ${fileData.origin}');
              str.writeln('РАЗБИРАЕМАЯ КОПИЯ: ${_dirName + '.txt'}');
              str.write(ink.getDebugString());
              File(_dirName + '.ink.txt').writeAsStringSync(str.toString());
              parsedData[_i] = ink;
              state.worked = state.worked + 1;
              return;
            }
          }

          // Пытаемся обработать к DOCX файл
          if ((fileDataNew = await parserFileDocx(
                  this,
                  fileData,
                  await File(p.join(_dirName, 'word', 'document.xml'))
                      .readAsString())) !=
              null) {
            if (fileDataNew /*!*/ .notes != null) {
              if ((fileDataNew.notesError ?? 0) > 0) {
                state.errors = state.errors + 1;
              }
              if ((fileDataNew.notesWarnings ?? 0) > 0) {
                state.warnings = state.warnings + 1;
              }
            }
            await tryFunc<File /*?*/ >(
                () => File(fileDataNew /*!*/ .path + '.json')
                    .writeAsString(jsonEncode(fileDataNew)), onError: (e) {
              errorsOut.writeln(DateTime.now().toIso8601String());
              errorsOut.writeln('!Save FileData');
              errorsOut.writeln(e);
              return null;
            });
            files[_i] = fileDataNew;
            state.worked = state.worked + 1;
            return;
          }
        } else {
          errorsOut.writeln(DateTime.now().toIso8601String());
          errorsOut.writeln('!Archive unzip ${arch.pathIn} => ${arch.pathOut}');
          errorsOut.writeln(arch);
        }
        state.worked = state.worked + 1;
        return;
      }
    }
    // текстовый файл не должен содержать управляющих символов
    if (data.any((e) =>
        e == 0x7f || (e <= 0x1f && (e != 0x09 && e != 0x0A && e != 0x0D)))) {
      // TODO: неизвестный бинарный файл
      // Либо база данных
      state.worked = state.worked + 1;
      return null;
    }
    // Подбираем кодировку
    final encodesRaiting = convGetMappingRaitings(sets.charMaps, data);
    final encode = convGetMappingMax(encodesRaiting);
    // Преобразуем байты из кодировки в символы
    final buffer = convDecode(data, sets.charMaps[encode] /*!*/);

    final las = IOneFileLasData.createByString(buffer);
    if (las != null) {
      final str = StringBuffer();
      str.writeCharCode(unicodeBomCharacterRune);

      str.writeCharCode(unicodeBomCharacterRune);
      str.writeln('РАЗОБРАННЫЙ LAS ФАЙЛ');
      str.writeln('ОРИГИНАЛ: ${fileData.origin}');
      str.writeln('РАЗБИРАЕМАЯ КОПИЯ: ${fileData.path}');
      str.write(las.getDebugString);
      File(fileData.path + '.txt').writeAsStringSync(str.toString());

      final str2 = StringBuffer();
      str2.writeCharCode(unicodeBomCharacterRune);
      str2.writeln('# МИНИМИЗИРОВАННЫЙ РАЗОБРАННЫЙ LAS ФАЙЛ');
      str2.writeln('# ОРИГИНАЛ: ${fileData.origin}');
      str2.writeln('# РАЗОБРАННАЯ КОПИЯ: ${fileData.path + '.txt'}');
      str2.write(las.normalizeLasFileData());
      File(fileData.path + '.min.las').writeAsStringSync(str2.toString());
      parsedData[_i] = las;
      state.worked = state.worked + 1;
      return;
    }

    // Пытаемся обработать к LAS файл
    if ((fileDataNew = await parserFileLas(this, fileData, buffer, encode)) !=
        null) {
      if (fileDataNew /*!*/ .notes != null) {
        if ((fileDataNew.notesError ?? 0) > 0) {
          state.errors = state.errors + 1;
        }
        if ((fileDataNew.notesWarnings ?? 0) > 0) {
          state.warnings = state.warnings + 1;
        }
      }
      await tryFunc<File /*?*/ >(
          () => File(fileDataNew /*!*/ .path + '.json')
              .writeAsString(jsonEncode(fileDataNew)), onError: (e) {
        errorsOut.writeln(DateTime.now().toIso8601String());
        errorsOut.writeln('!Save FileData');
        errorsOut.writeln(e);
        return null;
      });
      files[_i] = fileDataNew;
      state.worked = state.worked + 1;
      return;
    }
    // TODO: обработать неизвестный текстовый файл
    state.worked = state.worked + 1;
  }

  /// == INK FILES == Begin
  // Future handleFileInk(final File file, final String origin) async {
  //   final inks = await InkData.loadFile(file, this);
  //   if (inks != null) {
  //     for (final ink in inks) {
  //       if (ink != null) {
  //         ink.origin = origin;
  //         if (ink.listOfErrors.isEmpty) {
  //           // Данные корректны
  //           final newPath = newerOutInk.lock(ink.well +
  //               '___' +
  //               p.basenameWithoutExtension(file.path) +
  //               '.txt');
  //           final original = inkDB.addInkData(ink);

  //           try {
  //             if (original) {
  //               final io = File(newPath).openWrite(mode: FileMode.writeOnly);
  //               io.writeln(ink.well);
  //               final dat = ink.inkData;
  //               for (final item in dat.data) {
  //                 io.writeln('${item.depth}\t${item.angle}\t${item.azimuth}');
  //               }
  //               await io.flush();
  //               await io.close();
  //             }
  //           } catch (e) {
  //             listOfErrors.add(CErrorOnLine(
  //                 origin, newPath, [ErrorOnLine(KncError.exception, 0, e)]));
  //             errors = listOfErrors.length;
  //             print(e);
  //           }
  //           listOfFiles.add(CInkFile(
  //               origin, newPath, ink.well, ink.strt, ink.stop, original));
  //           files = listOfFiles.length;
  //           // TODO: обработка INK файла
  //           // await newerOutInk.unlock(newPath);
  //         } else {
  //           // Ошибка в данных файла
  //           final newPath = newerOutErr.lock(p.basename(file.path));
  //           try {
  //             await file.copy(newPath);
  //           } catch (e) {
  //             listOfErrors.add(CErrorOnLine(
  //                 origin, newPath, [ErrorOnLine(KncError.exception, 0, e)]));
  //             errors = listOfErrors.length;
  //             print(e);
  //           }
  //           listOfErrors.add(CErrorOnLine(origin, newPath, ink.listOfErrors));
  //           errors = listOfErrors.length;
  //           // TODO: бработка ошибок INK файла
  //           // await newerOutErr.unlock(newPath);
  //         }
  //       }
  //     }
  //   }
  //   return;
  // } // == INK FILES == End

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
          if (settings.ext_ar.contains(ext)) {
            if ((settings.maxsize_ar <= 0 ||
                    await entity.length() < settings.maxsize_ar) &&
                (settings.maxdepth_ar == -1 ||
                    iArchDepth < settings.maxdepth_ar)) {
              // вскрываем архив если он соотвествует размеру если он установлен и мы не привысили глубину вложенности
              final arch = await unzip(entity.path);
              if (arch.exitCode == 0) {
                await listFilesGet(iArchDepth + 1, pathToArch + relPath)(
                    Directory(arch.pathOut /*!*/), '');
                await Directory(arch.pathOut /*!*/).delete(recursive: true);
              } else {
                errorsOut.writeln(DateTime.now().toIso8601String());
                errorsOut.writeln(
                    '!Archive unzip ${arch.pathIn} => ${arch.pathOut}');
                errorsOut.writeln(arch);
                // listOfErrors.add(CErrorOnLine(arch.pathIn, arch.pathOut,
                //     [ErrorOnLine(KncError.arch, 0, arch.toWrapperMsg())]));
                // errors = listOfErrors.length;
              }
            } else {
              // отбрасываем большой архив или бОльшую глубину вложенности
              return;
            }
          } // == UNZIPPER == End
          return handleFileSearch(entity, pathToArch + relPath);
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
  Future<int> doc2x(final String path2doc, final String path2out) =>
      requestOnce(JMsgDoc2X(path2doc, path2out).toString())
          .then((msg) => int.parse(msg));

  /// Запекает данные в zip архиф с помощью 7zip
  Future<ArchiverOutput> zip(
          final String pathToData, final String pathToOutput) =>
      requestOnce(JMsgZip(pathToData, pathToOutput).toString())
          .then((value) => ArchiverOutput.fromWrapperMsg(value));

  /// Распаковывает архив [pathToArchive]
  Future<ArchiverOutput> unzip(final String pathToArchive) =>
      requestOnce(JMsgUnzip(pathToArchive).toString())
          .then((value) => ArchiverOutput.fromWrapperMsg(value));

  @override
  String toString() =>
      '$runtimeType{${sets.id}}(${settings.name})[${settings.user}]';
  TaskIso._init(this.sets, this.pathAbsolute)
      : settings = sets.settings,
        state = JTaskState({'id': sets.id, 'settings': sets.settings},
            Duration(milliseconds: sets.settings.update_duration)),
        dirFiles =
            Directory(p.join(TaskController.dirTasks.path, sets.id, 'temp')),
        errorsOut =
            File(p.join(TaskController.dirTasks.path, sets.id, 'errors.txt'))
                .openWrite(encoding: utf8, mode: FileMode.writeOnlyAppend)
                  ..writeCharCode(unicodeBomCharacterRune),
        super((msg) => sets.sendPort.send([sets.id, msg])) {
    print('$this created');
    instance = this;
    final fileState =
        File(p.join(TaskController.dirTasks.path, sets.id, 'state.json'));

    state.onUpdate = () {
      send(0, JMsgTaskUpdate(state).toString());
      fileState.writeAsStringSync(jsonEncode(state.map));
    };

    send(0, JMsgTaskUpdate.msgId + jsonEncode(state.map));

    /// Обрабатываем все сообщения через Wrapper
    receivePort.listen((final msg) {
      if (msg is String) {
        if (recv(msg)) {
          return;
        }
      }
      print('$this recieved unknown msg {$msg}');
    });

    waitMsgAll(JMsgGetTasks.msgId).listen((msg) {
      send(msg.i, jsonEncode(state));
    });

    /// Просьба удалить задачу
    waitMsgAll(JMsgTaskKill.msgId).listen((msg) {
      final _msg = JMsgTaskKill.fromString(msg.s);
      receivePort.close();
      send(msg.i, _msg.toString());
    });

    /// Запрос на получение списка файлов
    waitMsgAll(JMsgGetTaskFileList.msgId).listen((msg) {
      send(
          msg.i,
          jsonEncode(files
              .map((e) => e.toJson(withoutCurves: true, withoutNotes: true))
              .toList(growable: false)));
    });

    /// Запрос на получение полных данных о файле
    waitMsgAll(JMsgGetTaskFileNotesAndCurves.msgId).listen((msg) {
      final _msg = JMsgGetTaskFileNotesAndCurves.fromString(msg.s);
      final _path = _msg.path;
      if (files.isEmpty) {
        send(msg.i, '!!FILE NOT FOUND');
      } else {
        final _a =
            files.firstWhere((e) => e.path.endsWith(_path), orElse: () => null);
        if (_a == null) {
          send(msg.i, '!!FILE NOT FOUND');
        } else {
          send(msg.i, jsonEncode(_a.toJson()));
        }
      }
    });

/*
    /// Отвечаем на все запросы на получение заметок файла, где аругментом
    /// указан путь к рабочей копии файла, кодируем их в [json]
    waitMsgAll(wwwFileNotes).listen((msg) {
      send(msg.i, jsonEncode(files.firstWhere((e) => e.path == msg.s).notes));
    });

    /// Отвечаем на все запросы получения списка файлов задачи, кодируем их в
    /// [json]
    waitMsgAll(wwwTaskGetFiles).listen((msg) {
      send(msg.i, jsonEncode(files));
    });

    /// Получение списка файлов `file.path`
    waitMsgAll(wwwGetOneFileData).listen((msg) {
      final _ofd = files.firstWhere((e) => e.path == msg.s, orElse: () => null);
      if (_ofd != null) {
        send(msg.i, jsonEncode(_ofd.toJsonFull()));
      } else {
        send(msg.i, '');
      }
    });
*/
    /// Сохраняем настройки файла
    File(p.join(pathAbsolute, 'settings.json'))
        .writeAsString(jsonEncode(settings));

    /// отправляем порт для связи с запущенным изолятом
    sets.sendPort.send([sets.id, receivePort.sendPort]);
  }
  static /*late*/ TaskIso instance;

  // /// Загрузкить все данные
  // Future get loadAll => Future.wait([loadLasIgnore(), loadInkDbfMap()]);

  // /// Загружает таблицу игнорирования полей LAS файла
  // Future loadLasIgnore() => File(r'data/las.ignore.json')
  //     .readAsString(encoding: utf8)
  //     .then((buffer) => lasIgnore = json.decode(buffer));

  // /// Загружает таблицу переназначения полей DBF для инклинометрии
  // Future loadInkDbfMap() => File(r'data/ink.dbf.map.json')
  //     .readAsString(encoding: utf8)
  //     .then((buffer) => inkDbfMap = json.decode(buffer));
}
