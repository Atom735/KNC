import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'dart:isolate';

import 'package:knc/async.dart';
import 'package:knc/errors.dart';
import 'package:knc/www.dart';

import 'converters.dart';
import 'knc.main.dart';
import 'WebClient.dart';

class App {
  /// Собсна сам сервер
  HttpServer http;
  StreamSubscription<HttpRequest> httpSubscription;

  /// Виртуальная папка, при URL к файлам, файлы ищутся этой папке.
  ///
  /// указывается при создании класса
  final Directory dir;

  /// Порт прослушиваемый главным изолятом
  final receivePort = ReceivePort();
  StreamSubscription receivePortSubscription;

  /// Список запущенных задач
  final listOfTasks = <int, KncTaskOnMain>{};
  var _uTaskNewId = 0;

  /// Список подключенных клиентов
  final listOfClients = <WebClient>[];

  /// Очередь выполнения субпроцессов
  final queueProc = AsyncTaskQueue(8, false);

  /// Конвертер WordConv и архивтор 7zip
  MyConverters converters;

  /// Получить данные для формы TaskView
  String getWwwTaskViewUpdate() {
    final list = [];
    listOfTasks.forEach((key, task) {
      list.add(task.json);
    });
    return json.encode(list);
  }

  void sendForAllClients(final String str) {
    listOfClients.forEach((client) {
      client.wrapper.send(0, str);
    });
  }

  Future<void> run(final int port) async {
    converters = await MyConverters.init(queueProc);
    await converters.clear();
    http = await HttpServer.bind(InternetAddress.anyIPv4, port);
    print('Listening on http://${http.address.address}:${http.port}/');
    print('For connect use http://localhost:${http.port}/');
    httpSubscription = http.listen((request) async {
      if (request.uri.path == '/ws') {
        // ignore: unawaited_futures
        WebSocketTransformer.upgrade(request).then((socket) {
          final c = WebClient(socket);
          listOfClients.add(c);
        }, onError: getErrorFunc('Ошибка в подключении WebSocket'));
      } else {
        final response = request.response;
        response.statusCode = HttpStatus.internalServerError;
        await response.write('Internal Server Error');
        await response.flush();
        await response.close();
      }
    }, onError: getErrorFunc('Ошибка в прослушке HttpRequest:'));

    receivePortSubscription = receivePort.listen((msg) {
      if (msg is List) {
        if (msg.length == 3 && msg[0] is int && msg[1] is SendPort) {
          final kncTask = listOfTasks[msg[0]];
          kncTask.sendPort = msg[1];
          kncTask.pathOut = msg[2];
          kncTask.initWrapper();
        }
        if (msg.length == 2 && msg[0] is int && msg[1] is String) {
          final kncTask = listOfTasks[msg[0]];
          if (kncTask.wrapper != null) {
            kncTask.wrapper.recv(msg[1]);
          }
        }
      }
    }, onError: getErrorFunc('Ошибка в прослушке ReceivePort:'));
  }

  String getWwwTaskNew(final String s) {
    final value = json.decode(s);
    if (value['name'] == null || value['path'] == null) {
      return '';
    }
    _uTaskNewId += 1;
    final path = <String>[];
    for (String item in value['path']) {
      path.add(item);
    }
    final kncTask =
        KncTaskOnMain(_uTaskNewId, value['name'], path.toList(growable: false));
    listOfTasks[kncTask.id] = kncTask;

    KncTaskSpawnSets(kncTask, converters.ssCharMaps, receivePort.sendPort)
        .spawn()
        .then((isolate) => kncTask.isolate = isolate);
    return wwwTaskNew + json.encode(kncTask.json);
  }

  App._init(this.dir) {
    print('App created: $hashCode');
  }
  static App _instance;
  factory App() => _instance ?? (_instance = App._init(Directory(r'web')));
}
