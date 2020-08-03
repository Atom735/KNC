import 'dart:async';
import 'dart:io';
import 'dart:isolate';

import 'package:knc/async.dart';
import 'package:knc/converters.dart';
import 'package:knc/knc.dart';
import 'package:knc/web.dart';
import 'package:knc/www.dart';
import '../quickstart/web/www.dart';

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

  void handleRequestWS(
      final WebSocket socket, final String msg, final MyServer serv) {}

  WebClient(this.socket);
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

  Future<void> run(final int port) async {
    converters = await MyConverters.init(queueProc);
    await converters.clear();
    http = await HttpServer.bind(InternetAddress.anyIPv4, port);
    print('Listening on http://${http.address.address}:${http.port}/');
    print('For connect use http://localhost:${http.port}/');
    httpSubscription = http.listen((request) async {
      if (request.uri.path == '/ws') {
        // ignore: unawaited_futures
        WebSocketTransformer.upgrade(request).then((socket) {},
            onError: getErrorFunc('Ошибка в подключении сокета'));
      } else {
        final response = request.response;
        response.statusCode = HttpStatus.internalServerError;
        await response.write('Internal Server Error');
        await response.flush();
        await response.close();
      }
    }, onError: getErrorFunc('Ошибка в прослушке http порта:'));

    receivePortSubscription = receivePort.listen((msg) {},
        onError: getErrorFunc('Ошибка в прослушке внутреннего порта:'));
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

Future mainOld(List<String> args) async {
  /// Поднятый сервер
  final server = MyServer(Directory(r'web'));

  /// Порт прослушиваемый главным изолятом
  final receivePort = ReceivePort();

  /// Список запущенных задач
  final listOfTasks = <KncSettingsOnMain>[];

  /// Очередь выполнения субпроцессов
  final queueProc = AsyncTaskQueue(8, false);

  /// Конвертер WordConv и архивтор 7zip
  final converters = await MyConverters.init(queueProc);
  var _clientUID = 0;
  final clients = <int, WebClient>{};

  /// Обработка новых подключений ВебСокета
  server.handleWebSocketNew = (final WebSocket socket, final MyServer serv) {
    _clientUID += 1;
    final c = WebClient(socket);
    // clients[c.id] = c;
    socket.listen((event) async {
      print('WS: $event');
      if (event is String) {
        if (event == wwwTaskViewUpdate) {
          final value = [];
          for (var item in listOfTasks) {
            value.add({
              'id': item.uID,
              'name': item.ssTaskName,
              'state': item.iState.index,
              'errors': 0,
              'files': 0,
            });
          }
        } else {
          await c.handleRequestWS(socket, event, serv);
        }
      }
    }, onDone: () {
      print('WS: socket(${socket.hashCode}) closed');
      // clients.remove(c.id);
    });

    // socket.add('${wwwClientId}${c.id}');
    return true;
  };

  /// - in 0`{task.uID}` -
  /// Уникальный номер изолята
  ///
  /// - in 1`{SendPort}` -
  /// Порт для общения с субизолятом с номером uID
  /// - in 1`unzip`, 2`{unzip.uID}`, 3`{pathToArchive}` -
  /// Просьба разархивировать от субизолята
  /// - in 1`zip`, 2`{zip.uID}`, 3`{pathToData}`, 4`{pathToOutput}` -
  /// Просьба запаковать данные в Zip
  /// - in 1`doc2x`, 2`{doc2x.uID}`, 3`{path2doc}`, 4`{path2out}` -
  /// Просьба переконвертировать doc в docx
  /// - in 1`ssPathOut`, 2`{ssPathOut.uID}`, 3`{ssPathOut}` -
  /// Просьба обновить конечный путь
  ///
  /// - out 0`unzip`, 1`{unzip.uID}`, 2`{outputString}` -
  /// Ответ на прозьбу распаковки
  /// - out 0`zip`, 1`{zip.uID}`, 2`{outputString}` -
  /// Ответ на прозьбу запаковать
  /// - out 0`doc2x`, 1`{doc2x.uID}`, 2`{exitCode}` -
  /// Ответ на прозьбу запаковать
  /// - out 0`charMaps`, 1`{ssCharMaps}` -
  /// Данные о кодировках
  /// - out 0`ssPathOut`, 2`{ssPathOut.uID}` -
  /// Ответ на обновление конечного пути
  ///
  /// - in 1`#...` -
  /// Сообщение передаваемое сокету
  ///
  receivePort.listen((final data) async {
    if (data is List && data[0] is int) {
      final uID = data[0] as int;
      var task = listOfTasks.singleWhere((element) => element.uID == uID);
      if (data[1] is SendPort) {
        task.sendPort = data[1];
        task.iState = KncTaskState.work;
        server.sendMsgToAll(task.wsUpdateState);
        task.sendPort.send(['charMaps', converters.ssCharMaps]);
        return;
      } else if (data[1] is String) {
        final String dataStr = data[1];
        switch (dataStr) {
          case 'unzip':
            if (data[2] is int) {
              final err =
                  await converters.unzip(data[3], null, converters.ssCharMaps);
              task.sendPort.send([dataStr, data[2], err]);
              return;
            }
            break;
          case 'zip':
            if (data[2] is int) {
              final err =
                  await converters.zip(data[3], data[4], converters.ssCharMaps);
              task.sendPort.send([dataStr, data[2], err]);
              return;
            }
            break;
          case 'doc2x':
            if (data[2] is int) {
              final err = await converters.doc2x(data[3], data[4]);
              task.sendPort.send([dataStr, data[2], err]);
              return;
            }
            break;
          case 'ssPathOut':
            if (data[2] is int) {
              task.ssPathOut = data[3];
              task.sendPort.send([dataStr, data[2]]);
              return;
            }
            break;
          default:
        }
      }
    }
    print('main: recieved unknown msg {$data}');
  });

  server.handleRequest =
      (HttpRequest req, String content, MyServer serv) async {
    return false;
  };

  await server.bind(80);
}
