import 'dart:convert';
import 'dart:io';

/// Класс содержащий данные о пользователе
/// name fname mname lname	name (full name) given-name (first name) additional-name (middle name) family-name (last name)
class User {
  /// name (full name)
  ///
  /// Полное имя
  final String name;

  /// given-name (first name)
  ///
  /// Имя
  final String fname;

  /// additional-name (middle name)
  ///
  /// Отчество
  final String mname;

  /// family-name (last name)
  ///
  /// Фамилия
  final String lname;

  /// Почта пользователя
  final String email;

  /// Номер телефона
  final String phone;

  /// Пароль зашифрованный через функцию [passwordEncode]
  final String pass;

  /// Символы доступа пользователя
  final String access;

  /// Ключи доступа
  final tokens = <UserSessionToken>[];

  User(
    this.pass, {
    this.name = '',
    this.fname = '',
    this.mname = '',
    this.lname = '',
    this.email = '',
    this.phone = '',
    this.access = '',
  });

  static final guest = User('');

  factory User.fromJson(Map<String, dynamic> map) => User(
        map['pass'],
        name: map['name'] ?? '',
        fname: map['fname'] ?? '',
        mname: map['mname'] ?? '',
        lname: map['lname'] ?? '',
        email: map['email'] ?? '',
        phone: map['phone'] ?? '',
        access: map['access'] ?? '',
      );

  Map<String, dynamic> toJson() => {
        'pass': pass,
        'name': name,
        'fname': fname,
        'mname': mname,
        'lname': lname,
        'email': email,
        'phone': phone,
        'access': access,
      };

  /// Отправляет клиенту данные о пользователе
  String toWsMsg() => jsonEncode(toJson()..remove('pass'));
}

class UserSessionToken {
  /// Почта пользователя
  final User user;

  /// Сам токен
  final String token;

  /// Символы доступа токена
  final String access;

  final List<WebSocket> websockets = [];

  UserSessionToken(this.user, this.token, this.access);

  static final guest = UserSessionToken(User.guest, '', '');

  factory UserSessionToken.fromJson(Map<String, dynamic> map, User user) =>
      UserSessionToken(
        user,
        map['token'],
        map['access'],
      );

  Map<String, dynamic> toJson() => {
        'email': user.email,
        'token': token,
        'access': access,
      };
}
