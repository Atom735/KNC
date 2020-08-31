import 'dart:html';

import 'package:knc/knc.dart';

import 'misc.dart';

class User {
  final String mail;
  final String access;

  User._(this.mail, this.access) {
    _instance = this;
  }
  static User _instance;
  factory User() => _instance;

  @override
  String toString() => mail;

  /// Вход в систему
  static Future<User> signin(final String data) =>
      requestOnce('$wwwUserSignin$data').then((msg) {
        if (msg.isNotEmpty) {
          window.localStorage['signin'] = data;
          return User._(
              data.substring(0, data.indexOf(msgRecordSeparator)), msg);
        } else {
          window.localStorage['signin'] = null;
        }
        return null;
      });

  /// Вход с помощью сохранённых данных
  static Future<User> signByIndexDB() => signin(window.localStorage['signin']);
}
