import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:path/path.dart' as p;
import 'package:knc/knc.dart';

import 'Conv.dart';
import 'Task.dart';
import 'TaskSpawnSets.dart';
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

  @override
  void send(final int id, final String msg) {
    // todo last infinity wait

    print('$this: send ($id) => ${msg.substring(0, min(msg.length, 60))}');
    super.send(id, msg);
  }

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

    /// Просьба обновить список задач `task.id...` - которые надо проигнорировать
    waitMsgAll(wwwTaskViewUpdate).listen((msg) {
      final _id = (jsonDecode(msg.s) as List)
          .map((e) => e as int)
          .toList(growable: false);
      send(
          msg.i,
          jsonEncode(Task.list.values
              .where((e) =>
                  !_id.contains(e.id) &&
                  (e.settings.user == user.mail ||
                      (e.settings.users.contains(user.mail))))
              .toList(growable: false)));
    });

    /// Запуск новой задачи `task.settings`
    waitMsgAll(wwwTaskNew).listen((msg) {
      final v = jsonDecode(msg.s);
      v['user'] = user.mail;
      TaskSpawnSets.spawn(settings: TaskSettings.fromJson(v))
          .then((_) => send(msg.i, ''));
    });

    /// Получение заметок файла `task.id``file.path`
    waitMsgAll(wwwFileNotes).listen((msg) {
      final i0 = msg.s.indexOf(msgRecordSeparator);
      Task.list[int.parse(msg.s.substring(0, i0))]
          .requestOnce(
              '$wwwFileNotes${msg.s.substring(i0 + msgRecordSeparator.length)}')
          .then((v) => send(msg.i, v));
    });

    /// Получение списка файлов `task.id`
    waitMsgAll(wwwTaskGetFiles).listen((msg) {
      final _id = Task.list.values
          .firstWhere((e) => msg.s == p.basename(e.dir.path),
              orElse: () => null)
          ?.id;
      if (_id == null || Task.list[_id] == null) {
        send(msg.i, '');
      } else {
        Task.list[_id]
            .requestOnce('$wwwTaskGetFiles')
            .then((v) => send(msg.i, v));
      }
    });

    /// Получение данных файла `path``codepage`
    waitMsgAll(wwwGetFileData).listen((msg) {
      final i0 = msg.s.indexOf(msgRecordSeparator);
      if (i0 == -1) {
        File(msg.s).readAsBytes().then((data) {
          send(msg.i, Conv().decode(data));
        });
      } else {
        File(msg.s.substring(0, i0)).readAsBytes().then((data) {
          send(
              msg.i,
              convDecode(
                  data,
                  Conv().charMaps[
                      msg.s.substring(i0 + msgRecordSeparator.length)]));
        });
      }
    });

    /// Регистрация нового пользователя `mail``pass`
    waitMsgAll(wwwUserRegistration).listen((msg) {
      final i0 = msg.s.indexOf(msgRecordSeparator);
      if (i0 == -1) {
        send(msg.i, '');
        return;
      }
      final _user = User.reg(msg.s.substring(0, i0),
          msg.s.substring(i0 + msgRecordSeparator.length));
      if (_user != null) {
        user = _user;
        send(msg.i, user.access);
      } else {
        send(msg.i, '');
      }
    });

    /// Вход пользователя `mail``pass`
    waitMsgAll(wwwUserSignin).listen((msg) {
      final i0 = msg.s.indexOf(msgRecordSeparator);
      if (i0 == -1) {
        send(msg.i, '');
        return;
      }
      final _user = User.get(msg.s.substring(0, i0),
          msg.s.substring(i0 + msgRecordSeparator.length));
      if (_user != null) {
        user = _user;
        send(msg.i, user.access);
      } else {
        send(msg.i, '');
      }
    });
  }
}
