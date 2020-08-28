import 'dart:async';
import 'dart:io';
import 'dart:isolate';

import 'package:knc/knc.dart';

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
  static Future<void> spawn(
      {final TaskSettings settings, Directory dir}) async {
    _uid++;
    final _id = _uid;
    final _c = Completer<SendPort>();
    App().completers[_id] = _c;
    final _dir = dir ?? await Directory('tasks').absolute.createTemp();
    if (settings != null) {
      Task(
          _id,
          settings,
          await _c.future,
          await Isolate.spawn(
              IsoTask.entryPoint,
              TaskSpawnSets._(_id, App().receivePort.sendPort, settings,
                  Conv().charMaps, _dir),
              debugName: '{$_id}(${settings.name})[${settings.user}'),
          _dir);
    }
  }
}
