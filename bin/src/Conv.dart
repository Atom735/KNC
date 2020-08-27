import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:knc/knc.dart';
import 'package:path/path.dart' as p;

import 'ProcessManager.dart';

/// Класс содержащий всевохможные методы преобразования, а именно:
/// * Работа с архиватором: распаковка и запаковка
/// * Коневертирование старого `.doc` файла в новый `.docx`
/// * Работа с кодировками
class Conv extends ProcessManager {
  /// Путь к программе 7Zip
  final String pathArchiver;

  /// Путь к программе WordConv
  final String pathWordConv;

  /// Таблица кодировок `ssCharMaps['CP866']`
  final Map<String, List<String>> charMaps;

  /// Временная папка содержащая все временные функции разархивирования
  final Directory dirTemp;

  Conv(this.dirTemp, this.pathArchiver, this.pathWordConv, this.charMaps);

  /// Значение рейтинга кодировок
  Map<String, int> codePageRaiting;

  /// Конечная подобранная кодировка
  String codePage;

  /// создаёт экземпляр объекта
  static Future<Conv> init() {
    final dirTemp = Directory('temp').absolute;
    return Future.wait([
      dirTemp.exists().then((exist) => exist
          ? dirTemp
              .delete(recursive: true)
              .then((_) => dirTemp.create(recursive: true))
          : dirTemp.create(recursive: true)),
      _searchProgram_7Zip(),
      _searchProgram_WordConv(),
      _loadCharMaps()
    ]).then((f) => Conv(f[0], f[1], f[2], f[3]));
  }

  /// Подбирает кодировку и конвертирует в строку, подобранная кодировка
  /// будет записана в переменную [this.codePage]
  String decode(final List<int> bytes, [final String _codePage]) {
    if (_codePage == null) {
      // Подбираем кодировку
      codePageRaiting = getMappingRaitings(bytes);
      codePage = getMappingMax(codePageRaiting);
    } else {
      codePageRaiting = null;
      codePage = _codePage;
    }
    // Преобразуем байты из кодировки в символы
    return staticDecode(bytes, charMaps[codePage]);
  }

  /// Преобразует данные с помощью заданной кодировки
  static String staticDecode(
          final List<int> bytes, final List<String> charMap) =>
      String.fromCharCodes(
          bytes.map((i) => i >= 0x80 ? charMap[i - 0x80].codeUnitAt(0) : i));

  /// Конвертирует старый `.doc` файл в новый `.docx`
  Future<ProcessResult> doc2x(final String path2doc, final String path2out) =>
      run(pathWordConv, ['-oice', '-nme', path2doc, path2out]);

  static Future<Map<String, List<String>>> _loadCharMaps() =>
      _loadMappings('mappings');

  static const _SearchPath_7Zip = [
    r'C:\Program Files\7-Zip\7z.exe',
    r'C:\Program Files (x86)\7-Zip\7z.exe'
  ];

  /// Распаковывает архив [pathToArchive] в папку [pathToOutDir] если она указана.
  /// Если папка [pathToOutDir] не задана, то будет создана
  /// внутреняя временная папка, которая будет удалена по завершению работ
  Future<ArchiverOutput> unzip(String pathToArchive, [String pathToOutDir]) =>
      pathToOutDir == null
          ? (dirTemp
              .createTemp('arch.')
              .then((temp) => unzip(pathToArchive, temp.path)))
          : run(pathArchiver,
              ['x', '-o$pathToOutDir', pathToArchive, '-scsUTF-8'],
              stdoutEncoding: null, stderrEncoding: null).then((value) => archiverResults(value, pathToArchive, pathToOutDir));

  /// Запаковывает данные внутри папки [pathToData] в zip архиф [pathToOutput]
  /// с помощью 7zip
  Future<ArchiverOutput> zip(
          final String pathToData, final String pathToOutput) =>
      run(pathArchiver, ['a', '-tzip', pathToOutput, '*', '-scsUTF-8'],
          workingDirectory: pathToData,
          stdoutEncoding: null,
          stderrEncoding: null).then((value) => archiverResults(value, pathToData, pathToOutput));

  /// Ищет где находися программа 7Zip
  static Future<String> _searchProgram_7Zip() => Future.wait(
      _SearchPath_7Zip.map(
          (e) => File(e).exists().then((exist) => exist ? e : null))).then(
      (list) =>
          list.firstWhere((element) => element != null, orElse: () => null));

  static const _SearchPath_WordConv = [
    r'C:\Program Files\Microsoft Office',
    r'C:\Program Files (x86)\Microsoft Office'
  ];

  /// Ищет где находися программа WordConv
  static Future<String> _searchProgram_WordConv() => Future.wait(
          _SearchPath_WordConv.map((e) => Directory(e).exists().then((exist) =>
              exist
                  ? Directory(e)
                      .list(recursive: true, followLinks: false)
                      .firstWhere((file) => file is File && p.basename(file.path).toLowerCase() == 'wordconv.exe',
                          orElse: () => null)
                  : null)))
      .then(
          (list) => list.firstWhere((element) => element != null, orElse: () => null))
      .then((entity) => entity != null ? entity.path : null);

  /// Поиск кодировок
  static Future<Map<String, List<String>>> _loadMappings(
      final String path) async {
    final map = <String, List<String>>{};
    await for (final e in Directory(path).list(recursive: false)) {
      if (e is File) {
        final name = e.path.substring(
            max(e.path.lastIndexOf('/'), e.path.lastIndexOf('\\')) + 1,
            e.path.lastIndexOf('.'));
        map[name] = List<String>(0x80);
        for (final line in await e.readAsLines()) {
          if (line.startsWith('#')) {
            continue;
          }
          final lineCeils = line.split('\t');
          if (lineCeils.length >= 2) {
            final i = int.parse(lineCeils[0]);
            if (i >= 0x80) {
              if (lineCeils[1].startsWith('0x')) {
                map[name][i - 0x80] =
                    String.fromCharCode(int.parse(lineCeils[1]));
              } else {
                map[name][i - 0x80] =
                    String.fromCharCode(unicodeReplacementCharacterRune);
              }
            }
          }
        }
        map[name] = List.unmodifiable(map[name]);
      }
    }
    return map;
  }

  /// Возвращает актуальность той или иной кодировки
  Map<String, int> getMappingRaitings(final List<int> bytes) =>
      staticGetMappingRaitings(charMaps, bytes);

  /// Возвращает актуальность той или иной кодировки
  static Map<String, int> staticGetMappingRaitings(
      final Map<String, List<String>> map, final List<int> bytes) {
    final r = <String, int>{};
    map.forEach((k, v) {
      r[k] = 0;
    });
    var byteLast = 0;
    for (final byte in bytes) {
      if (byte >= 0x80 && byteLast >= 0x80) {
        // map.forEach(k,v) {
        //   // r[i] += freq_2letters(map[i][byteLast - 0x80] + map[i][byte - 0x80]);
        // }
        map.forEach((final k, final v) {
          r[k] += freq_2letters(v[byteLast - 0x80] + v[byte - 0x80]);
        });
      }
      byteLast = byte;
    }
    return r;
  }

  /// Преобразует данные процесса в выходные данные архиватора
  ArchiverOutput archiverResults(
          final ProcessResult res, final String pathIn, final String pathOut) {
    if (exitCode == 0) {
      return ArchiverOutput(
          exitCode: exitCode, pathIn: pathIn, pathOut: pathOut);
    }
    String stdOut;
    String stdErr;
    if (res.stdout != null) {
      if (res.stdout is List<int> && charMaps != null) {
        final encodesRaiting = staticGetMappingRaitings(charMaps, res.stdout);
        final encode = getMappingMax(encodesRaiting);
        // Преобразуем байты из кодировки в символы
        final buffer = String.fromCharCodes(res.stdout.map(
            (i) => i >= 0x80 ? charMaps[encode][i - 0x80].codeUnitAt(0) : i));
        stdOut = buffer;
      } else if (res.stdout is String) {
        stdOut = res.stdout;
      }
    }
    if (res.stderr != null) {
      if (res.stderr is List<int> && charMaps != null) {
        final encodesRaiting = staticGetMappingRaitings(charMaps, res.stderr);
        final encode = getMappingMax(encodesRaiting);
        // Преобразуем байты из кодировки в символы
        final buffer = String.fromCharCodes(res.stderr.map(
            (i) => i >= 0x80 ? charMaps[encode][i - 0x80].codeUnitAt(0) : i));
        stdErr = buffer;
      } else if (res.stderr is String) {
        stdErr = res.stderr;
      }
    }
    return ArchiverOutput(
        exitCode: exitCode, pathIn: pathIn, stdOut: stdOut, stdErr: stdErr);
  }

  /// Возвращает актуальную кодировку
  static String getMappingMax(final Map<String, int> r) {
    var o = '';
    r.forEach((final k, final v) {
      if (r[o] == null) {
        o = k;
      } else if (r[o] < v) {
        o = k;
      }
    });
    return o;
  }
}
