import 'dart:html';

main(List<String> args) {
  final webSocket = WebSocket('ws://localhost:4040/ws');
  final pSockState = document.createElement('p');
  document.body.append(pSockState);
  final pSockLastMessage = document.createElement('p');
  document.body.append(pSockLastMessage);
  var iSockLastMessge = 0;

  webSocket.onOpen.listen((event) {
    pSockState.text = 'Socket opend';
  });
  webSocket.onMessage.listen((event) {
    iSockLastMessge += 1;
    switch (event.type) {
      default:
        pSockLastMessage.text = '$iSockLastMessge:${event.type}\n${event.data}';
    }
  });
  webSocket.onClose.listen((event) {
    pSockState.text = 'Socket closed';
  });
}
