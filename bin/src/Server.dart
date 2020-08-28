import 'dart:io';

import 'package:knc/knc.dart';
import 'package:path/path.dart' as p;

import 'Client.dart';

class Server {
  /// Собсна сам сервер
  final HttpServer server;

  final dirs = <Directory>[];
  final fileMap = <String, File>{'/': File('build/index.html')};

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
    server.listen((request) async {
      final response = request.response;
      print('http: ${request.uri.path}');
      if (request.uri.path == '/ws') {
        final s = await WebSocketTransformer.upgrade(request);
        await response.close();
        Client(s);
      } else if (fileMap[request.uri.path] != null) {
        await serveFile(request, response, fileMap[request.uri.path]);
      } else {
        for (var dir in dirs) {
          final f = File(dir.path + request.uri.path);
          if (await f.exists()) {
            await serveFile(request, response, f);
            return;
          }
        }
      }
    },
        onError: getErrorFunc(
            'Ошибка в прослушке ${server.address.address}:${server.port}'));
  }
}
