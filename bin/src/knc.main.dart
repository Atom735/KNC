import 'dart:isolate';
import 'dart:convert' as c;

import 'package:knc/SocketWrapper.dart';
import 'package:knc/www.dart';

import 'App.dart';
import 'knc.dart';

class KncTaskSpawnSets {
  final int id;
  final String name;
  final List<String> path;
  final Map<String, List<String>> charMaps;
  final SendPort sendPort;

  /// Настройки расширения для архивных файлов
  final List<String> ssFileExtAr = ['.zip', '.rar'];

  /// Настройки расширения для файлов LAS
  final List<String> ssFileExtLas = ['.las'];

  /// Настройки расширения для файлов с инклинометрией
  final List<String> ssFileExtInk = ['.doc', '.docx', '.txt', '.dbf'];

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
  final int ssArMaxSize = 1024 * 1024 * 1024;

  /// Максимальный глубина прохода по архивам
  /// * `-1` - для бесконечной вложенности (По умолчанию)
  /// * `0` - для отбрасывания всех архивов
  /// * `1` - для входа на один уровень архива
  final int ssArMaxDepth = -1;

  KncTaskSpawnSets(final KncTaskOnMain t, this.charMaps, this.sendPort)
      : id = t.id,
        name = t.name,
        path = t.path;

  KncTaskSpawnSets.clone(
    final KncTaskSpawnSets t,
  )   : id = t.id,
        name = t.name,
        path = t.path,
        charMaps = t.charMaps,
        sendPort = t.sendPort;

  Future<Isolate> spawn() => Isolate.spawn(KncTask.entryPoint, this,
      debugName: 'task[${id}]: "${name}"');
}

class KncTaskOnMain {
  final int id;
  final String name;
  final List<String> path;

  String pathOut;
  int _state = 0;
  int _errors = 0;
  int _files = 0;

  /// Изолят выоплнения задачи
  Isolate isolate;

  /// Порт задачи
  SendPort sendPort;
  SocketWrapper wrapper;

  KncTaskOnMain(this.id, this.name, this.path);

  dynamic get json => {
        'id': id,
        'name': name,
        'state': _state,
        'errors': _errors,
        'files': _files
      };

  set state(final int i) {
    if (i == null || _state == i) {
      return;
    }
    _state = i;
    App().sendForAllClients(wwwTaskUpdates +
        c.json.encode([
          {'id': id, 'state': _state}
        ]));
  }

  set errors(final int i) {
    if (i == null || _errors == i) {
      return;
    }
    _errors = i;
    App().sendForAllClients(wwwTaskUpdates +
        c.json.encode([
          {'id': id, 'errors': _state}
        ]));
  }

  set files(final int i) {
    if (i == null || _files == i) {
      return;
    }
    _files = i;
    App().sendForAllClients(wwwTaskUpdates +
        c.json.encode([
          {'id': id, 'files': _files}
        ]));
  }

  void initWrapper() {
    wrapper = SocketWrapper((str) => sendPort.send(str));
    wrapper.waitMsgAll(msgTaskUpdateState).listen((msg) {
      state = int.tryParse(msg.s);
    });
    wrapper.waitMsgAll(msgDoc2x).listen((msg) {
      final i0 = msg.s.indexOf(msgRecordSeparator);
      App()
          .converters
          .doc2x(msg.s.substring(0, i0),
              msg.s.substring(i0 + msgRecordSeparator.length))
          .then((value) => wrapper.send(msg.i, value.toString()));
    });
    wrapper.waitMsgAll(msgZip).listen((msg) {
      final i0 = msg.s.indexOf(msgRecordSeparator);
      App()
          .converters
          .zip(msg.s.substring(0, i0),
              msg.s.substring(i0 + msgRecordSeparator.length))
          .then((value) => wrapper.send(msg.i, value.toWrapperMsg()));
    });
    wrapper.waitMsgAll(msgUnzip).listen((msg) {
      App()
          .converters
          .unzip(msg.s)
          .then((value) => wrapper.send(msg.i, value.toWrapperMsg()));
    });
  }
}

// const msgTaskUpdateState = 'taskstate;';
// const msgDoc2x = 'doc2x;';
// const msgZip = 'zip;';
// const msgUnzip = 'unzip;'
