import 'dart:io';
import 'dart:isolate';
import 'dart:convert';

import 'package:knc/SocketWrapper.dart';
import 'package:knc/www.dart';

import 'App.dart';
import 'Conv.dart';
import 'TaskInternal.dart';
import 'User.dart';
import 'msgs.dart';

class Task extends TaskInternal {
  String pathOut;

  /// Изолят выоплнения задачи
  Isolate isolate;

  /// Порт задачи
  SendPort sendPort;
  SocketWrapper wrapper;

  Task(final int _id, final WWW_TaskSettings _settings, final User _user)
      : super(
            _id,
            _user,
            _settings,
            App()
                .clients
                .where((client) => client.user == _user)
                .map((e) => e.wrapper)
                .toList(growable: true)) {
    final jsonMsg = wwwTaskNew + jsonEncode(json);
    sendForAllClients(jsonMsg);
  }

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
    final xmlUrl =
        '/' + i.replaceAll('\\', '/').replaceAll(':', ' ').replaceAll(' ', '_');
    App().listOfFiles[xmlUrl] = File(_raport);
    sendForAllClients(wwwTaskUpdates +
        jsonEncode([
          {'id': id, 'raport': xmlUrl}
        ]));
  }

  bool _pause = false;
  set pause(final bool i) {
    if (i == null || _pause == i) {
      return;
    }
    _pause = i;
    sendForAllClients(wwwTaskUpdates +
        jsonEncode([
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
        jsonEncode([
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
        jsonEncode([
          {'id': id, 'warnings': _warnings}
        ]));
  }

  int _worked = 0;
  set worked(final int i) {
    if (i == null || _worked == i) {
      return;
    }
    _worked = i;
    sendForAllClients(wwwTaskUpdates +
        jsonEncode([
          {'id': id, 'worked': _worked}
        ]));
  }

  int _errors = 0;
  set errors(final int i) {
    if (i == null || _errors == i) {
      return;
    }
    _errors = i;
    sendForAllClients(wwwTaskUpdates +
        jsonEncode([
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
        jsonEncode([
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
    wrapper
        .waitMsgAll(msgTaskUpdateWorked)
        .listen((msg) => worked = int.tryParse(msg.s));
    wrapper.waitMsgAll(msgTaskUpdateRaport).listen((msg) => raport = msg.s);

    wrapper.waitMsgAll(msgDoc2x).listen((msg) {
      final i0 = msg.s.indexOf(msgRecordSeparator);
      Conv()
          .doc2x(msg.s.substring(0, i0),
              msg.s.substring(i0 + msgRecordSeparator.length))
          .then((value) => wrapper.send(msg.i, value.toString()));
    });

    wrapper.waitMsgAll(msgZip).listen((msg) {
      final i0 = msg.s.indexOf(msgRecordSeparator);
      final pIn = msg.s.substring(0, i0);
      final pOut = msg.s.substring(i0 + msgRecordSeparator.length);
      Conv()
          .zip(pIn, pOut)
          .then((value) => wrapper.send(msg.i, value.toWrapperMsg()));
    });

    wrapper.waitMsgAll(msgUnzip).listen((msg) {
      Conv()
          .unzip(msg.s)
          .then((value) => wrapper.send(msg.i, value.toWrapperMsg()));
    });
  }

  Future<SocketWrapperResponse> Function(String msgBegin) get waitMsg =>
      wrapper.waitMsg;
  Stream<SocketWrapperResponse> Function(String msgBegin) get waitMsgAll =>
      wrapper.waitMsgAll;
  Future<String> Function(String msg) get requestOnce => wrapper.requestOnce;
  Stream<String> Function(String msg) get requestSubscribe =>
      wrapper.requestSubscribe;
}
