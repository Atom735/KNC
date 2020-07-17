import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:knc/unzipper.dart';
import 'package:path/path.dart' as p;

import 'package:knc/las.dart';
import 'package:knc/mapping.dart';

Future<ProcessResult> runUnZip(
    final String path2exe, final String path2arch, final String path2out) {
  // 7z <x или e> <архивный файл> -o"<путь, куда распаковываем>"
  return Process.run(path2exe, ['x', '-o$path2out', path2arch]);
}

Future<ProcessResult> runDoc2X(
    final String path2exe, final String path2doc, final String path2out) {
  // -oice -nme <input file> <output file>
  return Process.run(path2exe, ['-oice', '-nme', path2doc, path2out]);
}

Future main(List<String> args) async {
  /// Текстовые кодировки
  final charMaps = await loadMappings('mappings');

  /// ContentType mime = application/javascript
  final ct_JS = ContentType.parse('application/javascript');

  /// ContentType mime = application/vnd.dart
  final ct_Dart = ContentType.parse('application/vnd.dart');

  /// Путь для поиска файлов
  final pathInList = <String>[];

  /// Путь для выходных данных
  var pathOut = r'.ag47';

  /// Путь для копирования LAS файлов
  String pathOutLas;

  /// Путь для генерации файлов инклинометрии
  String pathOutInk;

  /// Путь для копирования файлов с ошибкой
  String pathOutErrors;

  /// Файл с данными ошибок
  IOSink errorsOut;

  /// Настройки расширения для архивных файлов
  var ssFileExtAr = <String>['.zip', '.rar'];

  /// Настройки расширения для файлов LAS
  var ssFileExtLas = <String>['.las'];

  /// Настройки расширения для файлов с инклинометрией
  var ssFileExtInk = <String>['.doc', '.docx', '.txt', '.dbf'];

  Unzipper unzipper;

  print('Search 7zip and WordConv');

  String ssPath7z;
  String ssPathWordconv;

  await Future.wait([
    File(r'C:\Program Files\7-Zip\7z.exe').exists().then((exist) {
      if (ssPath7z == null && exist) {
        ssPath7z = r'C:\Program Files\7-Zip\7z.exe';
      }
    }),
    File(r'C:\Program Files (x86)\7-Zip\7z.exe').exists().then((exist) {
      if (ssPath7z == null && exist) {
        ssPath7z = r'C:\Program Files (x86)\7-Zip\7z.exe';
      }
    }),
    Directory(r'C:\Program Files\Microsoft Office')
        .exists()
        .then((exist) async {
      if (exist) {
        return Directory(r'C:\Program Files\Microsoft Office')
            .list(recursive: true, followLinks: false)
            .listen((file) {
          if (file is File) {
            if (ssPathWordconv == null &&
                p.basename(file.path).toLowerCase() == 'wordconv.exe') {
              ssPathWordconv = file.path;
            }
          }
        }).asFuture();
      }
    }),
    Directory(r'C:\Program Files (x86)\Microsoft Office')
        .exists()
        .then((exist) async {
      if (exist) {
        return Directory(r'C:\Program Files (x86)\Microsoft Office')
            .list(recursive: true, followLinks: false)
            .listen((file) {
          if (file is File) {
            if (ssPathWordconv == null &&
                p.basename(file.path).toLowerCase() == 'wordconv.exe') {
              ssPathWordconv = file.path;
            }
          }
        }).asFuture();
      }
    })
  ]);

  final server = await HttpServer.bind(InternetAddress.anyIPv4, 4040);
  print('Listening on http://${server.address.address}:${server.port}/');
  print('For connect use http://localhost:${server.port}/');

  var runing = false;
  var runingDone = false;

  var websockets = <WebSocket>[];

  Future endTask;
  var socketMsgSended = <String>[];

  void sendMsg(final String txt) {
    socketMsgSended.add(txt);
    websockets.forEach((ws) {
      ws.add(txt);
    });
  }

  void errorAdd(final String txt) {
    errorsOut.writeln(txt);
    sendMsg('#ERROR:$txt');
  }

  void newSocketOpend(final WebSocket ws) {
    for (var msg in socketMsgSended) {
      ws.add(msg);
    }
  }

  Future newWebConnection(final HttpResponse response) {
    response.headers.contentType = ContentType.html;
    response.statusCode = HttpStatus.ok;
    return response.addStream(File(r'web/action.html').openRead());
  }

  Future<void> sendSettingsPage(final HttpResponse response) async {
    response.headers.contentType = ContentType.html;
    response.statusCode = HttpStatus.ok;
    var data = await File(r'web/index.html').readAsString();
    var i0 = 0;
    var i1 = data.indexOf(r'${{');
    while (i1 != -1) {
      response.write(data.substring(i0, i1));
      i0 = data.indexOf(r'}}', i1);
      var name = data.substring(i1 + 3, i0);
      switch (name) {
        case 'ssPathOut':
          response.write(pathOut);
          break;
        case 'ssPath7z':
          response.write(ssPath7z);
          break;
        case 'ssPathWordconv':
          response.write(ssPathWordconv);
          break;
        case 'ssFileExtAr':
          if (ssFileExtAr.isNotEmpty) {
            response.write(ssFileExtAr[0]);
            for (var i = 1; i < ssFileExtAr.length; i++) {
              response.write(';');
              response.write(ssFileExtAr[i]);
            }
          }
          break;
        case 'ssFileExtLas':
          if (ssFileExtLas.isNotEmpty) {
            response.write(ssFileExtLas[0]);
            for (var i = 1; i < ssFileExtLas.length; i++) {
              response.write(';');
              response.write(ssFileExtLas[i]);
            }
          }
          break;
        case 'ssFileExtInk':
          if (ssFileExtInk.isNotEmpty) {
            response.write(ssFileExtInk[0]);
            for (var i = 1; i < ssFileExtInk.length; i++) {
              response.write(';');
              response.write(ssFileExtInk[i]);
            }
          }
          break;
        case 'charMaps':
          charMaps.forEach((key, value) {
            response.write('<li>$key</li>');
          });
          break;
        default:
          response.write('[UNDIFINED NAME]');
      }
      i0 += 2;
      i1 = data.indexOf(r'${{', i0);
    }
    response.write(data.substring(i0));
  }

  Future<String> getOutPathNew(String prePath, String name) async {
    if (await File(p.join(prePath, p.basename(name))).exists()) {
      final f0 = p.join(prePath, p.basenameWithoutExtension(name));
      final fe = p.extension(name);
      var i = 0;
      while (await File('${f0}_$i$fe').exists()) {
        i++;
      }
      return '${f0}_$i$fe';
    } else {
      return p.join(prePath, p.basename(name));
    }
  }

  Future workFileLas(String origin, File file) async {
    final data =
        LasData(UnmodifiableUint8ListView(await file.readAsBytes()), charMaps);
    if (data.listOfErrors.isEmpty) {
      // No error
      final newPath = await getOutPathNew(
          pathOutLas, data.wWell + '___' + p.basename(file.path));

      sendMsg('#LAS:+"$origin"');
      sendMsg('#LAS:\t"${file.path}" => "${newPath}"');
      for (final c in data.curves) {
        sendMsg('#LAS:\t${c.mnem}: ${c.strtN} <=> ${c.stopN}');
      }
      sendMsg('#LAS:' + ''.padRight(20, '='));
      await file.copy(newPath);
    } else {
      // On Error
      final newPath = await getOutPathNew(pathOutErrors, p.basename(file.path));
      errorAdd('+LAS("$origin")');
      errorAdd('\t"${file.path}" => "${newPath}"');
      for (final err in data.listOfErrors) {
        errorAdd('\t$err');
      }
      errorAdd(''.padRight(20, '='));
      await file.copy(newPath);
    }
  }

  Future workFileInk(String origin, File file) async {}

  Future Function(FileSystemEntity entity) getFileEntityFunc(
          String pathToArch) =>
      (FileSystemEntity file) async {
        if (file is File) {
          final origin = p.join(
              pathToArch, file.path.substring(unzipper.pathToTempDir.length));
          final ext = p.extension(file.path).toLowerCase();
          for (var item in ssFileExtAr) {
            if (item == ext) {
              // Вскрываем архив
              return unzipper.unzip(file.path, getFileEntityFunc(file.path));
            }
          }
          for (var item in ssFileExtLas) {
            if (item == ext) {
              // LAS файл
              return workFileLas(origin, file);
            }
          }
          for (var item in ssFileExtInk) {
            if (item == ext) {
              // Файл с инклинометрией
              return workFileInk(origin, file);
            }
          }
        }
      };

  Future workDir(String origin, Directory dir) async {
    var tasks = <Future>[];
    await dir.list(recursive: true).listen((file) {
      if (file is File) {
        final ext = p.extension(file.path).toLowerCase();
        for (var item in ssFileExtAr) {
          if (item == ext) {
            // Вскрываем архив
            tasks.add(unzipper.unzip(file.path, getFileEntityFunc(file.path)));
            return;
          }
        }
        for (var item in ssFileExtLas) {
          if (item == ext) {
            // LAS файл
            tasks.add(workFileLas(file.path, file));
            return;
          }
        }
        for (var item in ssFileExtInk) {
          if (item == ext) {
            // Файл с инклинометрией
            tasks.add(workFileInk(file.path, file));
            return;
          }
        }
      }
    }).asFuture();
    return Future.wait(tasks);
  }

  Future workFile(String origin, File file) async {
    final ext = p.extension(file.path).toLowerCase();
    for (var item in ssFileExtAr) {
      if (item == ext) {
        // Вскрываем архив
        return unzipper.unzip(file.path, getFileEntityFunc(file.path));
      }
    }
    for (var item in ssFileExtLas) {
      if (item == ext) {
        // LAS файл
        return workFileLas(origin, file);
      }
    }
    for (var item in ssFileExtInk) {
      if (item == ext) {
        // Файл с инклинометрией
        return workFileInk(origin, file);
      }
    }
  }

  Future work() {
    var tasks = <Future>[];

    pathInList.forEach((path) {
      if (path.isNotEmpty) {
        tasks.add(FileSystemEntity.type(path).then((entity) {
          switch (entity) {
            case FileSystemEntityType.directory:
              print('dir: $path');
              tasks.add(workDir(path, Directory(path)));
              break;
            case FileSystemEntityType.file:
              print('file: $path');
              tasks.add(workFile(path, File(path)));
              break;
            case FileSystemEntityType.notFound:
              errorAdd('Не корректный путь: $path');
              break;
            default:
              errorAdd('По указанному пути находится непонятно что: $path');
          }
        }));
      }
    });

    return Future.wait(tasks);
  }

  Future workEnd() async {
    return errorsOut.flush().then((_) => errorsOut.close()).then((_) {
      runingDone = true;
      sendMsg('#DONE!');
    });
  }

  Future<bool> workInit(final String content) async {
    print(content);
    print('parse content');
    final map = <String, String>{};
    if (content.startsWith('--')) {
      final contentList = LineSplitter().convert(content);
      final bound = contentList[0];
      var bounded = true;
      var data = <String>[];
      var dataname = '';
      for (var line in contentList) {
        if (line == bound) {
          bounded = true;
          if (data.isNotEmpty) {
            map[dataname] = data.join('\n').trim();
            data.clear();
          }
        } else if (bounded) {
          if (line.toLowerCase().startsWith('content-disposition')) {
            final i0 = line.toLowerCase().indexOf('name=');
            if (i0 == -1) {
              return false;
            }
            final i1 = line.indexOf('"', i0 + 5);
            dataname = line.substring(i1 + 1, line.indexOf('"', i1 + 1));
          } else {
            if (line.isEmpty) {
              bounded = false;
            }
          }
        } else {
          data.add(line);
        }
      }
    } else {
      return false;
    }

    if (map['ssPathOut'] != null) {
      pathOut = map['ssPathOut'];
    }
    if (map['ssPath7z'] != null) {
      ssPath7z = map['ssPath7z'];
    }
    if (map['ssPathWordconv'] != null) {
      ssPathWordconv = map['ssPathWordconv'];
    }
    if (map['ssFileExtAr'] != null) {
      ssFileExtAr.clear();
      ssFileExtAr = map['ssFileExtAr'].toLowerCase().split(';');
      ssFileExtAr.removeWhere((element) => element.isEmpty);
    }
    if (map['ssFileExtLas'] != null) {
      ssFileExtLas.clear();
      ssFileExtLas = map['ssFileExtLas'].toLowerCase().split(';');
      ssFileExtLas.removeWhere((element) => element.isEmpty);
    }
    if (map['ssFileExtInk'] != null) {
      ssFileExtInk.clear();
      ssFileExtInk = map['ssFileExtInk'].toLowerCase().split(';');
      ssFileExtInk.removeWhere((element) => element.isEmpty);
    }
    pathInList.clear();
    for (var i = 0; map['path$i'] != null; i++) {
      pathInList.add(map['path$i']);
    }

    print('work init');
    unzipper = Unzipper(p.join(pathOut, 'temp'), ssPath7z);
    pathOutLas = p.join(pathOut, 'las');
    pathOutInk = p.join(pathOut, 'ink');
    pathOutErrors = p.join(pathOut, 'errors');

    final dirOut = Directory(pathOut);
    if (await dirOut.exists()) {
      await dirOut.delete(recursive: true);
    }
    await dirOut.create(recursive: true);
    await Future.wait([
      unzipper.clear(),
      Directory(pathOutLas).create(recursive: true),
      Directory(pathOutInk).create(recursive: true),
      Directory(pathOutErrors).create(recursive: true)
    ]);

    errorsOut = File(p.join(pathOutErrors, '.errors.txt'))
        .openWrite(encoding: utf8, mode: FileMode.writeOnly);
    errorsOut.writeCharCode(unicodeBomCharacterRune);

    print('start working');
    runing = true;

    endTask = work();

    return true;
  }

  await for (var req in server) {
    // final contentType = req.headers.contentType;
    final response = req.response;
    if (req.uri.path == '/ws') {
      var socket = await WebSocketTransformer.upgrade(req);
      websockets.add(socket);
      print('WS: socket(${socket.hashCode}) opened ');
      socket.listen((event) {
        print('WS: $event');
        if (event is String) {
          if (event == '#STOP!') {
            server.close();
          }
        }
      }, onDone: () {
        print('WS: socket(${socket.hashCode}) closed');
        websockets.remove(socket);
      });
      newSocketOpend(socket);
      continue;
    } else if (req.uri.path == '/main.dart') {
      response.headers.contentType = ct_Dart;
      response.statusCode = HttpStatus.ok;
      await response.addStream(File(r'web/main.dart').openRead());
    } else if (req.uri.path == '/main.dart.js') {
      response.headers.contentType = ct_JS;
      response.statusCode = HttpStatus.ok;
      await response.addStream(File(r'web/main.dart.js').openRead());
    } else if (req.uri.path == '/main.dart.js.map') {
      response.headers.contentType = ContentType.json;
      response.statusCode = HttpStatus.ok;
      await response.addStream(File(r'web/main.dart.js.map').openRead());
    } else if (runing) {
      await newWebConnection(response);
    } else {
      final content = await utf8.decoder.bind(req).join();
      if (content.isNotEmpty) {
        if (await workInit(content)) {
          await newWebConnection(response);
        } else {
          await sendSettingsPage(response);
        }
      } else {
        await sendSettingsPage(response);
      }
    }

    await response.flush();
    await response.close();
  }
  await endTask;

  await workEnd();
}

Future mainOld(List<String> args) async {
  final charMaps = await loadMappings('mappings');
  // Путь для поиска файлов
  final pathInList = <String>[];
  // Путь для выходных данных
  var pathOut = r'.ag47';
  var pathOutLas = p.join(pathOut, 'las');
  var pathOutInk = p.join(pathOut, 'ink');
  var pathOutErrors = p.join(pathOut, 'errors');

  var pathBin_zip = r'C:\Program Files\7-Zip\7z.exe';
  var pathBin_doc2x =
      r'C:\Program Files (x86)\Microsoft Office\root\Office16\Wordconv.exe';

  final dirOut = Directory(pathOut);
  if (dirOut.existsSync()) {
    dirOut.deleteSync(recursive: true);
  }
  dirOut.createSync(recursive: true);
  Directory(pathOutLas).createSync(recursive: true);
  Directory(pathOutErrors).createSync(recursive: true);

  final errorsOut = File(p.join(pathOutErrors, '.errors.txt'))
      .openWrite(encoding: utf8, mode: FileMode.writeOnly);
  errorsOut.writeCharCode(unicodeBomCharacterRune);

  final dataListLas = <LasData>[];

  void parseFile(final File file) {
    final name = p.basenameWithoutExtension(file.path);
    final fileExt = p.extension(file.path).toLowerCase();
    switch (fileExt) {
      case '.las':
        {
          final data = LasData(
              UnmodifiableUint8ListView(file.readAsBytesSync()), charMaps);
          if (data.listOfErrors.isEmpty) {
            // LasData no errors
            var newPath = p.join(pathOutLas, name);
            if (File(newPath + fileExt).existsSync()) {
              // exist file
              var i = 1;
              while (File(newPath + '_$i' + fileExt).existsSync()) {
                i += 1;
              }
              newPath = newPath + '_$i' + fileExt;
              file.copySync(newPath);
            } else {
              // not exist
              newPath = newPath + fileExt;
              file.copySync(newPath);
            }
            dataListLas.add(data);
          } else {
            // LasData with errors
            var newPath = p.join(pathOutErrors, name);
            if (File(newPath + fileExt).existsSync()) {
              // exist file
              var i = 1;
              while (File(newPath + '_$i' + fileExt).existsSync()) {
                i += 1;
              }
              newPath = newPath + '_$i' + fileExt;
              file.copySync(newPath);
            } else {
              // not exist
              newPath = newPath + fileExt;
              file.copySync(newPath);
            }
            errorsOut.writeln(file);
            errorsOut.writeln('\t$newPath');
            for (var err in data.listOfErrors) {
              errorsOut.writeln('\t$err');
            }
            errorsOut.writeln(''.padRight(80, '-'));
          }
        }
        break;
      default:
    }
  }

  for (var pathIn in pathInList) {
    final entity = FileSystemEntity.typeSync(pathIn, followLinks: false);
    switch (entity) {
      case FileSystemEntityType.file:
        parseFile(File(pathIn));
        break;
      case FileSystemEntityType.directory:
        (Directory(pathIn))
            .listSync(recursive: true, followLinks: false)
            .forEach((_) {
          if (_ is File) {
            parseFile(_);
          }
        });
        break;
      default:
    }
  }

  await errorsOut.flush();
  await errorsOut.close();
}
