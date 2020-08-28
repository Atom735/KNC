import 'dart:isolate';

import 'package:knc/knc.dart';

import 'IsoTask.dart';
import 'Task.dart';
import 'User.dart';

class TaskInternal {
  final int id;
  final User user;
  final WWW_TaskSettings settings;
  final List<SocketWrapper> wrappers;

  TaskInternal(this.id, this.user, this.settings, this.wrappers);
  TaskInternal.clone(final TaskInternal _this)
      : id = _this.id,
        user = _this.user,
        settings = _this.settings,
        wrappers = [];

  void sendForAllClients(final String msg) =>
      wrappers.forEach((s) => s.send(0, msg));
}

class TaskSpawnSets extends TaskInternal {
  final Map<String, List<String>> charMaps;
  final SendPort sendPort;

  TaskSpawnSets(final Task t, this.charMaps, this.sendPort) : super.clone(t);

  TaskSpawnSets.clone(final TaskSpawnSets t)
      : charMaps = t.charMaps,
        sendPort = t.sendPort,
        super.clone(t);

  Future<Isolate> spawn() => Isolate.spawn(IsoTask.entryPoint, this,
      debugName: '[$id]($user): "${settings.name}"');
}
