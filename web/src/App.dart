import 'dart:async';
import 'dart:html';

import 'package:knc/knc.dart';
import 'package:mdc_web/mdc_web.dart';

import 'DialogAddTask.dart';
import 'DialogLogin.dart';
import 'TaskCard.dart';
import 'misc.dart';

class AppUser {
  final String mail;
  final int access;

  AppUser(this.mail, this.access);
}

class App {
  /// Сокет для связи с сервером
  final WebSocket socket;
  final Completer socketCompleter;
  final SocketWrapper wrapper;

  /// Вошедший пользователь
  AppUser user;

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

  Future<SocketWrapperResponse> waitMsg(String msgBegin) =>
      wrapper.waitMsg(msgBegin);
  Stream<SocketWrapperResponse> waitMsgAll(String msgBegin) =>
      wrapper.waitMsgAll(msgBegin);
  Future<String> requestOnce(String msg) => wrapper.requestOnce(msg);
  Stream<String> requestSubscribe(String msg) => wrapper.requestSubscribe(msg);

  void signin(String mail, String access) {
    eLoginBtn.innerText = 'account_circle';
    user = AppUser(mail, int.parse(access));
    MyTaskCardTemplate().updateTasks();
  }

  App._init(this.socket, this.socketCompleter)
      : wrapper = SocketWrapper((msg) {
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
      if (window.localStorage['signin'] != null) {
        requestOnce('$wwwSignIn${window.localStorage['signin']}').then((msg) {
          if (msg != 'null') {
            final s = window.localStorage['signin'];
            signin(s.substring(0, s.indexOf(':')), msg);
          } else {
            window.localStorage['signin'] = null;
          }
        });
      }
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
