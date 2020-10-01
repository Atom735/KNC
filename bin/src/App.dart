import 'dart:async';
import 'dart:ffi';
import 'dart:isolate';
import 'dart:math';

import 'package:knc/knc.dart';

import 'Server.dart';
import 'User.dart';
import 'Client.dart';
import 'Conv.dart';
import 'TaskController.dart';

/// RegExp for migrate
/// ```
/// (?<!\*)((?:\brequired\b)|(?:\blate\b)|(?:(?<=[\w\]\)>])(?:(?:!)|(?:\?(?!\.)))))
/// ```
/// /*$1*/

class App {
  /// Порт прослушиваемый главным изолятом
  final receivePort = ReceivePort();

  /// Комплитеры для завершения спавна задачи
  final completers = <String, Completer<SendPort>>{};

  void _recvMsg(String id, String msg, int trying) {
    final _task = TaskController.list[id];
    if (_task != null) {
      if (!_task.recv(msg)) {
        final _o = 'UNKNOWN MSG from ${_task.toString()}:\n$msg';
        print(_o.substring(0, min(256, _o.length)));
      }
    } else if (trying < 600) {
      Future.delayed(Duration(milliseconds: 16)).then((_) {
        receivePort.sendPort.send([id, msg, trying + 1]);
      });
    } else {
      print('Не удалось переслать сообщение ');
      final _o = 'ERROR MSG to $id:\n$msg';
      print(_o.substring(0, min(256, _o.length)));
    }
  }

  /// Точка входа для приложения
  Future<void> run() async {
    /// Слушаем входящие сообщения от [TaskIso]
    receivePort.listen((msg) {
      if (msg is List) {
        if (msg.length == 2 && msg[0] is String && msg[1] is SendPort) {
          /// Передаём порт связи перехватчику
          completers[msg[0]]?.complete(msg[1]);
        }

        /// Сообщение созданые [SocketWrapper] пересылаем на обработку
        /// [TaskController]
        if (msg.length >= 2 && msg[0] is String && msg[1] is String) {
          if (completers[msg[0]] != null) {
            /// Если задача запущена а [TaskController] для неё ещё не
            /// существует
            completers[msg[0]] /*!*/ .future.then((value) {
              _recvMsg(
                  msg[0], msg[1], msg.length > 2 && msg[2] is int ? msg[2] : 0);
              completers.remove(msg[0]);
            });
          } else {
            _recvMsg(
                msg[0], msg[1], msg.length > 2 && msg[2] is int ? msg[2] : 0);
          }
        }
      }
    }, onError: getErrorFunc('Ошибка в прослушке ReceivePort:'));

    await Conv.init();
    await User.load();
    await Server.init();
    await TaskController.init();
  }

  /// Отправка всем подключенным клиентам
  void sendForAllClients(final String msg) {
    Client.list.forEach((e) {
      e.send(0, msg);
    });
  }

  App._create() {
    print('$this: created');
  }
  @override
  String toString() => '${runtimeType.toString()}($hashCode)';
  static final App _instance = App._create();
  factory App() => _instance;
}
