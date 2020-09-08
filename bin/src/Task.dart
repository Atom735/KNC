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

class Task extends SocketWrapper {
  /// Уникальный номер задачи
  final int id;

  /// Портя для связи с изолятом задачи
  final SendPort sendPort;

  /// Настройки задачи
  final TaskSettings settings;

  /// Изолят выполнения задачи
  final Isolate isolate;

  /// Папка задачи
  final Directory dir;

  /// Список всех выполняемых задач
  static final list = <int, Task>{};

  /// Список всех закрытых задач
  static final listClosed = <int, Task>{};

  /// Папка со всеми задачами
  static final dirTasks = Directory('tasks').absolute;

  /// Данные состояния задачи
  final Map<String, Object> map;

  /// Закешированные данные о файлах, только для закрытой задачи
  List<OneFileData> filesDataCached;

  Future<List<OneFileData>> getFilesData() async {
    if (filesDataCached != null) {
      return filesDataCached;
    }
    final data = await File(p.join(dir.path, 'files.txt')).readAsString();
    final lines = LineSplitter.split(data).toList(growable: false);
    final _l = lines.length ~/ 4;
    final _fc = List<OneFileData>(_l);
    for (var i = 0; i < _l; i++) {
      final _path = lines[i * 4 + 2];
      final _origin = lines[i * 4 + 1];
      final _fileJson = File(_path + '.json');
      if (await _fileJson.exists()) {
        _fc[i] =
            OneFileData.byJsonFull(jsonDecode(await _fileJson.readAsString()));
      } else {
        _fc[i] = OneFileData(_path, _origin, NOneFileDataType.unknown,
            await File(_path).length());
      }
    }
    return filesDataCached = _fc;
  }

  @override
  String toString() => '$runtimeType{$id}(${settings.name})[${settings.user}]';

  /// Поиск всех закрытых задач и регистрация их в системе
  static Future<void> searchClosed() async {
    if (await dirTasks.exists()) {
      try {
        await dirTasks
            .list()
            .asyncMap<Task>(
                (entity) => entity is Directory ? Task.closed(entity) : null)
            .last;
      } catch (e) {
        print('Exception when list closed tasks: $e');
      }
    } else {
      await dirTasks.create();
    }
  }

  /// Создаёт экземляр закрытой задачей
  static Future<Task> closed(Directory _dir) async {
    final _fileState = File(p.join(_dir.path, 'state.json'));
    final state = await _fileState
        .exists()
        .then<String>((ex) => ex ? _fileState.readAsString() : null)
        .then<Map<String, Object>>(
            (data) => data != null ? jsonDecode(data) : null);
    final _fileSetting = File(p.join(_dir.path, 'settings.json'));

    final settings = await _fileSetting
        .exists()
        .then((ex) => ex ? _fileSetting.readAsString() : null)
        .then((data) =>
            data != null ? TaskSettings.fromJson(jsonDecode(data)) : null);
    if (state != null && settings != null) {
      /// Если хватает всех данных для создания экземпляра
      final task = Task(state['id'], settings, null, null, _dir, closed: true);
      task.map.addAll(state);
      return task;
    }
    return null;
  }

  /// Создаёт экземпляр задачи с указанными настройками
  Task(this.id, this.settings, final SendPort _sendPort, this.isolate, this.dir,
      {bool closed = false})
      : sendPort = _sendPort,
        map = {'id': id, 'dir': p.basename(dir.path), 'name': settings.name},
        super((msg) => _sendPort.send(msg)) {
    if (closed) {
      print('$this created [CLOSED TYPE]');
      listClosed[id] = this;
      map['closed'] = true;
      App.uidTaskCounter = max(App.uidTaskCounter, id);
    } else {
      print('$this created');
      list[id] = this;
      map['closed'] = false;

      /// Перенаправление сообщений об обновлённом состоянии
      /// задачи всем доступныым клиентам
      waitMsgAll(wwwTaskUpdates).listen((msg) {
        map.addAll(jsonDecode(msg.s));
        if ((map['raport'] != null) &&
            !(map['raport'] as String).startsWith('/raport/')) {
          final xmlUrl = '/raport/${passwordEncode(map['raport'])}';
          Server().fileMap[xmlUrl] = File(map['raport']);
          map['raport'] = xmlUrl;
        }
        sendForAllClients(wwwTaskUpdates + msg.s);
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
        Conv()
            .zip(pIn, pOut)
            .then((value) => send(msg.i, value.toWrapperMsg()));
      });

      /// Просьба задачи на распаковку архива $1
      waitMsgAll(msgUnzip).listen((msg) {
        Conv().unzip(msg.s).then((value) => send(msg.i, value.toWrapperMsg()));
      });

      // уведомить клиентов о старте новой задачи
      sendForAllClients(wwwTaskNew + jsonEncode(this));
    }
  }

  /// Отправка сообщения всем пользователям, которым доступна задача
  void sendForAllClients(final String msg) => Client.list
      .where((e) =>
          e.user.mail == settings.user || settings.users.contains(e.user.mail))
      .forEach((e) => e.send(0, msg));

  Map<String, Object> toJson() => map;
}
