import 'dart:async';
import 'dart:io';
import 'dart:isolate';

import 'package:knc/async.dart';
import 'package:knc/converters.dart';
import 'package:knc/knc.dart';
import 'package:knc/web.dart';
import 'package:knc/www.dart';
import '../quickstart/web/www.dart';
import '../quickstart/web/socketWrapper.dart';

class KncSettingsOnMain extends KncSettingsInternal {
  /// Уникальный номер выполняемой задачи
  int id;

  /// Изолят выоплнения задачи
  Isolate isolate;

  /// Порт задачи
  SendPort sendPort;
}

class WebClient {
  /// Сокет для связи с клиентом
  final WebSocket socket;
  final SocketWrapper wrapper;
  StreamSubscription socketSubscription;

  WebClient(this.socket)
      : wrapper = SocketWrapper((final String msg) => socket.add(msg)) {
    socketSubscription = socket.listen((event) {
      if (event is String) {
        print('WS_RECV: $event');
        wrapper.recv(event);
      }
    }, onError: getErrorFunc('Ошибка в прослушке WebSocket:'));
    waitMsgAll(wwwTaskViewUpdate).listen((msg) {
      wrapper.send(msg.i, ServerApp().getWwwTaskViewUpdate());
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

void Function(dynamic error, StackTrace stackTrace) getErrorFunc(
        final String txt) =>
    (error, StackTrace stackTrace) {
      print(txt);
      print(error);
      print('StackTrace:');
      print(stackTrace);
    };

class ServerApp {
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

  /// Список подключенных клиентов
  final listOfClients = <WebClient>[];

  /// Очередь выполнения субпроцессов
  final queueProc = AsyncTaskQueue(8, false);

  /// Конвертер WordConv и архивтор 7zip
  MyConverters converters;

  /// Получить данные для формы TaskView
  String getWwwTaskViewUpdate() {
    return '{}';
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

    receivePortSubscription = receivePort.listen((msg) {},
        onError: getErrorFunc('Ошибка в прослушке ReceivePort:'));
  }

  ServerApp._init(this.dir) {
    print('Server App created: $this');
  }
  static ServerApp _instance;
  factory ServerApp([Directory dir]) =>
      _instance ?? (_instance = ServerApp._init(dir));
}

void main(List<String> args) {
  ServerApp(Directory(r'web')).run(80);
}
