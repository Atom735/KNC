import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

import 'mapping.dart';

/// Личные данные каждого изолята
class IsoData {
  final int id; // Номер изолята (начиная с 1)
  final SendPort sendPort; // Порт для передачи данных главному изоляту
  final Map<String, List<String>> charMaps; // Таблицы кодировок
  final String pathOut;

  int iErrors; // Количество ошибок
  IOSink fErrors; // Файл для записи ошибок

  IsoData(final int id, final SendPort sendPort, final charMaps,
      final String pathOut)
      : id = id,
        sendPort = sendPort,
        charMaps = Map.unmodifiable(charMaps),
        pathOut = pathOut;
}

void runIsolate(final IsoData iso) {
  // ===========================================================================
  final receivePort = ReceivePort(); // Порт прослушиваемый изолятом
  var tasks = <Future>[];

  Directory(iso.pathOut + '/errors/${iso.id}').createSync(recursive: true);
  iso.iErrors = 0;
  iso.fErrors = File(iso.pathOut + '/errors/${iso.id}/__.txt')
      .openWrite(mode: FileMode.writeOnly, encoding: utf8);

  receivePort.listen((final msg) {
    // Прослушивание сообщений полученных от главного изолята
    if (msg is String) {
      // Сообщение о закрытии
      if (msg == '-e') {
        Future.wait(tasks).then((final v) {
          iso.fErrors.flush().then((final v) {
            iso.fErrors.close().then((final v) {
              print('sub[${iso.id}]: end');
              iso.sendPort.send([iso.id, '+e']);
            });
          });
        });
        receivePort.close();
        return;
      }
    } else if (msg is File) {
      if (msg.path.toLowerCase().endsWith('.las')) {
        // futures.add(parseLas(iso, msg));
        return;
      }
    }
    print('sub[${iso.id}]: recieved unknown msg {$msg}');
    // sleep(Duration(milliseconds: 300));
  });

  // Отправка данных для порта входящих сообщений
  print('sub[${iso.id}]: sync main');
  iso.sendPort.send([iso.id, receivePort.sendPort]);
  return;
}

Future<void> main(List<String> args) async {
  // Таблицы кодировок
  final charMaps = Map.unmodifiable(await loadMappings('mappings'));
  // Количество потоков
  const isoCount = 3;
  // Порты для передачи данных вспомогательным изолятам
  final isoSends = List<SendPort>(isoCount);
  // Количество задач у каждого вспомогательного изолята в очереди
  final isoTasks = List<int>.filled(isoCount, 0);
  final isolate = List<Future<Isolate>>(isoCount);
  // Порт прослушиваемый главным изолятом
  final receivePort = ReceivePort();

  // Путь для поиска файлов
  final pathIn = [r'\\NAS\Public\common\Gilyazeev\ГИС\Искринское м-е'];
  // Путь для выходных данных
  final pathOut = r'.ag47';
  final dirOut = Directory(pathOut);

  var tasks = <Future>[];

  if (dirOut.existsSync()) {
    dirOut.deleteSync(recursive: true);
  }
  dirOut.createSync(recursive: true);

  /// Проверяет кончились ли у изолятов задачи на выполнение
  bool isoTasksZero() {
    for (final i in isoTasks) {
      if (i != 0) {
        return false;
      }
    }
    return true;
  }

  /// Оптравить сообщение всем изолятам
  void isoSendToAll(final msg) {
    for (var i = 0; i < isoCount; i++) {
      print('main: send to sub[${i + 1}] "$msg"');
      isoTasks[i] += 1;
      isoSends[i].send(msg);
    }
  }

  /// Отправить сообщение наименее занятому изоляту
  void isoSendToIdle(final msg) {
    var j = 0;
    for (var i = 0; i < isoCount; i++) {
      if (isoTasks[i] < isoTasks[j]) {
        j = i;
      }
    }
    isoTasks[j] += 1;
    isoSends[j].send(msg);
  }

  // Слушаем порт, ждём отчётов от сообщений
  receivePort.listen((final msg) {
    if (msg is List) {
      if (msg[1] is SendPort) {
        // Передача порта для связи
        isoTasks[msg[0] - 1] = 0;
        isoSends[msg[0] - 1] = msg[1];
        print('main: sub[${msg[0]}] synced');
        if (isoTasksZero()) {
          print('main: all subs synced');
          // Начинаем работу после создания изолятов и их синхронизации

          // TODO: follow links
          // TODO: follow archives
          for (var path in pathIn) {
            tasks.add(FileSystemEntity.type(path, followLinks: false)
                .then((final entity) {
              switch (entity) {
                case FileSystemEntityType.directory:
                  // Если указанный путь -> папка, обходим все сущности внутри папки
                  return Directory(path)
                      .list(recursive: true, followLinks: false)
                      .listen((final e) {
                    if (e is File) {
                      // Если сущность файл, то отправляем на обработку
                      final ePath = e.path.toLowerCase();
                      if (ePath.endsWith('.las') ||
                          ePath.endsWith('.dbf') ||
                          ePath.endsWith('.txt') ||
                          ePath.endsWith('.doc') ||
                          ePath.endsWith('.docx')) {
                        isoSendToIdle(e);
                      }
                    }
                  }).asFuture();
                case FileSystemEntityType.file:
                  // Если указанный путь -> файл, отправляем на обработку
                  final ePath = path.toLowerCase();
                  if (ePath.endsWith('.las') ||
                      ePath.endsWith('.dbf') ||
                      ePath.endsWith('.txt') ||
                      ePath.endsWith('.doc') ||
                      ePath.endsWith('.docx')) {
                    isoSendToIdle(File(path));
                  }
                  return Future.value(0);
              }
              return Future.error('Unknown File Entity ${entity}');
            }));
          }
          // Все обходы заверешны и файлы разосланы
          Future.wait(tasks).then((e) {
            isoSendToAll('-e');
          });
        }
        return;
      } else if (msg[1] is String) {
        if (msg[1] == '+e') {
          // Ответ на просьбу закрыться
          print('main: sub[${msg[0]}] ended');
          if (isoTasks[msg[0] - 1] != 1) {
            print('WARNING: sub[${msg[0]}] have ${isoTasks[msg[0] - 1]} tasks');
          }

          isoTasks[msg[0] - 1] = 0;
          if (isoTasksZero()) {
            // Если все изоляты закончили работу
            print('main: all subs ended');
            // Закрываем порт
            receivePort.close();
          }
          return;
        } else if (msg[1] == '+las') {
          // Обработан LAS файл и данные корректны
          isoTasks[msg[0] - 1] -= 1;
          print('main: sub[${msg[0]}] have ${isoTasks[msg[0] - 1]} tasks');
          return;
        } else if (msg[1] == '-las') {
          // Обработан LAS файл, но произошла ошибка
          isoTasks[msg[0] - 1] -= 1;
          print('main: sub[${msg[0]}] have ${isoTasks[msg[0] - 1]} tasks');
          return;
        }
      }
    }

    print('main: recieved unknown msg {$msg}');
  });

  // Создание изолятов
  for (var i = 0; i < isoCount; i++) {
    final data = IsoData(i + 1, receivePort.sendPort, charMaps, pathOut);
    isoTasks[i] = -1;
    print('main: spawn sub[${i + 1}]');
    isolate[i] = Isolate.spawn(runIsolate, data, debugName: 'sub[${i + 1}]');
  }
  // Ожидаем создания
  await Future.wait(isolate);
  print('main: all subs spawned');
}
