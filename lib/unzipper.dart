import 'dart:io';

class Unzipper {
  final String pathToTempDir;
  final String pathTo7z;
  Directory _dirTemp;

  Unzipper(this.pathToTempDir, this.pathTo7z) {
    _dirTemp = Directory(pathToTempDir);
  }

  /// Очищает и пересоздаёт временную папку указанную в [pathToTempDir] при создании объекта
  Future<void> clear() => _dirTemp.exists().then((exist) => exist
      ? _dirTemp
          .delete(recursive: true)
          .then((_) => _dirTemp.create(recursive: true))
      : _dirTemp.create(recursive: true));

  /// Распаковывает архив [pathToArchive] в папку [pathToOutDir] если она указана.
  /// Если папка [pathToOutDir] не задана, то будет создана
  /// внутреняя временная папка, которая будет удалена по завершению работ
  Future unzip(String pathToArchive,
      [Future Function(FileSystemEntity entity, String relPath) funcEntity,
      Future Function(dynamic taskListEnded) funcEnd,
      String pathToOutDir]) {
    if (pathToOutDir == null) {
      return _dirTemp.createTemp().then((dirTemp) =>
          unzip(pathToArchive, null, null, dirTemp.path).then((result) {
            if (result == null) {
              final tasks = <Future>[];
              return dirTemp
                  .list(recursive: true, followLinks: false)
                  .listen((entityInZip) {
                    if (funcEntity != null) {
                      tasks.add(funcEntity(entityInZip,
                          entityInZip.path.substring(dirTemp.path.length)));
                    }
                  })
                  .asFuture(tasks)
                  .then(
                      (taskList) => Future.wait(taskList).then((taskListEnded) {
                            if (funcEnd != null) {
                              return funcEnd(taskListEnded)
                                  .then((_) => dirTemp.delete(recursive: true));
                            } else {
                              return dirTemp.delete(recursive: true);
                            }
                          }));
            } else {
              return result;
            }
          }));
    } else {
      return Process.run(pathTo7z, ['x', '-o$pathToOutDir', pathToArchive])
          .then((result) {
        switch (result.exitCode) {
          case 0:
            return Future.value(null);
          case 1:
            return Future.value(
                r'[7z]: Warning (Non fatal error(s)). For example, one or more files were locked by some other application, so they were not compressed.');
          case 2:
            return Future.error(r'[7z]: Fatal error');
          case 7:
            return Future.error(r'[7z]: Command line error');
          case 8:
            return Future.error(r'[7z]: Not enough memory for operation');
          case 255:
            return Future.error(r'[7z]: User stopped the process');
          default:
            return Future.error('[7z]: Unknown error');
        }
      });
    }
  }
}
