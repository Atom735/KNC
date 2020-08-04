import 'dart:typed_data';
import 'dart:io';

import 'package:knc/async.dart';
import 'mapping.dart';

/// Архиватор
class Archiver {
  /// Путь к программе архиватору
  final String p7z;

  /// Очередь выполнения
  AsyncTaskQueue queue;

  /// Временная папка содержащая все временные функции разархивирования
  final Directory dir;

  Archiver(this.p7z, this.dir, [this.queue]);

  /// Очищает и пересоздаёт временную папку указанную в [pathToTempDir] при создании объекта
  Future<void> clear() => dir.exists().then((exist) => exist
      ? dir.delete(recursive: true).then((_) => dir.create(recursive: true))
      : dir.create(recursive: true));

  /// Распаковывает архив [pathToArchive] в папку [pathToOutDir] если она указана.
  /// Если папка [pathToOutDir] не задана, то будет создана
  /// внутреняя временная папка, которая будет удалена по завершению работ
  ///
  /// Возвращает строку ошибки
  /// - первый символ означает тип ошибки
  /// - тело сообщения между `:` и `#`
  /// - следом между кавычками идёт имя выходной папки
  /// - следом до символов `^!@#$` идёт строка стандартного вывода идёт
  /// - следом идёт строка вывода ошибок идёт
  ///
  /// Первый символ:
  /// - `O` - нет ошибки
  /// - `W` - предупреждение
  /// - `E` - ошибка
  Future<String> unzip(String pathToArchive,
          [String pathToOutDir, final Map<String, List<String>> charMaps]) =>
      pathToOutDir == null
          ? (dir
              .createTemp('arch.')
              .then((temp) => unzip(pathToArchive, temp.path, charMaps)))
          : queue != null
              ? (queue.addTask(() => Process.run(p7z, ['x', '-o$pathToOutDir', pathToArchive, '-scsUTF-8'], stdoutEncoding: null, stderrEncoding: null)
                  .then((result) => results(result.exitCode, result.stdout,
                      result.stderr, pathToOutDir, charMaps))))
              : Process.run(p7z, ['x', '-o$pathToOutDir', pathToArchive, '-scsUTF-8'], stdoutEncoding: null, stderrEncoding: null)
                  .then((result) => results(result.exitCode, result.stdout, result.stderr, pathToOutDir, charMaps));

  /// Запаковывает данные внутри папки [pathToData] в zip архиф [pathToOutput]
  /// с помощью 7zip
  ///
  /// Возвращает строку ошибки
  /// - первый символ означает тип ошибки
  /// - тело сообщения между `:` и `#`
  /// - следом между кавычками идёт имя выходной папки
  /// - следом до символов `^!@#$` идёт строка стандартного вывода идёт
  /// - следом идёт строка вывода ошибок идёт
  ///
  /// Первый символ:
  /// - `O` - нет ошибки
  /// - `W` - предупреждение
  /// - `E` - ошибка
  Future<String> zip(final String pathToData, final String pathToOutput,
          [final Map<String, List<String>> charMaps]) =>
      queue != null
          ? queue.addTask(() => Process.run(p7z, ['a', '-tzip', pathToOutput, '*', '-scsUTF-8'], workingDirectory: pathToData, stdoutEncoding: null, stderrEncoding: null).then((result) => results(
              result.exitCode,
              result.stdout,
              result.stderr,
              pathToOutput,
              charMaps)))
          : Process.run(p7z, ['a', '-tzip', pathToOutput, '*', '-scsUTF-8'],
                  workingDirectory: pathToData,
                  stdoutEncoding: null,
                  stderrEncoding: null)
              .then((result) => results(result.exitCode, result.stdout, result.stderr, pathToOutput, charMaps));

  /// Возвращает строку ошибки
  /// - первый символ означает тип ошибки
  /// - тело сообщения между `:` и `#`
  /// - следом между кавычками идёт имя выходной папки
  /// - следом до символов `^!@#$` идёт строка стандартного вывода идёт
  /// - следом идёт строка вывода ошибок идёт
  ///
  /// Первый символ:
  /// - `O` - нет ошибки
  /// - `W` - предупреждение
  /// - `E` - ошибка
  static String results(final int exitCode, final stdOut, final stdErr,
      final String pathToOutput, final Map<String, List<String>> charMaps) {
    var sOut = '';
    var sErr = '';
    if (stdOut != null) {
      if (stdOut is List<int> && charMaps != null) {
        final encodesRaiting = getMappingRaitings(charMaps, stdOut);
        final encode = getMappingMax(encodesRaiting);
        // Преобразуем байты из кодировки в символы
        final buffer = String.fromCharCodes(stdOut.map(
            (i) => i >= 0x80 ? charMaps[encode][i - 0x80].codeUnitAt(0) : i));
        sOut = buffer;
      } else if (stdOut is String) {
        sOut = stdOut;
      }
    }
    if (stdErr != null) {
      if (stdErr is List<int> && charMaps != null) {
        final encodesRaiting = getMappingRaitings(charMaps, stdErr);
        final encode = getMappingMax(encodesRaiting);
        // Преобразуем байты из кодировки в символы
        final buffer = String.fromCharCodes(stdErr.map(
            (i) => i >= 0x80 ? charMaps[encode][i - 0x80].codeUnitAt(0) : i));
        sErr = buffer;
      } else if (stdErr is String) {
        sErr = stdErr;
      }
    }
    var sCode = '';
    switch (exitCode) {
      case 0:
        sCode = 'O:';
        break;
      case 1:
        sCode =
            r'W:(Non fatal error(s)). For example, one or more files were locked by some other application, so they were not compressed.';
        break;
      case 2:
        sCode = r'E:Fatal error';
        break;
      case 7:
        sCode = r'E:Command line error';
        break;
      case 8:
        sCode = r'E:Not enough memory for operation';
        break;
      case 255:
        sCode = r'E:User stopped the process';
        break;
      default:
        sCode = r'E:Unknown error';
    }
    return '${sCode}#"${pathToOutput}"${sOut}^!@#\$${sErr}';
  }
}
