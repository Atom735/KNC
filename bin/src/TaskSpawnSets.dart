import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

import 'package:knc/knc.dart';
import 'package:path/path.dart' as p;

import 'App.dart';
import 'Conv.dart';
import 'IsoTask.dart';
import 'Task.dart';

/// Данные задачи передаваемые сервером изоляту при запуске
class TaskSpawnSets {
  /// Уникальный номер задачи
  final int id;

  /// Портя для связи с сервером
  final SendPort sendPort;

  /// Настройки задачи
  final TaskSettings settings;

  /// Кодировки
  final Map<String, List<String>> charMaps;

  /// Папка задачи
  final Directory dir;

  TaskSpawnSets._(
      this.id, this.sendPort, this.settings, this.charMaps, this.dir);

  static var _uid = 0;

  /// Запускает новую задачу с указанными настройками
  static Future<void> spawn({TaskSettings settings, Directory dir}) async {
    _uid++;
    final _id = _uid;
    dir ??= await Directory('tasks').absolute.createTemp();
    final fSets = File(p.join(dir.path, 'settings.json'));
    if (await fSets.exists()) {
      settings ??=
          TaskSettings.fromJson(jsonDecode(await fSets.readAsString()));
    }
    if (settings != null) {
      final _c = Completer<SendPort>();
      App().completers[_id] = _c;
      await File(p.join(dir.path, 'settings.json'))
          .writeAsString(jsonEncode(settings));
      final _iso = await Isolate.spawn(
          IsoTask.entryPoint,
          TaskSpawnSets._(
              _id, App().receivePort.sendPort, settings, Conv().charMaps, dir),
          debugName: '{$_id}(${settings.name})[${settings.user}');
      final _sendPort = await _c.future;
      App().completers[_id] = Completer<SendPort>();
      Task(_id, settings, _sendPort, _iso, dir);
      App().completers[_id].complete();
      App().completers.remove(_id);
    }
  }
}
