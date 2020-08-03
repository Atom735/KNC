import 'dart:async';

/// Оболочка для взаимодействия передочи потоковых данных
///
/// * [send] - функция отправки сообщения - должна быть задана
/// * [recv] - функция вызываемаемая при получении сообщения
class SocketWrapper {
  final void Function(String msgRaw) send;
  final String streamCloseMsg;
  final String msgIdBegin;
  final String msgIdEnd;

  int _requestID = 0;
  final _listOfRequest = <int, Completer<String>>{};
  int _subscribersID = 0;
  final _listOfSubscribers = <int, StreamController<String>>{};

  final _listOfResponses = <String, Completer<String>>{};
  final _listOfRespSubers = <String, StreamController<String>>{};

  SocketWrapper(this.send,
      {this.streamCloseMsg = 'streamclose',
      this.msgIdBegin = '\u{1}',
      this.msgIdEnd = '\u{2}'});

  void recv(final String msgRaw) {
    if (msgRaw[0] == msgIdBegin) {
      final i0 = msgRaw.indexOf(msgIdEnd);
      if (i0 != -1) {
        final id = int.tryParse(msgRaw.substring(0, i0));
        final msg = msgRaw.substring(i0 + msgIdEnd.length);
        if (_listOfRequest[id] != null) {
          _listOfRequest[id].complete(msg);
        }
        if (_listOfSubscribers[id] != null) {
          _listOfSubscribers[id].add(msg);
        }
        return recv(msg);
      }
    }
    _listOfResponses.forEach((key, value) {
      if (msgRaw.startsWith(key)) {
        value.complete(msgRaw.substring(key.length));
      }
    });
    _listOfRespSubers.forEach((key, value) {
      if (msgRaw.startsWith(key)) {
        value.add(msgRaw.substring(key.length));
      }
    });
  }

  /// Подписаться на получение единождого ответа
  Future<String> waitMsg(final String msgBegin) {
    final c = Completer<String>();
    _listOfResponses[msgBegin] = c;
    c.future.then((_) => _listOfResponses.remove(msgBegin));
    return c.future;
  }

  /// Подписаться на получение всех ответов
  Stream<String> waitMsgAll(final String msgBegin) {
    final c = StreamController<String>(
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
    send('$msgIdBegin$id$msgIdEnd$msg');
    return c.future;
  }

  /// Отправить запрос на подписку к событиям
  Stream<String> requestSubscribe(final String msg) {
    _subscribersID += 1;
    final id = _subscribersID;
    final c = StreamController<String>(onCancel: () {
      _listOfSubscribers.remove(id);
      send('$msgIdBegin$id$msgIdEnd$streamCloseMsg');
    });
    _listOfSubscribers[id] = c;
    send('$msgIdBegin$id$msgIdEnd$msg');
    return c.stream;
  }
}
