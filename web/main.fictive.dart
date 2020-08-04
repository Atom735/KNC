import 'dart:convert';

import 'main.dart';
import 'package:knc/www.dart';

class FictiveTask {
  final int id;
  final String name;
  final List<String> paths;

  FictiveTask(this.id, this.name, this.paths);
}

class FictiveApp extends App {
  /// Уникальный Айди задачи
  int _uTaskID = 0;

  final _taskList = <int, FictiveTask>{};

  /// Отправить данные на сервер
  @override
  void send(final String msgRAW) {
    print('send: $msgRAW');
    final i0 = msgRAW.indexOf(';');
    final i1 = msgRAW.indexOf(';', i0 + 1);
    final cUID = int.tryParse(msgRAW.substring(0, i0));
    final rUID = int.tryParse(msgRAW.substring(i0 + 1, i1));
    final msg = msgRAW.substring(i1 + 1);
    switch (msg) {
      case wwwTaskViewUpdate:
        Future.delayed(Duration(milliseconds: 100)).then((_) {
          final value = [
            {
              'id': 13,
              'name': 'Адам',
              'state': 0,
              'errors': 0,
              'files': 0,
            },
            {
              'id': 17,
              'name': 'Почти первый',
              'state': 1,
              'errors': 597,
              'files': 1324,
            },
            {
              'id': 24,
              'name': 'Тройка!!! Пока ещё без таблицы',
              'state': 2,
              'errors': 4123,
              'files': 9876,
            },
            {
              'id': 37,
              'name': 'А этот уже !@#\$%^&*()"{} всё закончил',
              'state': 3,
              'errors': 14,
              'files': 178,
            }
          ];
          onMessage('$rUID;${json.encode(value)}');
        });

        break;
      default:
        if (msg.startsWith(wwwTaskNew)) {
          final map = json.decode(msg.substring(wwwTaskNew.length));
          _uTaskID += 1;
          final taskID = _uTaskID;
          final list = List<String>((map['path'] as List).length);
          for (var i = 0; i < list.length; i++) {
            list[i] = (map['path'] as List)[i];
          }
          _taskList[taskID] = (FictiveTask(taskID, map['name'], list));
          Future.delayed(Duration(milliseconds: 333)).then((_) {
            onMessage('$rUID;$taskID');
          });
        }
    }
  }

  @override
  void onMessage(final String msg) {
    print('recv: $msg');
    super.onMessage(msg);
  }

  FictiveApp.init() : super.init() {
    Future.delayed(Duration(milliseconds: 100))
        .then((_) => onOpen())
        .then((_) => Future.delayed(Duration(milliseconds: 100)))
        .then((_) => onMessage('@312'));
  }
  factory FictiveApp() => (App.instance) ?? (App.instance = FictiveApp.init());
}
