import 'dart:convert';

import 'package:knc/knc.dart';

/// Вход пользователя в систему.
///
/// Клиент отправляет запрос серверу, в ответ приходят данные о пользователе
/// [JUser] в `Json` формате, в случае неудачи пустая строка.
class JMsgUserSignin {
  static const msgId = 'JMsgUserSignin:';

  final String mail;
  final String pass;

  factory JMsgUserSignin.fromString(final String str) {
    final s = str.split(msgRecordSeparator);
    return JMsgUserSignin(s[0], s[1]);
  }
  const JMsgUserSignin(this.mail, this.pass);

  @override
  String toString() => '$mail$msgRecordSeparator$pass';
}

/// Выход пользователя из системы.
///
/// Клиент отправляет запрос серверу, в ответ приходит пустая строка.
class JMsgUserLogout {
  static const msgId = 'JMsgUserLogout:';
}

/// Регистрация нового пользователя и вход.
///
/// Клиент отправляет запрос серверу с данными нового пользователя,
/// в ответ приходят данные о пользователе
/// [JUser] в `Json` формате, в случае неудачи пустая строка.
class JMsgUserRegistration {
  static const msgId = 'JMsgUserRegistration:';
  final JUser user;

  factory JMsgUserRegistration.fromString(final String str) =>
      JMsgUserRegistration(JUser.fromJson(jsonDecode(str)));
  const JMsgUserRegistration(this.user);

  @override
  String toString() => jsonEncode(user);
}
