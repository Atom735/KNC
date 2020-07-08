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
  // Путь для поиска файлов
  final pathInList = [r'\\NAS\Public\common\Gilyazeev\ГИС\Искринское м-е'];
  // Путь для выходных данных
  final pathOut = r'.ag47';
  final pathOutLas = p.join(pathOut, 'las');
  final pathOutErrors = p.join(pathOut, 'errors');

  final pathBin_zip = r'C:\Program Files\7-Zip\7z.exe';
  final pathBin_doc2x =
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
