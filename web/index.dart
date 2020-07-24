import 'dart:html';

import 'package:knc/www.dart';

void main(List<String> args) {
  /// Web Socket для связи с сервером в реальном времени
  final ws = WebSocket('ws://${document.domain}/ws');

  /// Параграф показывающий текст состояния ВебСокета
  final pStatusSocket = document.getElementById('statusSocket');

  /// Секция показывающая состояние сервера
  final pStatusServer = document.getElementById('statusServer');

  final ss = <KncSettingsInternal>[];

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
        if (txt.startsWith('#SS.ADD:')) {
          final s = KncSettingsInternal();
          s.json = txt.substring(8);
          ss.add(s);
          final pTaskBlock = document.createElement('details');
          pTaskBlock.innerHtml = '''
            <summary>${s.ssTaskName}</summary>
            <p class="state">В процессе</p>
            <p class="out">${s.ssPathOut}</p>
          ''';
          for (var item in s.pathInList) {
            pTaskBlock.appendHtml('<p class="in">${item}</p>');
          }
          pStatusServer.append(pTaskBlock);
        }
      }
      print(event);
    });
}
