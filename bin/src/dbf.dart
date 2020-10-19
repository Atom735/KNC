import 'dart:convert';
import 'dart:io';
import 'package:knc/src/dbf.dart';
import 'package:path/path.dart' as p;

void main(List<String> args) {
  final dir = Directory(p.join('.ignore', 'files', 'dbf')).absolute;
  dir.listSync(recursive: true).forEach((e) {
    if (e is File) {
      final ext = p.extension(e.path).toLowerCase();
      if (ext == '.dbf') {
        final path = e.path + '.txt';
        final dbf = IOneFileDbf.createByByteData(
            e.readAsBytesSync().buffer.asByteData());
        if (dbf != null) {
          final str = StringBuffer();
          str.writeCharCode(unicodeBomCharacterRune);
          str.write(dbf.getDebugString());
          File(path).writeAsStringSync(str.toString());
        }
      }
    }
  });
}
