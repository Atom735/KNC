import 'dart:io';

import 'package:knc/errors.dart';
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

  void errorAdd(final String txt) {
    ss.errorsOut.writeln(txt);
    server.sendMsg('#ERROR:$txt');
  }

  /// Обработчик готовых Las данных
  Future handleOkLas(
      LasData las, File file, String newPath, int originals) async {
    try {
      if (originals > 0) {
        await file.copy(newPath);
        server.sendMsg('#LAS:+"${las.origin}"');
        server.sendMsg('#LAS:\tВ базу добавлено ${originals} кривых');
        server.sendMsg('#LAS:\t"${file.path}" => "${newPath}"');
        server.sendMsg('#LAS:\t"Well: ${las.wWell}');
        for (final c in las.curves) {
          server.sendMsg('#LAS:\t${c.mnem}: ${c.strtN} <=> ${c.stopN}');
        }
        server.sendMsg('#LAS:' + ''.padRight(20, '='));
      }
    } catch (e) {
      await handleErrorCatcher(e);
    }
  }

  /// Обработчик ошибочных Las данных
  Future handleErrorLas(LasData las, File file, String newPath) async {
    try {
      await file.copy(newPath);
    } catch (e) {
      await handleErrorCatcher(e);
    }
    errorAdd('+LAS("${las.origin}")');
    errorAdd('\t"${file.path}" => "${newPath}"');
    for (final err in las.listOfErrors) {
      errorAdd('\tСтрока ${err.line}: ${kncErrorStrings[err.err]}');
    }
    errorAdd(''.padRight(20, '='));
  }

  /// Обработчик готовых Ink данных
  Future handleOkInk(
      InkData ink, File file, String newPath, bool original) async {
    try {
      if (original) {
        server.sendMsg('#INK:+"${ink.origin}"');
        server.sendMsg('#INK:\t"${file.path}" => "${newPath}"');
        server.sendMsg('#INK:\tWell: ${ink.well}');
        server.sendMsg('#INK:\t${ink.strt} <=> ${ink.stop}');
        server.sendMsg('#INK:' + ''.padRight(20, '='));
        final io = File(newPath).openWrite(mode: FileMode.writeOnly);
        io.writeln(ink.well);
        final dat = ink.inkData;
        for (final item in dat.data) {
          io.writeln('${item.depth}\t${item.angle}\t${item.azimuth}');
        }
        await io.flush();
        await io.close();
      }
    } catch (e) {
      await handleErrorCatcher(e);
    }
  }

  /// Обработчик ошибочных Ink данных
  Future handleErrorInk(InkData ink, File file, String newPath) async {
    try {
      await file.copy(newPath);
    } catch (e) {
      await handleErrorCatcher(e);
    }
    errorAdd('+INK("${ink.origin}")');
    errorAdd('\t"${file.path}" => "${newPath}"');
    for (final err in ink.listOfErrors) {
      errorAdd('\tСтрока ${err.line}: ${kncErrorStrings[err.err]}');
    }
    errorAdd(''.padRight(20, '='));
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
      work = ss
          .startWork(
              handleErrorCatcher: handleErrorCatcher,
              handleOkLas: handleOkLas,
              handleErrorLas: handleErrorLas,
              handleOkInk: handleOkInk,
              handleErrorInk: handleErrorInk)
          .then((_) async {
        /// По заверешнию работы
        /// начинаем подготавливать таблицу
        server.sendMsg('#PREPARE_TABLE!');
        var xls = await ss.createXlTable();
        xls = File(xls)
            .absolute
            .path
            .substring(Directory('web').absolute.path.length);

        /// ОТправляем клиенту что всё закончено и файл можно скачать
        server.sendMsg('#DONE:$xls');
      });
      return reqWhileWork(req, content, serv);
    }
  }

  /// загрузка всех настроек
  await ss.loadAll;

  /// запуск сервера, начало обработок
  server.handleRequest = reqBeforeWork;
  await server.bind(80);
}
