import 'dart:io';

import 'package:knc/src/las/index.dart';

void main(List<String> args) {
  final pathList = File(r'.ignore\files\las\__out.txt').readAsLinesSync()
    ..removeWhere((e) => e.isEmpty);
  final s = StringBuffer('\uFEFF');
  for (var path in pathList) {
    final data = File(path).readAsBytesSync();
    if (Las.validate(data)) {
      final las = Las(data);
      s.writeln(las.well);
      File(path + '.txt').writeAsStringSync('\uFEFF' + las.debugStringFull);
    }
  }
  File(r'.ignore\files\las\__wells.txt').writeAsStringSync(s.toString());
}
