import 'dart:convert';
import 'dart:io';

import 'package:knc/knc.dart';

import 'misc.dart';

/// Данные пользователя на сервере
class User extends JUser {
  /// База даных всех пользователей
  static final dataBase = <String, User>{};

  /// Создаёт нового пользователя и регистрирует его в базе данных
  User.fromJson(Map<String, Object> m) : super.fromJson(m) {
    if (dataBase[mail] != null) {
      throw Exception('Такой пользователь уже существует');
    }
    dataBase[mail] = this;
  }

  /// Загружает данные всех пользователей
  static Future<void> load() =>
      tryFunc(File('data/users.json').exists).then((b) => b
          ? tryFunc(File('data/users.json').readAsString).then((data) =>
              (jsonDecode(data) as List).forEach((m) => User.fromJson(m)))
          : null);

  /// Сохраняет данные всех пользователей
  static Future<void> save() =>
      File('data/users.json').writeAsString(jsonEncode(dataBase.values));
}
