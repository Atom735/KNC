import 'dart:async';
import 'dart:io';
import 'dart:isolate';
import 'dart:convert';

import 'package:knc/knc.dart';
import 'package:path/path.dart' as p;

import 'FIleParserLas.dart';
import 'TaskSpawnSets.dart';
import 'misc.dart';
import 'xls.dart';

class IsoTask extends SocketWrapper {
  /// Порт для получение сообщений этим изолятом
  final ReceivePort receivePort = ReceivePort();

  /// Данные полученные при спавне задачи
  final TaskSpawnSets sets;

  /// Копия ссылки на настройки
  final TaskSettings settings;

  /// Папка со всеми обработанными Las файлами
  final Directory dirLas;

  /// Папка со всеми обработанными Ink файлами
  final Directory dirInk;

  /// Папка со всеми временными файлами (рабочими копиями)
  final Directory dirTemp;

  /// Поток для записи иформации об ошибках в файл
  final IOSink errorsOut;

  // final lasDB = LasDataBase();
  // dynamic lasIgnore;

  // final inkDB = InkDataBase();
  // dynamic inkDbfMap;

  // final lasCurvesNameOriginals = <String>[];

  final filesSearche = <OneFileData>[];
  KncXlsBuilder xls;

  /// Данные подготовляемые для отправки как обновление состояния задачи
  final _updatesMap = <String, Object>{};

  /// Handle таймера
  Future<void> _updatesFuture;

  /// json Объект состояния задачи
  final stateMap = <String, Object>{};

  /// Обновление данных для отправки сообщения об обновлении
  void _update(String n, Object v) {
    _updatesMap[n] = v;
    stateMap[n] = v;
    _updatesFuture ??=
        Future.delayed(Duration(milliseconds: settings.update_duration))
            .then((_) {
      _updatesMap['id'] = sets.id;
      send(0, wwwTaskUpdates + jsonEncode(_updatesMap));
      File(p.join(sets.dir.path, 'state.json'))
          .writeAsString(jsonEncode(stateMap));
      _updatesFuture = null;
      _updatesMap.clear();
    });
  }

  /// Состояние задачи
  int get state => _state;
  int _state = 0;
  set state(final int i) {
    if (i == null || _state == i) {
      return;
    }
    _state = i;
    _update('state', state);
  }

  /// Количество обработанных файлов с ошибками
  int get errors => _errors;
  int _errors = 0;
  set errors(final int i) {
    if (i == null || _errors == i) {
      return;
    }
    _errors = i;
    _update('errors', errors);
  }

  /// Количество найденных файлов для обработки
  int get files => _files;
  int _files = 0;
  set files(final int i) {
    if (i == null || _files == i) {
      return;
    }
    _files = i;
    _update('files', files);
  }

  /// Количество обработанных файлов с предупреждениями и/или ошибками
  int get warnings => _warnings;
  int _warnings = 0;
  set warnings(final int i) {
    if (i == null || _warnings == i) {
      return;
    }
    _warnings = i;
    _update('warnings', warnings);
  }

  /// Количество обработанных файлов
  int get worked => _worked;
  int _worked = 0;
  set worked(final int i) {
    if (i == null || _worked == i) {
      return;
    }
    _worked = i;
    _update('worked', worked);
  }

  // final listOfErrors = <CErrorOnLine>[];
  // final listOfFiles = <C_File>[];

  /// Точка входа для изолята
  static Future<void> entryPoint(final TaskSpawnSets sets) async {
    await IsoTask(sets).entryPointInClass();
  }

  /// Точка входа изолята внутри класса
  Future<void> entryPointInClass() async {
    await Future.wait([
      dirTemp.create(),
      dirLas.create(),
      dirInk.create(),
    ]);

    /// Смена состояния на поиск файлов
    state = NTaskState.searchFiles.index;
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
    await File(p.join(sets.dir.path, 'files.txt')).writeAsString(filesSearche
        .map((e) => '${e.type.toString()}\n${e.origin}\n${e.path}\n')
        .join('\n'));
    state = NTaskState.workFiles.index;
    final _l = filesSearche.length;
    for (var i = 0; i < _l; i++) {
      await handleFile(i);
    }
    state = NTaskState.generateTable.index;
    // TODO: Генерация таблицы
    await _generateTable();
    // xls.
    state = NTaskState.completed.index;
  }

  /// Генерация таблицы
  Future<void> _generateTable() async {
    final xlsDataIn = Directory(p.join('data', 'xls')).absolute;
    final xlsDataOut = Directory(p.join(sets.dir.path, 'xls')).absolute;
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

    /// Заполняем списки названий скважин и кривых
    final _k = filesSearche.length;
    for (var k = 0; k < _k; k++) {
      final e = filesSearche[k];

      /// Пропускаем файлы без кривых
      if (e.curves == null) {
        continue;
      }
      if (e.curves != null && e.curves.length >= 2) {
        final _length = e.curves.length;
        for (var i = 0; i < _length; i++) {
          final _name = e.curves[i].name;
          final _well = e.curves[i].well;
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
    final _rows = <List<String>>[]; // WELL, INK, GISx2...
    final _methodsLength = _methods.length;
    for (var k = 0; k < _k; k++) {
      final e = filesSearche[k];

      /// Пропускаем файлы без кривых
      if (e.curves == null) {
        continue;
      }
      final _length = e.curves.length;
      for (var i = 0; i < _length; i++) {
        final _name = e.curves[i].name;
        final _well = e.curves[i].well;

        /// Подбираем номер колонки в зависимости от названия кривой
        final _i = _methods.indexOf(_name) * 2 + 2;

        /// Подбираем строку, чтобы совпадало название скважины
        /// и выбранная колонка была пустая, иначе создаём новую строку
        var _row = _rows.firstWhere((_e) => _e[0] == _well && _e[_i] == null,
            orElse: () {
          _rows.add(List(_methodsLength * 2 + 2));
          return _rows.last..[0] = _well;
        });

        /// Записываем значения кривых в эти ячейки
        _row[_i] = e.curves[i].strt;
        _row[_i + 1] = e.curves[i].stop;
      }
    }
    ;

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
    _update('raport', xlsPath);
  }

  /// Обработка файлов во время поиска всех файлов
  Future<void> handleFileSearch(final File file, final String origin) async {
    final ext = p.extension(file.path).toLowerCase();
    if (settings.ext_files.contains(ext)) {
      /// Если файл необходимого расширения
      final i = files;
      files++;
      final ph = p.join(dirTemp.path, i.toRadixString(36).padLeft(8, '0'));
      filesSearche.add(OneFileData(
          ph, origin, NOneFileDataType.unknown, await file.length()));

      await tryFunc(() => file.copy(ph), (e) => errorsOut.writeln(e));
    }
  }

  /// Обрабтчик файлов
  Future<void> handleFile(final int _i) async {
    final fileData = filesSearche[_i];
    final file = File(fileData.path);
    final data = await tryFunc<List<int>>(() => file.readAsBytes(), (e) {
      errorsOut.writeln(e);
      return null;
    });

    /// Если не удалось считать данные файла
    if (data == null) {
      return;
    }

    OneFileData fileDataNew;
    // проверка на совпадения сигнатур
    if (signatureBegining(data, signatureDoc)) {
      // TODO: обработать doc файл
      worked++;
      return;
    }
    for (final signature in signatureZip) {
      if (signatureBegining(data, signature)) {
        // TODO: обработать docx файл
        worked++;
        return;
      }
    }
    // текстовый файл не должен содержать управляющих символов
    if (data.any((e) =>
        e == 0x7f || (e <= 0x1f && (e != 0x09 && e != 0x0A && e != 0x0D)))) {
      // TODO: неизвестный бинарный файл
      // Либо база данных
      worked++;
      return null;
    }
    // Подбираем кодировку
    final encodesRaiting = convGetMappingRaitings(sets.charMaps, data);
    final encode = convGetMappingMax(encodesRaiting);
    // Преобразуем байты из кодировки в символы
    final buffer = String.fromCharCodes(data.map(
        (i) => i >= 0x80 ? sets.charMaps[encode][i - 0x80].codeUnitAt(0) : i));

    // Пытаемся обработать к LAS файл
    if ((fileDataNew = await parserFileLas(this, fileData, buffer, encode)) !=
        null) {
      if (fileDataNew.notes.any((e) => e.text.startsWith('!E'))) {
        errors++;
      } else if (fileDataNew.notes.any((e) => e.text.startsWith('!W'))) {
        warnings++;
      }
      await tryFunc<File>(
          () => File(fileDataNew.path + '.json')
              .writeAsString(jsonEncode(fileDataNew.toJsonFull())), (e) {
        errorsOut.writeln('!Save FileData');
        errorsOut.writeln(e);
        return null;
      });
      filesSearche[_i] = fileDataNew;
      worked++;
      return;
    }
    // TODO: обработать неизвестный текстовый файл
    worked++;
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
                    Directory(arch.pathOut), '');
                await Directory(arch.pathOut).delete(recursive: true);
              } else {
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
      requestOnce('$msgDoc2x$path2doc$msgRecordSeparator$path2out')
          .then((msg) => int.tryParse(msg));

  /// Запекает данные в zip архиф с помощью 7zip
  Future<ArchiverOutput> zip(
          final String pathToData, final String pathToOutput) =>
      requestOnce('$msgZip$pathToData$msgRecordSeparator$pathToOutput')
          .then((value) => ArchiverOutput.fromWrapperMsg(value));

  /// Распаковывает архив [pathToArchive]
  Future<ArchiverOutput> unzip(final String pathToArchive) =>
      requestOnce('$msgUnzip$pathToArchive')
          .then((value) => ArchiverOutput.fromWrapperMsg(value));

  @override
  String toString() =>
      '$runtimeType{${sets.id}}(${settings.name})[${settings.user}]';
  IsoTask._init(this.sets)
      : settings = sets.settings,
        dirLas = Directory(p.join(sets.dir.path, 'las')),
        dirInk = Directory(p.join(sets.dir.path, 'ink')),
        dirTemp = Directory(p.join(sets.dir.path, 'temp')),
        errorsOut = File(p.join(sets.dir.path, 'errors.txt'))
            .openWrite(encoding: utf8, mode: FileMode.writeOnlyAppend)
              ..writeCharCode(unicodeBomCharacterRune),
        super((msg) => sets.sendPort.send([sets.id, msg])) {
    print('$this created');

    /// Обрабатываем все сообщения через Wrapper
    receivePort.listen((final msg) {
      if (msg is String) {
        if (recv(msg)) {
          return;
        }
      }
      print('$this recieved unknown msg {$msg}');
    });

    /// Отвечаем на все запросы на получение заметок файла, где аругментом
    /// указан путь к рабочей копии файла, кодируем их в [json]
    waitMsgAll(wwwFileNotes).listen((msg) {
      send(msg.i,
          jsonEncode(filesSearche.firstWhere((e) => e.path == msg.s).notes));
    });

    /// Отвечаем на все запросы получения списка файлов задачи, кодируем их в
    /// [json]
    waitMsgAll(wwwTaskGetFiles).listen((msg) {
      send(
          msg.i,
          jsonEncode(
              filesSearche.map((e) => e.toJson()).toList(growable: false)));
    });

    /// Заполняем json объект состояния
    stateMap['id'] = sets.id;
    stateMap['dir'] = sets.dir.path;

    /// Сохраняем настройки файла
    File(p.join(sets.dir.path, 'settings.json'))
        .writeAsString(jsonEncode(settings));

    /// отправляем порт для связи с запущенным изолятом
    sets.sendPort.send([sets.id, receivePort.sendPort]);
  }
  static IsoTask _instance;
  factory IsoTask([final TaskSpawnSets sets]) =>
      _instance ?? (_instance = IsoTask._init(sets));

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
