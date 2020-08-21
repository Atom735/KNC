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

import 'FIleParserLas.dart';
import 'ink.dart';
import 'knc.main.dart';
import 'las.dart';
import 'mapping.dart';

const msgTaskUpdateState = 'taskstate;';
const msgTaskUpdateErrors = 'taskerrors;';
const msgTaskUpdateFiles = 'taskfiles;';
const msgTaskUpdateWarnings = 'taskwarnings;';
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

enum NOneFileDataType { unknown, las }

/// Значения иследований
class OneFilesDataCurve {
  /// Наименоваине кривой (.ink - для инклинометрии)
  final String name;

  /// Глубина начальной точки кривой
  final String strt;

  /// Глубина конечной точки кривой
  final String stop;

  /// Шаг точек (null для инклинометрии)
  final String step;

  /// Значения в точках (у инклинометрии по три значения на точку)
  final List<String> data;

  OneFilesDataCurve(this.name, this.strt, this.stop, this.step, this.data);
  Map<String, String> get json => {
        'name': name,
        'strt': strt,
        'stop': stop,
        'step': step,
      };
}

class OneFileLineNote {
  /// Номер линии
  final int line;

  /// Номер символа в строке
  final int column;

  /// Текст заметки
  final String text;

  /// Доп. данные заметки (обычно то что записано в строке)
  final String data;

  OneFileLineNote(this.line, this.column, this.text, this.data);
}

class OneFileData {
  /// Путь к сущности обработанного файла
  final String path;

  /// Путь к оригинальной сущности файла
  final String origin;

  /// Тип файла
  final NOneFileDataType type;

  /// Размер файла в байтах
  final int size;

  /// Название кодировки
  final String encode;

  /// Наименование скважины
  final String well;

  /// Кривые найденные в файле
  final List<OneFilesDataCurve> curves;

  final List<OneFileLineNote> errors;
  final List<OneFileLineNote> warnings;

  OneFileData(this.path, this.origin, this.type, this.size,
      {this.well, this.curves, this.encode, this.errors, this.warnings});

  Map<String, Object> get json => {
        'type': type.index,
        'path': path,
        'origin': origin,
        'size': size,
        'encode': encode,
      }..addAll(well != null
          ? {
              'well': well,
              'curves': curves.map((e) => e.json).toList(growable: false)
            }
          : {});
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

  final String pathTemp;
  final filesSearche = <OneFileData>[];

  int _state = 0;
  int get state => _state;
  set state(final int i) {
    if (i == null || _state == i) {
      return;
    }
    _state = i;
    wrapper.send(0, '$msgTaskUpdateState$_state');
  }

  int _errors = 0;
  int get errors => _errors;
  set errors(final int i) {
    if (i == null || _errors == i) {
      return;
    }
    _errors = i;
    wrapper.send(0, '$msgTaskUpdateErrors$_errors');
  }

  int _files = 0;
  int get files => _files;
  set files(final int i) {
    if (i == null || _files == i) {
      return;
    }
    _files = i;
    wrapper.send(0, '$msgTaskUpdateFiles$_files');
  }

  int _warnings = 0;
  int get warnings => _warnings;
  set warnings(final int i) {
    if (i == null || _warnings == i) {
      return;
    }
    _warnings = i;
    wrapper.send(0, '$msgTaskUpdateWarnings$_warnings');
  }

  final listOfErrors = <CErrorOnLine>[];
  final listOfFiles = <C_File>[];

  static Future<void> entryPoint(final KncTaskSpawnSets sets) async {
    final pathOut = (await Directory('temp').createTemp('task.')).absolute.path;
    await KncTask(sets, pathOut).entryPointInClass();
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
    settings.path.forEach((element) {
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
    await Future.wait(fs);
    await File(p.join(pathOut, 'searchedFiles.txt')).writeAsString(filesSearche
        .map((e) => '${e.type.toString()}\n${e.origin}\n${e.path}\n')
        .join('\n'));
    state = NTaskState.workFiles.index;
    final _l = filesSearche.length;
    for (var i = 0; i < _l; i++) {
      await handleFile(i);
    }
    state = NTaskState.completed.index;
    // TODO: Генерация таблицы
  }

  Future<void> handleFileSearch(final File file, final String origin) async {
    final ext = p.extension(file.path).toLowerCase();
    if (settings.ext_files.contains(ext)) {
      final i = filesSearche.length;
      final ph = p.join(pathTemp, i.toRadixString(36).padLeft(8, '0'));
      filesSearche.add(OneFileData(
          ph, origin, NOneFileDataType.unknown, await file.length()));
      files = i;
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
    }
  }

  Future<void> handleFile(final int _i) async {
    final fileData = filesSearche[_i];
    final file = File(fileData.path);
    final data = await file.readAsBytes();
    OneFileData fileDataNew;
    // проверка на совпадения сигнатур
    if (signatureBegining(data, signatureDoc)) {
      return;
    }
    for (final signature in signatureZip) {
      if (signatureBegining(data, signature)) {
        return;
      }
    }
    // текстовый файл не должен содержать бинарных данных
    if (data.any((e) =>
        e == 0x7f || (e <= 0x1f && (e != 0x09 && e != 0x0A && e != 0x0D)))) {
      return null;
    }
    // Подбираем кодировку
    final encodesRaiting = getMappingRaitings(charMaps, data);
    final encode = getMappingMax(encodesRaiting);
    // Преобразуем байты из кодировки в символы
    final buffer = String.fromCharCodes(data
        .map((i) => i >= 0x80 ? charMaps[encode][i - 0x80].codeUnitAt(0) : i));

    if ((fileDataNew = await parserFileLas(this, fileData, buffer, encode)) !=
        null) {
      filesSearche[_i] = fileDataNew;
      return;
    }
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
            final newPath = await newerOutInk.lock(ink.well +
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
            await newerOutInk.unlock(newPath);
          } else {
            // Ошибка в данных файла
            final newPath = await newerOutErr.lock(p.basename(file.path));
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
            await newerOutErr.unlock(newPath);
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
        pathTemp = p.join(pathOut, 'temp'),
        wrapper = SocketWrapper((msg) => sets.sendPort.send([sets.id, msg])),
        super.clone(sets) {
    print('$runtimeType created: $hashCode');
    receivePort.listen((final msg) {
      if (msg is String) {
        wrapper.recv(msg);
        return;
      }
      print('task[$id]: recieved unknown msg {$msg}');
    });

    wrapper.waitMsgAll(wwwTaskGetErrors).listen((msg) {
      final ic = int.tryParse(msg.s);
      final im = listOfErrors.length - ic;
      final v = List(im);
      for (var i = 0; i < im; i++) {
        v[i] = listOfErrors[i + ic].toJson();
      }
      wrapper.send(msg.i, json.encode(v));
    });

    wrapper.waitMsgAll(wwwTaskGetFiles).listen((msg) {
      final ic = int.tryParse(msg.s);
      final im = listOfFiles.length - ic;
      final v = List(im);
      for (var i = 0; i < im; i++) {
        v[i] = listOfFiles[i + ic].toJson();
      }
      wrapper.send(msg.i, json.encode(v));
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
