import 'dart:convert';
import 'dart:io';
import 'package:knc/src/dbf.dart';
import 'package:knc/src/ink.dbf.dart';
import 'package:path/path.dart' as p;

void main(List<String> args) {
  final dir = Directory(p.join('.ignore', 'files', 'dbf')).absolute;
  dir.listSync(recursive: true).forEach((e) {
    if (e is File) {
      final ext = p.extension(e.path).toLowerCase();
      if (ext == '.dbf') {
        final str = StringBuffer();
        final dbf = IOneFileDbf.createByByteData(
            e.readAsBytesSync().buffer.asByteData());
        if (dbf != null) {
          str.writeCharCode(unicodeBomCharacterRune);
          str.write(dbf.getDebugString());
          File(e.path + '.txt').writeAsStringSync(str.toString());
          final ink = IOneFileInkDataDbf.createByDbf(dbf);
          if (ink != null) {
            str.writeCharCode(unicodeBomCharacterRune);
            str.write(ink.getDebugString());
            File(e.path + '.ink.txt').writeAsStringSync(str.toString());
          }
        }
      }
    }
  });
}
