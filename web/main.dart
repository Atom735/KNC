import 'dart:html';
import 'package:knc/www.dart';

import 'ws.dart';

void main(List<String> args) {
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

  final w = MyWeb.wsInit(((msg) async {
    iSockLastMessge += 1;
    pSockLastMessage.text = '$iSockLastMessge:${msg}';
    if (msg == '#PREPARE_TABLE!') {
      pStatus.innerText = 'Работа почти закончена, мы генерируем таблицу';
      pStatus.classes.add('prepareForTable');
      return true;
    } else if (msg.startsWith('#DONE:')) {
      final datatxt = msg.substring(6);
      pStatus.innerHtml =
          'Работа закончена, таблицу можно загрузить по <a href="$datatxt">ссылке</a>';
      pStatus.classes.remove('prepareForTable');
      pStatus.classes.add('withLink');
      return true;
    } else if (msg.startsWith(wwwMsgLasBegin)) {
      lastInfoSection = document.createElement('details');
      lastInfoSection.classes.add('las');
      final summary = document.createElement('summary');
      summary.innerText = msg.substring(wwwMsgLasBegin.length);
      lastInfoSection.append(summary);
      return true;
    } else if (msg.startsWith(wwwMsgLas)) {
      final p = document.createElement('p');
      p.innerText = msg.substring(wwwMsgLas.length);
      lastInfoSection.append(p);
      return true;
    } else if (msg == wwwMsgLasEnd && lastInfoSection != null) {
      sectionInfo.append(lastInfoSection);
      lastInfoSection = null;
      return true;
    } else if (msg.startsWith(wwwMsgInkBegin)) {
      lastInfoSection = document.createElement('details');
      lastInfoSection.classes.add('ink');
      final summary = document.createElement('summary');
      summary.innerText = msg.substring(wwwMsgInkBegin.length);
      lastInfoSection.append(summary);
      return true;
    } else if (msg.startsWith(wwwMsgInk)) {
      final p = document.createElement('p');
      p.innerText = msg.substring(wwwMsgInk.length);
      lastInfoSection.append(p);
      return true;
    } else if (msg == wwwMsgInkEnd && lastInfoSection != null) {
      sectionInfo.append(lastInfoSection);
      lastInfoSection = null;
      return true;
    } else if (msg.startsWith(wwwMsgError)) {
      final datatxt = msg.substring(wwwMsgError.length);
      if (datatxt.startsWith('+')) {
        lastErrorSection = document.createElement('details');
        lastErrorSection.classes.add('error');
        final summary = document.createElement('summary');
        summary.innerText = datatxt.substring(1);
        lastErrorSection.append(summary);
        return true;
      } else if (datatxt.startsWith('\t')) {
        final p = document.createElement('p');
        p.innerText = datatxt.substring(1);
        lastErrorSection.append(p);
        return true;
      } else if (datatxt.startsWith('==========') && lastErrorSection != null) {
        sectionErrors.append(lastErrorSection);
        lastErrorSection = null;
        return true;
      } else {
        final p = document.createElement('p');
        p.innerText = datatxt;
        sectionErrors.append(p);
        return true;
      }
    } else if (msg.startsWith(wwwMsgException)) {
      final datatxt = msg.substring(wwwMsgException.length);
      final p = document.createElement('p');
      p.classes.add('exception');
      p.innerText = datatxt;
      sectionErrors.append(p);
      return true;
    }
    return false;
  }));

  btnStop.onClick.listen((event) {
    w.ws.sendString('#STOP!');
  });
}
