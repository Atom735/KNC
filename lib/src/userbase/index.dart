import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';

import 'structs.dart';
export 'structs.dart';

final _fileBase = File('data/users.json');

/// key - email
final Map<String, User> userbaseUsers = {};

/// key - token
final Map<String, UserSessionToken> userbaseTokens = {};

/// Преоразует строку пароля в шифрованный пароль
String passwordEncode(final String pass) => sha256.convert([
      ...'0x834^'.codeUnits,
      ...pass.codeUnits,
      ...'x12kdasdj'.codeUnits
    ]).toString();

/// Загружает данные всех пользователей
void userbaseLoad() {
  userbaseUsers.clear();
  userbaseTokens.clear();
  if (_fileBase.existsSync()) {
    final map = jsonDecode(_fileBase.readAsStringSync());
    final mapUsers = map['users'] as List;
    final mapTokens = map['tokens'] as List;

    for (final mapUser in mapUsers) {
      final user = User.fromJson(mapUser);
      userbaseUsers[user.email.toLowerCase()] = user;
    }

    for (final mapToken in mapTokens) {
      final email = mapToken['email'];
      final token = UserSessionToken.fromJson(
          mapToken, userbaseUsers[email.toLowerCase()]);
      userbaseTokens[token.token] = token;
    }
  }
}

/// Загружает данные всех пользователей
void userbaseSave() => _fileBase.writeAsStringSync(jsonEncode({
      'users': [...userbaseUsers.values.map((e) => e.toJson())],
      'tokens': [...userbaseTokens.values.map((e) => e.toJson())]
    }));

/// Создать нового пользователя
User userNew(final User user) {
  if (userbaseUsers.containsKey(user.email.toLowerCase())) {
    throw Exception('Этот email уже зарегестрирован');
  }
  userbaseUsers[user.email.toLowerCase()] = user;
  return user;
}

int _userTokenGeneratorCount = 0;

/// Получает новый ключ сессии для пользователя
UserSessionToken userNewToken(final User user) {
  final token = sha512.convert([
    ..._userTokenGeneratorCount.toString().codeUnits,
    ...jsonEncode(user.toJson()).codeUnits,
    ...DateTime.now().toString().codeUnits
  ]).toString();
  if (userbaseTokens.containsKey(token)) {
    return userNewToken(user);
  }
  return userbaseTokens[token] = UserSessionToken(user, token, user.access);
}
