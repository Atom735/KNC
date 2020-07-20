import 'dart:io';
import 'package:path/path.dart' as p;
import 'dart:convert';

import 'mapping.dart';
import 'unzipper.dart';
import 'las.dart';

int calculate() {
  return 6 * 7;
}

/// Подбирает новое имя для файла, если он уже существует в папке [prePath]
///
/// [prePath] - это путь именно к существующей папке
///
/// [name] - это может быть как путь, так и только имя
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

  LasDataBase lasDB = LasDataBase();
  dynamic lasIgnore;

  Unzipper unzipper;

  /// Загружает кодировки и записывает их в настройки
  Future<Map<String, List<String>>> loadCharMaps() =>
      loadMappings('mappings').then((charmap) => ssCharMaps = charmap);

  /// Загружает таблицу игнорирования полей LAS файла
  Future loadLasIgnore() => File(r'data/las.ignore.json')
      .readAsString(encoding: utf8)
      .then((buffer) => lasIgnore = json.decode(buffer));

  /// Очищает папки, подготавливает распаковщик,
  /// открывает файл с ошибками для записи
  Future<void> initializing() async {
    final dirOut = Directory(ssPathOut);
    if (await dirOut.exists()) {
      await dirOut.delete(recursive: true);
    }
    await dirOut.create(recursive: true);
    if (dirOut.isAbsolute == false) {
      ssPathOut = dirOut.absolute.path;
    }

    unzipper = Unzipper(p.join(ssPathOut, 'temp'), ssPath7z);

    pathOutLas = p.join(ssPathOut, 'las');
    pathOutInk = p.join(ssPathOut, 'ink');
    pathOutErrors = p.join(ssPathOut, 'errors');

    await Future.wait([
      unzipper.clear(),
      Directory(pathOutLas).create(recursive: true),
      Directory(pathOutInk).create(recursive: true),
      Directory(pathOutErrors).create(recursive: true)
    ]);

    errorsOut = File(p.join(pathOutErrors, '.errors.txt'))
        .openWrite(encoding: utf8, mode: FileMode.writeOnly);
    errorsOut.writeCharCode(unicodeBomCharacterRune);
  }

  /// Отправляет страницу с натсройками
  Future servSettings(final HttpResponse response) async {
    response.headers.contentType = ContentType.html;
    response.statusCode = HttpStatus.ok;
    response.write(
        updateBufferByThis(await File(r'web/index.html').readAsString()));
    await response.flush();
    await response.close();
  }

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

  Future<ProcessResult> runDoc2X(
          final String path2doc, final String path2out) =>
      Process.run(ssPathWordconv, ['-oice', '-nme', path2doc, path2out]);
}
