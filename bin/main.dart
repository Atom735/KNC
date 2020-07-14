import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

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
  final charMaps = await loadMappings('mappings');
  final ct_JS = ContentType.parse('application/javascript');
  // Путь для поиска файлов
  final pathInList = <String>[];
  // Путь для выходных данных
  var pathOut = r'.ag47';

  print('Search 7zip and WordConv');

  String pathBin_zip;
  String pathBin_doc2x;

  await Future.wait([
    File(r'C:\Program Files\7-Zip\7z.exe').exists().then((exist) {
      if (pathBin_zip == null && exist) {
        pathBin_zip = r'C:\Program Files\7-Zip\7z.exe';
      }
    }),
    File(r'C:\Program Files (x86)\7-Zip\7z.exe').exists().then((exist) {
      if (pathBin_zip == null && exist) {
        pathBin_zip = r'C:\Program Files (x86)\7-Zip\7z.exe';
      }
    }),
    Directory(r'C:\Program Files\Microsoft Office').exists().then((exist) {
      if (exist) {
        return Directory(r'C:\Program Files\Microsoft Office')
            .list(recursive: true, followLinks: false)
            .listen((file) {
          if (file is File) {
            if (pathBin_doc2x == null &&
                p.basename(file.path).toLowerCase() == 'wordconv.exe') {
              pathBin_doc2x = file.path;
            }
          }
        }).asFuture();
      }
    }),
    Directory(r'C:\Program Files (x86)\Microsoft Office')
        .exists()
        .then((exist) {
      if (exist) {
        return Directory(r'C:\Program Files (x86)\Microsoft Office')
            .list(recursive: true, followLinks: false)
            .listen((file) {
          if (file is File) {
            if (pathBin_doc2x == null &&
                p.basename(file.path).toLowerCase() == 'wordconv.exe') {
              pathBin_doc2x = file.path;
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

  var websockets = <WebSocket>[];

  await for (var req in server) {
    // final contentType = req.headers.contentType;
    final response = req.response;
    if (req.uri.path == '/ws') {
      var socket = await WebSocketTransformer.upgrade(req);
      websockets.add(socket);
      socket.listen((event) {
        print('WS: $event');
      });
      socket.add('Hello by Dart!');
      continue;
    } else if (req.uri.path == '/main.dart.js') {
      response.headers.contentType = ct_JS;
      response.statusCode = HttpStatus.ok;
      await response.addStream(File(r'web/main.dart.js').openRead());
    } else if (req.uri.path == '/main.dart.js.map') {
      response.headers.contentType = ContentType.json;
      response.statusCode = HttpStatus.ok;
      await response.addStream(File(r'web/main.dart.js.map').openRead());
    } else if (runing) {
      response.headers.contentType = ContentType.html;
      response.statusCode = HttpStatus.ok;
      await response.addStream(File(r'web/action.html').openRead());
    } else {
      final content = await utf8.decoder.bind(req).join();
      if (content.isNotEmpty) {
        runing = true;

        response.headers.contentType = ContentType.html;
        response.statusCode = HttpStatus.ok;
        await response.addStream(File(r'web/action.html').openRead());
      } else {
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
              response.write(pathBin_zip);
              break;
            case 'ssPathWordconv':
              response.write(pathBin_doc2x);
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
    }

    await response.flush();
    await response.close();
  }
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
