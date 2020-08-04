import 'dart:io';

import 'package:knc/ArchiverOtput.dart';
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
  Future<ArchiverOutput> unzip(String pathToArchive,
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
  Future<ArchiverOutput> zip(final String pathToData, final String pathToOutput,
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

  static ArchiverOutput results(final int exitCode, final stdOut, final stdErr,
      final String pathToOutput, final Map<String, List<String>> charMaps) {
    String sOut;
    String sErr;
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
    return ArchiverOutput(pathToOutput, exitCode, sOut, sErr);
  }
}
