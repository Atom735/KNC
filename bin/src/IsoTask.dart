import 'dart:async';
import 'dart:io';
import 'dart:isolate';
import 'dart:convert';

import 'package:knc/knc.dart';
import 'package:path/path.dart' as p;

import 'FIleParserLas.dart';
import 'ink.dart';
import 'TaskSpawnSets.dart';
import 'las.dart';
import 'misc.dart';
import 'msgs.dart';
import 'xls.dart';

class PathNewer {
  /// Путь именно к существующей папке, в которой будет подбираться имя
  final String prePath;

  /// Список зарезервированных имён файлов/папок
  final _reserved = <String>[];

  /// [prePath] - это путь именно к существующей папке
  PathNewer(this.prePath);

  /// Подбирает новое имя для файла, если он уже существует в папке [prePath]
  /// И резервирует его
  String lock(final String name) {
    var n = p.basename(name);
    var o = p.join(prePath, n);
    if (!_reserved.contains(n)) {
      // Если имя не зарезрвированно и файла с таким именем не существует
      _reserved.add(n);
      return o;
    } else {
      final fn = p.basenameWithoutExtension(name);
      final fe = p.extension(name);
      var i = 0;
      do {
        n = '${fn}(${i})${fe}';
        o = p.join(prePath, n);
        i += 1;
      } while (_reserved.contains(n));
      _reserved.add(n);
      return o;
    }
  }

  /// Отменить резервацию файла
  bool unlock(final String name) => _reserved.remove(p.basename(name));
}

class IsoTask extends SocketWrapper {
  /// Порт для получение сообщений этим изолятом
  final ReceivePort receivePort = ReceivePort();

  /// Данные полученные при спавне задачи
  final TaskSpawnSets sets;

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

  final String pathTemp;
  final filesSearche = <OneFileData>[];
  KncXlsBuilder xls;

  int _state = 0;
  int get state => _state;
  set state(final int i) {
    if (i == null || _state == i) {
      return;
    }
    _state = i;
    send(0, '$msgTaskUpdateState$_state');
  }

  int _errors = 0;
  int get errors => _errors;
  set errors(final int i) {
    if (i == null || _errors == i) {
      return;
    }
    _errors = i;
    send(0, '$msgTaskUpdateErrors$_errors');
  }

  int _files = 0;
  int get files => _files;
  set files(final int i) {
    if (i == null || _files == i) {
      return;
    }
    _files = i;
    send(0, '$msgTaskUpdateFiles$_files');
  }

  int _warnings = 0;
  int get warnings => _warnings;
  set warnings(final int i) {
    if (i == null || _warnings == i) {
      return;
    }
    _warnings = i;
    send(0, '$msgTaskUpdateWarnings$_warnings');
  }

  int _worked = 0;
  int get worked => _worked;
  set worked(final int i) {
    if (i == null || _worked == i) {
      return;
    }
    _worked = i;
    send(0, '$msgTaskUpdateWorked$_worked');
  }

  final listOfErrors = <CErrorOnLine>[];
  final listOfFiles = <C_File>[];

  static Future<void> entryPoint(final TaskSpawnSets sets) async {
    final pathOut = (await Directory('temp').createTemp('task.')).absolute.path;
    await IsoTask(sets, pathOut).entryPointInClass();
  }

  Future<void> entryPointInClass() async {
    await Future.wait([
      Directory(pathTemp).create(recursive: true),
      Directory(pathOutLas).create(recursive: true),
      Directory(pathOutInk).create(recursive: true),
      Directory(pathOutErr).create(recursive: true)
    ]);
    state = NTaskState.searchFiles.index;
    final fs = <Future>[];
    final func = listFilesGet(0, '');
    sets.settings.path.forEach((element) {
      if (element.isNotEmpty) {
        print('task[${sets.id}] scan $element');
        fs.add(FileSystemEntity.type(element).then((value) =>
            value == FileSystemEntityType.file
                ? func(File(element), element)
                : value == FileSystemEntityType.directory
                    ? func(Directory(element), element)
                    : null));
      }
    });
    await Future.wait(fs);
    await File(p.join(pathOut, 'searchedFiles.txt')).writeAsString(filesSearche
        .map((e) => '${e.type.toString()}\n${e.origin}\n${e.path}\n')
        .join('\n'));
    state = NTaskState.workFiles.index;
    final _l = filesSearche.length;
    for (var i = 0; i < _l; i++) {
      await handleFile(i);
    }
    state = NTaskState.generateTable.index;
    // TODO: Генерация таблицы
    await generateTable();
    // xls.
    state = NTaskState.completed.index;
  }

  Future<void> generateTable() async {
    final xlsDataIn = Directory(p.join('data', 'xls')).absolute;
    final xlsDataOut = Directory(p.join(pathOut, 'xls')).absolute;
    await copyDirectoryRecursive(xlsDataIn, xlsDataOut);
    final xlsSheet =
        File(p.join(xlsDataOut.path, 'xl', 'worksheets', 'sheet1.xml'));
    final xlsSharedStrings =
        File(p.join(xlsDataOut.path, 'xl', 'sharedStrings.xml'));
    final xlsSheetTemplate = await xlsSheet.readAsString();
    final xlsSharedStringsTemplate = await xlsSharedStrings.readAsString();
    final _methods = <String>[];
    final _wells = <String>[];

    filesSearche.forEach((e) {
      if (e.well == null || e.well.isEmpty) {
        return;
      }
      if (e.curves != null && e.curves.length >= 2) {
        final _length = e.curves.length;
        for (var i = 1; i < _length; i++) {
          final _name = e.curves[i].name;
          if (!_methods.contains(_name)) {
            _methods.add(e.curves[i].name);
          }
        }
      }
      if (e.well != null && !_wells.contains(e.well)) {
        _wells.add(e.well);
      }
    });
    final _rows = <List<String>>[]; // WELL, INK, GISx2...
    final _methodsLength = _methods.length;
    filesSearche.forEach((e) {
      if (e.well == null || e.well.isEmpty) {
        return;
      }
      if (e.curves != null && e.curves.length >= 2) {
        final _length = e.curves.length;
        for (var i = 1; i < _length; i++) {
          final _i = _methods.indexOf(e.curves[i].name) * 2 + 2;
          var _row = _rows.firstWhere((_e) => _e[0] == e.well && _e[_i] == null,
              orElse: () => null);
          if (_row == null) {
            _rows.add(List(_methodsLength * 2 + 2));
            _row = _rows.last;
            _row[0] = e.well;
          }
          _row[_i] = e.curves[i].strt;
          _row[_i + 1] = e.curves[i].stop;
        }
      }
    });

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
    send(0, '$msgTaskUpdateRaport$xlsPath');
  }

  Future<void> handleFileSearch(final File file, final String origin) async {
    // if (filesSearche.length > 1000) {
    //   return;
    // }
    final ext = p.extension(file.path).toLowerCase();
    if (sets.settings.ext_files.contains(ext)) {
      final i = files;
      files++;
      final ph = p.join(pathTemp, i.toRadixString(36).padLeft(8, '0'));
      filesSearche.add(OneFileData(
          ph, origin, NOneFileDataType.unknown, await file.length()));
      var _tryes = 0;
      while (_tryes < 100) {
        try {
          await file.copy(ph);
          break;
        } catch (e) {
          await Future.delayed(Duration(milliseconds: 1));
          _tryes++;
        }
      }
      // newerTemp.unlock(ph);
    }
  }

  Future<void> handleFile(final int _i) async {
    final fileData = filesSearche[_i];
    final file = File(fileData.path);
    final data = await file.readAsBytes();
    OneFileData fileDataNew;
    // проверка на совпадения сигнатур
    if (signatureBegining(data, signatureDoc)) {
      worked++;
      return;
    }
    for (final signature in signatureZip) {
      if (signatureBegining(data, signature)) {
        worked++;
        return;
      }
    }
    // текстовый файл не должен содержать бинарных данных
    if (data.any((e) =>
        e == 0x7f || (e <= 0x1f && (e != 0x09 && e != 0x0A && e != 0x0D)))) {
      worked++;
      return null;
    }
    // Подбираем кодировку
    final encodesRaiting = convGetMappingRaitings(sets.charMaps, data);
    final encode = convGetMappingMax(encodesRaiting);
    // Преобразуем байты из кодировки в символы
    final buffer = String.fromCharCodes(data.map(
        (i) => i >= 0x80 ? sets.charMaps[encode][i - 0x80].codeUnitAt(0) : i));

    if ((fileDataNew = await parserFileLas(this, fileData, buffer, encode)) !=
        null) {
      filesSearche[_i] = fileDataNew;
      if (fileDataNew.notes.any((e) => e.text.startsWith('!E'))) {
        errors++;
      } else if (fileDataNew.notes.any((e) => e.text.startsWith('!W'))) {
        warnings++;
      }
      worked++;
      return;
    }
    worked++;
  }

  /// == INK FILES == Begin
  Future handleFileInk(final File file, final String origin) async {
    final inks = await InkData.loadFile(file, this);
    if (inks != null) {
      for (final ink in inks) {
        if (ink != null) {
          ink.origin = origin;
          if (ink.listOfErrors.isEmpty) {
            // Данные корректны
            final newPath = newerOutInk.lock(ink.well +
                '___' +
                p.basenameWithoutExtension(file.path) +
                '.txt');
            final original = inkDB.addInkData(ink);

            try {
              if (original) {
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
              listOfErrors.add(CErrorOnLine(
                  origin, newPath, [ErrorOnLine(KncError.exception, 0, e)]));
              errors = listOfErrors.length;
              print(e);
            }
            listOfFiles.add(CInkFile(
                origin, newPath, ink.well, ink.strt, ink.stop, original));
            files = listOfFiles.length;
            // TODO: обработка INK файла
            // await newerOutInk.unlock(newPath);
          } else {
            // Ошибка в данных файла
            final newPath = newerOutErr.lock(p.basename(file.path));
            try {
              await file.copy(newPath);
            } catch (e) {
              listOfErrors.add(CErrorOnLine(
                  origin, newPath, [ErrorOnLine(KncError.exception, 0, e)]));
              errors = listOfErrors.length;
              print(e);
            }
            listOfErrors.add(CErrorOnLine(origin, newPath, ink.listOfErrors));
            errors = listOfErrors.length;
            // TODO: бработка ошибок INK файла
            // await newerOutErr.unlock(newPath);
          }
        }
      }
    }
    return;
  } // == INK FILES == End

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
          if (sets.settings.ext_ar.contains(ext)) {
            if ((sets.settings.maxsize_ar <= 0 ||
                    await entity.length() < sets.settings.maxsize_ar) &&
                (sets.settings.maxdepth_ar == -1 ||
                    iArchDepth < sets.settings.maxdepth_ar)) {
              // вскрываем архив если он соотвествует размеру если он установлен и мы не привысили глубину вложенности
              final arch = await unzip(entity.path);
              if (arch.exitCode == 0) {
                await listFilesGet(iArchDepth + 1, pathToArch + relPath)(
                    Directory(arch.pathOut), '');
                await Directory(arch.pathOut).delete(recursive: true);
                // TODO: удалить вскрытый архив
              } else {
                // TODO: обработка ошибки
                listOfErrors.add(CErrorOnLine(arch.pathIn, arch.pathOut,
                    [ErrorOnLine(KncError.arch, 0, arch.toWrapperMsg())]));
                errors = listOfErrors.length;
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

  IsoTask._init(this.sets, this.pathOut)
      : pathOutLas = p.join(pathOut, 'las'),
        newerOutLas = PathNewer(p.join(pathOut, 'las')),
        pathOutInk = p.join(pathOut, 'ink'),
        newerOutInk = PathNewer(p.join(pathOut, 'ink')),
        pathOutErr = p.join(pathOut, 'errors'),
        newerOutErr = PathNewer(p.join(pathOut, 'errors')),
        errorsOut = File(p.join(pathOut, 'errors.txt'))
            .openWrite(encoding: utf8, mode: FileMode.writeOnly)
              ..writeCharCode(unicodeBomCharacterRune),
        pathTemp = p.join(pathOut, 'temp'),
        super((msg) => sets.sendPort.send([sets.id, msg])) {
    print('$runtimeType created: $hashCode');
    receivePort.listen((final msg) {
      if (msg is String) {
        recv(msg);
        return;
      }
      print('task[${sets.id}]: recieved unknown msg {$msg}');
    });

    waitMsgAll(wwwFileNotes).listen((msg) {
      send(
          msg.i,
          jsonEncode(
              filesSearche.firstWhere((e) => e.path == msg.s).jsonNotes));
    });

    waitMsgAll(wwwTaskGetFiles).listen((msg) {
      final ic = int.tryParse(msg.s);
      final im = filesSearche.length - ic;
      final v = List(im);
      for (var i = 0; i < im; i++) {
        v[i] = filesSearche[i + ic].toJson();
      }
      send(msg.i, jsonEncode({'first': ic, 'task': sets.id, 'data': v}));
    });

    sets.sendPort.send([sets.id, receivePort.sendPort]);
  }
  static IsoTask _instance;
  factory IsoTask([final TaskSpawnSets sets, final String pathOut]) =>
      _instance ?? (_instance = IsoTask._init(sets, pathOut));

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
