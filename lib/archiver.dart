import 'dart:io';
import 'async.dart';

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
  Future unzip(String pathToArchive,
          [Future Function(FileSystemEntity entity, String relPath) funcEntity,
          Future Function(dynamic taskListEnded) funcEnd,
          String pathToOutDir]) =>
      pathToOutDir == null
          ? (dir.createTemp().then((temp) =>
              unzip(pathToArchive, null, null, temp.path).then((result) {
                if (result == null) {
                  final tasks = <Future>[];
                  return temp
                      .list(recursive: true, followLinks: false)
                      .listen((entityInZip) {
                        if (funcEntity != null) {
                          tasks.add(funcEntity(entityInZip,
                              entityInZip.path.substring(temp.path.length)));
                        }
                      })
                      .asFuture(tasks)
                      .then((taskList) =>
                          Future.wait(taskList).then((taskListEnded) {
                            if (funcEnd != null) {
                              return funcEnd(taskListEnded)
                                  .then((_) => temp.delete(recursive: true));
                            } else {
                              return temp.delete(recursive: true);
                            }
                          }));
                } else {
                  return result;
                }
              })))
          : queue != null
              ? (queue.addTask(() =>
                  Process.run(p7z, ['x', '-o$pathToOutDir', pathToArchive])))
              : Process.run(p7z, ['x', '-o$pathToOutDir', pathToArchive])
                  .then((result) => results(result.exitCode));

  /// Запаковывает данные внутри папки [pathToData] в zip архиф с помощью 7zip
  Future zip(final String pathToData, final String pathToOutput) =>
      Process.run(p7z, ['a', '-tzip', pathToOutput, '*'],
              workingDirectory: pathToData)
          .then((result) => results(result.exitCode));

  /// Возвращает Future с ошибкой, если произошла ошибка
  static Future results(final int exitCode) {
    switch (exitCode) {
      case 0:
        return Future.value(null);
      case 1:
        return Future.value(
            r'Warning (Non fatal error(s)). For example, one or more files were locked by some other application, so they were not compressed.');
      case 2:
        return Future.error(r'Fatal error');
      case 7:
        return Future.error(r'Command line error');
      case 8:
        return Future.error(r'Not enough memory for operation');
      case 255:
        return Future.error(r'User stopped the process');
      default:
        return Future.error('Unknown error');
    }
  }
}
