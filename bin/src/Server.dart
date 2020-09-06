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

  void serveFile(HttpRequest request, HttpResponse response, File file) {
    if (file != null && file.existsSync()) {
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
      response.addStream(file.openRead()).then((_) {
        response.flush().then((_) {
          response.close().then((_) {
            iReq -= 1;
            print(
                'http(${request.hashCode}): ${request.uri.path} closed ($iReq)');
          });
        });
      });
      print('http: ${request.uri.path} serve $file');
    } else {
      response.statusCode = HttpStatus.notFound;
      response.write('404: Not Found');
      response.flush().then((_) {
        response.close().then((_) {
          iReq -= 1;
          print(
              'http(${request.hashCode}): ${request.uri.path} closed ($iReq)');
        });
      });
    }
  }

  @override
  String toString() =>
      '$runtimeType($hashCode)[${server.address.address}:${server.port}]';
  int iReq = 0;
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
      iReq += 1;
      final response = request.response;
      print('http(${request.hashCode}): ${request.uri.path} opend ($iReq)');
      if (request.uri.path == '/ws') {
        WebSocketTransformer.upgrade(request).then((websocket) {
          print('http: ${request.uri.path} upgraded to WebSocket');
          Client(websocket);
          request.response.flush().then((_) {
            request.response.close().then((_) {
              iReq -= 1;
              print(
                  'http(${request.hashCode}): ${request.uri.path} closed ($iReq)');
            });
          });
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
