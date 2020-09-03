import 'dart:io';

import 'package:knc/knc.dart';
import 'package:path/path.dart' as p;

import 'Client.dart';

class Server {
  /// Собсна сам сервер
  final HttpServer server;

  final dirs = <Directory>[
    Directory('build').absolute,
    Directory('tasks').absolute,
    Directory('web').absolute,
  ];
  final fileMap = <String, File>{'/': File('web/index.html')};
  final reMap = <RegExp, File>{
    RegExp(r'^\/app(\/.+)?', caseSensitive: false): File('web/index.html')
  };

  Future<void> serveFile(
      HttpRequest request, HttpResponse response, File file) async {
    if (file != null && await file.exists()) {
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
      print('http: ${request.uri.path} serve $file');
    } else {
      response.statusCode = HttpStatus.notFound;
      await response.write('404: Not Found');
      await response.flush();
      await response.close();
      print('http: ${request.uri.path} 404: Not Found');
    }
  }

  @override
  String toString() =>
      '$runtimeType($hashCode)[${server.address.address}:${server.port}]';

  static Future<Server> init() async =>
      Server._init(await HttpServer.bind(InternetAddress.anyIPv4, wwwPort));
  static Server _instance;
  factory Server() => _instance;
  Server._init(this.server) {
    print('$this created');
    print('Listening on http://${server.address.address}:${server.port}/');
    print('For connect use http://localhost:${server.port}/');
    _instance = this;
    server.listen((request) {
      final response = request.response;
      print('http: ${request.uri.path}');
      if (request.uri.path == '/ws') {
        WebSocketTransformer.upgrade(request).then((websocket) {
          print('http: ${request.uri.path} upgraded to WebSocket');
          Client(websocket);
        });
      } else if (fileMap[request.uri.path] != null) {
        serveFile(request, response, fileMap[request.uri.path]);
      } else {
        for (var key in reMap.keys) {
          if (key.hasMatch(request.uri.path)) {
            serveFile(request, response, reMap[key]);
            return;
          }
        }
        for (var dir in dirs) {
          final f = File(dir.path + request.uri.path);
          if (f.existsSync()) {
            serveFile(request, response, f);
            return;
          }
        }
        serveFile(request, response, null);
      }
    },
        onError: getErrorFunc(
            'Ошибка в прослушке ${server.address.address}:${server.port}'));
  }
}
