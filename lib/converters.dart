import 'dart:io';

import 'archiver.dart';
import 'async.dart';
import 'mapping.dart';

import 'package:path/path.dart' as p;

class MyConverters extends Archiver {
  /// Путь к программе 7Zip
  final String ssPath7z;

  /// Путь к программе WordConv
  final String ssPathWordconv;

  /// Таблица кодировок `ssCharMaps['CP866']`
  final Map<String, List<String>> ssCharMaps;

  MyConverters(
      this.ssPath7z, this.ssPathWordconv, this.ssCharMaps, final Directory dir,
      [final AsyncTaskQueue queue])
      : super(ssPath7z, dir, queue);

  static Future<MyConverters> init([final AsyncTaskQueue queue]) async =>
      MyConverters(await searchProgram_7Zip(), await searchProgram_WordConv(),
          await loadCharMaps(), Directory('temp').absolute, queue);

  static Future<Map<String, List<String>>> loadCharMaps() =>
      loadMappings('mappings').then((charmap) => charmap);

  static const _SearchPath_7Zip = [
    r'C:\Program Files\7-Zip\7z.exe',
    r'C:\Program Files (x86)\7-Zip\7z.exe'
  ];

  /// Ищет где находися программа 7Zip
  static Future<String> searchProgram_7Zip() => Future.wait(
      _SearchPath_7Zip.map(
          (e) => File(e).exists().then((exist) => exist ? e : null))).then(
      (list) =>
          list.firstWhere((element) => element != null, orElse: () => null));

  static const _SearchPath_WordConv = [
    r'C:\Program Files\Microsoft Office',
    r'C:\Program Files (x86)\Microsoft Office'
  ];

  /// Ищет где находися программа WordConv
  static Future<String> searchProgram_WordConv() =>
      Future.wait(_SearchPath_WordConv.map((e) => Directory(e).exists().then((exist) => exist
              ? Directory(e).list(recursive: true, followLinks: false).firstWhere(
                  (file) =>
                      file is File &&
                      p.basename(file.path).toLowerCase() == 'wordconv.exe',
                  orElse: () => null)
              : null)))
          .then((list) => list.firstWhere((element) => element != null, orElse: () => null))
          .then((entity) => entity != null ? entity.path : null);

  Future<int> doc2x(final String path2doc, final String path2out) =>
      queue.addTask(() =>
          Process.run(ssPathWordconv, ['-oice', '-nme', path2doc, path2out])
              .then((e) => e.exitCode));
}
