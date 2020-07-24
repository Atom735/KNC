import 'dart:collection';
import 'dart:io';
import 'dart:isolate';

import 'package:knc/errors.dart';
import 'package:knc/ink.dart';
import 'package:knc/knc.dart';
import 'package:knc/las.dart';
import 'package:knc/web.dart';
import 'package:knc/www.dart';

class KncSettingsOnMain extends KncSettingsInternal {
  /// Изолят выоплнения задачи
  Isolate isolate;

  SendPort sendPort;

  KncSettingsOnMain(KncSettingsInternal ss) {
    uID = ss.uID;
    ssTaskName = ss.ssTaskName;
    ssPathOut = ss.ssPathOut;
    ssFileExtAr = [];
    ssFileExtAr.addAll(ss.ssFileExtAr);
    ssFileExtLas = [];
    ssFileExtLas.addAll(ss.ssFileExtLas);
    ssFileExtInk = [];
    ssFileExtInk.addAll(ss.ssFileExtInk);
    pathInList = [];
    pathInList.addAll(ss.pathInList);
    ssArMaxSize = ss.ssArMaxSize;
    ssArMaxDepth = ss.ssArMaxDepth;
  }
}

Future main(List<String> args) async {
  /// Настройки работы
  final ss = KncSettingsInternal();

  /// Поднятый сервер
  final server = MyServer(Directory(r'web'));

  /// Порт прослушиваемый главным изолятом
  final receivePort = ReceivePort();

  /// Список запущенных задач
  final listOfTasks = <KncSettingsOnMain>[];

  /// Уникальный номер задачи
  var newTaskUID = 1;

  /// Флаг завершения работы, будет выполнен когда все файлы обработаются
  Future work;

  receivePort.listen((final data) {
    if (data is List && data[0] is int) {
      final uID = data[0] as int;
      var task = listOfTasks.singleWhere((element) => element.uID == uID);
      if (data[1] is SendPort) {
        task.sendPort = data[1];
        task.iState = KncTaskState.synced;
        server.sendMsgToAll(task.wsUpdateState);
        return;
      }
    }
    print('main: recieved unknown msg {$data}');
  });

  /// Обработка новых подключений ВебСокета
  server.handleWebSocketNew = (WebSocket socket, MyServer serv) async {
    for (final ss in listOfTasks) {
      socket.add('${wwwKncTaskAdd}${ss.json}');
    }
  };

  server.handleRequest =
      (HttpRequest req, String content, MyServer serv) async {
    if (req.uri.path == '/') {
      final response = req.response;
      response.headers.contentType = ContentType.html;
      response.statusCode = HttpStatus.ok;
      response.write(ss
          .updateBufferByThis(await File(r'web/index.html').readAsString())
          .replaceAll(r'${{!uniqFormPost}}', '$wwwPathToTasks$newTaskUID'));
      await response.flush();
      await response.close();
    } else if (req.uri.path.startsWith(wwwPathToTasks)) {
      final taskUID =
          int.tryParse(req.uri.path.substring(wwwPathToTasks.length));
      if (taskUID != null) {
        var bNew = true;
        for (var task in listOfTasks) {
          if (task.uID == taskUID) {
            bNew = true;
            break;
          }
        }
        if (bNew && content.isNotEmpty) {
          ss.updateByMultiPartFormData(parseMultiPartFormData(content));
          ss.uID = taskUID;
          final newTask = KncSettingsOnMain(ss);
          listOfTasks.add(newTask);
          newTaskUID += 1;
          final newTaskSettigs = KncTask.fromSettings(ss);
          newTaskSettigs.sendPort = receivePort.sendPort;
          newTask.isolate = await Isolate.spawn(
              KncTask.isolateEntryPoint, newTaskSettigs,
              debugName:
                  'task[${newTaskSettigs.uID}]: "${newTaskSettigs.ssTaskName}"');
          for (final socket in serv.ws) {
            socket.add('${wwwKncTaskAdd}${newTask.json}');
          }
        }
        final response = req.response;
        response.headers.contentType = ContentType.html;
        response.statusCode = HttpStatus.ok;
        await response.addStream(File(r'web/action.html').openRead());
        await response.flush();
        await response.close();
        return true;
      }
    } else if (req.uri.path == '/lib/www.dart') {
      final response = req.response;
      response.headers.contentType = ct_Dart;
      response.statusCode = HttpStatus.ok;

      await response.addStream(File('lib/www.dart').openRead());
      await response.flush();
      await response.close();
      return true;
    }
    return false;
  };

  await server.bind(80);
}
