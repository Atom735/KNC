import 'dart:io';
import 'package:path/path.dart' as p;

import 'mapping.dart';

int calculate() {
  return 6 * 7;
}

class KncSettings {
  /// Путь к конечным данным
  String ssPathOut = 'out';

  /// Путь к программе 7Zip
  String ssPath7z;

  /// Путь к программе WordConv
  String ssPathWordconv;

  /// Настройки расширения для архивных файлов
  List<String> ssFileExtAr = ['.zip', '.rar'];

  /// Настройки расширения для файлов LAS
  List<String> ssFileExtLas = ['.las'];

  /// Настройки расширения для файлов с инклинометрией
  List<String> ssFileExtInk = ['.doc', '.docx', '.txt', '.dbf'];

  /// Таблица кодировок `ssCharMaps['CP866']`
  Map<String, List<String>> ssCharMaps;

  /// Путь для поиска файлов
  List<String> pathInList = [];

  String pathOutLas;
  String pathOutInk;
  String pathOutErrors;
  IOSink errorsOut;

  /// Загружает кодировки и записывает их в настройки
  Future<Map<String, List<String>>> loadCharMaps() =>
      loadMappings('mappings').then((charmap) => ssCharMaps = charmap);

  /// Заменяет теги ${{tag}} на значение настройки
  String updateBufferByThis(final String data) {
    final out = StringBuffer();
    var i0 = 0;
    var i1 = data.indexOf(r'${{');
    while (i1 != -1) {
      out.write(data.substring(i0, i1));
      i0 = data.indexOf(r'}}', i1);
      var name = data.substring(i1 + 3, i0);
      switch (name) {
        case 'ssPathOut':
          out.write(ssPathOut);
          break;
        case 'ssPath7z':
          out.write(ssPath7z);
          break;
        case 'ssPathWordconv':
          out.write(ssPathWordconv);
          break;
        case 'ssFileExtAr':
          if (ssFileExtAr.isNotEmpty) {
            out.write(ssFileExtAr[0]);
            for (var i = 1; i < ssFileExtAr.length; i++) {
              out.write(';');
              out.write(ssFileExtAr[i]);
            }
          }
          break;
        case 'ssFileExtLas':
          if (ssFileExtLas.isNotEmpty) {
            out.write(ssFileExtLas[0]);
            for (var i = 1; i < ssFileExtLas.length; i++) {
              out.write(';');
              out.write(ssFileExtLas[i]);
            }
          }
          break;
        case 'ssFileExtInk':
          if (ssFileExtInk.isNotEmpty) {
            out.write(ssFileExtInk[0]);
            for (var i = 1; i < ssFileExtInk.length; i++) {
              out.write(';');
              out.write(ssFileExtInk[i]);
            }
          }
          break;
        case 'ssCharMaps':
          ssCharMaps.forEach((key, value) {
            out.write('<li>$key</li>');
          });
          break;
        default:
          out.write('[UNDIFINED NAME]');
      }
      i0 += 2;
      i1 = data.indexOf(r'${{', i0);
    }
    out.write(data.substring(i0));
    return out.toString();
  }

  /// Обновляет данные через полученные данные HTML формы
  void updateByMultiPartFormData(final Map<String, String> map) {
    if (map['ssPathOut'] != null) {
      ssPathOut = map['ssPathOut'];
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
  }

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

  /// Устанавливает переменные путей программ в найденные,
  /// возвращает список путей к программам
  ///
  /// Переменные установятся только если дождатся обещанного выполнения
  Future<List<String>> serchPrograms() => Future.wait([
        searchProgram_7Zip().then((path) => ssPath7z = path),
        searchProgram_WordConv().then((path) => ssPathWordconv = path),
      ]);
}
