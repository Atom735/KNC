import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'dart:isolate';

import 'package:knc/async.dart';
import 'package:knc/errors.dart';
import 'package:knc/www.dart';
import 'package:path/path.dart' as p;

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
  final listOfFiles = <String, File>{'/': File('build/index.html')};

  /// Получить данные для формы TaskView
  String getWwwTaskViewUpdate(
      final WebClientUser user, final List<int> updated) {
    final list = [];
    listOfTasks.forEach((key, task) {
      if (!updated.contains(key)) {
        list.add(task.json);
      }
    });
    return json.encode(list);
  }

  void sendForAllClients(final String str) {
    listOfClients.forEach((client) {
      client.wrapper.send(0, str);
    });
  }

  Future<void> serveFile(
      HttpRequest request, HttpResponse response, File file) async {
    if (await file.exists()) {
      response.statusCode = HttpStatus.ok;
      final ext = p.extension(file.path).toLowerCase();
      switch (ext) {
        case '.html':
          response.headers.add('content-type', 'text/html');
          break;
        case '.css':
          response.headers.add('content-type', 'text/css');
          break;
        case '.js':
          response.headers.add('content-type', 'application/javascript');
          break;
        case '.ico':
          response.headers.add('content-type', 'image/x-icon');
          break;
        case '.map':
          response.headers.add('content-type', 'application/json');
          break;
        case '.xlsx':
          response.headers.add('content-type', 'application/vnd.ms-excel');
          break;
        default:
      }
      await response.addStream(file.openRead());
      await response.flush();
      await response.close();
    } else {
      response.statusCode = HttpStatus.notFound;
      await response.write('404: Not Found');
      await response.flush();
      await response.close();
    }
  }

  Future<void> run() async {
    WebClientUsersDB();
    converters = await MyConverters.init(queueProc);
    await converters.clear();
    http = await HttpServer.bind(InternetAddress.anyIPv4, wwwPort);
    print('Listening on http://${http.address.address}:${http.port}/');
    print('For connect use http://localhost:${http.port}/');
    httpSubscription = http.listen((request) async {
      final response = request.response;
      print('http: ${request.uri.path}');
      if (request.uri.path == '/ws') {
        // ignore: unawaited_futures
        WebSocketTransformer.upgrade(request).then((socket) {
          response.close();
          final c = WebClient(socket);
          listOfClients.add(c);
        }, onError: getErrorFunc('Ошибка в подключении WebSocket'));
      } else if (listOfFiles[request.uri.path] != null) {
        await serveFile(request, response, listOfFiles[request.uri.path]);
      } else if (listOfFiles[request.uri.path] != null) {
        await serveFile(request, response, listOfFiles[request.uri.path]);
      } else {
        await serveFile(request, response, File('build' + request.uri.path));
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
          if (kncTask.wrapperSendPort != null) {
            kncTask.wrapperSendPort.recv(msg[1]);
          }
        }
      }
    }, onError: getErrorFunc('Ошибка в прослушке ReceivePort:'));
  }

  void getWwwTaskNew(final String s, final WebClientUser user) {
    _uTaskNewId += 1;
    final task = WWW_TaskSettings.fromJson(jsonDecode(s));
    final kncTask = KncTaskOnMain(_uTaskNewId, task, user);
    listOfTasks[kncTask.id] = kncTask;

    KncTaskSpawnSets(kncTask, converters.ssCharMaps, receivePort.sendPort)
        .spawn()
        .then((isolate) => kncTask.isolate = isolate);
  }

  App._init(this.dir) {
    print('${runtimeType.toString()} created: $hashCode');
  }
  static App _instance;
  factory App() => _instance ?? (_instance = App._init(Directory(r'web')));
}
