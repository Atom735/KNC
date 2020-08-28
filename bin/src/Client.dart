import 'dart:convert';
import 'dart:io';

import 'package:knc/knc.dart';

import 'App.dart';
import 'Conv.dart';
import 'Task.dart';
import 'User.dart';

class Client extends SocketWrapper {
  /// Сокет для связи с клиентом
  final WebSocket socket;

  /// Пользователь подключённого клиента
  User user;

  /// Список подключенных клиентов
  static final list = <Client>[];
  @override
  String toString() =>
      '$runtimeType($hashCode)[$user].WebSocket(${socket.hashCode})';

  /// Создание нового клиента с указанным сокетом и
  /// пользователем, если он был задан
  Client(this.socket, [this.user = User.guest])
      : super((msg) => socket.add(msg)) {
    print('$this created');
    list.add(this);

    socket.listen(
        (event) {
          if (event is String) {
            print('$this: recv => $event');
            recv(event);
          }
        },
        onError: getErrorFunc('Ошибка в прослушке $this'),
        onDone: () {
          list.remove(this);
          print('$this released');
        });
    // waitMsgAll(wwwTaskViewUpdate).listen((msg) {
    //   send(
    //       msg.i,
    //       App().getWwwTaskViewUpdate(
    //           user,
    //           (jsonDecode(msg.s) as List)
    //               .map((e) => e as int)
    //               .toList(growable: false)));
    // });
    // waitMsgAll(wwwTaskNew).listen((msg) {
    //   App().getWwwTaskNew(msg.s, user);
    //   send(msg.i, '');
    // });
    waitMsgAll(wwwTaskGetErrors).listen((msg) {
      final i0 = msg.s.indexOf(':');
      final id = int.tryParse(msg.s.substring(0, i0));
      Task.list[id]
          .requestOnce('$wwwTaskGetErrors${msg.s.substring(i0 + 1)}')
          .then((v) => send(msg.i, v));
    });
    waitMsgAll(wwwTaskGetFiles).listen((msg) {
      final i0 = msg.s.indexOf(':');
      final id = int.tryParse(msg.s.substring(0, i0));
      Task.list[id]
          .requestOnce('$wwwTaskGetFiles${msg.s.substring(i0 + 1)}')
          .then((v) => send(msg.i, v));
    });
    waitMsgAll(wwwGetFileData).listen((msg) {
      File(msg.s).readAsBytes().then((data) {
        send(msg.i, Conv().decode(data));
      });
    });

    waitMsgAll(wwwRegistration).listen((msg) {
      final i0 = msg.s.indexOf(':');
      final _user = User.reg(msg.s.substring(0, i0), msg.s.substring(i0 + 1));
      if (_user != null) {
        user = _user;
        send(msg.i, user.access);
      } else {
        send(msg.i, '?');
      }
    });

    waitMsgAll(wwwSignIn).listen((msg) {
      final i0 = msg.s.indexOf(':');
      final _user = User.get(msg.s.substring(0, i0), msg.s.substring(i0 + 1));
      if (_user != null) {
        user = _user;
        send(msg.i, user.access);
      } else {
        send(msg.i, '?');
      }
    });
  }
}
