import 'dart:html';

import 'package:knc/knc.dart';

import 'App.dart';

final htmlValidator = NodeValidatorBuilder.common()
  ..allowElement('button', attributes: ['data-badge']);

final uri = Uri.tryParse(document.baseUri);

Element eGetById(final String id) => document.getElementById(id);

NodeValidator nodeValidator = NodeValidatorBuilder.common()
  ..allowElement('button', attributes: ['action'])
  ..allowElement('input', attributes: ['minlength']);

Future<SocketWrapperResponse> waitMsg(String msgBegin) =>
    App().waitMsg(msgBegin);
Stream<SocketWrapperResponse> waitMsgAll(String msgBegin) =>
    App().waitMsgAll(msgBegin);
Future<String> requestOnce(String msg) => App().requestOnce(msg);
Stream<String> requestSubscribe(String msg) => App().requestSubscribe(msg);
