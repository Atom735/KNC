import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:knc/errors.dart';
import 'package:knc/SocketWrapper.dart';
import 'package:knc/www.dart';

import 'App2.dart';
import 'User.dart';

class Client {
  /// Сокет для связи с клиентом
  final WebSocket socket;

  /// Оболчка для обработки запросов
  final SocketWrapper wrapper;

  /// Пользователь подключённого клиента
  User user;

  /// Создание нового клиента с указанным сокетом и
  /// пользователем, если он был задан
  Client(this.socket, [this.user = User.guest])
      : wrapper = SocketWrapper((msg) => socket.add(msg)) {
    print(
        '$runtimeType($hashCode)[$user].WebSocket(${socket.hashCode}) создан');

    socket.listen(
        (event) {
          if (event is String) {
            print('$runtimeType($hashCode)[$user]: recv => $event');
            wrapper.recv(event);
          }
        },
        onError: getErrorFunc(
            'Ошибка в прослушке $runtimeType($hashCode)[$user].WebSocket(${socket.hashCode}):'),
        onDone: () {
          App().clients.remove(this);
          print(
              '$runtimeType($hashCode)[$user].WebSocket(${socket.hashCode}) уничтожен');
        });
    waitMsgAll(wwwTaskViewUpdate).listen((msg) {
      wrapper.send(
          msg.i,
          App().getWwwTaskViewUpdate(
              user,
              (jsonDecode(msg.s) as List)
                  .map((e) => e as int)
                  .toList(growable: false)));
    });
    waitMsgAll(wwwTaskNew).listen((msg) {
      App().getWwwTaskNew(msg.s, user);
      wrapper.send(msg.i, '');
    });
    waitMsgAll(wwwTaskGetErrors).listen((msg) {
      final i0 = msg.s.indexOf(':');
      final id = int.tryParse(msg.s.substring(0, i0));
      App()
          .listOfTasks[id]
          .wrapperSendPort
          .requestOnce('$wwwTaskGetErrors${msg.s.substring(i0 + 1)}')
          .then((v) => wrapper.send(msg.i, v));
    });
    waitMsgAll(wwwTaskGetFiles).listen((msg) {
      final i0 = msg.s.indexOf(':');
      final id = int.tryParse(msg.s.substring(0, i0));
      App()
          .listOfTasks[id]
          .wrapperSendPort
          .requestOnce('$wwwTaskGetFiles${msg.s.substring(i0 + 1)}')
          .then((v) => wrapper.send(msg.i, v));
    });
    waitMsgAll(wwwGetFileData).listen((msg) {
      File(msg.s).readAsBytes().then((data) {
        wrapper.send(msg.i, App().converters.convertData(data));
      });
    });

    waitMsgAll(wwwRegistration).listen((msg) {
      final i0 = msg.s.indexOf(':');
      final _user = User.reg(msg.s.substring(0, i0), msg.s.substring(i0 + 1));
      if (_user != null) {
        user = _user;
        wrapper.send(msg.i, user.access);
      } else {
        wrapper.send(msg.i, '?');
      }
    });

    waitMsgAll(wwwSignIn).listen((msg) {
      final i0 = msg.s.indexOf(':');
      final _user = User.get(msg.s.substring(0, i0), msg.s.substring(i0 + 1));
      if (_user != null) {
        user = _user;
        wrapper.send(msg.i, user.access);
      } else {
        wrapper.send(msg.i, '?');
      }
    });
  }

  Future<SocketWrapperResponse> Function(String msgBegin) get waitMsg =>
      wrapper.waitMsg;
  Stream<SocketWrapperResponse> Function(String msgBegin) get waitMsgAll =>
      wrapper.waitMsgAll;
  Future<String> Function(String msg) get requestOnce => wrapper.requestOnce;
  Stream<String> Function(String msg) get requestSubscribe =>
      wrapper.requestSubscribe;
}
