import 'dart:convert';
import 'dart:io';
import 'package:knc/src/ink.txt.dart';
import 'package:knc/src/office.word.dart';
import 'package:path/path.dart' as p;

import 'Conv.dart';

Future _mainStepDoc2x(Directory dir) {
  final _f = <Future>[];
  dir.listSync(recursive: true).forEach((e) {
    if (e is File) {
      final ext = p.extension(e.path).toLowerCase();
      if (ext == '.doc') {
        _f.add(Conv().doc2x(e.path, e.path + '.docx'));
      }
    }
  });
  return Future.wait(_f);
}

Future _mainStepUnZipDocx(Directory dir) {
  final _f = <Future>[];
  dir.listSync(recursive: true).forEach((e) {
    if (e is File) {
      final ext = p.extension(e.path).toLowerCase();
      if (ext == '.docx') {
        _f.add(Conv().unzip(e.path, e.path + '.dir'));
      }
    }
  });
  return Future.wait(_f);
}

void main(List<String> args) async {
  await Conv.init();
  final dir = Directory(
      '\\\\?\\' + Directory(p.join('.ignore', 'files', 'doc')).absolute.path);
  // await _mainStepDoc2x(dir);
  // await _mainStepUnZipDocx(dir);
  dir.listSync(recursive: true).forEach((e) {
    if (e is Directory) {
      final ext = p.extension(e.path, 2).toLowerCase();
      if (ext == '.docx.dir') {
        final doc = OfficeWordDocument.createByXmlString(
            File(p.join(e.path, 'word', 'document.xml')).readAsStringSync());
        if (doc != null) {
          final str = StringBuffer();
          str.writeCharCode(unicodeBomCharacterRune);
          str.writeln('РАЗОБРАННЫЙ WORD файл');
          str.writeln(doc.toString());
          File(e.path + '.txt').writeAsStringSync(str.toString());
        }
      }
    }
  });
}
