import 'dart:async';

class SocketWrapperResponse {
  final String s;
  final int i;
  SocketWrapperResponse(this.s, this.i);
}

/// Оболочка для взаимодействия передочи потоковых данных
///
/// * [sender] - функция отправки сообщения - должна быть задана
/// * [recv] - функция вызываемаемая при получении сообщения
class SocketWrapper {
  final void Function(String msgRaw) sender;
  final String streamCloseMsg;
  final String msgIdBegin;
  final String msgIdEnd;
  Future signal;

  int _requestID = 0;
  final _listOfRequest = <int, Completer<String>>{};
  int _subscribersID = 0;
  final _listOfSubscribers = <int, StreamController<String>>{};

  final _listOfResponses = <String, Completer<SocketWrapperResponse>>{};
  final _listOfRespSubers = <String, StreamController<SocketWrapperResponse>>{};

  SocketWrapper(this.sender,
      {this.streamCloseMsg = 'streamclose',
      this.msgIdBegin = '\u{1}',
      this.msgIdEnd = '\u{2}',
      this.signal}) {
    if (signal != null) {
      signal.then((_) => signal = null);
    }
  }

  /// Функция отправки сообщений с уникальным айди
  void send(final int id, final String msg) => signal == null
      ? sender('$msgIdBegin$id$msgIdEnd$msg')
      : signal.then((_) => sender('$msgIdBegin$id$msgIdEnd$msg'));

  void recv(final String msgRaw, [final int id]) {
    if (msgRaw.startsWith(msgIdBegin)) {
      final i0 = msgRaw.indexOf(msgIdEnd, msgIdBegin.length);
      if (i0 != -1) {
        final id = int.tryParse(msgRaw.substring(msgIdBegin.length, i0));
        final msg = msgRaw.substring(i0 + msgIdEnd.length);
        if (_listOfRequest[id] != null) {
          _listOfRequest[id].complete(msg);
        }
        if (_listOfSubscribers[id] != null) {
          _listOfSubscribers[id].add(msg);
        }
        return recv(msg, id);
      }
    }
    _listOfResponses.forEach((key, value) {
      if (msgRaw.startsWith(key)) {
        value.complete(SocketWrapperResponse(msgRaw.substring(key.length), id));
      }
    });
    _listOfRespSubers.forEach((key, value) {
      if (msgRaw.startsWith(key)) {
        value.add(SocketWrapperResponse(msgRaw.substring(key.length), id));
      }
    });
  }

  /// Подписаться на получение единождого ответа
  Future<SocketWrapperResponse> waitMsg(final String msgBegin) {
    final c = Completer<SocketWrapperResponse>();
    _listOfResponses[msgBegin] = c;
    c.future.then((_) => _listOfResponses.remove(msgBegin));
    return c.future;
  }

  /// Подписаться на получение всех ответов
  Stream<SocketWrapperResponse> waitMsgAll(final String msgBegin) {
    final c = StreamController<SocketWrapperResponse>(
        onCancel: () => _listOfRespSubers.remove(msgBegin));
    _listOfRespSubers[msgBegin] = c;
    return c.stream;
  }

  /// Отправить запрос и получить на него ответ
  Future<String> requestOnce(final String msg) {
    _requestID += 1;
    final id = _requestID;
    final c = Completer<String>();
    _listOfRequest[id] = c;
    c.future.then((_) => _listOfRequest.remove(id));
    send(id, msg);
    return c.future;
  }

  /// Отправить запрос на подписку к событиям
  Stream<String> requestSubscribe(final String msg) {
    _subscribersID += 1;
    final id = _subscribersID;
    final c = StreamController<String>(onCancel: () {
      _listOfSubscribers.remove(id);
      send(id, streamCloseMsg);
    });
    _listOfSubscribers[id] = c;
    send(id, msg);
    return c.stream;
  }
}
