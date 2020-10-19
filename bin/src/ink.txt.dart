import 'dart:convert';
import 'dart:io';
import 'package:knc/src/dbf.dart';
import 'package:knc/src/ink.txt.dart';
import 'package:path/path.dart' as p;

void main(List<String> args) async {
  final dir = Directory(p.join('.ignore', 'files', 'txt')).absolute;
  await dir.list(recursive: true).listen((e) {
    if (e is File) {
      final ext = p.extension(e.path).toLowerCase();
      if (ext == '.txt') {
        final path = e.path + '._.txt';
        final str = StringBuffer();
        // final ink = IOneFileInkDataTxt.createByString(
        //     e.readAsBytesSync().buffer.asByteData());
        // if (dbf != null) {
        //   str.writeCharCode(unicodeBomCharacterRune);
        //   str.write(dbf.getDebugString());
        //   File(path).writeAsStringSync(str.toString());
        // }
      }
    }
  }).asFuture();
}
