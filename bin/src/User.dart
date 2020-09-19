import 'dart:convert';
import 'dart:io';

import 'package:knc/knc.dart';

class User extends JUser {

  /// База даных всех пользователей
  static final dataBase = <User>{};

  User._fromJson(Map<String, Object> _) : super.fromJson(_);

  static final


  /// Получает данные пользователя, если он существует
  static User? get(final String mail, final String pass) => dataBase
      .firstWhere((e) => e.mail == mail && e.pass == pass, orElse: () => null);

}

/// Список пользователей
static final _list = <User>[];

  /// Получает данные пользователя, если он существует
  static User? get(final String mail, final String pass) => _list
      .firstWhere((e) => e.mail == mail && e.pass == pass, orElse: () => null);

  /// Создаёт пользователя, если он не существует, возвращает данные пользователя
  static User? reg(final String mail, final String pass,
      [final String? firstName, final String? secondName]) {
    if (_list.any((e) => e.mail == mail)) {
      return null;
    }
    final _user = User._(
      mail,
      pass,
      '0',
      firstName: firstName,
      secondName: secondName,
    );
    _list.add(_user);
    save();
    return _user;
  }

  /// Загружает данные всех пользователей
  static Future<void> load() => File('data/users.json').exists().then((b) => b
      ? File('data/users.json').readAsString().then((data) => _list
          .addAll((jsonDecode(data) as List).map((e) => User._fromJson(e))))
      : null);

  /// Сохраняет данные всех пользователей
  static Future<void> save() =>
      File('data/users.json').writeAsString(jsonEncode(_list));
}
