import 'dart:async';
import 'dart:html';

import 'package:knc/SocketWrapper.dart';

import 'HtmlGenerator.dart';
import 'TaskSets.dart';
import 'TaskViewSection.dart';
import 'misc.dart';

class App {
  /// Сокет для связи с сервером
  final WebSocket socket;
  final Completer socketCompleter;
  final SocketWrapper wrapper;

  final DivElement eTitleSpinner = eGetById('page-title-spinner');
  final SpanElement eTitleText = eGetById('page-title-text');

  final TaskSetsDialog taskSets = TaskSetsDialog();
  final TaskViewSection taskView = TaskViewSection();

  void onOpen() {
    eTitleText.innerText = 'Пункт приёма стеклотары.';
    eTitleSpinner.hidden = true;
    socketCompleter.complete();
    taskSets.eOpen.disabled = false;
  }

  void onClose() {
    eTitleText.innerText = 'Меня отключили и потеряли...';
    taskSets.eOpen.disabled = true;
  }

  void onMessage(final String msg) => wrapper.recv(msg);

  Future<SocketWrapperResponse> Function(String msgBegin) get waitMsg =>
      wrapper.waitMsg;
  Stream<SocketWrapperResponse> Function(String msgBegin) get waitMsgAll =>
      wrapper.waitMsgAll;
  Future<String> Function(String msg) get requestOnce => wrapper.requestOnce;
  Stream<String> Function(String msg) get requestSubscribe =>
      wrapper.requestSubscribe;

  App._init(this.socket, this.socketCompleter)
      : wrapper = SocketWrapper((msg) => socket.sendString(msg),
            signal: socketCompleter.future) {
    socket.onOpen.listen((_) => onOpen());
    socket.onClose.listen((_) => onClose());
    socket.onMessage.listen((_) => onMessage(_.data));

    generator();
  }
  static App _instance;
  // WebSocket('ws://${uri.host}:${uri.port}');
  factory App() =>
      (_instance) ??
      (_instance = App._init(WebSocket('ws://${uri.host}:80/ws'), Completer()));
}
