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
final _httpDirs = <Directory>[
  Directory('web').absolute,
];

/// Количество активных подключений
int _httpRequestCount = 0;

/// Закешированные файлы
final _httpFilesCache = <String, Uint8List>{};

/// Контрольная сумма закешированных файлов
final _httpFilesCrc = <String, String>{};

Future<void> httpServerSpawn() async {
  httpServer = await HttpServer.bind(InternetAddress.anyIPv4, 80);
  print(
      'http: Listening on http://${Platform.localHostname}:${httpServer.port}/');

  for (final dir in _httpDirs) {
    if (!dir.existsSync()) {
      dir.createSync(recursive: true);
    }

    /// Следим за изменением файлов в папках
    dir.watch(recursive: true).listen((event) {
      final _key = File(event.path).absolute.path.toLowerCase();
      if (_httpFilesCache[_key] != null) {
        _httpFilesCache.remove(_key);
        _httpFilesCrc.remove(_key);
        print('$_key cached removed');
      }
    });
  }

  httpServer.listen((request) {
    _httpRequestCount++;
    _httpListner(request);
  },
      onError: getErrorFunc(
          'Ошибка в прослушке HTTP:${httpServer.address.address}:${httpServer.port}'));
}

void _httpListner(HttpRequest request) {
  final response = request.response;
  print('http: ${request.uri.path}\n\topend ($_httpRequestCount)');

  /// если есть необходимый файл в папках
  for (final dir in _httpDirs) {
    final path = p.normalize(dir.absolute.path + request.uri.path);
    if (File(path).existsSync()) {
      _httpServeFile(request, response, path);
      return;
    }
  }
  _httpServeFile(request, response, '');
}

void _httpServeFile(
  HttpRequest request,
  HttpResponse response,
  String path,
) {
  final _key = path.toLowerCase();
  if (_httpFilesCrc.containsKey(_key)) {
    if (request.headers.value(HttpHeaders.ifNoneMatchHeader) != null &&
        _httpFilesCrc[_key] ==
            (request.headers
                    .value(HttpHeaders.ifNoneMatchHeader)
                    ?.toLowerCase() ??
                'ETAG is EMPTY')) {
      /// Если E-tag совпадает
      response
        ..statusCode = HttpStatus.notModified
        ..flush().then((_) {
          response.close().then((_) {
            _httpRequestCount--;
            print(
                'http: ${request.uri.path}\n\tclosed ($_httpRequestCount) not modified');
          });
        });
    } else {
      final mime = mimeResolver.lookup(_key) /*as String?*/;

      /// Файл закеширован
      response
        ..statusCode = HttpStatus.ok
        ..headers.contentType =
            mime != null ? ContentType.parse(mime /*!*/) : ContentType.binary
        ..headers.add(HttpHeaders.etagHeader, _httpFilesCrc[_key] /*!*/)
        ..add(_httpFilesCache[_key] /*!*/)
        ..flush().then((_) {
          response.close().then((_) {
            _httpRequestCount--;
            print(
                'http: ${request.uri.path}\n\tclosed ($_httpRequestCount) from cache #${_httpFilesCrc[_key] /*!*/}');
          });
        });
    }
  } else if (File(path).existsSync()) {
    /// Файл существует
    File(path).readAsBytes().then((bytes) {
      _httpFilesCache[_key] = bytes;
      _httpFilesCrc[_key] =
          Crc64().convert(bytes).toRadixString(36).toLowerCase();
      print('$_key cached #${_httpFilesCrc[_key] /*!*/}');

      final mime = mimeResolver.lookup(_key);

      /// Файл закеширован
      response
        ..statusCode = HttpStatus.ok
        ..headers.contentType =
            mime != null ? ContentType.parse(mime /*!*/) : ContentType.binary
        ..headers.add(HttpHeaders.etagHeader, _httpFilesCrc[_key] /*!*/)
        ..add(bytes)
        ..flush().then((_) {
          response.close().then((_) {
            _httpRequestCount--;
            print(
                'http: ${request.uri.path}\n\tclosed ($_httpRequestCount) and cached #${_httpFilesCrc[_key] /*!*/}');
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
          _httpRequestCount--;
          print(
              'http: ${request.uri.path}\n\tclosed ($_httpRequestCount) NOT FOUND');
        });
      });
  }
}
