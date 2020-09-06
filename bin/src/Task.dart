import 'dart:io';
import 'dart:isolate';
import 'dart:convert';

import 'package:knc/knc.dart';
import 'package:path/path.dart' as p;

import 'Client.dart';
import 'Conv.dart';
import 'Server.dart';
import 'msgs.dart';

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

  /// Данные подготовляемые для отправки как обновление состояния задачи
  final vUpdate = <String, Object>{};

  /// Future отправения обновления
  Future vUpdateFuture;

  @override
  String toString() => '$runtimeType{$id}(${settings.name})[${settings.user}]';

  Task(this.id, this.settings, final SendPort _sendPort, this.isolate, this.dir)
      : sendPort = _sendPort,
        super((msg) => _sendPort.send(msg)) {
    print('$this created');
    list[id] = this;

    waitMsgAll(msgTaskUpdateState).listen((msg) => state = int.tryParse(msg.s));
    waitMsgAll(msgTaskUpdateErrors)
        .listen((msg) => errors = int.tryParse(msg.s));
    waitMsgAll(msgTaskUpdateFiles).listen((msg) => files = int.tryParse(msg.s));
    waitMsgAll(msgTaskUpdateWarnings)
        .listen((msg) => warnings = int.tryParse(msg.s));
    waitMsgAll(msgTaskUpdateWorked)
        .listen((msg) => worked = int.tryParse(msg.s));
    waitMsgAll(msgTaskUpdateRaport).listen((msg) => raport = msg.s);

    waitMsgAll(msgDoc2x).listen((msg) {
      final i0 = msg.s.indexOf(msgRecordSeparator);
      Conv()
          .doc2x(msg.s.substring(0, i0),
              msg.s.substring(i0 + msgRecordSeparator.length))
          .then((value) => send(msg.i, value.toString()));
    });

    waitMsgAll(msgZip).listen((msg) {
      final i0 = msg.s.indexOf(msgRecordSeparator);
      final pIn = msg.s.substring(0, i0);
      final pOut = msg.s.substring(i0 + msgRecordSeparator.length);
      Conv().zip(pIn, pOut).then((value) => send(msg.i, value.toWrapperMsg()));
    });

    waitMsgAll(msgUnzip).listen((msg) {
      Conv().unzip(msg.s).then((value) => send(msg.i, value.toWrapperMsg()));
    });

    // TODO: уведомить клиентов о старте новой задачи
    sendForAllClients('$wwwTaskNew${jsonEncode(this)}');
  }

  /// Отправка сообщения всем пользователям, которым доступна задача
  void sendForAllClients(final String msg) => Client.list
      .where((e) =>
          e.user.mail == settings.user || settings.users.contains(e.user.mail))
      .forEach((e) => e.send(0, msg));

  Map<String, Object> toJson() => {
        'id': id,
        'name': settings.name,
        'state': _state,
        'errors': _errors,
        'files': _files,
        'warnings': _warnings,
        'pause': _pause,
        'raport':
            (_raport != null ? '/raport/${passwordEncode(_raport)}' : null),
        'dir': p.basename(dir.path),
      };

  /// Обновление данных для отправки сообщения об обновлении
  void update(String n, Object v) {
    vUpdate[n] = v;
    vUpdateFuture ??=
        Future.delayed(Duration(milliseconds: settings.update_duration))
            .then((_) {
      vUpdate['id'] = id;
      sendForAllClients(wwwTaskUpdates + jsonEncode(vUpdate));
      vUpdateFuture = null;
      vUpdate.clear();
    });
  }

  String _raport;
  set raport(final String i) {
    if (i == null || _raport == i) {
      return;
    }
    _raport = i;
    final xmlUrl = '/raport/${passwordEncode(_raport)}';
    Server().fileMap[xmlUrl] = File(_raport);
    update('raport', xmlUrl);
  }

  bool _pause = false;
  set pause(final bool i) {
    if (i == null || _pause == i) {
      return;
    }
    _pause = i;
    update('pause', _pause);
  }

  int _state = NTaskState.initialization.index;
  set state(final int i) {
    if (i == null || _state == i) {
      return;
    }
    _state = i;
    update('state', _state);
  }

  int _warnings = 0;
  set warnings(final int i) {
    if (i == null || _warnings == i) {
      return;
    }
    _warnings = i;
    update('warnings', _warnings);
  }

  int _worked = 0;
  set worked(final int i) {
    if (i == null || _worked == i) {
      return;
    }
    _worked = i;
    update('worked', _worked);
  }

  int _errors = 0;
  set errors(final int i) {
    if (i == null || _errors == i) {
      return;
    }
    _errors = i;
    update('errors', _errors);
  }

  int _files = 0;
  set files(final int i) {
    if (i == null || _files == i) {
      return;
    }
    _files = i;
    update('files', _files);
  }
}
