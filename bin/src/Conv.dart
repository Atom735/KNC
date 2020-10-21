import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:knc/knc.dart';
import 'package:path/path.dart' as p;

import 'ProcessManager.dart';

/// Данные о подборе кодировок и сами данные файла
class ConvDecodeData {
  /// Значение рейтинга кодировок
  final Map<String, int> /*?*/ codePageRaiting;

  /// Конечная подобранная кодировка
  final String codePage;

  /// Перекодированные данные
  final String data;

  const ConvDecodeData(this.data, this.codePage, [this.codePageRaiting]);
}

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

  @override
  String toString() =>
      '$runtimeType($hashCode)[$pathArchiver;$pathWordConv]{${charMaps.keys.join(";")}}';
  Conv._create(
      this.dirTemp, this.pathArchiver, this.pathWordConv, this.charMaps) {
    print('$this created');
    _instance = this;
  }
  static /*late*/ Conv _instance;
  factory Conv() => _instance;

  /// создаёт экземпляр объекта
  static Future<Conv> init() async {
    final dirTemp = Directory('temp').absolute;
    if (await dirTemp.exists()) {
      await dirTemp.delete(recursive: true);
    }

    return Conv._create(await dirTemp.create(), await _searchProgram_7Zip(),
        await _searchProgram_WordConv(), await _loadCharMaps());
  }

  /// Подбирает кодировку и конвертирует в строку, подобранная кодировка
  /// будет записана в переменную [this.codePage]
  ConvDecodeData decode(final List<int> bytes, [final String /*?*/ _codePage]) {
    if (_codePage == null) {
      if (bytes.length >= 3 &&
          bytes[0] == 0xEF &&
          bytes[1] == 0xBB &&
          bytes[2] == 0xBF) {
        return ConvDecodeData(utf8.decode(bytes), 'UTF-8 (BOM)');
      }
      // Подбираем кодировку
      final codePageRaiting = getMappingRaitings(bytes);
      final codePage = convGetMappingMax(codePageRaiting);
      if (codePageRaiting[codePage] <= 0) {
        return ConvDecodeData(
            utf8.decode(bytes, allowMalformed: true), 'UTF-8', codePageRaiting);
      }
      return ConvDecodeData(convDecode(bytes, charMaps[codePage] /*!*/),
          codePage, codePageRaiting);
    } else {
      if (_codePage.startsWith('UTF-8')) {
        return ConvDecodeData(
            utf8.decode(bytes, allowMalformed: true), 'UTF-8');
      }
      return ConvDecodeData(
          convDecode(bytes, charMaps[_codePage] /*!*/), _codePage);
    }
  }

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
  Future<ArchiverOutput> unzip(String pathToArchive,
          [String pathToOutDir = '']) =>
      pathToOutDir.isEmpty
          ? (dirTemp
              .createTemp('arch.')
              .then((temp) => unzip(pathToArchive, temp.path)))
          : run(pathArchiver,
                  ['x', '-o$pathToOutDir', pathToArchive, '-scsUTF-8'],
                  stdoutEncoding: null, stderrEncoding: null)
              .then((value) =>
                  archiverResults(value, pathToArchive, pathToOutDir));

  /// Запаковывает данные внутри папки [pathToData] в zip архиф [pathToOutput]
  /// с помощью 7zip
  Future<ArchiverOutput> zip(
          final String pathToData, final String pathToOutput) =>
      run(pathArchiver, ['a', '-tzip', pathToOutput, '*', '-scsUTF-8'],
              workingDirectory: pathToData,
              stdoutEncoding: null,
              stderrEncoding: null)
          .then((value) => archiverResults(value, pathToData, pathToOutput));

  /// Ищет где находися программа 7Zip
  static Future<String> _searchProgram_7Zip() =>
      Future.wait(_SearchPath_7Zip.map(
              (e) => File(e).exists().then((exist) => exist ? e : '')))
          .then((list) => list.firstWhere((element) => element.isNotEmpty));

  static const _SearchPath_WordConv = [
    r'C:\Program Files\Microsoft Office',
    r'C:\Program Files (x86)\Microsoft Office'
  ];

  /// Ищет где находися программа WordConv
  static Future<String> _searchProgram_WordConv() async {
    for (var path in _SearchPath_WordConv) {
      final _dir = Directory(path);
      if (await _dir.exists()) {
        final _file = (await _dir
            .list(recursive: true, followLinks: false)
            .firstWhere(
                (file) =>
                    file is File &&
                    p.basename(file.path).toLowerCase() == 'wordconv.exe',
                orElse: () => File(''))) as File;
        if (_file.path.isNotEmpty) {
          return _file.path;
        }
      }
    }
    return '';
  }

  /// Поиск кодировок
  static Future<Map<String, List<String>>> _loadMappings(
      final String path) async {
    final map = <String, List<String>>{};
    await for (final e in Directory(path).list(recursive: false)) {
      if (e is File) {
        final name = e.path.substring(
            max(e.path.lastIndexOf('/'), e.path.lastIndexOf('\\')) + 1,
            e.path.lastIndexOf('.'));
        final _map = List<String>.filled(
            0x80, String.fromCharCode(unicodeReplacementCharacterRune));
        for (final line in await e.readAsLines()) {
          if (line.startsWith('#')) {
            continue;
          }
          final lineCeils = line.split('\t');
          if (lineCeils.length >= 2) {
            final i = int.parse(lineCeils[0]);
            if (i >= 0x80 && lineCeils[1].startsWith('0x')) {
              _map[i - 0x80] = String.fromCharCode(int.parse(lineCeils[1]));
            }
          }
        }
        map[name] = List.unmodifiable(_map);
      }
    }
    return map;
  }

  /// Возвращает актуальность той или иной кодировки
  Map<String, int> getMappingRaitings(final List<int> bytes) =>
      convGetMappingRaitings(charMaps, bytes);

  /// Преобразует данные процесса в выходные данные архиватора
  ArchiverOutput archiverResults(
      final ProcessResult res, final String pathIn, final String pathOut) {
    if (exitCode == 0) {
      return ArchiverOutput(
          exitCode: exitCode, pathIn: pathIn, pathOut: pathOut);
    }
    String /*?*/ stdOut;
    String /*?*/ stdErr;
    if (res.stdout != null) {
      if (res.stdout is List<int>) {
        stdOut = decode(res.stdout).data;
      } else if (res.stdout is String) {
        stdOut = res.stdout;
      }
    }
    if (res.stderr != null) {
      if (res.stderr is List<int>) {
        stdErr = decode(res.stderr).data;
      } else if (res.stderr is String) {
        stdErr = res.stderr;
      }
    }
    return ArchiverOutput(
        exitCode: exitCode, pathIn: pathIn, stdOut: stdOut, stdErr: stdErr);
  }
}
