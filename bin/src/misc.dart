import 'dart:io';

String numToXlsAlpha(int i) {
  return ((i >= 26) ? numToXlsAlpha((i ~/ 26) - 1) : '') +
      String.fromCharCode('A'.codeUnits[0] + (i % 26));
}

Future<void> copyDirectoryRecursive(
    final Directory i, final Directory o) async {
  await o.create();
  final entitys = await i.list();
  await for (var entity in entitys) {
    if (entity is File) {
      await entity.copy(o.path + entity.path.substring(i.path.length));
    } else if (entity is Directory) {
      await copyDirectoryRecursive(
          entity, Directory(o.path + entity.path.substring(i.path.length)));
    }
  }
}

/// Количество попыток
const _tryesMax = 128;

/// Время ожидания для повторной попытки
const _tryesDuration = 16;

/// Функция попытки выполнения
Future<T> tryFunc<T>(Future<T> Function() func,
    [T Function(dynamic) onError]) async {
  /// пытаемся выполнить операцию
  var _tryes = 0;
  var _e;
  var _o;
  while (_tryes < _tryesMax) {
    try {
      /// Если попытка успешная, то выходим из цикла
      _o = await func();
      _e = null;
      break;
    } catch (e) {
      /// Ждём повторной попытки
      await Future.delayed(Duration(milliseconds: _tryesDuration));
      _tryes++;
      _e = e;
    }
  }
  if (_tryes >= _tryesMax) {
    /// Превысили количество попыток
    _o = onError != null ? onError(_e) : null;
  }
  return _o;
}
