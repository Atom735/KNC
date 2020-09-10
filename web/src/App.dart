import 'dart:async';
import 'dart:html';

import 'package:path/path.dart' as p;
import 'package:knc/knc.dart';
import 'package:mdc_web/mdc_web.dart';

import 'DialogLogin.dart';
import 'DialogUser.dart';
import 'FileLas.dart';
import 'TaskFiles.dart';
import 'User.dart';
import 'misc.dart';

class App extends SocketWrapper {
  /// Сокет для связи с сервером
  final WebSocket socket;
  final Completer socketCompleter;

  final eMain = document.body.querySelector('main.app');
  final eTopBar = MDCTopAppBar(eGetById('my-top-app-bar'));
  final eTopBarRoot = eGetById('my-top-app-bar');
  final eLinearProgress = MDCLinearProgress(eGetById('my-app-linear-progress'));
  final eTitle = eGetById('my-app-title');
  final eLoginBtn = eGetById('my-app-login');
  final eLoginMail = eGetById('my-app-login-mail');

  final DivElement eTitleSpinner = eGetById('page-title-spinner');

  static Future<void> init() async {
    document.body.insertAdjacentHtml(
        'afterBegin', await HttpRequest.getString('/src/App.html'),
        validator: nodeValidator);
  }

  // final TaskSetsDialog taskSets = TaskSetsDialog();
  // final TaskViewSection taskView = TaskViewSection();
  // final CardAddTask cardAddTask = CardAddTask();

  /// Установить состояние приложения как "Подключение к серверу"
  void _stateConnecting() {
    eTopBarRoot.style.backgroundColor = 'var(--mdc-theme-secondary)';
    eTopBarRoot.style.color = 'var(--mdc-theme-on-secondary)';
    eTopBarRoot
        .querySelectorAll(
            '.mdc-top-app-bar .mdc-top-app-bar__action-item, .mdc-top-app-bar .mdc-top-app-bar__navigation-icon')
        .forEach((e) => e.style.color = 'var(--mdc-theme-on-secondary)');
    eTitle.innerText = 'Подлкючение к серверу...';
    eLinearProgress.open();
  }

  /// Установить состояние приложения как "Подключено"
  void _stateConnected() {
    eTopBarRoot.style.backgroundColor = 'var(--mdc-theme-primary)';
    eTopBarRoot.style.color = 'var(--mdc-theme-on-primary)';
    eTopBarRoot
        .querySelectorAll(
            '.mdc-top-app-bar .mdc-top-app-bar__action-item, .mdc-top-app-bar .mdc-top-app-bar__navigation-icon')
        .forEach((e) => e.style.color = 'var(--mdc-theme-on-primary)');
    eTitle.innerText = 'Попытка входа в систему...';
    socketCompleter.complete();

    /// Попытка автомотического входа
    User.signByIndexDB().then((user) {
      eTitle.innerText = 'Пункт приёма стеклотары.';
      eLinearProgress.close();
    });
  }

  /// Установить состояние приложения как "Отключён от сервера"
  void _stateClosed() {
    eTitle.innerText = 'Меня отключили и потеряли...';
    eTopBarRoot.style.backgroundColor = 'var(--mdc-theme-error)';
    eTopBarRoot.style.color = 'var(--mdc-theme-on-error)';
    eTopBarRoot
        .querySelectorAll(
            '.mdc-top-app-bar .mdc-top-app-bar__action-item, .mdc-top-app-bar .mdc-top-app-bar__navigation-icon')
        .forEach((e) => e.style.color = 'var(--mdc-theme-on-error)');
  }

  @override
  String toString() =>
      '$runtimeType($hashCode)WebSocket[${socket.hashCode}].${socket.readyState}';
  App._init(this.socket, this.socketCompleter)
      : super((msg) {
          print('SEND: $msg');
          socket.sendString(msg);
        }, signal: socketCompleter.future) {
    print('$this created');
    _instance = this;
    _stateConnecting();

    eLoginBtn.onClick.listen(
        (_) => User() == null ? DialogLogin().open() : DialogUser().open());

    socket.onOpen.listen((_) => _stateConnected());
    socket.onClose.listen((_) => _stateClosed());
    socket.onMessage
        .listen((_) => recv(_.data) ? null : print('RECV: ${_.data}'));

    eMain.addEventListener('animationend', (event) {
      if ((event as AnimationEvent).animationName == 'slideout') {
        eMain.hidden = true;
        eMain.classes.remove('a-closing');
      } else if ((event as AnimationEvent).animationName == 'slidein') {
        eMain.hidden = false;
        eMain.classes.remove('a-opening');
      }
    });

    window.onPopState.listen((e) {
      uri = Uri.parse(document.baseUri);
      uriPaths = uri.pathSegments;
      pageSet();
    });

    pageSet();
  }

  void _open() {
    closeAll('app');
    eMain
      ..hidden = false
      ..classes.add('a-opening');
  }

  void pageSet() {
    if (uri.pathSegments.length >= 4 &&
        uri.pathSegments[0] == 'app' &&
        uri.pathSegments[1] == 'task') {
      if (uri.pathSegments[3] == 'files') {
        TaskFiles()
            .open(uri.pathSegments[2],
                uri.pathSegments.length >= 5 ? uri.pathSegments[4] : null)
            .then((b) {
          if (!b) {
            window.history.pushState('data', 'title', '/app');
            uri = Uri.parse(document.baseUri);
            uriPaths = uri.pathSegments;
            _open();
          }
        });
      }
      // TODO: другие действия с задачей
    }
    if (uri.pathSegments.length >= 4 &&
        uri.pathSegments[0] == 'app' &&
        uri.pathSegments[1] == 'file') {
      if (uri.pathSegments[2] == 'tasks') {
        FileLas()
            .open(
                OneFileData(
                    p.joinAll(uri.pathSegments.sublist(2)), null, null, null),
                uri.query)
            .then((b) {
          if (!b) {
            window.history.pushState('data', 'title', '/app');
            uri = Uri.parse(document.baseUri);
            uriPaths = uri.pathSegments;
            _open();
          }
        });
      }
      // TODO: другие действия с задачей
    } else {
      _open();
    }
  }

  static App _instance;
  // WebSocket('ws://${uri.host}:${uri.port}');
  factory App() =>
      (_instance) ??
      (_instance =
          App._init(WebSocket('ws://${uri.host}:$wwwPort/ws'), Completer()));
}
