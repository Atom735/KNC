import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

import 'package:knc/knc.dart';

import 'Server.dart';
import 'User.dart';
import 'Client.dart';
import 'Conv.dart';
import 'Task.dart';

class App {
  /// Порт прослушиваемый главным изолятом
  final receivePort = ReceivePort();

  /// Комплитеры для завершения спавна задачи
  final completers = <int, Completer<SendPort>>{};

  /// Точка входа для приложения
  Future<void> run() async {
    await Future.wait([User.load(), Conv.init()]);

    receivePort.listen((msg) {
      if (msg is List) {
        if (msg.length == 2 && msg[0] is int && msg[1] is SendPort) {
          completers[msg[0]].complete(msg[1]);
        }
        if (msg.length == 2 && msg[0] is int && msg[1] is String) {
          if (completers[msg[0]] != null) {
            completers[msg[0]].future.then((value) {
              Task.list[msg[0]].recv(msg[1]);
              completers.remove(msg[0]);
            });
          } else {
            Task.list[msg[0]].recv(msg[1]);
          }
        }
      }
    }, onError: getErrorFunc('Ошибка в прослушке ReceivePort:'));

    await Server.init();
  }

  /// Отправка всем подключенным клиентам
  void sendForAllClients(final String msg) {
    Client.list.forEach((e) {
      e.send(0, msg);
    });
  }

  @override
  String toString() => '${runtimeType.toString()}($hashCode)';
  App._init() {
    print('$this: created');
    _instance = this;
  }
  static App _instance;
  factory App() => _instance ?? (_instance = App._init());
}
