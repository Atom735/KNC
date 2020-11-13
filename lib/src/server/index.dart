import 'dart:io';
import 'dart:typed_data';

import 'package:crclib/reveng.dart';
import 'package:mime/mime.dart';
import 'package:path/path.dart' as p;

import '../errors.dart';

HttpServer httpServer;

/// Помошник по mime типам
final mimeResolver = MimeTypeResolver()
  ..addExtension('map', 'application/json');

/// Корневые каталоги, где будут искаться файлы в первую очередь
final httpDirs = <Directory>[
  Directory('web').absolute,
];

/// Количество активных подключений
int httpRequestCount = 0;

/// Закешированные файлы
final httpFilesCache = <String, Uint8List>{};

/// Контрольная сумма закешированных файлов
final httpFilesCrc = <String, String>{};

Future<void> httpServerSpawn() async {
  httpServer = await HttpServer.bind(InternetAddress.anyIPv4, 80);
  print(
      'http: Listening on http://${Platform.localHostname}:${httpServer.port}/');

  for (final dir in httpDirs) {
    if (!dir.existsSync()) {
      dir.createSync(recursive: true);
    }

    /// Следим за изменением файлов в папках
    dir.watch(recursive: true).listen((event) {
      final _key = File(event.path).absolute.path.toLowerCase();
      if (httpFilesCache[_key] != null) {
        httpFilesCache.remove(_key);
        httpFilesCrc.remove(_key);
        print('$_key cached removed');
      }
    });
  }

  httpServer.listen((request) {
    httpRequestCount++;
    httpListner(request);
  },
      onError: getErrorFunc(
          'Ошибка в прослушке HTTP:${httpServer.address.address}:${httpServer.port}'));
}

void httpListner(HttpRequest request) {
  final response = request.response;
  print('http: ${request.uri.path}\n\topend ($httpRequestCount)');

  /// если есть необходимый файл в папках
  for (final dir in httpDirs) {
    final path = p.normalize(dir.absolute.path + request.uri.path);
    if (File(path).existsSync()) {
      httpServeFile(request, response, path);
      return;
    }
  }
  httpServeFile(request, response, '');
}

void httpServeFile(
  HttpRequest request,
  HttpResponse response,
  String path,
) {
  final _key = path.toLowerCase();
  if (httpFilesCrc.containsKey(_key)) {
    if (request.headers.value(HttpHeaders.ifNoneMatchHeader) != null &&
        httpFilesCrc[_key] ==
            (request.headers
                    .value(HttpHeaders.ifNoneMatchHeader)
                    ?.toLowerCase() ??
                'ETAG is EMPTY')) {
      /// Если E-tag совпадает
      response
        ..statusCode = HttpStatus.notModified
        ..flush().then((_) {
          response.close().then((_) {
            httpRequestCount--;
            print(
                'http: ${request.uri.path}\n\tclosed ($httpRequestCount) not modified');
          });
        });
    } else {
      final mime = mimeResolver.lookup(_key) /*as String?*/;

      /// Файл закеширован
      response
        ..statusCode = HttpStatus.ok
        ..headers.contentType =
            mime != null ? ContentType.parse(mime /*!*/) : ContentType.binary
        ..headers.add(HttpHeaders.etagHeader, httpFilesCrc[_key] /*!*/)
        ..add(httpFilesCache[_key] /*!*/)
        ..flush().then((_) {
          response.close().then((_) {
            httpRequestCount--;
            print(
                'http: ${request.uri.path}\n\tclosed ($httpRequestCount) from cache #${httpFilesCrc[_key] /*!*/}');
          });
        });
    }
  } else if (File(path).existsSync()) {
    /// Файл существует
    File(path).readAsBytes().then((bytes) {
      httpFilesCache[_key] = bytes;
      httpFilesCrc[_key] =
          Crc64().convert(bytes).toRadixString(36).toLowerCase();
      print('$_key cached #${httpFilesCrc[_key] /*!*/}');

      final mime = mimeResolver.lookup(_key);

      /// Файл закеширован
      response
        ..statusCode = HttpStatus.ok
        ..headers.contentType =
            mime != null ? ContentType.parse(mime /*!*/) : ContentType.binary
        ..headers.add(HttpHeaders.etagHeader, httpFilesCrc[_key] /*!*/)
        ..add(bytes)
        ..flush().then((_) {
          response.close().then((_) {
            httpRequestCount--;
            print(
                'http: ${request.uri.path}\n\tclosed ($httpRequestCount) and cached #${httpFilesCrc[_key] /*!*/}');
          });
        });
    });
  } else {
    /// Файл не наден
    response
      ..statusCode = HttpStatus.notFound
      ..write('404: Not Found')
      ..flush().then((_) {
        response.close().then((_) {
          httpRequestCount--;
          print(
              'http: ${request.uri.path}\n\tclosed ($httpRequestCount) NOT FOUND');
        });
      });
  }
}
