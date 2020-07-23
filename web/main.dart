import 'dart:html';

void main(List<String> args) {
  final webSocket = WebSocket('ws://localhost:4040/ws');
  final pSockState = document.createElement('p');
  document.body.append(pSockState);
  final pSockLastMessage = document.createElement('p');
  document.body.append(pSockLastMessage);
  var iSockLastMessge = 0;
  final sectionErrors = document.getElementById('errors');
  final sectionInfo = document.getElementById('info');
  final ButtonElement btnStop = document.getElementById('btnStop');
  final pStatus = document.getElementById('status');

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
      if (data == '#PREPARE_TABLE!') {
        pStatus.innerText = 'Работа почти закончена, мы генерируем таблицу';
        pStatus.classes.add('prepareForTable');
      } else if (data.startsWith('#DONE:')) {
        final datatxt = data.substring(6);
        pStatus.innerHtml =
            'Работа закончена, таблицу можно загрузить по <a href="$datatxt">ссылке</a>';
        pStatus.classes.remove('prepareForTable');
        pStatus.classes.add('withLink');
      } else if (data.startsWith('#LAS:')) {
        final datatxt = data.substring(5);
        if (datatxt.startsWith('+')) {
          lastInfoSection = document.createElement('details');
          lastInfoSection.classes.add('las');
          final summary = document.createElement('summary');
          summary.innerText = datatxt.substring(1);
          lastInfoSection.append(summary);
        } else if (datatxt.startsWith('\t')) {
          final p = document.createElement('p');
          p.innerText = datatxt.substring(1);
          lastInfoSection.append(p);
        } else if (datatxt.startsWith('==========') &&
            lastInfoSection != null) {
          sectionInfo.append(lastInfoSection);
          lastInfoSection = null;
        } else {
          final p = document.createElement('p');
          p.innerText = datatxt;
          sectionInfo.append(p);
        }
      } else if (data.startsWith('#INK:')) {
        final datatxt = data.substring(5);
        if (datatxt.startsWith('+')) {
          lastInfoSection = document.createElement('details');
          lastInfoSection.classes.add('ink');
          final summary = document.createElement('summary');
          summary.innerText = datatxt.substring(1);
          lastInfoSection.append(summary);
        } else if (datatxt.startsWith('\t')) {
          final p = document.createElement('p');
          p.innerText = datatxt.substring(1);
          lastInfoSection.append(p);
        } else if (datatxt.startsWith('==========') &&
            lastInfoSection != null) {
          sectionInfo.append(lastInfoSection);
          lastInfoSection = null;
        } else {
          final p = document.createElement('p');
          p.innerText = datatxt;
          sectionInfo.append(p);
        }
      } else if (data.startsWith('#ERROR:')) {
        final datatxt = data.substring(7);
        if (datatxt.startsWith('+')) {
          lastErrorSection = document.createElement('details');
          lastErrorSection.classes.add('error');
          final summary = document.createElement('summary');
          summary.innerText = datatxt.substring(1);
          lastErrorSection.append(summary);
        } else if (datatxt.startsWith('\t')) {
          final p = document.createElement('p');
          p.innerText = datatxt.substring(1);
          lastErrorSection.append(p);
        } else if (datatxt.startsWith('==========') &&
            lastErrorSection != null) {
          sectionErrors.append(lastErrorSection);
          lastErrorSection = null;
        } else {
          final p = document.createElement('p');
          p.innerText = datatxt;
          sectionErrors.append(p);
        }
      } else if (data.startsWith('#EXCEPTION:')) {
        final datatxt = data.substring(11);
        final p = document.createElement('p');
        p.classes.add('exception');
        p.innerText = datatxt;
        sectionErrors.append(p);
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
