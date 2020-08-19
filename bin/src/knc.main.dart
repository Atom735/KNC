import 'dart:isolate';
import 'dart:convert' as c;

import 'package:knc/SocketWrapper.dart';
import 'package:knc/www.dart';

import 'App.dart';
import 'WebClient.dart';
import 'knc.dart';

class KncTaskInternal {
  final int id;
  final WebClientUser user;
  final WWW_TaskSettings settings;
  final List<SocketWrapper> wrappers;

  KncTaskInternal(this.id, this.user, this.settings, this.wrappers);
  KncTaskInternal.clone(final KncTaskInternal _this)
      : id = _this.id,
        user = _this.user,
        settings = _this.settings,
        wrappers = [];
}

class KncTaskSpawnSets extends KncTaskInternal {
  final Map<String, List<String>> charMaps;
  final SendPort sendPort;

  KncTaskSpawnSets(final KncTaskOnMain t, this.charMaps, this.sendPort)
      : super.clone(t);

  KncTaskSpawnSets.clone(final KncTaskSpawnSets t)
      : charMaps = t.charMaps,
        sendPort = t.sendPort,
        super.clone(t);

  Future<Isolate> spawn() => Isolate.spawn(KncTask.entryPoint, this,
      debugName: '[$id]($user): "${settings.name}"');
}

class KncTaskOnMain extends KncTaskInternal {
  String pathOut;

  /// Изолят выоплнения задачи
  Isolate isolate;

  /// Порт задачи
  SendPort sendPort;
  SocketWrapper wrapper;

  KncTaskOnMain(final int _id, final WWW_TaskSettings _settings,
      final WebClientUser _user)
      : super(
            _id,
            _user,
            _settings,
            App()
                .listOfClients
                .where((client) => client.user == _user)
                .map((e) => e.wrapper)
                .toList(growable: true)) {
    final jsonMsg = wwwTaskNew + c.jsonEncode(json);
    sendForAllClients(jsonMsg);
  }

  void sendForAllClients(final String msg) =>
      wrappers.forEach((s) => s.send(0, msg));

  dynamic get json => {
        'id': id,
        'name': settings.name,
        'state': _state,
        'errors': _errors,
        'files': _files,
        'warnings': _warnings,
        'pause': _pause,
        'raport': _raport,
      };

  String _raport;
  set raport(final String i) {
    if (i == null || _raport == i) {
      return;
    }
    _raport = i;
    sendForAllClients(wwwTaskUpdates +
        c.json.encode([
          {'id': id, 'raport': _raport}
        ]));
  }

  bool _pause = false;
  set pause(final bool i) {
    if (i == null || _pause == i) {
      return;
    }
    _pause = i;
    sendForAllClients(wwwTaskUpdates +
        c.json.encode([
          {'id': id, 'pause': _pause}
        ]));
  }

  int _state = NTaskState.initialization.index;
  set state(final int i) {
    if (i == null || _state == i) {
      return;
    }
    _state = i;
    sendForAllClients(wwwTaskUpdates +
        c.json.encode([
          {'id': id, 'state': _state}
        ]));
  }

  int _warnings = 0;
  set warnings(final int i) {
    if (i == null || _warnings == i) {
      return;
    }
    _warnings = i;
    sendForAllClients(wwwTaskUpdates +
        c.json.encode([
          {'id': id, 'warnings': _warnings}
        ]));
  }

  int _errors = 0;
  set errors(final int i) {
    if (i == null || _errors == i) {
      return;
    }
    _errors = i;
    sendForAllClients(wwwTaskUpdates +
        c.json.encode([
          {'id': id, 'errors': _errors}
        ]));
  }

  int _files = 0;
  set files(final int i) {
    if (i == null || _files == i) {
      return;
    }
    _files = i;
    sendForAllClients(wwwTaskUpdates +
        c.json.encode([
          {'id': id, 'files': _files}
        ]));
  }

  void initWrapper() {
    wrapper = SocketWrapper((str) => sendPort.send(str));
    wrapper
        .waitMsgAll(msgTaskUpdateState)
        .listen((msg) => state = int.tryParse(msg.s));
    wrapper
        .waitMsgAll(msgTaskUpdateErrors)
        .listen((msg) => errors = int.tryParse(msg.s));
    wrapper
        .waitMsgAll(msgTaskUpdateFiles)
        .listen((msg) => files = int.tryParse(msg.s));
    wrapper
        .waitMsgAll(msgTaskUpdateWarnings)
        .listen((msg) => warnings = int.tryParse(msg.s));

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
