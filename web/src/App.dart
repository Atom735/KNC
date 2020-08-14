import 'dart:async';
import 'dart:html';

import 'package:knc/SocketWrapper.dart';
import 'package:mdc_web/mdc_web.dart';

import 'DialogLogin.dart';
import 'HtmlGenerator.dart';
import 'TaskSets.dart';
import 'TaskViewSection.dart';
import 'misc.dart';

class App {
  /// Сокет для связи с сервером
  final WebSocket socket;
  final Completer socketCompleter;
  final SocketWrapper wrapper;

  final eLinearProgress = MDCLinearProgress(eGetById('my-app-linear-progress'));
  final eTitle = eGetById('my-app-title');
  final eLoginBtn = eGetById('my-app-login')
    ..onClick.listen((_) => DialogLogin().open());

  final DivElement eTitleSpinner = eGetById('page-title-spinner');
  final SpanElement eTitleText = eGetById('my-app-title');

  final TaskSetsDialog taskSets = TaskSetsDialog();
  final TaskViewSection taskView = TaskViewSection();

  Future<SocketWrapperResponse> waitMsg(String msgBegin) =>
      wrapper.waitMsg(msgBegin);
  Stream<SocketWrapperResponse> waitMsgAll(String msgBegin) =>
      wrapper.waitMsgAll(msgBegin);
  Future<String> requestOnce(String msg) => wrapper.requestOnce(msg);
  Stream<String> requestSubscribe(String msg) => wrapper.requestSubscribe(msg);

  App._init(this.socket, this.socketCompleter)
      : wrapper = SocketWrapper((msg) => socket.sendString(msg),
            signal: socketCompleter.future) {
    print('App created: $hashCode');

    socket.onOpen.listen((_) {
      eTitle.innerText = 'Пункт приёма стеклотары.';
      eLinearProgress.close();
      socketCompleter.complete();
    });
    socket.onClose.listen((_) {
      eTitleText.innerText = 'Меня отключили и потеряли...';
    });
    socket.onMessage.listen((_) => wrapper.recv(_.data));
  }
  static App _instance;
  // WebSocket('ws://${uri.host}:${uri.port}');
  factory App() =>
      (_instance) ??
      (_instance = App._init(WebSocket('ws://${uri.host}:80/ws'), Completer()));
}
