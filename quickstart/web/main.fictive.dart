import 'dart:convert';

import 'main.dart';

class FictiveApp extends App {
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
        if (msg.startsWith(wwwTaskNew)) {}
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
