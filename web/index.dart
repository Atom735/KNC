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

  void webInit() {
    pStateName.innerText = '($uID)' + ssTaskName;
    pStateText.innerText = 'В процессе';
    pStateOutPath.innerText = ssPathOut;
    for (final item in pathInList) {
      pStateInList.add(document.createElement('p')
        ..classes.add('in')
        ..innerText = item);
    }
    pStateLastMsg.innerText = lastWsMsg;

    pStateBlock.append(pStateName);
    pStateBlock.append(pStateText);
    pStateBlock.append(pStateOutPath);
    for (final item in pStateInList) {
      pStateBlock.append(item);
    }
    pStateBlock.append(pStateLastMsg);
  }

  @override
  set lastWsMsg(final String txt) {
    super.lastWsMsg = txt;
    pStateLastMsg.innerText = lastWsMsg;
  }
}

void main(List<String> args) {
  /// Web Socket для связи с сервером в реальном времени
  final ws = WebSocket('ws://${document.domain}${wwwPathToWs}');

  /// Параграф показывающий текст состояния ВебСокета
  final pStatusSocket = document.getElementById('statusSocket');

  /// Секция показывающая состояние сервера
  final pStatusServer = document.getElementById('statusServer');

  final ss = <KncSettingsStateWeb>[];

  ws
    ..onOpen.listen((event) {
      pStatusSocket.text = 'Сокет открыт';
      pStatusSocket.classes.clear();
      pStatusSocket.classes.add('opend');
    })
    ..onClose.listen((event) {
      pStatusSocket.text = 'Сокет закрыт';
      pStatusSocket.classes.clear();
      pStatusSocket.classes.add('closed');
    })
    ..onMessage.listen((event) {
      if (event.data is String) {
        final String txt = event.data;
        if (txt.startsWith(wwwKncTaskAdd)) {
          final s = KncSettingsStateWeb();
          s.json = txt.substring(wwwKncTaskAdd.length);
          ss.add(s);
          s.webInit();
          pStatusServer.append(s.pStateBlock);
        } else if (txt[0] == '^') {
          final i0 = txt.indexOf('#');
          final uID = int.tryParse(txt.substring(1, i0));
          final task = ss.singleWhere((e) => e.uID == uID);
          task.lastWsMsg = txt.substring(i0);
        }
      }
      print(event);
    });
}
