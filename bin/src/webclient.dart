import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:knc/errors.dart';
import 'package:knc/SocketWrapper.dart';
import 'package:knc/www.dart';

import 'App.dart';

class WebClientUsersDB {
  final _list = <WebClientUser>[];
  WebClientUsersDB._init() {
    print('${runtimeType.toString()} created: $hashCode');

    File('data/users.json').readAsString(encoding: utf8).then((data) =>
        _list.addAll(
            (jsonDecode(data) as List).map((e) => WebClientUser.fromJson(e))));
  }
  WebClientUser signIn(WebClientUser user) =>
      _list.firstWhere((e) => e.mail == user.mail && e.pass == user.pass,
          orElse: () => null);

  bool register(WebClientUser user) {
    if (_list.any((e) => e.mail == user.mail)) {
      return false;
    }
    _list.add(user);
    save();
    return true;
  }

  void save() => File('data/users.json').writeAsString(jsonEncode(_list));

  static WebClientUsersDB _instance;
  factory WebClientUsersDB() =>
      _instance ?? (_instance = WebClientUsersDB._init());
}

class WebClientUser {
  final String mail;
  final String pass;
  final int access;

  Map<String, dynamic> toJson() =>
      {'mail': mail, 'pass': pass, 'access': access};

  WebClientUser.fromJson(final Map v)
      : mail = v['mail'],
        pass = v['pass'],
        access = v['access'];
  WebClientUser(this.mail, this.pass, [this.access = 0]);
  static WebClientUser guest = WebClientUser('guest', null, 0);
}

class WebClient {
  /// Сокет для связи с клиентом
  final WebSocket socket;
  final SocketWrapper wrapper;
  WebClientUser user = WebClientUser.guest;
  StreamSubscription socketSubscription;

  WebClient(this.socket) : wrapper = SocketWrapper((msg) => socket.add(msg)) {
    print('$runtimeType created: $hashCode');
    print('socket [${socket.hashCode}] created');
    socket.listen(
        (event) {
          if (event is String) {
            print('WS_RECV: $event');
            wrapper.recv(event);
          }
        },
        onError: getErrorFunc('Ошибка в прослушке WebSocket:'),
        onDone: () {
          print('socket [${socket.hashCode}] done');
          App().listOfClients.remove(this);
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
      final _user =
          WebClientUser(msg.s.substring(0, i0), msg.s.substring(i0 + 1));
      if (WebClientUsersDB().register(_user)) {
        user = _user;
        wrapper.send(msg.i, user.access.toString());
      } else {
        wrapper.send(msg.i, 'null');
      }
    });

    waitMsgAll(wwwSignIn).listen((msg) {
      final i0 = msg.s.indexOf(':');
      final _user = WebClientUsersDB().signIn(
          WebClientUser(msg.s.substring(0, i0), msg.s.substring(i0 + 1)));
      if (_user != null) {
        user = _user;
        wrapper.send(msg.i, user.access.toString());
      } else {
        wrapper.send(msg.i, 'null');
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
