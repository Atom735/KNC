@JS()
library mydart_ws;

import 'dart:html';

import 'package:js/js.dart';

import 'index.dart';

@JS()
class JsSocketWrapper {
  WebSocket ws;
  SocketWrapper sw;

  static JsSocketWrapper create(
      String token, void Function(JsSocketWrapper) callback) {
    final o = JsSocketWrapper();
    o.ws = WebSocket('ws://${document.domain}/ws/$token');
    o.ws.onOpen.first.then((value) => callback(o));
    o.sw = SocketWrapper((String msg) => o.ws.sendString(msg),
        signal: o.ws.onOpen.first);

    o.send = allowInteropCaptureThis(
        (JsSocketWrapper _, String msg, int id) => _.sw.send(id, msg));
    o.recv = allowInteropCaptureThis(
        (JsSocketWrapper _, String msg, [int id]) => _.sw.recv(msg, id ?? 0));
    o.waitMsg = allowInteropCaptureThis(
        (JsSocketWrapper _, String msg, void Function(String, int) callback,
            [bool _sync]) {
      _.sw
          .waitMsg(msg, _sync ?? false)
          .then((value) => callback?.call(value.s, value.i));
    });

    o.waitMsgAll = allowInteropCaptureThis(
        (JsSocketWrapper _, String msg, void Function(String, int) callback,
            [bool _sync]) {
      final ss = _.sw
          .waitMsgAll(msg, _sync ?? false)
          .listen((value) => callback?.call(value.s, value.i));
      return () {
        ss.cancel();
      };
    });
    o.requestOnce = allowInteropCaptureThis(
        (JsSocketWrapper _, String msg, void Function(String) callback,
            [bool _sync]) {
      _.sw
          .requestOnce(msg, _sync ?? false)
          .then((value) => callback?.call(value));
    });
    return o;
  }

  external set send(void Function(JsSocketWrapper, String, int) f);
  external set recv(bool Function(JsSocketWrapper, String, [int]) f);
  external set waitMsg(
      void Function(JsSocketWrapper, String, [void Function(String, int), bool])
          f);
  external set waitMsgAll(
      void Function() Function(JsSocketWrapper, String,
              [void Function(String, int), bool])
          f);
  external set requestOnce(
      void Function(JsSocketWrapper, String, [void Function(String), bool]) f);
}

@JS('JsSocketWrapper')
external set _JsSocketWrapper(JsSocketWrapper Function(String, Function) f);

void main() {
  _JsSocketWrapper =
      allowInterop((String s, Function f) => JsSocketWrapper.create(s, f));
}
