import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as p;

/// ContentType mime = application/javascript
final ct_JS = ContentType.parse('application/javascript');

/// ContentType mime = application/vnd.dart
final ct_Dart = ContentType.parse('application/vnd.dart');

String getRequestDebugData(final HttpRequest request) {
  final string = StringBuffer();
  string.writeln('Received request ${request.method}: ${request.uri.path}');
  string.writeln('HTTP: ${request.protocolVersion}');
  string.writeln();
  string.writeln('= cookies begin =');
  for (var i = 0; i < request.cookies.length; i++) {
    string.writeln('[${i + 1}] = ${request.cookies[i]}');
  }
  string.writeln('= cookies end =');
  string.writeln();
  string.writeln('= headers begin =');
  request.headers.forEach((name, values) {
    if (values.length == 1) {
      string.writeln('$name: ${values[0]}');
    } else {
      string.writeln('$name:');
      values.forEach((value) {
        string.writeln('    $value');
      });
    }
  });
  string.writeln('= headers end =');
  return string.toString();
}

Map<String, String> parseMultiPartFormData(final String content) {
  final map = <String, String>{};
  if (content.startsWith('--')) {
    final contentList = LineSplitter().convert(content);
    final bound = contentList[0];
    var bounded = true;
    var data = <String>[];
    var dataname = '';
    for (var line in contentList) {
      if (line == bound) {
        bounded = true;
        if (data.isNotEmpty) {
          map[dataname] = data.join('\n').trim();
          data.clear();
        }
      } else if (bounded) {
        if (line.toLowerCase().startsWith('content-disposition')) {
          final i0 = line.toLowerCase().indexOf('name=');
          if (i0 == -1) {
            return null;
          }
          final i1 = line.indexOf('"', i0 + 5);
          dataname = line.substring(i1 + 1, line.indexOf('"', i1 + 1));
        } else {
          if (line.isEmpty) {
            bounded = false;
          }
        }
      } else {
        data.add(line);
      }
    }
  } else {
    return null;
  }
  return map;
}

class MyServer {
  /// Собсна сам сервер
  HttpServer server;

  /// Список сокетов
  var ws = <WebSocket>[];

  /// Список отправленных данных через вебсокеты,
  /// будут отправлены вновь подключишимся сокетам
  var wsSendsList = <String>[];

  /// Виртуальная папка, при URL к файлам, файлы ищутся этой папке.
  ///
  /// указывается при создании класса
  final Directory dir;

  /// Функция обработчик запросов к серверу.
  ///
  /// Если вернёт `true`, то сервер считает что запрос был обрабатан
  Future<bool> Function(HttpRequest req, String content, MyServer serv)
      handleRequest;

  /// Функция обработчик данных отправляемых через _WebSocket_.
  Future<void> Function(WebSocket socket, String content, MyServer serv)
      handleRequestWS;

  MyServer(this.dir);

  /// Функция отправки сообщения через _WebSocket_.
  void sendMsg(final String txt) {
    wsSendsList.add(txt);
    ws.forEach((ws) {
      ws.add(txt);
    });
  }

  /// Подключить сервер на прослушку порта [port]
  ///
  /// Изначально необходимо установить функции обработчики запросов [handleRequest],
  /// хотя можно обойтись и без этого, тогда сервер будет работать как файловый
  /// сервер к папке [this.dir]
  Future<void> bind(final int port) async {
    server = await HttpServer.bind(InternetAddress.anyIPv4, port);
    print('Listening on http://${server.address.address}:${server.port}/');
    print('For connect use http://localhost:${server.port}/');
    await for (var req in server) {
      if (req.uri.path == '/ws') {
        final socket = await WebSocketTransformer.upgrade(req);
        ws.add(socket);
        print('WS: socket(${socket.hashCode}) opened ');
        socket.listen((event) async {
          print('WS: $event');
          if (event is String) {
            if (event == '#STOP!') {
              server.close(); // ignore: unawaited_futures
            }
            if (handleRequestWS != null) {
              await handleRequestWS(socket, event, this);
            }
          }
        }, onDone: () {
          print('WS: socket(${socket.hashCode}) closed');
          ws.remove(socket);
        });
        for (final msg in wsSendsList) {
          socket.add(msg);
        }
      } else {
        final file = File(p.join(dir.absolute.path, req.uri.path.substring(1)));
        final response = req.response;
        if (await file.exists()) {
          print('serve: $file');
          switch (p.extension(file.path)) {
            case '.js':
              response.headers.contentType = ct_JS;
              break;
            case '.dart':
              response.headers.contentType = ct_Dart;
              break;
            case '.html':
              response.headers.contentType = ContentType.html;
              break;
            case '.bin':
              response.headers.contentType = ContentType.binary;
              break;
            case '.json':
            case '.map':
              response.headers.contentType = ContentType.json;
              break;
            default:
              response.headers.contentType = ContentType.text;
          }
          response.statusCode = HttpStatus.ok;

          await response.addStream(file.openRead());
          await response.flush();
          await response.close();
        } else if (handleRequest != null &&
            await handleRequest(
                req, await utf8.decoder.bind(req).join(), this)) {
        } else {
          final response = req.response;
          response.statusCode = HttpStatus.internalServerError;
          await response.write('Internal Server Error');
          await response.flush();
          await response.close();
        }
      }
    }
    var list = <Future>[];
    for (var socket in ws) {
      list.add(socket.close());
    }
    await Future.wait(list);
  }
}
