import 'dart:html';

void main(List<String> args) {
  /// Web Socket для связи с сервером в реальном времени
  final ws = WebSocket('ws://${document.domain}/ws');

  /// Параграф показывающий текст состояния ВебСокета
  final pStatusSocket = document.getElementById('statusSocket');

  /// Секция показывающая состояние сервера
  final pStatusServer = document.getElementById('statusServer');

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
    ..onMessage.listen((event) {});
}
