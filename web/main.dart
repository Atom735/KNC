import 'dart:html';

main(List<String> args) {
  final webSocket = WebSocket('ws://localhost:4040/ws');
  webSocket.onOpen.listen((event) {
    window.alert('onOpen: ' + event.toString());
  });
  webSocket.onMessage.listen((event) {
    window.alert('onMessage: ' + event.toString());
  });
  webSocket.onClose.listen((event) {
    window.alert('onClose: ' + event.toString());
  });
}
