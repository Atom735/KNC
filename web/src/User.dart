import 'dart:html';

import 'package:knc/knc.dart';

import 'App.dart';
import 'CardTask.dart';
import 'misc.dart';

class User {
  final String mail;
  final String access;

  User._(this.mail, this.access) {
    _instance = this;
    App().eLoginBtn.innerText = 'account_circle';
    App().eLoginMail.innerText = mail;
    CardTaskTemplate().updateTasks();
  }
  static User _instance;
  factory User() => _instance;

  /// Выход из системы
  static void logout() {
    requestOnce('$wwwUserLogout').then((value) {
      _instance = null;
      window.localStorage['signin'] = null;
      App().eLoginBtn.innerText = 'login';
      App().eLoginMail.innerText = '@guest';
      CardTaskTemplate().removeAllTasks();
      CardTaskTemplate().updateTasks();
    });
  }

  @override
  String toString() => mail;

  /// Вход в систему
  static Future<User> signin(final String data) => data == null
      ? Future(() => null)
      : requestOnce('$wwwUserSignin$data').then((msg) {
          if (msg.isNotEmpty) {
            window.localStorage['signin'] = data;
            return User._(
                data.substring(0, data.indexOf(msgRecordSeparator)), msg);
          }
          window.localStorage['signin'] = null;
          return null;
        });

  /// Регистрация и вход в систему
  static Future<User> reg(final String data) => data == null
      ? Future(() => null)
      : requestOnce('$wwwUserRegistration$data').then((msg) {
          if (msg.isNotEmpty) {
            window.localStorage['signin'] = data;
            return User._(
                data.substring(0, data.indexOf(msgRecordSeparator)), msg);
          }
          window.localStorage['signin'] = null;
          return null;
        });

  /// Вход с помощью сохранённых данных
  static Future<User> signByIndexDB() => signin(window.localStorage['signin']);
}
