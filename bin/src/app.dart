import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'dart:isolate';

import 'package:knc/async.dart';
import 'package:knc/errors.dart';

import 'converters.dart';
import 'knc.dart';
import 'knc.main.dart';
import 'webclient.dart';

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
  final listOfTasks = <int, KncSettingsOnMain>{};
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
    return json.encode(list);
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
        if (msg.length == 2 && msg[0] is int && msg[1] is SendPort) {
          final kncTask = listOfTasks[msg[0]];
          kncTask.sendPort = msg[1];
          kncTask.initWrapper();
        }
        if (msg.length == 2 && msg[0] is int && msg[1] is String) {
          final kncTask = listOfTasks[msg[0]];
          print('SERV_RECV: ${msg[0]}; ${msg[1]}');
          if (kncTask.wrapper != null) {
            kncTask.wrapper.recv(msg[1]);
          }
        }
      }
    }, onError: getErrorFunc('Ошибка в прослушке ReceivePort:'));
  }

  App._init(this.dir) {
    print('Server App created: $this');
  }
  static App _instance;
  factory App([Directory dir]) => _instance ?? (_instance = App._init(dir));

  String getWwwTaskNew(final String s) {
    final value = json.decode(s);
    if (value['name'] == null || value['path'] == null) {
      return '';
    }
    _uTaskNewId += 1;
    final kncTask = KncSettingsOnMain();
    kncTask.uID = _uTaskNewId;
    kncTask.ssTaskName = value['name'];
    for (String item in value['path']) {
      kncTask.pathInList.add(item);
    }
    listOfTasks[kncTask.uID] = kncTask;

    final kncTaskA = KncTask();
    kncTaskA.uID = _uTaskNewId;
    kncTaskA.ssTaskName = value['name'];
    for (String item in value['path']) {
      kncTaskA.pathInList.add(item);
    }
    kncTaskA.sendPort = receivePort.sendPort;
    kncTaskA.ssCharMaps = converters.ssCharMaps;

    Isolate.spawn(KncTask.isolateEntryPoint, kncTaskA,
            debugName: 'task[${kncTaskA.uID}]: "${kncTaskA.ssTaskName}"')
        .then((isolate) {
      kncTask.isolate = isolate;
    });

    return '${kncTask.uID}';
  }
}
