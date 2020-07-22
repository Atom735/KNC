import 'dart:io';

import 'package:knc/ink.dart';
import 'package:knc/knc.dart';
import 'package:knc/las.dart';
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

  /// Обработчик готовых Las данных
  Future handleOkLas(
      LasData las, File file, String newPath, int originals) async {}

  /// Обработчик ошибочных Las данных
  Future handleErrorLas(LasData las, File file, String newPath) async {}

  /// Обработчик готовых Ink данных
  Future handleOkInk(
      InkData ink, File file, String newPath, bool original) async {}

  /// Обработчик ошибочных Ink данных
  Future handleErrorInk(InkData ink, File file, String newPath) async {}

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
      work = ss.startWork(
          handleErrorCatcher: handleErrorCatcher,
          handleOkLas: handleOkLas,
          handleErrorLas: handleErrorLas,
          handleOkInk: handleOkInk,
          handleErrorInk: handleErrorInk);
      return reqWhileWork(req, content, serv);
    }
  }

  /// загрузка всех настроек
  await ss.loadAll;

  /// запуск сервера, начало обработок
  server.handleRequest = reqBeforeWork;
  await server.bind(4040);
}
