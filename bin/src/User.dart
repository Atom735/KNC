import 'dart:convert';
import 'dart:io';

import 'package:knc/knc.dart';

import 'misc.dart';

/// Данные пользователя на сервере
class User extends JUser {
  /// База даных всех пользователей, ключами является [mail]`.toLowerCase()`
  static final dataBase = <String, User>{};

  /// Планировщик перезаписывания базы данных
  static Future<void>? _futureSaveBase;

  static final _fileBase = File('data/users.json');

  /// Создаёт нового пользователя и регистрирует его в базе данных
  User.fromJson(final Map<String, dynamic> m) : super.fromJson(m) {
    final _mail = (dataBase[mail] as String).toLowerCase();
    if (dataBase[_mail] != null) {
      throw Exception('Такой пользователь уже существует');
    }
    dataBase[_mail] = this;

    /// Перезаписываем базу данных, через 333мс, после изменений
    _futureSaveBase =
        _futureSaveBase ?? Future.delayed(Duration(milliseconds: 333), save);
  }

  /// Загружает данные всех пользователей
  static Future<void> load() async {
    if (await _fileBase.exists()) {
      (jsonDecode(await tryFunc(_fileBase.readAsString)) as List)
          .forEach((m) => User.fromJson(m));
      print('База данных пользователей загружена!');
    }
  }

  /// Сохраняет данные всех пользователей
  static Future<void> save() {
    final _data = jsonEncode(dataBase.values);
    _futureSaveBase = null;
    return tryFunc(() => _fileBase.writeAsString(_data));
  }
}
