import 'dart:async';
import 'dart:html';

import 'package:knc/knc.dart';
import 'package:mdc_web/mdc_web.dart';

import 'DialogAddTask.dart';
import 'DialogLogin.dart';
import 'TaskCard.dart';
import 'misc.dart';

class App extends SocketWrapper {
  /// Сокет для связи с сервером
  final WebSocket socket;
  final Completer socketCompleter;

  final eTopBar = MDCTopAppBar(eGetById('my-top-app-bar'));
  final eTopBarRoot = eGetById('my-top-app-bar');
  final eLinearProgress = MDCLinearProgress(eGetById('my-app-linear-progress'));
  final eTitle = eGetById('my-app-title');
  final eLoginBtn = eGetById('my-app-login');

  final DivElement eTitleSpinner = eGetById('page-title-spinner');
  final SpanElement eTitleText = eGetById('my-app-title');

  // final TaskSetsDialog taskSets = TaskSetsDialog();
  // final TaskViewSection taskView = TaskViewSection();
  // final CardAddTask cardAddTask = CardAddTask();

  void signin(String mail, String access) {
    eLoginBtn.innerText = 'account_circle';
    user = AppUser(mail, access);
    MyTaskCardTemplate().updateTasks();
  }

  App._init(this.socket, this.socketCompleter)
      : super((msg) {
          print('SEND: $msg');
          socket.sendString(msg);
        }, signal: socketCompleter.future) {
    print('$runtimeType created: $hashCode');
    _instance = this;

    MyTaskCardTemplate();
    CardAddTask();

    eTopBarRoot.style.backgroundColor = 'var(--mdc-theme-secondary)';
    eTopBarRoot.style.color = 'var(--mdc-theme-on-secondary)';
    eTopBarRoot
        .querySelectorAll(
            '.mdc-top-app-bar .mdc-top-app-bar__action-item, .mdc-top-app-bar .mdc-top-app-bar__navigation-icon')
        .forEach((e) => e.style.color = 'var(--mdc-theme-on-secondary)');
    eTitle.innerText = 'Подлкючение к серверу...';

    eLoginBtn.onClick.listen((_) => user == null ? DialogLogin().open() : 0);
    socket.onOpen.listen((_) {
      eLinearProgress.close();
      socketCompleter.complete();
      eTopBarRoot.style.backgroundColor = 'var(--mdc-theme-primary)';
      eTopBarRoot.style.color = 'var(--mdc-theme-on-primary)';
      eTopBarRoot
          .querySelectorAll(
              '.mdc-top-app-bar .mdc-top-app-bar__action-item, .mdc-top-app-bar .mdc-top-app-bar__navigation-icon')
          .forEach((e) => e.style.color = 'var(--mdc-theme-on-primary)');
      eTitle.innerText = 'Пункт приёма стеклотары.';
    });
    socket.onClose.listen((_) {
      eTitleText.innerText = 'Меня отключили и потеряли...';
      eTopBarRoot.style.backgroundColor = 'var(--mdc-theme-error)';
      eTopBarRoot.style.color = 'var(--mdc-theme-on-error)';
      eTopBarRoot
          .querySelectorAll(
              '.mdc-top-app-bar .mdc-top-app-bar__action-item, .mdc-top-app-bar .mdc-top-app-bar__navigation-icon')
          .forEach((e) => e.style.color = 'var(--mdc-theme-on-error)');
    });
    socket.onMessage
        .listen((_) => wrapper.recv(_.data) ? null : print('RECV: ${_.data}'));
  }
  static App _instance;
  // WebSocket('ws://${uri.host}:${uri.port}');
  factory App() =>
      (_instance) ??
      (_instance =
          App._init(WebSocket('ws://${uri.host}:$wwwPort/ws'), Completer()));
}
