import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:path/path.dart' as p;
import 'package:knc/knc.dart';

import 'Conv.dart';
import 'TaskController.dart';
import 'TaskSpawnSets.dart';
import 'User.dart';

/// Связующий класс между веб-клиентом (браузером) и сервером...
///
/// Связь происходит через `WebSocket`.
///
/// * [user] - конкретный авторизированный пользователь данного подключения
class Client extends SocketWrapper {
  /// Сокет для связи с клиентом
  final WebSocket _socket;

  /// Пользователь подключённого клиента, при отсуствии считается гостем
  User? user;

  /// Список подключенных клиентов
  static final list = <Client>[];

  @override
  String toString() =>
      '$runtimeType($hashCode)[$user].WebSocket(${_socket.hashCode})';

  @override
  void send(final int id, final String msg) {
    print('$this: send ($id) => ${msg.substring(0, min(msg.length, 300))}');
    super.send(id, msg);
  }

  /// Создание нового клиента с указанным сокетом и
  /// пользователем, если он был задан
  Client(this._socket, [this.user]) : super((msg) => _socket.add(msg)) {
    print('$this created');
    list.add(this);

    _socket.listen(
        (event) {
          if (event is String) {
            print('$this: recv => $event');
            recv(event);
          } else {
            print('$this: recv unknown => $event');
          }
        },
        onError: getErrorFunc('Ошибка в прослушке $this'),
        onDone: () {
          list.remove(this);
          print('$this released');
        });
/*
    /// Просьба обновить список задач `task.id...` - которые надо проигнорировать
    waitMsgAll(wwwTaskViewUpdate).listen((msg) {
      final _id = (jsonDecode(msg.s) as List)
          .map((e) => e as String)
          .toList(growable: false);
      send(
          msg.i,
          jsonEncode(Task.list.values
              .where((e) =>
                  !_id.contains(e.id) &&
                  (user != null && e.settings.user == user.mail ||
                      (e.settings.users.contains(user.mail)) ||
                      (e.settings.users.contains(User.guest.mail))))
              .toList()
                ..addAll(Task.listClosed.values.where((e) =>
                    !_id.contains(e.id) &&
                    (e.settings.user == user.mail ||
                        (e.settings.users.contains(user.mail)) ||
                        (e.settings.users.contains(User.guest.mail)))))));
    });

    /// Запуск новой задачи `task.settings`
    waitMsgAll(wwwTaskNew).listen((msg) {
      final v = jsonDecode(msg.s);
      v['user'] = user.mail;
      TaskSpawnSets.spawn(settings: JTaskSettings.fromJson(v))
          .then((_) => send(msg.i, ''));
    });

    /// Получение заметок файла `task.id``file.path`
    waitMsgAll(wwwFileNotes).listen((msg) {
      final i0 = msg.s.indexOf(msgRecordSeparator);
      Task.list[msg.s.substring(0, i0)]
          .requestOnce(
              '$wwwFileNotes${msg.s.substring(i0 + msgRecordSeparator.length)}')
          .then((v) => send(msg.i, v));
    });

    /// Получение списка файлов `task.id`
    waitMsgAll(wwwTaskGetFiles).listen((msg) {
      final _id = Task.list.values
          .firstWhere((e) => msg.s == e.id,
              orElse: () => Task.listClosed.values
                  .firstWhere((e) => msg.s == e.id, orElse: () => null))
          ?.id;
      if (_id == null) {
        send(msg.i, '');
      } else if (Task.list[_id] != null) {
        Task.list[_id]
            .requestOnce('$wwwTaskGetFiles')
            .then((v) => send(msg.i, v));
      } else if (Task.listClosed[_id] != null) {
        Task.listClosed[_id]
            .getFilesData()
            .then((v) => send(msg.i, jsonEncode(v)));
      } else {
        send(msg.i, '');
      }
    });

    /// Получение списка файлов `file.path`
    waitMsgAll(wwwGetOneFileData).listen((msg) {
      /// Путь к файлу, данные которого необходимо получить
      var _path = msg.s;
      if (msg.s.startsWith('tasks')) {
        _path = p.join(Task.dirTasks.path, msg.s.substring(6));
      }
      final _fileJson = File(_path + '.json');
      _fileJson.exists().then((_exist) {
        if (_exist) {
          _fileJson.readAsString().then((data) => send(msg.i, data));
        } else {
          /// Если файла с данными не нашли
          final _id =
              p.split(_path.substring(Task.dirTasks.path.length + 1)).first;
          if (Task.list[_id] != null) {
            Task.list[_id]
                .requestOnce('$wwwGetOneFileData$_path')
                .then((v) => send(msg.i, v));
          } else if (Task.listClosed[_id] != null) {
            Task.listClosed[_id].getFilesData().then((v) {
              final _ofd =
                  v.firstWhere((e) => e.path == _path, orElse: () => null);
              if (_ofd != null) {
                send(msg.i, jsonEncode(_ofd.toJsonFull()));
              } else {
                send(msg.i, '');
              }
            });
          } else {
            send(msg.i, '');
          }
        }
      });
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
    */

    /// Регистрация нового пользователя `mail``pass`
    waitMsgAll(JMsgUserRegistration.msgId).listen((msg) {
      final _msg = JMsgUserRegistration.fromString(msg.s);
      final _mail = _msg.user.mail.toLowerCase();
      if (User.dataBase[_mail] != null) {
        send(msg.i, '');
      } else {
        user = User.fromJson(_msg.user.toJson());
        send(msg.i, jsonEncode(user));
      }
    });

    /// Вход пользователя `mail``pass`
    waitMsgAll(JMsgUserSignin.msgId).listen((msg) {
      final _msg = JMsgUserSignin.fromString(msg.s);
      final _mail = _msg.mail.toLowerCase();
      if (User.dataBase[_mail] == null) {
        send(msg.i, '');
      } else {
        user = User.dataBase[_mail];
        send(msg.i, jsonEncode(user!));
      }
    });

    /// Выход пользователя
    waitMsgAll(JMsgUserLogout.msgId).listen((msg) {
      user = null;
      send(msg.i, '');
    });
  }
}
