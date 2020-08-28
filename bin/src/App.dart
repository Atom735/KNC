import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

import 'package:knc/knc.dart';
import 'package:path/path.dart' as p;

import 'Server.dart';
import 'User.dart';
import 'Client.dart';
import 'Conv.dart';
import 'knc.main.dart';

class App {
  /// Собсна сам сервер
  Server server;

  /// Виртуальная папка, при URL к файлам, файлы ищутся этой папке.
  ///
  /// указывается при создании класса
  final Directory dir;

  /// Порт прослушиваемый главным изолятом
  final receivePort = ReceivePort();

  /// Список запущенных задач
  final listOfTasks = <int, KncTaskOnMain>{};
  var _uTaskNewId = 0;

  /// Список подключенных клиентов
  final clients = <Client>[];

  /// Конвертер WordConv и архивтор 7zip
  Conv conv;
  final listOfFiles = <String, File>{'/': File('build/index.html')};

  /// Получить данные для формы TaskView
  String getWwwTaskViewUpdate(final User user, final List<int> updated) {
    final list = [];
    listOfTasks.forEach((key, task) {
      if (!updated.contains(key)) {
        list.add(task.json);
      }
    });
    return jsonEncode(list);
  }

  void sendForAllClients(final String str) {
    clients.forEach((client) {
      client.wrapper.send(0, str);
    });
  }

  Future<void> run() async {
    await Future.wait([User.load(), Conv.init()]);

    receivePort.listen((msg) {
      if (msg is List) {
        if (msg.length == 3 && msg[0] is int && msg[1] is SendPort) {
          final kncTask = listOfTasks[msg[0]];
          kncTask.sendPort = msg[1];
          kncTask.pathOut = msg[2];
          kncTask.initWrapper();
        }
        if (msg.length == 2 && msg[0] is int && msg[1] is String) {
          final kncTask = listOfTasks[msg[0]];
          if (kncTask.wrapperSendPort != null) {
            kncTask.wrapperSendPort.recv(msg[1]);
          }
        }
      }
    }, onError: getErrorFunc('Ошибка в прослушке ReceivePort:'));
    await Server.init();
  }

  void getWwwTaskNew(final String s, final User user) {
    _uTaskNewId += 1;
    final task = WWW_TaskSettings.fromJson(jsonDecode(s));
    final kncTask = KncTaskOnMain(_uTaskNewId, task, user);
    listOfTasks[kncTask.id] = kncTask;

    KncTaskSpawnSets(kncTask, conv.charMaps, receivePort.sendPort)
        .spawn()
        .then((isolate) => kncTask.isolate = isolate);
  }

  @override
  String toString() => '${runtimeType.toString()}($hashCode)';

  App._init(this.dir) {
    print('$this: created');
    _instance = this;
  }
  static App _instance;
  factory App() => _instance ?? (_instance = App._init(Directory(r'web')));
}
