import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:knc/knc.dart';

import 'App.dart';
import 'Conv.dart';
import 'User.dart';

class Client {
  /// Сокет для связи с клиентом
  final WebSocket socket;

  /// Оболчка для обработки запросов
  final SocketWrapper wrapper;

  /// Пользователь подключённого клиента
  User user;

  @override
  String toString() =>
      '$runtimeType($hashCode)[$user].WebSocket(${socket.hashCode})';

  /// Создание нового клиента с указанным сокетом и
  /// пользователем, если он был задан
  Client(this.socket, [this.user = User.guest])
      : wrapper = SocketWrapper((msg) => socket.add(msg)) {
    print('$this created');
    App().clients.add(this);

    socket.listen(
        (event) {
          if (event is String) {
            print('$this: recv => $event');
            wrapper.recv(event);
          }
        },
        onError: getErrorFunc('Ошибка в прослушке $this'),
        onDone: () {
          App().clients.remove(this);
          print('$this released');
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
        wrapper.send(msg.i, Conv().decode(data));
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
