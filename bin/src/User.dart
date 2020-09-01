import 'dart:convert';
import 'dart:io';

/// Класс содержащий данные о пользователе, а так же хранящий всех пользователей
class User {
  final String mail;
  final String pass;
  final String access;

  Map<String, dynamic> toJson() =>
      {'mail': mail, 'pass': pass, 'access': access};

  User._fromJson(final Map v)
      : mail = v['mail'],
        pass = v['pass'],
        access = v['access'];
  const User._(this.mail, this.pass, [this.access = '']);

  @override
  String toString() => mail;

  static const User guest = User._('guest', '', 'a');

  static final _list = <User>[];

  /// Получает данные пользователя, если он существует
  static User get(final String mail, final String pass) => _list
      .firstWhere((e) => e.mail == mail && e.pass == pass, orElse: () => null);

  /// Создаёт пользователя, если он не существует, возвращает данные пользователя
  static User reg(final String mail, final String pass) {
    if (_list.any((e) => e.mail == mail)) {
      return null;
    }
    final _user = User._(mail, pass, 'a');
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
