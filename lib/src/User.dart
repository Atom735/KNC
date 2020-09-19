/// Вход на сервер возможен с помощью отправки почты и шифрованного пароля
/// с помощью метода `POST`, тогда вебклиенту возвращается строка прав доступа
/// и другие данные пользователя...
///
/// - `mail` и `pass` храним в `Cookie` браузера для послебующих запросов
/// - `WebSocket` соединение считается постоянным и не требует идентификации
/// при каждом запросе

/// Класс содержащий данные о пользователе
class JUser {
  /// Имя пользователя
  final String? firstName;
  static const jsonKey_firstName = r'first_name';

  /// Фамилия пользователя
  final String? secondName;
  static const jsonKey_secondName = r'second_name';

  /// Почта пользователя
  final String mail;
  static const jsonKey_mail = r'mail';

  /// Захешированная в `md5` строка пароля
  final String pass;
  static const jsonKey_pass = r'pass';

  /// Символы доступа пользователя
  final String access;
  static const jsonKey_access = r'access';

  @override
  String toString() => '$firstName($mail)';

  Map<String, dynamic> toJson() => {
        jsonKey_firstName: firstName,
        jsonKey_secondName: secondName,
        jsonKey_mail: mail,
        jsonKey_pass: pass,
        jsonKey_access: access,
      };

  JUser.fromJson(final Map<String, Object> m)
      : firstName = m[jsonKey_firstName] as String?,
        secondName = m[jsonKey_secondName] as String?,
        mail = m[jsonKey_mail] as String,
        pass = m[jsonKey_pass] as String,
        access = m[jsonKey_access] as String;
  const JUser(
    this.mail,
    this.pass,
    this.access, {
    this.firstName,
    this.secondName,
  });
}
