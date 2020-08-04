import 'dart:async';
import 'dart:io';
import 'dart:isolate';
import 'dart:convert';

import 'package:path/path.dart' as p;
import 'package:knc/SocketWrapper.dart';

import 'ink.dart';
import 'knc.main.dart';
import 'las.dart';

const msgTaskUpdateState = 'taskstate;';
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
  /// Настройки расширения для архивных файлов
  List<String> ssFileExtAr = ['.zip', '.rar'];

  /// Настройки расширения для файлов LAS
  List<String> ssFileExtLas = ['.las'];

  /// Настройки расширения для файлов с инклинометрией
  List<String> ssFileExtInk = ['.doc', '.docx', '.txt', '.dbf'];

  /// Максимальный размер вскрываемого архива в байтах
  ///
  /// Для задания значения можно использовать постфиксы:
  /// * `k` = КилоБайты
  /// * `m` = МегаБайты = `kk`
  /// * `g` = ГигаБайты = `kkk`
  ///
  /// `0` - для всех архивов
  ///
  /// По умолчанию 1Gb
  int ssArMaxSize = 1024 * 1024 * 1024;

  /// Максимальный глубина прохода по архивам
  /// * `-1` - для бесконечной вложенности (По умолчанию)
  /// * `0` - для отбрасывания всех архивов
  /// * `1` - для входа на один уровень архива
  int ssArMaxDepth = -1;

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
  }

  /// Преобразует данные
  ///
  /// Возвращает число вернувшиеся программой wordconv
  Future<int> doc2x(final String path2doc, final String path2out) => wrapper
      .requestOnce('$msgDoc2x$path2doc$msgRecordSeparator$path2out')
      .then((msg) => int.tryParse(msg));

  /// Запекает данные в zip архиф с помощью 7zip
  ///
  /// Возвращает данные об архивации
  Future<String> zip(final String pathToData, final String pathToOutput) =>
      wrapper.requestOnce('$msgZip$pathToData$msgRecordSeparator$pathToOutput');

  /// Распаковывает архив [pathToArchive]
  ///
  /// Отправляет сообщение главному потоку который как раз и занимается разархивированием
  ///
  /// Возвращает либо путь к разархивированной папке, либо данные об архивации
  Future<String> unzip(final String pathToArchive) =>
      wrapper.requestOnce('$msgUnzip$pathToArchive');

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
