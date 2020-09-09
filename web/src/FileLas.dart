import 'dart:convert';
import 'dart:html';

import 'package:knc/knc.dart';

import 'misc.dart';

class FileLas {
  Element e;
  OneFileData oneFileData;
  List<String> fileData;

  Future<bool> open(OneFileData file, [final String query]) async {
    if (file == null || file.path == null) {
      return false;
    }
    print('try to open ${file.path}');

    /// Обновляем данные о файле
    if (oneFileData == null || !oneFileData.path.endsWith(file.path)) {
      final _msg = await requestOnce('$wwwGetOneFileData${file.path}');
      if (_msg.isEmpty) {
        return false;
      }
      oneFileData = OneFileData.byJsonFull(jsonDecode(_msg));
      e?.remove();
    }
    if (oneFileData.type != NOneFileDataType.las) {
      return false;
    }
    if (e == null) {
      e = document.createElement('main')
        ..classes.addAll(['opend-file', 'a-opening', 'las'])
        ..append(DivElement()
          ..classes.add('file-sets')
          ..append(SpanElement()
            ..classes.add('file-sets-type')
            ..innerText =
                'Тип: ${file.type.toString().substring(file.type.runtimeType.toString().length)}')
          ..append(SpanElement()
            ..classes.add('file-sets-size')
            ..innerText = 'Размер: ${file.size} байт'));

      e.addEventListener('animationend', (event) {
        if ((event as AnimationEvent).animationName == 'slideout') {
          e.hidden = true;
          e.classes.remove('a-closing');
        } else if ((event as AnimationEvent).animationName == 'slidein') {
          e.hidden = false;
          e.classes.remove('a-opening');
        }
      });
    } else {
      e.classes.add('a-opening');
      e.hidden = false;
    }
    closeAll('opend-file');
    return false;
  }

  FileLas._init();
  static FileLas _instance;
  factory FileLas() => _instance ?? (_instance = FileLas._init());
}
