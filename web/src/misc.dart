import 'dart:html';

import 'package:knc/knc.dart';

import 'App.dart';

final htmlValidator = NodeValidatorBuilder.common()
  ..allowElement('button', attributes: ['data-badge']);

final uri = Uri.parse(document.baseUri);
List<String> uriPaths = uri.pathSegments;

Element eGetById(final String id) => document.getElementById(id);

NodeValidator nodeValidator = NodeValidatorBuilder.common()
  ..allowHtml5()
  ..allowElement('button', attributes: ['data-mdc-dialog-action'])
  ..allowElement('input', attributes: ['minlength'])
  ..allowElement('header', attributes: ['style'])
  ..allowElement('div', attributes: ['tabindex'])
  ..allowElement('main');

Future<SocketWrapperResponse> waitMsg(String msgBegin) =>
    App().waitMsg(msgBegin);
Stream<SocketWrapperResponse> waitMsgAll(String msgBegin) =>
    App().waitMsgAll(msgBegin);
Future<String> requestOnce(String msg) => App().requestOnce(msg);
Stream<String> requestSubscribe(String msg) => App().requestSubscribe(msg);
