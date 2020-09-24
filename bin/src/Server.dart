import 'dart:io';

import 'package:crclib/reveng.dart';
import 'package:knc/knc.dart';
import 'package:path/path.dart' as p;
import 'package:mime/mime.dart';

import 'Client.dart';
import 'TaskController.dart';

class Server {
  /// Собсна сам сервер
  final HttpServer server;

  /// Собсна сам сервер но с SSL
  /*SECURE*final HttpServer serverSecure;*/

  /// Помошник по mime типам
  final mimeResolver = MimeTypeResolver()
    ..addExtension('map', 'application/json');

  /// Корневые каталоги, где будут искаться файлы в первую очередь
  final dirs = <Directory>[
    Directory('build').absolute,
    Directory('web').absolute,
    TaskController.dirTasks,
  ];

  /// Маппинг ссылок на файлам
  final fileMap = <String, File>{'/': File('web/index.html').absolute};

  /// `RegExp` Маппинг ссылок на файлам
  final reMap = <RegExp, File>{
    RegExp(r'^/.*', caseSensitive: false): File('web/index.html').absolute
  };

  /// Закешированные файлы
  final fileMapCache = <File, List<int>>{};

  /// Контрольная сумма закешированных файлов
  final fileMapCrc = <File, String>{};

  void serveFile(
    HttpRequest request,
    HttpResponse response,
    File file,
    /*SECURE*[bool bSecure = false]*/
  ) {
    if (fileMapCrc[file] != null &&
        request.headers.value(HttpHeaders.ifNoneMatchHeader) != null &&
        fileMapCrc[file] ==
            (request.headers
                    .value(HttpHeaders.ifNoneMatchHeader)
                    ?.toLowerCase() ??
                'ETAG is EMPTY')) {
      /// Если E-tag совпадает
      response
        ..statusCode = HttpStatus.notModified
        ..flush().then((_) {
          response.close().then((_) {
            /*SECURE*if (bSecure) {*/
            iReq -= 1;
            /*SECURE*} else {
              iReqSecure -= 1;
            }*/
            print(
                'http (${request.hashCode}): ${request.uri.path} closed ($iReq) not modified');
          });
        });
    } else if (fileMapCache[file] != null) {
      final mime = mimeResolver.lookup(file.path) as String /*?*/;

      /// Файл закеширован
      response
        ..statusCode = HttpStatus.ok
        ..headers.contentType =
            mime != null ? ContentType.parse(mime /*!*/) : ContentType.binary
        ..headers.add(HttpHeaders.etagHeader, fileMapCrc[file] /*!*/)
        ..add(fileMapCache[file] /*!*/)
        ..flush().then((_) {
          response.close().then((_) {
            /*SECURE*if (bSecure) {*/
            iReq -= 1;
            /*SECURE*} else {
              iReqSecure -= 1;
            }*/
            print(
                'http (${request.hashCode}): ${request.uri.path} closed ($iReq) from cache #${fileMapCrc[file] /*!*/}');
          });
        });
    } else if (file.existsSync()) {
      /// Файл существует
      file.readAsBytes().then((bytes) {
        fileMapCache[file] = bytes;
        fileMapCrc[file] =
            Crc64().convert(bytes).toRadixString(36).toLowerCase();
        print('$file cached #${fileMapCrc[file] /*!*/}');
        serveFile(request, response, file);
      });
    } else {
      /// Файл не наден
      response
        ..statusCode = HttpStatus.notFound
        ..write('404: Not Found')
        ..flush().then((_) {
          response.close().then((_) {
            /*SECURE*if (bSecure) {*/
            iReq -= 1;
            /*SECURE*} else {
              iReqSecure -= 1;
            }*/
            print(
                'http (${request.hashCode}): ${request.uri.path} closed ($iReq)');
          });
        });
    }
  }

  @override
  String toString() =>
      '$runtimeType($hashCode)[${server.address.address}:${server.port}]';

  /// Количество активных подключений
  int iReq = 0;

  /// Количество активных подключений к защищённому подключению
  int iReqSecure = 0;
  static Future<Server> init() async {
    return Server._create(await HttpServer.bind(InternetAddress.anyIPv4,
            wwwPort) /*SECURE*,
        await HttpServer.bindSecure(
            InternetAddress.anyIPv4,
            443,
            SecurityContext()
              ..useCertificateChain(p.join('data', 'cert.pem'))
              ..usePrivateKey(p.join('data', 'key.pem'),
                  password: '1234567890'),
            backlog: 5)*/
        );
  }

  static /*late*/ Server _instance;
  factory Server() => _instance;
  Server._create(this.server /*SECURE*, this.serverSecure*/) {
    print('$this created');
    print('Listening on http://${server.address.address}:${server.port}/');
    print('For connect use http://localhost:${server.port}/');
    /*SECURE*print(
        'Listening Secure on https://${serverSecure.address.address}:${serverSecure.port}/');
    print('For connect use https://localhost:${serverSecure.port}/');*/
    _instance = this;

    for (final dir in dirs) {
      if (!dir.existsSync()) {
        dir.createSync();
      }

      /// Следим за изменением файлов в папках
      dir.watch(recursive: true).listen((event) {
        final file = File(event.path).absolute;
        if (fileMapCache[file] != null) {
          fileMapCache.remove(file);
          fileMapCrc.remove(file);
          print('$file cached removed');
        }
      });
    }

    server.listen((request) {
      iReq += 1;
      serverListner(request);
    },
        onError: getErrorFunc(
            'Ошибка в прослушке HTTP:${server.address.address}:${server.port}'));
    /*SECURE*serverSecure.listen((request) {
      iReqSecure += 1;
      serverListner(request, true);
    },
        onError: getErrorFunc(
            'Ошибка в прослушке HTTPS:${serverSecure.address.address}:${serverSecure.port}'));*/
  }

  void serverListner(HttpRequest request /*SECURE*, [bool bSecure = false]*/) {
    final response = request.response;
    print('http (${request.hashCode}): ${request.uri.path} opend ($iReq)');

    /// если есть необходимый файл в папках
    for (final dir in dirs) {
      final f = File(dir.path + request.uri.path);
      if (f.existsSync()) {
        serveFile(request, response, f);
        return;
      }
    }

    if (request.uri.path == '/ws') {
      /// если подключается сокет
      WebSocketTransformer.upgrade(request).then((websocket) {
        print('http ${request.uri.path} upgraded to WebSocket');
        Client(websocket);
        request.response.flush().then((_) {
          request.response.close().then((_) {
            /*SECURE*if (bSecure) {*/
            iReq -= 1;
            /*SECURE*} else {
              iReqSecure -= 1;
            }*/
            print(
                'http (${request.hashCode}): ${request.uri.path} closed ($iReq)');
          });
        });
      });
    } else if (fileMap[request.uri.path] != null) {
      /// если есть ремап кнкретной ссылки на файл
      serveFile(request, response, fileMap[request.uri.path] /*!*/);
      return;
    } else {
      /// если есть ремап шаблона ссылки на файл
      for (final key in reMap.keys) {
        if (key.hasMatch(request.uri.path)) {
          serveFile(request, response, reMap[key] /*!*/);
          return;
        }
      }

      serveFile(request, response, File('not-found'));
    }
  }
}
