import 'dart:io';

import 'package:knc/knc.dart';
import 'package:knc/web.dart';

Future main(List<String> args) async {
  /// Настройки работы
  final ss = KncSettings();

  /// Поднятый сервер
  final server = MyServer(Directory(r'web'));

  /// Флаг завершения работы, будет выполнен когда все файлы обработаются
  Future work;

  /// Обработчик исключений
  Future handleErrorCatcher(dynamic e) async {
    ss.errorsOut.writeln(e.toString());
    server.sendMsg('#EXCEPTION:${e.toString()}');
  }

  /// Обработчик соединения во время работы
  Future<bool> reqWhileWork(
      HttpRequest req, String content, MyServer serv) async {
    final response = req.response;
    response.headers.contentType = ContentType.html;
    response.statusCode = HttpStatus.ok;
    await response.addStream(File(r'web/action.html').openRead());
    await response.flush();
    await response.close();
    return true;
  }

  /// Обработчик соединения до начала работы
  Future<bool> reqBeforeWork(
      HttpRequest req, String content, MyServer serv) async {
    if (content.isEmpty) {
      await ss.servSettings(req.response);
      return true;
    } else {
      serv.handleRequest = reqWhileWork;
      ss.updateByMultiPartFormData(parseMultiPartFormData(content));
      await ss.initializing();
      work = ss.startWork(handleErrorCatcher: handleErrorCatcher);
      return reqWhileWork(req, content, serv);
    }
  }

  /// загрузка всех настроек
  await ss.loadAll;

  /// запуск сервера, начало обработок
  server.handleRequest = reqBeforeWork;
  await server.bind(4040);
}
