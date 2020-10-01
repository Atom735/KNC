import 'dart:async';
import 'dart:io';
import 'dart:isolate';
import 'dart:convert';

import 'package:knc/knc.dart';
import 'package:path/path.dart' as p;

import 'FIleParserLas.dart';
import 'TaskController.dart';
import 'TaskSpawnSets.dart';
import 'misc.dart';

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

  /// Состояние задачи
  ///
  ///
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
      await dirFiles.create();
      await runSearchFiles();
      await runWorkFiles();
      await runGenerateTable();
      state.state = NTaskState.completed;
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
        fs.add(FileSystemEntity.type(element).then((value) =>
            value == FileSystemEntityType.file
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
            '${e.size}')
        .join('\n'));
  }

  /// Процедура обработки файлов
  Future<void> runWorkFiles() async {
    state.state = NTaskState.workFiles;
    final _l = files.length;
    for (var i = 0; i < _l; i++) {
      await handleFile(i);
    }
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
    state.raport = true;
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
          // TODO: обработать docx файл
          await _dir.delete(recursive: true);
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
        state = JTaskState({'id': sets.id},
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
    state.onUpdate = () {
      send(0, JMsgTaskUpdate(state).toString());
    };

    /// Обрабатываем все сообщения через Wrapper
    receivePort.listen((final msg) {
      if (msg is String) {
        if (recv(msg)) {
          return;
        }
      }
      print('$this recieved unknown msg {$msg}');
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
