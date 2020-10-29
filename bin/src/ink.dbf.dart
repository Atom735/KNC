import 'dart:convert';
import 'dart:io';
import 'package:knc/src/dbf.dart';
import 'package:knc/src/ink.dbf.dart';
import 'package:path/path.dart' as p;

import 'Conv.dart';

void _mainStepInkDbf(List<String> list) {
  list.forEach((e) {
    try {
      final ext = p.extension(e).toLowerCase();
      if (ext == '.dbf') {
        final dbf = IOneFileDbf.createByByteData(
            File(e).readAsBytesSync().buffer.asByteData());
        if (dbf != null) {
          final str = StringBuffer();
          str.writeCharCode(unicodeBomCharacterRune);
          str.write(dbf.getDebugString());
          File(e + '.txt').writeAsStringSync(str.toString());
          final ink = IOneFileInkDataDbf.createByDbf(dbf);
          if (ink != null) {
            final str = StringBuffer();
            str.writeCharCode(unicodeBomCharacterRune);
            str.write(ink.getDebugString());
            File(e + '.ink.txt').writeAsStringSync(str.toString());
            final _k = ink.normalizeInkFileData();
            _k.forEach((key, value) {
              final str2 = StringBuffer();
              str2.writeCharCode(unicodeBomCharacterRune);
              str2.writeln(e);
              str2.write(value);
              File(e + '.ink.$key.txt').writeAsStringSync(str2.toString());
            });
          }
        }
      }
    } catch (_e, bt) {
      print(e);
      print(_e);
      print(bt);
    }
  });
}

void main(List<String> args) async {
  await Conv.init();
  _mainStepInkDbf(File(p.join('.ignore', 'files', 'dbf', '__out.txt'))
      .absolute
      .readAsLinesSync());
}
