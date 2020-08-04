import 'dart:isolate';
import 'dart:convert';

import 'package:knc/SocketWrapper.dart';
import 'package:knc/www.dart';

import 'App.dart';
import 'knc.dart';

class KncSettingsOnMain extends KncSettingsInternal {
  /// Изолят выоплнения задачи
  Isolate isolate;

  /// Порт задачи
  SendPort sendPort;
  SocketWrapper wrapper;

  void initWrapper() {
    wrapper = SocketWrapper((str) => sendPort.send(str));
    wrapper.waitMsg(msgTaskPathOutSets).then((msg) {
      ssPathOut = msg.s;
      wrapper.send(msg.i, '');
    });
    wrapper.waitMsgAll(msgTaskUpdateState).listen((msg) {
      iState = KncTaskState.values[int.tryParse(msg.s)];
      App().listOfClients.forEach((client) {
        final value = [
          {'id': uID, 'state': iState.index}
        ];
        client.wrapper.send(0, '$wwwTaskUpdates${json.encode(value)}');
      });
    });
  }
}
