@JS()
library mydart_userbase;

import 'dart:convert';

import 'package:js/js.dart';

import 'index.dart' show passwordEncode;

@JS()
class JsUser {
  /// name (full name)
  ///
  /// Полное имя
  external String /*?*/ get name;
  external set name(String /*?*/ s);

  /// given-name (first name)
  ///
  /// Имя
  external String /*?*/ get fname;
  external set fname(String /*?*/ s);

  /// additional-name (middle name)
  ///
  /// Отчество
  external String /*?*/ get mname;
  external set mname(String /*?*/ s);

  /// family-name (last name)
  ///
  /// Фамилия
  external String /*?*/ get lname;
  external set lname(String /*?*/ s);

  /// Почта пользователя
  external String /*?*/ get email;
  external set email(String /*?*/ s);

  /// Номер телефона
  external String /*?*/ get phone;
  external set phone(String /*?*/ s);

  /// Пароль незашифрованный
  external String /*?*/ get pass;
  external set pass(String /*?*/ s);

  /// Символы доступа пользователя
  external String /*?*/ get access;
  external set access(String /*?*/ s);

  /// Создаёт экземпляр из данных сообщения
  static JsUser create(String str) {
    final o = JsUser();
    if (str.isNotEmpty) {
      final map = jsonDecode(str) as Map;
      o.name = map['name'];
      o.fname = map['fname'];
      o.mname = map['mname'];
      o.lname = map['lname'];
      o.email = map['email'];
      o.phone = map['phone'];
      o.access = map['access'];
    }
    o.genJsonStringReg = allowInteropCaptureThis((JsUser _) => jsonEncode({
          'pass': passwordEncode(_.pass ?? ''),
          'name': _.name ?? '',
          'fname': _.fname ?? '',
          'mname': _.mname ?? '',
          'lname': _.lname ?? '',
          'email': _.email ?? '',
          'phone': _.phone ?? '',
        }));
    o.genJsonStringPass = allowInteropCaptureThis((JsUser _) => jsonEncode({
          'pass': passwordEncode(_.pass ?? ''),
          'email': _.email ?? '',
        }));

    return o;
  }

  /// Сгенерировать сообщение для регистрации в системе,
  /// поле [access] игнорируется
  external set genJsonStringReg(String Function(JsUser) f);

  /// Сгенерировать сообщение для входа в систему,
  /// используются только поля [email] и [pass]
  external set genJsonStringPass(String Function(JsUser) f);
}

@JS('JsUser')
external set _JsUser(JsUser Function([String]) f);

void main() {
  _JsUser = allowInterop(([String str]) => JsUser.create(str ?? ''));
}
