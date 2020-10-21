import 'dart:convert';
import 'dart:io';
import 'package:knc/src/ink.txt.dart';
import 'package:path/path.dart' as p;

import 'Conv.dart';

void _mainStepTxt(Directory dir) {
  dir.listSync(recursive: true).forEach((e) {
    if (e is File) {
      final ext = p.extension(e.path).toLowerCase();
      if (ext == '.txt') {
        final data = Conv().decode(e.readAsBytesSync());
        final ink = IOneFileInkDataTxt.createByString(data.data);
        if (ink != null) {
          final str = StringBuffer();
          str.writeCharCode(unicodeBomCharacterRune);
          str.writeln(e.path);
          str.write(ink.getDebugString());
          File(e.path + '._.txt').writeAsStringSync(str.toString());
        }
      }
    }
  });
}

void main(List<String> args) async {
  await Conv.init();
  // _mainStepTxt(Directory(p.join('.ignore', 'files', 'txt')).absolute);
  final dir = Directory(
      '\\\\?\\' + Directory(p.join('.ignore', 'files', 'doc')).absolute.path);
  _mainStepTxt(Directory(
      r'\\?\D:\ARGilyazeev\github\KNC\.ignore\files\doc\Abilov\ЗАП_ЩЕРБЕНЬСКОЕ\Первичная_информация\Западно-Щербеньское м-е, ГИС\'));
}
