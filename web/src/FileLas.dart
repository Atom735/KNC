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
    if (oneFileData == null || !oneFileData.path.endsWith(file.path)) {
      final _msg = await requestOnce('$wwwGetOneFileData${file.path}');
      if (_msg.isEmpty) {
        return false;
      }
      oneFileData = OneFileData.byJsonFull(jsonDecode(_msg));
    }

    return false;
  }

  FileLas._init();
  static FileLas _instance;
  factory FileLas() => _instance ?? (_instance = FileLas._init());
}
