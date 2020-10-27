import 'dart:convert';
import 'dart:io';
import 'package:knc/src/las.dart';
import 'package:path/path.dart' as p;

import 'Conv.dart';

void _mainStepLas(List<String> list) {
  list.forEach((e) {
    final ext = p.extension(e).toLowerCase();
    if (ext == '.las') {
      final data = Conv().decode(File(e).readAsBytesSync());
      final las = IOneFileLasData.createByString(data.data);
      if (las != null) {
        final str = StringBuffer();
        str.writeCharCode(unicodeBomCharacterRune);
        str.writeln(e);
        str.write(las.getDebugString);
        File(e + '.txt').writeAsStringSync(str.toString());
      }
    }
  });
}

void main(List<String> args) async {
  await Conv.init();
  _mainStepLas(File(p.join('.ignore', 'files', 'las', '__out.txt'))
      .absolute
      .readAsLinesSync());
}
