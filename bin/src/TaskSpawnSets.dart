import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

import 'package:knc/knc.dart';
import 'package:path/path.dart' as p;

import 'App.dart';
import 'Conv.dart';
import 'TaskIso.dart';
import 'TaskController.dart';

/// Данные задачи передаваемые сервером изоляту при запуске
class TaskSpawnSets {
  /// Уникальный номер задачи (Название папки)
  final String id;

  /// Портя для связи с сервером
  final SendPort sendPort;

  /// Настройки задачи
  final JTaskSettings settings;

  /// Кодировки
  final Map<String, List<String>> charMaps;

  /// Флаг существования экзепляра задачи, т.е. настройки были загружены из
  /// папки задачи, а не заданны по новой
  final bool exists;

  TaskSpawnSets._(
      this.id, this.sendPort, this.settings, this.charMaps, this.exists);

  /// Запускает новую задачу с указанными настройками или из папки.
  ///
  /// * [dir] - восстанавливает задачу из папки
  /// * [settings] - запускает новую задачу с указанными настройками
  static Future<void> spawn(
      {JTaskSettings /*?*/ settings, Directory /*?*/ dir}) async {
    /// Если папки не существует, то создаём её
    dir ??= await TaskController.dirTasks.createTemp();
    final _id = p.basename(dir.path);
    final _fileSettings = File(p.join(dir.path, 'settings.json'));
    var _bExistsTask = false;
    if (await _fileSettings.exists()) {
      /// Если найден файл настроек, то загружаем его
      settings = JTaskSettings.fromJson(
          jsonDecode(await _fileSettings.readAsString()));
      _bExistsTask = true;
    }
    if (settings == null) {
      return;
    }

    await File(p.join(dir.path, 'settings.json'))
        .writeAsString(jsonEncode(settings));

    /// Устанавливаем перехватчик портя связи нового изолята
    final _c = Completer<SendPort>();
    App().completers[_id] = _c;

    /// Запускаем поток исполнения задачи
    final _iso = await Isolate.spawn(
        TaskIso.entryPoint,
        TaskSpawnSets._(_id, App().receivePort.sendPort, settings,
            Conv().charMaps, _bExistsTask),
        debugName: '{$_id}(${settings.name})[${settings.user}');

    /// Ждём пока поток вернёт порт для связи
    final _sendPort = await _c.future;

    /// Теперь создаём перехватчик остальных сообщений, так как сама задача уже
    /// работает, а её сообщения некому перехватывать, поэтому создаём новый
    /// перехватчик, при ожидании которго, будут откладываться сообщения
    /// полученные изолятом
    App().completers[_id] = Completer<SendPort>();

    /// Создаём экземпляр задачи на сервере, для контроля
    TaskController(_id, settings, _sendPort, _iso, dir);

    /// Завершаем перехватчик, после чего все ожидающие сообщения тут же
    /// отправятся только что созданному контроллеру задачи
    App().completers[_id] /*!*/ .complete();

    /// Удаляем перехватчик, так как теперь сообщения можно перенаправялть
    /// на прямую задаче
    App().completers.remove(_id);
  }
}
