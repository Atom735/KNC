import 'dart:io';

import 'package:path/path.dart' as p;

main(List<String> args) {
  final _re = RegExp(
      r"(\[[\r\n\s]*(?:[\r\n\s]*ConstUniSymbol[\r\n\s]*\([\r\n\s]*.*?,[\r\n\s]*.*?,[\r\n\s]*r'.*?'[\r\n\s]*\)[\r\n\s]*,[\r\n\s]*)*)(?:ConstUniSymbol[\r\n\s]*\([\r\n\s]*(.*?),[\r\n\s]*(.*?),[\r\n\s]*(r'.*?')[\r\n\s]*\)[\r\n\s]*,[\r\n\s]*)\][\r\n\s]*,[\r\n\s]*\[(.*?)\][\r\n\s]*,[\r\n\s]*\[(.*?)\][\r\n\s]*,[\r\n\s]*\[(.*?)\]");
  Directory(p.join('lib', 'src', 'charmaps')).listSync().forEach((e) {
    if (e is File) {
      var _data = e.readAsStringSync();

      while (_re.hasMatch(_data)) {
        _data = _data.replaceAllMapped(
            _re,
            (m) =>
                '${m[1]}], [${m[3]},${m[5]}], [${m[3]}:${m[2]},${m[6]}], [${m[4]},${m[7]}]');
      }
      e.writeAsStringSync(_data);
    }
  });
}
