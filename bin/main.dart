import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';
import 'dart:math';

import 'package:knc/mapping.dart';

/// Las outer data [$WELL, $METHOD, $STRT, $STOP]
/// Ink outer data [$WELL, $STRT, $STOP]

List<String> pathToList(final String path) =>
    path.split(r'\').expand((e) => e.split(r'/')).toList();

Future<ProcessResult> runZip(
    final String path2exe, final String path2arch, final String path2out) {
  final pathList = pathToList(path2exe.toLowerCase());
  if (pathList.last == '7z.exe') {
    // 7z <x или e> <архивный файл> -o"<путь, куда распаковываем>"
    return Process.run(path2exe, ['x', '-o$path2out', path2arch]);
  }
  return Future.error(r'Not valid path to 7z.exe');
}

Future<ProcessResult> runDoc2X(
    final String path2exe, final String path2doc, final String path2out) {
  final pathList = pathToList(path2exe.toLowerCase());
  if (pathList.last == 'doc2x.exe') {
    // [-c | inputfile] [-o outputfile] [-v level] [-?]
    return Process.run(path2exe, [path2doc, '-o', path2out]);
  }
  if (pathList.last == 'wordconv.exe') {
    // -oice -nme <input file> <output file>
    return Process.run(path2exe, ['-oice', '-nme', path2doc, path2out]);
  }
  return Future.error(r'Not valid path to doc converter');
}

/// Личные данные каждого изолята
class IsoData {
  /// Номер изолята (начиная с 1)
  final int id;

  /// Порт для передачи данных главному изоляту
  final SendPort sendPort;

  /// Таблицы кодировок
  final Map<String, List<String>> charMaps;

  /// Путь к конечным файлам
  final String pathOut;

  /// Путь к программе архиватору (7Zip)
  final String pathBin_zip;

  /// Путь к программе конвертеру Doc файлов (Wordconv, doc2x)
  final String pathBin_doc2x;

  int iErrors; // Количество ошибок
  IOSink fErrors; // Файл для записи ошибок
  Random
      randomTemp; // Рандомизатор для создания временных фалов или папок в temp

  IsoData(
      final int id,
      final SendPort sendPort,
      final charMaps,
      final String pathOut,
      final String pathBin_zip,
      final String pathBin_doc2x)
      : id = id,
        sendPort = sendPort,
        charMaps = Map.unmodifiable(charMaps),
        pathOut = pathOut,
        pathBin_zip = pathBin_zip,
        pathBin_doc2x = pathBin_doc2x;
}

String getRnadomName(final IsoData iso) =>
    iso.pathOut +
    '/temp/${iso.id}/0x' +
    iso.randomTemp.nextInt(1 << 16).toRadixString(16).padLeft(16, '0');

// ===========================================================================
void runIsolate(final IsoData iso) {
  // Порт прослушиваемый изолятом
  final receivePort = ReceivePort();
  final tasks = <Future>[];

  Directory(iso.pathOut + '/errors/${iso.id}').createSync(recursive: true);
  Directory(iso.pathOut + '/las/${iso.id}').createSync(recursive: true);
  Directory(iso.pathOut + '/temp/${iso.id}').createSync(recursive: true);
  iso.randomTemp = Random(iso.id);

  iso.iErrors = 0;
  iso.fErrors = File(iso.pathOut + '/errors/${iso.id}/__.txt')
      .openWrite(mode: FileMode.writeOnly, encoding: utf8);
  iso.fErrors.writeCharCode(unicodeBomCharacterRune); // BOM

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
      final path = msg.path.toLowerCase();
      // TODO: Parse File
      if (path.endsWith('.las')) {
        tasks.add(parseLas(iso, msg));
        return;
      } else if (path.endsWith('.doc')) {
        tasks.add(parseDoc(iso, msg));
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

Future parseDocX(final IsoData iso, final File file) async {
  final path = getRnadomName(iso);
  await runZip(iso.pathBin_zip, file.path, path);
}

Future parseDoc(final IsoData iso, final File file) async {
  final path = getRnadomName(iso) + '.docx';
  await runDoc2X(iso.pathBin_doc2x, file.path, path);
  return parseDocX(iso, file).then((v) => File(path).delete());
}

Future parseLas(final IsoData iso, final File file) async {
  // Считываем данные файла (Асинхронно)
  final bytes = await file.readAsBytes();
  // Подбираем кодировку
  final cp = getMappingMax(getMappingRaitings(iso.charMaps, bytes));
  final buffer = String.fromCharCodes(bytes
      .map((i) => i >= 0x80 ? iso.charMaps[cp][i - 0x80].codeUnitAt(0) : i));
  // Нарезаем на линии
  final lines = LineSplitter.split(buffer);
  var lineNum = 0;
  var iErrors = 0;
  Future futureCopyFile;

  var section = '';
  String vVers;
  String vWrap;
  String wNull;
  double wNullN;
  String wStrt;
  double wStrtN;
  String wStop;
  double wStopN;
  String wStep;
  double wStepN;
  String wWell;
  final methods = <String>[];
  List<String> methodsStrt;
  List<double> methodsStrtN;
  List<String> methodsStop;
  List<double> methodsStopN;

  void logError(final String txt) {
    if (iErrors == 0) {
      iso.iErrors += 1;
      iso.fErrors.writeln(file);
      final newPath = iso.pathOut + '/errors/${iso.id}/${iso.iErrors}.las';
      iso.fErrors.writeln('\t$newPath');
      futureCopyFile = file.copy(newPath);
    }
    iErrors += 1;
    iso.fErrors.writeln('\t[$iErrors]\tСтрока:$lineNum\t$txt');
  }

  var iA = 0;
  lineLoop:
  for (final lineFull in lines) {
    lineNum += 1;
    final line = lineFull.trim();
    if (line.isEmpty || line.startsWith('#')) {
      // Пустую строку и строк с комментарием пропускаем
      continue lineLoop;
    } else if (section == 'A') {
      // ASCII Log Data Section

      for (final e in line.split(' ')) {
        if (e.isNotEmpty) {
          var val = double.tryParse(e);
          if (val == null) {
            logError(r'Ошибка в разборе числа');
            break lineLoop;
          }
          if (vWrap == 'NO' && iA >= methods.length) {
            logError(r'Слишком много чисел в линии');
            break lineLoop;
          }
          if (val != wNullN) {
            if (iA != 0) {
              if (methodsStrt[iA] == null) {
                methodsStrt[iA] = methodsStop[0];
                methodsStrtN[iA] = methodsStopN[0];
              }
              methodsStop[iA] = methodsStop[0];
              methodsStopN[iA] = methodsStopN[0];
            } else {
              if (methodsStrt[iA] == null) {
                methodsStrt[iA] = e;
                methodsStrtN[iA] = val;
              }
              methodsStop[iA] = e;
              methodsStopN[iA] = val;
            }
          }
          iA += 1;
          if (vWrap == 'YES' && iA >= methods.length) {
            iA = 0;
          }
        }
      }

      if (vWrap == 'NO') {
        if (iA == methods.length) {
          iA = 0;
        } else {
          logError(r'Ошибка в количестве чисел в линии');
          break lineLoop;
        }
      }

      continue lineLoop;
    } else if (line.startsWith('~')) {
      // Заголовок секции
      section = line[1];
      switch (section) {
        case 'A': // ASCII Log data
          if (iErrors > 0) {
            break lineLoop;
          } else if (vVers == null ||
              vWrap == null ||
              wNull == null ||
              wNullN == null ||
              wStrt == null ||
              wStrtN == null ||
              wStop == null ||
              wStopN == null ||
              wStep == null ||
              wStepN == null ||
              wWell == null) {
            logError(r'Не все данные корректны для продолжения парсинга');
            logError('Vers  === $vVers');
            logError('Wrap  === $vWrap');
            logError('Null  === $wNull');
            logError('NullN === $wNullN');
            logError('Strt  === $wStrt');
            logError('StrtN === $wStrtN');
            logError('Stop  === $wStop');
            logError('StopN === $wStopN');
            logError('Step  === $wStep');
            logError('StepN === $wStepN');
            logError('Well  === $wWell');
            break lineLoop;
          }
          methodsStrt = List(methods.length);
          methodsStrtN = List(methods.length);
          methodsStop = List(methods.length);
          methodsStopN = List(methods.length);
          continue lineLoop;
        case 'C': // ~Curve information
        case 'O': // ~Other information
        case 'P': // ~Parameter information
        case 'V': // ~Version information
        case 'W': // ~Well information
          continue lineLoop;
        default:
          logError(r'Неизвестная секция');
          break lineLoop;
      }
      continue lineLoop;
    } else {
      if (section.isEmpty) {
        logError(r'Отсутсвует секция');
        break lineLoop;
      }
      final i0 = line.indexOf('.');
      if (i0 == -1) {
        logError(r'Отсутсвует точка');
        continue lineLoop;
      }
      // if (line.contains('.', i0 + 1)) {
      //   logError(r'Две точки на линии');
      //   continue lineLoop;
      // }
      final i1 = line.indexOf(':');
      if (i1 == -1) {
        logError(r'Отсутсвует двоеточие');
        continue lineLoop;
      }
      if (i1 < i0) {
        logError(r'Двоеточие перед первой точкой');
        continue lineLoop;
      }
      // if (line.contains(':', i1 + 1)) {
      //   logError(r'Два двоеточия на линии');
      //   continue lineLoop;
      // }
      final i2 = line.indexOf(' ', i0);
      final mnem = line.substring(0, i0).trim();
      final unit = line.substring(i0 + 1, i2).trim();
      final data = line.substring(i2 + 1, i1).trim();
      final desc = line.substring(i1 + 1).trim();
      switch (section) {
        case 'V':
          switch (mnem) {
            case 'VERS':
              vVers = data;
              if (unit.isNotEmpty) {
                logError(r'После точки должен быть пробел');
              }
              if (vVers != '1.20' && vVers != '2.0') {
                logError(r'Ошибка в версии файла');
                vVers = null;
              }
              continue lineLoop;
            case 'WRAP':
              vWrap = data;
              if (unit.isNotEmpty) {
                logError(r'После точки должен быть пробел');
              }
              if (vWrap != 'YES' && vWrap != 'NO') {
                logError(r'Ошибка в значении многострочности');
                vWrap = null;
              }
              continue lineLoop;
            default:
              logError(r'Неизвестная мнемоника в секции ~V');
              continue lineLoop;
          }
          break;
        case 'W':
          switch (mnem) {
            case 'NULL':
              wNull = data;
              wNullN = double.tryParse(wNull);
              if (wNullN == null) {
                logError(r'Некорректное число');
              }
              continue lineLoop;
            case 'STEP':
              wStep = data;
              wStepN = double.tryParse(wStep);
              if (wStepN == null) {
                logError(r'Некорректное число');
              }
              continue lineLoop;
            case 'STRT':
              wStrt = data;
              wStrtN = double.tryParse(wStrt);
              if (wStrtN == null) {
                logError(r'Некорректное число');
              }
              continue lineLoop;
            case 'STOP':
              wStop = data;
              wStopN = double.tryParse(wStop);
              if (wStopN == null) {
                logError(r'Некорректное число');
              }
              continue lineLoop;
            case 'WELL':
              wWell = data;
              if (wWell.isEmpty || wWell == 'WELL') {
                wWell = desc;
              }
              if (wWell.isEmpty ||
                  [
                    'WELL',
                    'WELL NAME',
                    'WELL NUMBER',
                    'Well',
                    'Well name',
                    'Наименование скважины',
                    'Нет поля СКВАЖИН',
                    'Номер скважины',
                    'СКВ№',
                    'Скважина',
                    'скважина'
                  ].contains(wWell)) {
                logError(r'Невозможно получить номер скважины по полю WELL');
                wWell = null;
              }
              continue lineLoop;
            default:
              continue lineLoop;
          }
          break;
        case 'C':
          methods.add(mnem);
          break;
      }
    }
  }

  /// ==========================================================================
  if (iErrors == 0) {
    print([iso.id, wWell, methods, methodsStrt, methodsStop]);
    iso.sendPort
        .send([iso.id, '+las', wWell, methods, methodsStrt, methodsStop]);

    var newPath = iso.pathOut +
        '/las/${iso.id}/${wWell}__' +
        file.path.substring(
            max(file.path.lastIndexOf(r'\'), file.path.lastIndexOf(r'/')) + 1,
            file.path.lastIndexOf('.'));
    var i = 0;
    futureCopyFile = File(newPath + '.las').exists().then((final b) {
      if (b) {
        i += 1;
        Future _next() {
          return File(newPath + '_${i}.las').exists().then((final b) {
            if (b) {
              i += 1;
              return _next();
            } else {
              return file.copy(newPath + '_${i}.las');
            }
          });
        }

        return _next();
      } else {
        return file.copy(newPath + '.las');
      }
    });
  } else {
    iso.sendPort.send([iso.id, '-las']);
  }

  return futureCopyFile;
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

  final pathBin_zip = r'C:\Program Files\7-Zip\7z.exe';
  // final pathBin_doc2x = r'D:\ARGilyazeev\doc2x_r649\doc2x.exe';
  final pathBin_doc2x =
      r'C:\Program Files (x86)\Microsoft Office\root\Office16\Wordconv.exe';

  final tasks = <Future>[];

  final listOfLas = [];

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
          listOfLas.add(msg);
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
    isoTasks[i] = -1;
    print('main: spawn sub[${i + 1}]');
    isolate[i] = Isolate.spawn(
        runIsolate,
        IsoData(i + 1, receivePort.sendPort, charMaps, pathOut, pathBin_zip,
            pathBin_doc2x),
        debugName: 'sub[${i + 1}]');
  }
  // Ожидаем создания
  await Future.wait(isolate);
  print('main: all subs spawned');
}
