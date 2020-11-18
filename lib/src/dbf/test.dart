import 'dart:io';
import 'dart:typed_data';

import 'index.dart';

void main(List<String> args) {
  final pathList = File(r'.ignore\files\dbf\__out.txt').readAsLinesSync()
    ..removeWhere((e) => e.isEmpty);
  for (var path in pathList) {
    final data = ByteData.sublistView(File(path).readAsBytesSync());
    if (Dbf.validate(data)) {
      final dbf = Dbf(data);
      File(path + '.txt').writeAsStringSync('\uFEFF' + dbf.debugStringFull);
    }
  }
}
