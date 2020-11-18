@JS()
library mydart_ws;

import 'dart:html';

import 'package:js/js.dart';

import 'index.dart';

class JsSocketWrapper extends SocketWrapper {
  final WebSocket ws;

  JsSocketWrapper(this.ws, void Function(String msgRaw) sender, Future signal)
      : super(sender, signal: signal);

  static JsSocketWrapper constructor(String token, Function callbackOnOpen) {
    final ws = WebSocket('ws://${document.domain}/ws/$token');
    final o = JsSocketWrapper(ws, (msgRaw) => ws.send(msgRaw),
        ws.onOpen.first.then((value) => callbackOnOpen()));
    ws.onMessage.listen((event) {
      o.recv(event.data);
    });
    return o;
  }

  static void addCallbackOpen(JsSocketWrapper _, Function f) {
    if (_.signal != null) {
      _.signal.then((value) => f);
    } else {
      f();
    }
  }

  // void _connect(String token) {
  //   if (ws != null) {
  //     _disconnect();
  //   }

  //   ws = WebSocket('ws://${document.domain}/ws/$token');
  //   final signal = ws.onOpen.first;
  //   _sw = SocketWrapper((msgRaw) => ws.send(msgRaw), signal: signal);
  //   signal.then((_) => onOpen != null ? onOpen() : null);
  // }

  // void _disconnect() {
  //   if (ws != null) {
  //     ws.close();
  //     ws = null;
  //     _sw = null;
  //   }
  // }
}

@JS('JsSocketWrapper')
external set _JsSocketWrapper(JsSocketWrapper Function(String, Function) f);
@JS('JsSocketWrapperAddOnOpenCallback')
external set _JsSocketWrapperAddCallbackOpen(
    void Function(JsSocketWrapper, Function) f);
@JS('JsSocketWrapperSend')
external set _JsSocketWrapperSend(
    void Function(JsSocketWrapper, int, String) f);
@JS('JsSocketWrapperRecv')
external set _JsSocketWrapperRecv(
    bool Function(JsSocketWrapper, String, int) f);
@JS('JsSocketWrapperWaitMsg')
external set _JsSocketWrapperWaitMsg(
    void Function(JsSocketWrapper, String, bool, Function) f);
@JS('JsSocketWrapperWaitMsgAll')
external set _JsSocketWrapperWaitMsgAll(
    Function Function(JsSocketWrapper, String, bool, Function) f);
@JS('JsSocketWrapperRequestOnce')
external set _JsSocketWrapperRequestOnce(
    void Function(JsSocketWrapper, String, bool, Function) f);

void main() {
  _JsSocketWrapper = allowInterop(JsSocketWrapper.constructor);
  _JsSocketWrapperAddCallbackOpen =
      allowInterop((JsSocketWrapper _, Function func) {
    if (_.signal != null) {
      _.signal.then((value) => func);
    } else {
      func();
    }
  });
  _JsSocketWrapperSend =
      allowInterop((JsSocketWrapper _, int id, String msg) => _.send(id, msg));
  _JsSocketWrapperRecv =
      allowInterop((JsSocketWrapper _, String msg, int id) => _.recv(msg, id));
  _JsSocketWrapperWaitMsg = allowInterop(
      (JsSocketWrapper _, String msg, bool sync, Function callback) {
    _.waitMsg(msg, sync).then((value) => callback(value.i, value.s));
  });
  _JsSocketWrapperWaitMsgAll = allowInterop(
      (JsSocketWrapper _, String msg, bool sync, Function callback) {
    // final stream = ;
    final ss = _.waitMsgAll(msg, sync).listen((event) {
      callback(event.i, event.s);
    });
    return () => ss.cancel();
  });
  _JsSocketWrapperRequestOnce = allowInterop(
      (JsSocketWrapper _, String msg, bool sync, Function callback) {
    _.requestOnce(msg, sync).then((value) => callback(value));
  });
  // _connect = allowInterop(connect);
  // _disconnect = allowInterop(disconnect);
}
