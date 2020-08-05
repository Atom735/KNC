import 'dart:async';
import 'dart:io';

import 'package:knc/errors.dart';
import 'package:knc/SocketWrapper.dart';
import 'package:knc/www.dart';

import 'App.dart';

class WebClient {
  /// Сокет для связи с клиентом
  final WebSocket socket;
  final SocketWrapper wrapper;
  StreamSubscription socketSubscription;

  WebClient(this.socket) : wrapper = SocketWrapper((msg) => socket.add(msg)) {
    socketSubscription = socket.listen((event) {
      if (event is String) {
        print('WS_RECV: $event');
        wrapper.recv(event);
      }
    }, onError: getErrorFunc('Ошибка в прослушке WebSocket:'));
    waitMsgAll(wwwTaskViewUpdate).listen((msg) {
      wrapper.send(msg.i, App().getWwwTaskViewUpdate());
    });
    waitMsgAll(wwwTaskNew).listen((msg) {
      App().sendForAllClients(App().getWwwTaskNew(msg.s));
      wrapper.send(msg.i, '');
    });
    waitMsgAll(wwwTaskGetErrors).listen((msg) {
      final i0 = msg.s.indexOf(':');
      final id = int.tryParse(msg.s.substring(0, i0));
      App()
          .listOfTasks[id]
          .wrapper
          .requestOnce('$wwwTaskGetErrors${msg.s.substring(i0 + 1)}')
          .then((v) => wrapper.send(msg.i, v));
    });
    waitMsgAll(wwwTaskGetFiles).listen((msg) {
      final i0 = msg.s.indexOf(':');
      final id = int.tryParse(msg.s.substring(0, i0));
      App()
          .listOfTasks[id]
          .wrapper
          .requestOnce('$wwwTaskGetFiles${msg.s.substring(i0 + 1)}')
          .then((v) => wrapper.send(msg.i, v));
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
