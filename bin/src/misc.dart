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

/// Функция попытки выполнения.
///
/// Цыклически выполняет заданную функцию [func], пока не перестанут выподать
/// исключения.
/// * [tryesMax] - задаёт количество попыток
/// * [tryesDuration] - задаёт время в милисекундах между попытками
Future<T> tryFunc<T>(Future<T> Function() func,
    {T Function(dynamic)? onError,
    int tryesMax = _tryesMax,
    int tryesDuration = _tryesDuration}) async {
  /// пытаемся выполнить операцию
  try {
    /// Если попытка успешная, то выходим
    return await func();
  } catch (e) {
    /// Ждём повторной попытки
    await Future.delayed(Duration(milliseconds: tryesDuration));
    var _tryes = 0;
    while (_tryes < tryesMax) {
      try {
        /// Если попытка успешная, то выходим
        return await func();
      } catch (e) {
        /// Ждём повторной попытки
        await Future.delayed(Duration(milliseconds: tryesDuration));
        _tryes++;
        if (_tryes >= tryesMax) {
          /// Превысили количество попыток
          if (onError != null) {
            return onError(e);
          }
        }
        rethrow;
      }
    }
    rethrow;
  }
}
