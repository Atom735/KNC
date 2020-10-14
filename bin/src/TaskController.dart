import 'dart:io';
import 'dart:isolate';
import 'dart:convert';
import 'dart:math';

import 'package:knc/knc.dart';
import 'package:path/path.dart' as p;

import 'App.dart';
import 'Client.dart';
import 'Conv.dart';
import 'Server.dart';
import 'TaskSpawnSets.dart';
import 'User.dart';
import 'misc.dart';

/// Класс управления задачей находящийся на сервере...
/// Все взаимдействия с задачами происходят через него, также через него
/// происходит общение с запущенной задачей, у которой работает свой `Isolate`
/// (Поток исполнения)
class TaskController extends SocketWrapper {
  /// Уникальный номер задачи (имя рабочей папки)
  final String id;

  /// Порт для связи с изолятом задачи
  final SendPort sendPort;

  /// Настройки задачи
  JTaskSettings settings;

  /// Изолят выполнения задачи
  final Isolate isolate;

  /// Папка задачи
  final Directory dir;

  /// Список всех задач
  static final list = <String, TaskController>{};

  /// Папка со всеми задачами
  static final dirTasks = Directory('tasks').absolute;

  @override
  String toString() => '$runtimeType{$id}(${settings.name})[${settings.user}]';

  /// Поиск всех закрытых задач и регистрация их в системе
  static Future<void> init() async {
    if (await dirTasks.exists()) {
      try {
        await dirTasks.list().asyncMap<Null>((entity) {
          if (entity is Directory) {
            /// Пытаемся восстановить задачу
            TaskSpawnSets.spawn(dir: entity);
          }
        }).last;
      } catch (e, _st) {
        getErrorFunc('Исключение при обходе папки с задачами:')(e, _st);
      }
    } else {
      await dirTasks.create();
    }
  }

  /// Создаёт экземпляр задачи с указанными настройками
  TaskController(
      this.id, this.settings, final SendPort _sendPort, this.isolate, this.dir,
      {bool closed = false})
      : sendPort = _sendPort,
        super((msg) => _sendPort.send(msg)) {
    print('$this created');
    list[id] = this;

    /// Просьба задачи на конвертацию doc файла в docx
    waitMsgAll(JMsgDoc2X.msgId).listen((msg) {
      final _msg = JMsgDoc2X.fromString(msg.s);
      Conv()
          .doc2x(_msg.doc, _msg.docx)
          .then((value) => send(msg.i, value.exitCode.toString()));
    });

    /// Просьба задачи на запаковку внутренностей папки $1 в zip архив $2
    waitMsgAll(JMsgZip.msgId).listen((msg) {
      final _msg = JMsgZip.fromString(msg.s);
      Conv()
          .zip(_msg.dir, _msg.zip)
          .then((value) => send(msg.i, value.toWrapperMsg()));
    });

    /// Просьба задачи на распаковку архива $1
    waitMsgAll(JMsgUnzip.msgId).listen((msg) {
      final _msg = JMsgUnzip.fromString(msg.s);
      Conv()
          .unzip(_msg.zip, _msg.dir)
          .then((value) => send(msg.i, value.toWrapperMsg()));
    });

    /// Перенаправление сообщений об обновлённом состоянии
    /// задачи всем доступныым клиентам
    waitMsgAll(JMsgTaskUpdate.msgId)
        .listen((msg) => sendForAllClients(JMsgTaskUpdate.msgId + msg.s));

    /// Сообщение об изменении отчёта
    waitMsgAll(JMsgTaskRaport.msgId).listen((msg) {
      final _msg = JMsgTaskRaport.fromString(msg.s);
      final _url = '/' + (p.url.join('raports', id)) + '.xlsx';
      final _urlLas = '/' + (p.url.join('lases', id)) + '.zip';
      final _urlInk = '/' + (p.url.join('inks', id)) + '.zip';
      if (_msg.path.isNotEmpty) {
        final _filePath = p.join(TaskController.dirTasks.path, id, _msg.path);
        final _filePathLas =
            p.join(TaskController.dirTasks.path, id, 'lases.zip');
        final _filePathInk =
            p.join(TaskController.dirTasks.path, id, 'inks.zip');
        Server().addFileMap(_url, File(_filePath));
        Server().addFileMap(_urlLas, File(_filePathLas));
        Server().addFileMap(_urlInk, File(_filePathInk));
      } else {
        Server().addFileMap(_url, null);
        Server().addFileMap(_urlLas, null);
        Server().addFileMap(_urlInk, null);
      }
    });

    /// Сообщение об удалении задачи
    waitMsgAll(JMsgTaskKill.msgId).listen((msg) {
      final _msg = JMsgTaskKill.fromString(msg.s);
      sendForAllClients(_msg.toString());
      final _task = list[_msg.id];
      _task.isolate.kill(priority: Isolate.immediate);
      tryFunc(() => _task.dir.delete(recursive: true),
          tryesMax: 600, tryesDuration: 100);
      list.remove(_msg.id);
    });

    // уведомить клиентов о старте новой задачи
    sendForAllClients(JMsgTaskNew(id).toString());
  }

  /// Получить список веб клиентов имеющих доступ к задаче.
  Iterable<Client> getTaskClients() => Client.list.where((e) =>

      /// Клиенты запустившие задачу
      (e.user?.mail ?? '@guest') == settings.user ||

      /// Клиенты находящиеся в списке доступа
      (settings.users?.contains(e.user?.mail ?? '@guest') ?? false) ||

      /// Доступность неавторизированным пользователям
      (settings.users?.contains('@guest') ?? true) ||

      /// Доступность суперпользавателю
      (e.user?.access?.contains('x') ?? false));

  /// Отправка сообщения всем пользователям, которым доступна задача
  void sendForAllClients(final String msg) =>
      getTaskClients().forEach((e) => e.send(0, msg));
}
