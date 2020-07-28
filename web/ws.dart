import 'dart:html';

import 'package:knc/www.dart';

class KncSettingsStateWeb extends KncSettingsInternal {
  final DetailsElement pStateBlock = document.createElement('details');
  final Element pStateName = document.createElement('summary');
  final ParagraphElement pStateText = document.createElement('p')
    ..classes.add('state');
  final ParagraphElement pStateOutPath = document.createElement('p')
    ..classes.add('out');
  final List<ParagraphElement> pStateInList = [];
  final ParagraphElement pStateLastMsg = document.createElement('p')
    ..classes.add('msg');
  final AnchorElement pStateAnchorToTask = document.createElement('a')
    ..classes.add('hrefbtn');
  final AnchorElement pStateAnchorToXls = document.createElement('a')
    ..classes.add('hrefbtn')
    ..innerText = 'ссылка на таблицу';

  void webInit() {
    pStateName.innerText = '($uID)' + ssTaskName;
    pStateText.innerText = '...';
    pStateOutPath.innerText = ssPathOut;
    for (final item in pathInList) {
      pStateInList.add(document.createElement('p')
        ..classes.add('in')
        ..innerText = item);
    }
    pStateLastMsg.innerText = lastWsMsg;
    pStateAnchorToTask.innerText = 'ссылка на задачу';
    pStateAnchorToTask.href = '$wwwPathToTasks$uID';

    pStateBlock.append(pStateName);
    pStateBlock.append(pStateAnchorToTask);
    pStateBlock.append(pStateText);
    pStateBlock.append(pStateOutPath);
    for (final item in pStateInList) {
      pStateBlock.append(item);
    }
    pStateBlock.append(pStateLastMsg);
  }

  @override
  set pathToTable(final String path) {
    super.pathToTable = path;
    pStateAnchorToXls.href = path;
    pStateBlock.insertBefore(pStateAnchorToXls, pStateText);
  }

  @override
  set lastWsMsg(final String txt) {
    super.lastWsMsg = txt;
    pStateLastMsg.innerText = lastWsMsg;
  }

  @override
  set iState(KncTaskState state) {
    super.iState = state;
    switch (iState) {
      case KncTaskState.initializing:
        pStateText
          ..innerText = 'Инициализация...'
          ..classes.clear()
          ..classes.addAll(['state', 'init']);
        break;
      case KncTaskState.work:
        pStateText
          ..innerText = 'Обработка файлов...'
          ..classes.clear()
          ..classes.addAll(['state', 'work']);
        break;
      case KncTaskState.savesDatas:
        pStateText
          ..innerText = 'Сохранение данных...'
          ..classes.clear()
          ..classes.addAll(['state', 'save']);
        break;
      case KncTaskState.generateTable:
        pStateText
          ..innerText = 'Генерация таблицы...'
          ..classes.clear()
          ..classes.addAll(['state', 'genxls']);
        break;
      case KncTaskState.end:
        pStateText
          ..innerText = 'Работа завершена...'
          ..classes.clear()
          ..classes.addAll(['state', 'end']);
        break;
      default:
    }
  }
}

class MyWeb {
  /// Web Socket для связи с сервером в реальном времени
  final ws = WebSocket('ws://${document.domain}${wwwPathToWs}');

  /// Параграф показывающий текст состояния ВебСокета
  final pStatusSocket = document.getElementById('statusSocket');

  /// Секция показывающая состояние сервера
  final pStatusServer = document.getElementById('statusServer');

  /// Список выполянемых задач сервера
  final ss = <KncSettingsStateWeb>[];

  /// устанавливает [handleWs] - обработчик сообщений от сокета,
  /// если он не установлен, обрабатывает сообщения по умолчанию,
  /// если он вернёт `true` то сообщение считается обработаным
  ///
  /// - `#statusSocket` - Обновляется состоянием сокета
  /// - `#statusServer` - Обновляется состоянием сервера
  MyWeb.wsInit([Future<bool> Function(String msg) handleWs]) {
    ws
      ..onOpen.listen((event) {
        pStatusSocket.text = 'Сокет открыт';
        pStatusSocket.classes.clear();
        pStatusSocket.classes.add('opend');
        ws.send('^${document.baseUri}');
      })
      ..onClose.listen((event) {
        pStatusSocket.text = 'Сокет закрыт';
        pStatusSocket.classes.clear();
        pStatusSocket.classes.add('closed');
      })
      ..onMessage.listen((event) async {
        if (event.data is String) {
          final String txt = event.data;
          print(txt);
          if (handleWs != null) {
            if ((await handleWs(txt)) == true) {
              return;
            }
          }
          if (txt.startsWith(wwwKncTaskAdd)) {
            final s = KncSettingsStateWeb();
            s.json = txt.substring(wwwKncTaskAdd.length);
            ss.add(s);
            s.webInit();
            pStatusServer.append(s.pStateBlock);
          } else if (txt.startsWith(wwwKncTaskLastMsg)) {
            final i0 = txt.indexOf(':', wwwKncTaskLastMsg.length);
            final uID =
                int.tryParse(txt.substring(wwwKncTaskLastMsg.length, i0));
            final task = ss.singleWhere((e) => e.uID == uID);
            task.lastWsMsg = txt.substring(i0 + 1);
          } else if (txt.startsWith(wwwKncTaskUpdateState)) {
            final i0 = txt.indexOf(':', wwwKncTaskUpdateState.length);
            final uID =
                int.tryParse(txt.substring(wwwKncTaskUpdateState.length, i0));
            final task = ss.singleWhere((e) => e.uID == uID);
            task.iState =
                KncTaskState.values[int.tryParse(txt.substring(i0 + 1))];
          } else if (txt.startsWith(wwwKncTaskUpdateXlsTable)) {
            final i0 = txt.indexOf(':', wwwKncTaskUpdateXlsTable.length);
            final uID = int.tryParse(
                txt.substring(wwwKncTaskUpdateXlsTable.length, i0));
            final task = ss.singleWhere((e) => e.uID == uID);
            task.pathToTable = txt.substring(i0 + 1);
          }
        }
      });
  }
}
