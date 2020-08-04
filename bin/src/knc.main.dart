import 'dart:isolate';
import 'dart:convert';

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
  int _iState = -1;
  int _iErrors = -1;
  int _iFiles = -1;

  /// Изолят выоплнения задачи
  Isolate isolate;

  /// Порт задачи
  SendPort sendPort;
  SocketWrapper wrapper;

  KncTaskOnMain(this.id, this.name, this.path);

  set iState(final int i) {
    if (i == null || _iState == i) {
      return;
    }
    _iState = i;
    App().sendForAllClients(wwwTaskUpdates +
        json.encode([
          {'id': id, 'state': _iState}
        ]));
  }

  set iErrors(final int i) {
    if (i == null || _iErrors == i) {
      return;
    }
    _iErrors = i;
    App().sendForAllClients(wwwTaskUpdates +
        json.encode([
          {'id': id, 'errors': _iState}
        ]));
  }

  set iFiles(final int i) {
    if (i == null || _iFiles == i) {
      return;
    }
    _iFiles = i;
    App().sendForAllClients(wwwTaskUpdates +
        json.encode([
          {'id': id, 'files': _iFiles}
        ]));
  }

  void initWrapper() {
    wrapper = SocketWrapper((str) => sendPort.send(str));
    wrapper.waitMsgAll(msgTaskUpdateState).listen((msg) {
      iState = int.tryParse(msg.s);
    });
  }
}
