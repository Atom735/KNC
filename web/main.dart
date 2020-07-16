import 'dart:html';

main(List<String> args) {
  final webSocket = WebSocket('ws://localhost:4040/ws');
  final pSockState = document.createElement('p');
  document.body.append(pSockState);
  final pSockLastMessage = document.createElement('p');
  document.body.append(pSockLastMessage);
  var iSockLastMessge = 0;
  final sectionErrors = document.getElementById('errors');
  final sectionInfo = document.getElementById('info');
  ButtonElement btnStop = document.getElementById('btnStop');

  Element lastErrorSection;
  Element lastInfoSection;

  // <details>
  //  <summary>Внимание, спойлер!</summary>
  //  <p>Убийца — дворецкий!</p>
  // </details>

  webSocket.onOpen.listen((event) {
    pSockState.text = 'Socket opend';
    btnStop.onClick.listen((event) {
      webSocket.sendString('#STOP!');
    });
  });
  webSocket.onMessage.listen((msg) {
    iSockLastMessge += 1;
    final data = msg.data;
    if (data is String) {
      if (data == '#DONE!') {
        btnStop.innerText = 'Работа закончена, нажмите чтобы закрыть программу';
      } else if (data.startsWith('#LAS:')) {
        if (data.startsWith('#LAS:+')) {
          lastInfoSection = document.createElement('details');
          final summary = document.createElement('summary');
          summary.innerText = data.substring(5);
          lastInfoSection.append(summary);
        } else if (data.startsWith('#LAS:\t')) {
          final p = document.createElement('p');
          p.innerText = data.substring(6);
          lastInfoSection.append(p);
        } else if (data.startsWith('#LAS:==========') &&
            lastInfoSection != null) {
          sectionInfo.append(lastInfoSection);
          lastInfoSection = null;
        } else {
          final p = document.createElement('p');
          p.innerText = data.substring(5);
          sectionInfo.append(p);
        }
      } else if (data.startsWith('#ERROR:')) {
        if (data.startsWith('#ERROR:+')) {
          lastErrorSection = document.createElement('details');
          final summary = document.createElement('summary');
          summary.innerText = data.substring(7);
          lastErrorSection.append(summary);
        } else if (data.startsWith('#ERROR:\t')) {
          final p = document.createElement('p');
          p.innerText = data.substring(8);
          lastErrorSection.append(p);
        } else if (data.startsWith('#ERROR:==========') &&
            lastErrorSection != null) {
          sectionErrors.append(lastErrorSection);
          lastErrorSection = null;
        } else {
          final p = document.createElement('p');
          p.innerText = data.substring(7);
          sectionErrors.append(p);
        }
      }
    }

    switch (msg.type) {
      default:
        pSockLastMessage.text = '$iSockLastMessge:${msg.type}\n${msg.data}';
    }
  });
  webSocket.onClose.listen((event) {
    pSockState.text = 'Socket closed';
  });
}
