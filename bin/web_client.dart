import 'dart:convert';
import 'dart:io';

import 'package:knc/web.dart';

Future main(List<String> args) async {
  final server = await HttpServer.bind(InternetAddress.anyIPv4, 4040);
  print('Listening on http://${server.address.address}:${server.port}/');
  await for (var req in server) {
    // final contentType = req.headers.contentType;
    final response = req.response;

    void handleReqMethodGet() async {
      try {
        if (req.uri.path == '/') {
          response.headers.contentType = ContentType.html;
          response.statusCode = HttpStatus.ok;
          await response.addStream(File(r'web/index.html').openRead());
        } else {
          response
            ..statusCode = HttpStatus.badRequest
            ..write('Bad Request');
        }
      } catch (e) {
        response
          ..statusCode = HttpStatus.internalServerError
          ..write('Exception: $e.');
      }
    }

    void handleReqMethodPost() async {
      try {
        final content = await utf8.decoder.bind(req).join();
        response
          ..statusCode = HttpStatus.ok
          ..write(content);
      } catch (e) {
        response
          ..statusCode = HttpStatus.internalServerError
          ..write('Exception: $e.');
      }
    }

    switch (req.method) {
      case 'GET':
        await handleReqMethodGet();
        break;
      case 'POST':
        await handleReqMethodPost();
        break;
      default:
        response
          ..statusCode = HttpStatus.methodNotAllowed
          ..write('Unsupported request: ${req.method}.');
    }
    await response.flush();
    await response.close();
  }
}
