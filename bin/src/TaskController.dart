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

/*
    /// Перенаправление сообщений об обновлённом состоянии
    /// задачи всем доступныым клиентам
    waitMsgAll(wwwTaskUpdates).listen((msg) {
      map.addAll(jsonDecode(msg.s));
      if ((map['raport'] != null) &&
          !(map['raport'] as String).startsWith('/raport/')) {
        final xmlUrl = '/raport/${passwordEncode(map['raport'])}';
        Server().fileMap[xmlUrl] = File(map['raport']);
        map['raport'] = xmlUrl;
        sendForAllClients(wwwTaskUpdates + jsonEncode(map));
      } else {
        sendForAllClients(wwwTaskUpdates + msg.s);
      }
    });

    /// Просьба задачи на конвертацию doc файла в docx
    waitMsgAll(msgDoc2x).listen((msg) {
      final i0 = msg.s.indexOf(msgRecordSeparator);
      final pIn = msg.s.substring(0, i0);
      final pOut = msg.s.substring(i0 + msgRecordSeparator.length);
      Conv().doc2x(pIn, pOut).then((value) => send(msg.i, value.toString()));
    });

    /// Просьба задачи на запаковку внутренностей папки $1 в zip архив $2
    waitMsgAll(msgZip).listen((msg) {
      final i0 = msg.s.indexOf(msgRecordSeparator);
      final pIn = msg.s.substring(0, i0);
      final pOut = msg.s.substring(i0 + msgRecordSeparator.length);
      Conv().zip(pIn, pOut).then((value) => send(msg.i, value.toWrapperMsg()));
    });

    /// Просьба задачи на распаковку архива $1
    waitMsgAll(msgUnzip).listen((msg) {
      Conv().unzip(msg.s).then((value) => send(msg.i, value.toWrapperMsg()));
    });

    // уведомить клиентов о старте новой задачи
    sendForAllClients(wwwTaskNew + jsonEncode(this));
*/
  }

  /// Отправка сообщения всем пользователям, которым доступна задача
  void sendForAllClients(final String msg) => Client.list
      .where((e) =>

          /// Клиенты запустившие задачу
          (e.user?.mail ?? '') == settings.user ||

          /// Клиенты находящиеся в списке доступа
          (settings.users?.contains(e.user?.mail ?? '') ?? false) ||

          /// Доступность неавторизированным пользователям
          (settings.users?.contains('') ?? true))
      .forEach((e) => e.send(0, msg));
}