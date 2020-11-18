import 'dart:io';

import 'index.dart';

void main(List<String> args) {
  final pathList = File(r'.ignore\files\las\__out.txt').readAsLinesSync()
    ..removeWhere((e) => e.isEmpty);
  final s = StringBuffer('\uFEFF');
  final lases = <Las>[];
  for (var path in pathList) {
    final data = File(path).readAsBytesSync();
    if (Las.validate(data)) {
      try {
        final las = Las(data);
        s.writeln(las.well);
        final _str = StringBuffer('\uFEFF');
        final _k = lases.length;
        for (var i = 0; i < _k; i++) {
          final _i = las.compare(lases[i]);
          if (_i > 0.5) {
            _str.writeln(
                'СОВПАДЕНИЕ НА ${_i.toStringAsFixed(2)} С ФАЙЛОМ ${pathList[i]}');
          }
        }
        _str.write(las.debugStringFull);
        File(path + '.txt').writeAsStringSync(_str.toString());
        File(path + '.min.txt').writeAsStringSync('\uFEFF' +
            las.getViaString(
                lineFeed: '\r\n',
                addComments: true,
                deleteEmptyLines: true,
                rewriteAscii: true));
        lases.add(las);
      } catch (e, bt) {
        File(path + '.txt').writeAsStringSync('\uFEFF$e\r\n$bt');
      }
    }
  }
  File(r'.ignore\files\las\__wells.txt').writeAsStringSync(s.toString());
}
