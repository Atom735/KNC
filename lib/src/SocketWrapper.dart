import 'dart:async';

const msgRecordSeparator = '\u001E';
const msgStreamClose = '\u0018';

const msgIdBegin = '\u0001';
const msgIdEnd = '\u0002';

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
  Future /*?*/ signal;

  int _requestID = 0;
  final _listOfRequest = <int, Completer<String>>{};

  final _listOfResponses = <String, Completer<SocketWrapperResponse>>{};
  final _listOfRespSubers = <String, StreamController<SocketWrapperResponse>>{};

  SocketWrapper(this.sender, {this.signal}) {
    signal?.then((_) => signal = null);
  }

  /// Функция отправки сообщений с уникальным айди
  void send(final int id, final String msg) =>
      signal?.then((_) => sender('$msgIdBegin$id$msgIdEnd$msg')) ??
      sender('$msgIdBegin$id$msgIdEnd$msg');

  /// Возвращает `false` если на сообщение не вызвано реакции
  bool recv(final String msgRaw, [final int id = 0]) {
    var b = false;

    /// Если сообщение содержит идетнификатор, то разбираем его
    if (msgRaw.startsWith(msgIdBegin)) {
      final i0 = msgRaw.indexOf(msgIdEnd, msgIdBegin.length);
      if (i0 != -1) {
        final idStr = msgRaw.substring(msgIdBegin.length, i0);
        final id = int.tryParse(idStr) ?? 0;
        final msg = msgRaw.substring(i0 + msgIdEnd.length);
        b |= _listOfRequest[id] != null;
        _listOfRequest[id]?.complete(msg);

        if (!b) {
          /// Если сообщение не обработанно, то значит это не ответ на запрос
          /// а уведомитенльное, или сообщение команды...
          return recv(msg, id);
        } else {
          recv(msg, id);
          return true;
        }
      } else {
        throw Exception('Сообщение без идентификатора:\n$msgRaw');
      }
    } else {
      _listOfResponses.forEach((key, value) {
        if (msgRaw.startsWith(key)) {
          value.complete(
              SocketWrapperResponse(msgRaw.substring(key.length), id));
          b = true;
        }
      });
      _listOfRespSubers.forEach((key, value) {
        if (msgRaw.startsWith(key)) {
          value.add(SocketWrapperResponse(msgRaw.substring(key.length), id));
          b = true;
        }
      });
    }
    return b;
  }

  /// Подписаться на получение единождого ответа
  ///
  /// Например ждём запрос `^{id}$LoginAPI:login:pass`
  ///
  /// В ответ отправим `^{id}${someText}`
  ///
  /// Ну или серию ответов.
  Future<SocketWrapperResponse> waitMsg(final String msgBegin,
      [final bool sync = false]) {
    final c = sync
        ? Completer<SocketWrapperResponse>.sync()
        : Completer<SocketWrapperResponse>();

    _listOfResponses[msgBegin] = c;
    c.future.then((_) => _listOfResponses.remove(msgBegin));
    return c.future;
  }

  /// Подписаться на получение всех ответов
  ///
  /// Тоже самое как [waitMsg], но ждём без остановки
  Stream<SocketWrapperResponse> waitMsgAll(final String msgBegin,
      [final bool sync = false]) {
    final c = StreamController<SocketWrapperResponse>(
        onCancel: () => _listOfRespSubers.remove(msgBegin), sync: sync);
    _listOfRespSubers[msgBegin] = c;
    return c.stream;
  }

  /// Отправить запрос и получить на него единождый ответ
  ///
  /// Например отправляем запрос `^123$LoginAPI:login:pass`
  ///
  /// В ответ получим `^123${someText}`
  Future<String> requestOnce(final String msg, [final bool sync = false]) {
    _requestID += 1;
    final id = _requestID;
    final c = sync ? Completer<String>.sync() : Completer<String>();
    _listOfRequest[id] = c;
    c.future.then((_) => _listOfRequest.remove(id));
    send(id, msg);
    return c.future;
  }
}
