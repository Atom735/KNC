import 'dart:io';

import 'package:path/path.dart' as p;

const dartSdk = r'D:\ARGilyazeev\dart-sdk\bin\';

String dartType2TsType(String type) => type
    .trim()
    .replaceAll('String', 'string')
    .replaceAll('num', 'number')
    .replaceAll('int', 'number')
    .replaceAll('double', 'number')
    .replaceAll('bool', 'boolean')
    .replaceAll('dynamic', 'any')
    .replaceAll('List', 'Array');

List<String> getDocComments(String data) => data
    .trim()
    .split('\n')
    .map((e) => e.trim())
    .where((e) => e.startsWith('///'))
    .map((e) => e.substring(3))
    .toList(growable: false);

// ignore: slash_for_doc_comments
/**
```regexp
((?:^\s*\/\/\/.*\r?\n)*)\s*
?(\w+(?:\s*\<\w+\>)?(?:\s*\/\*\?\*\/)?)
?\s+(\w+);
```
- 1 - doc comment
- 2 - varable type
- 3 - varable ident
*/
final reClassMember = RegExp(
    r'((?:^\s*\/\/\/.*\r?\n)*)\s*'
    r'?(\w+(?:\s*\<\w+\>)?(?:\s*\/\*\?\*\/)?)'
    r'?\s+(\w+);',
    multiLine: true);

class DartClassMember {
  /// Комментарии класса
  List<String> /*?*/ docComments;

  /// Наименование типа
  String type;

  /// Наименования дженерников типа
  List<String> /*?*/ typeGenericsNames;

  /// Наименование переменной
  String ident;

  /// Может ли отсутсвовать
  bool canBeNull;

  static DartClassMember getByRegExpMatch(final RegExpMatch match) {
    final o = DartClassMember();
    final _docComments = match.group(1);
    final _type = match.group(2);
    o.ident = match.group(3);
    if (_docComments != null && _docComments.trim().isNotEmpty) {
      o.docComments = getDocComments(_docComments);
    }
    if (_type.endsWith('/*?*/')) {
      o.type = _type.substring(0, _type.length - 5).trim();
      o.canBeNull = true;
    } else {
      o.type = _type;
      o.canBeNull = false;
    }
    return o;
  }

  /// Распарсить Dart class Body
  static List<DartClassMember> getByString(String data) {
    final o = <DartClassMember>[];
    final matches = reClassHead.allMatches(data);
    for (var match in matches) {
      o.add(getByRegExpMatch(match));
    }
    return o;
  }

  /// Получить строку как член TS интерфейса
  String getTsInterface([int tabs = 1]) {
    final str = StringBuffer();
    if (docComments != null) {
      str.writeln(''.padLeft(tabs, '\t') + '/**');
      for (var comment in docComments) {
        str.writeln(''.padLeft(tabs, '\t') + ' *' + comment);
      }
      str.writeln(''.padLeft(tabs, '\t') + ' */');
    }
    str.writeln(''.padLeft(tabs, '\t') +
        ident +
        (canBeNull ? '?: ' : ': ') +
        dartType2TsType(type) +
        ';');
    return str.toString();
  }
}

// ignore: slash_for_doc_comments
/**
```regexp
((?:^\s*\/\/\/.*\r?\n)*)\s*
?class\s+(\w+)
?(?:\s*\<\s*(\w+(?:\s+extends\s+\w+)?
?(?:\s*\,\s*\w+(?:\s+extends\s+\w+)?)*)\s*\>)?
?(?:\s+extends\s+(\w+)
?(?:\s*\<\s*(\w+(?:\s+extends\s+\w+)?
?(?:\s*\,\s*\w+(?:\s+extends\s+\w+)?)*)\s*\>)?)?
?\s*\{
```
- 1 - doc comment
- 2 - class ident
- 3 - generic params
- 4 - superclass name
- 5 - superclass generic params
*/
final reClassHead = RegExp(
    r'((?:^\s*\/\/\/.*\r?\n)*)\s*'
    r'class\s+(\w+)'
    r'(?:\s*\<\s*(\w+(?:\s+extends\s+\w+)?'
    r'(?:\s*\,\s*\w+(?:\s+extends\s+\w+)?)*)\s*\>)?'
    r'(?:\s+extends\s+(\w+)'
    r'(?:\s*\<\s*(\w+(?:\s+extends\s+\w+)?'
    r'(?:\s*\,\s*\w+(?:\s+extends\s+\w+)?)*)\s*\>)?)?'
    r'\s*\{',
    multiLine: true);

class DartClass {
  /// Комментарии класса
  List<String> /*?*/ docComments;

  /// Имя класса
  String ident;

  /// Наименования дженерников
  List<String> /*?*/ genericsNames;

  /// Расширения джинерников
  List<String /*?*/ > /*?*/ genericsExtends;

  /// Имя суперкласса
  String /*?*/ superClassName;

  /// Наименования дженерников суперкласса
  List<String> /*?*/ superClassGenericsNames;

  /// Члены класса
  List<DartClassMember> /*?*/ members;

  static DartClass getByRegExpMatch(final RegExpMatch match) {
    final o = DartClass();
    final _docComments = match.group(1);
    o.ident = match.group(2);
    final _genericParams = match.group(3);
    final _superClassName = match.group(4);
    final _superClassGenericsNames = match.group(5);
    if (_docComments != null && _docComments.trim().isNotEmpty) {
      o.docComments = getDocComments(_docComments);
    }
    if (_superClassName != null && _superClassName.trim().isNotEmpty) {
      o.superClassName = _superClassName.trim();
    }
    if (_superClassGenericsNames != null &&
        _superClassGenericsNames.trim().isNotEmpty) {
      o.superClassGenericsNames = _superClassGenericsNames
          .trim()
          .split(',')
          .map((e) => e.trim())
          .toList(growable: false);
    }
    if (_genericParams != null && _genericParams.trim().isNotEmpty) {
      final _genParams = _genericParams
          .trim()
          .split(',')
          .map((e) => e
              .trim()
              .split('extends')
              .map((e) => e.trim())
              .toList(growable: false))
          .toList(growable: false);
      o.genericsNames = _genParams.map((e) => e[0]);
      o.genericsExtends = _genParams.map((e) => e.length > 1 ? e[1] : null);
    }

    final _input = match.input;
    final _body =
        _input.substring(match.end, _input.indexOf('}', match.end)).trim();
    if (_body.isNotEmpty) {
      o.members = DartClassMember.getByString(_body);
    }
    return o;
  }

  /// Распарсить Dart файл
  static List<DartClass> getByString(String data) {
    final o = <DartClass>[];
    final matches = reClassHead.allMatches(data);
    for (var match in matches) {
      o.add(getByRegExpMatch(match));
    }
    return o;
  }

  /// Получить строку как TS интерфейс
  String getTsInterface([int tabs = 0]) {
    final str = StringBuffer();
    if (docComments != null) {
      str.writeln(''.padLeft(tabs, '\t') + '/**');
      for (var comment in docComments) {
        str.writeln(''.padLeft(tabs, '\t') + ' *' + comment);
      }
      str.writeln(''.padLeft(tabs, '\t') + ' */');
    }
    str.write(''.padLeft(tabs, '\t') + 'export interface $ident');
    if (genericsNames != null && genericsNames.isNotEmpty) {
      str.write('<' + genericsNames[0]);
      if (genericsExtends[0] != null && genericsExtends[0].isNotEmpty) {
        str.write(' extends ' + dartType2TsType(genericsExtends[0]));
      }
      final _l = genericsNames.length;
      for (var i = 1; i < _l; i++) {
        str.write(', ' + genericsNames[i]);
        if (genericsExtends[i] != null && genericsExtends[i].isNotEmpty) {
          str.write(' extends ' + dartType2TsType(genericsExtends[i]));
        }
      }
      str.write('>');
    }
    if (superClassName != null && superClassName.isNotEmpty) {
      str.write(' extends ' + dartType2TsType(superClassName));
      if (superClassGenericsNames != null &&
          superClassGenericsNames.isNotEmpty) {
        str.write('<' + superClassGenericsNames[0]);
        final _l = superClassGenericsNames.length;
        for (var i = 1; i < _l; i++) {
          str.write(', ' + superClassGenericsNames[i]);
        }
        str.write('>');
      }
    }
    str.writeln(' {');
    if (members != null && members.isNotEmpty) {
      for (var member in members) {
        str.writeln(member.getTsInterface(tabs + 1));
      }
    }
    str.writeln('}');
    return str.toString();
  }
}

/// Папка содержащие файлы которые неоходимо преобразовать
final dirLibTs =
    Directory(p.join(Directory.current.absolute.path, 'lib', 'ts'));

/// Папка куда будут помещены преобразованные в Dart файлы
final dirLibSrc =
    Directory(p.join(Directory.current.absolute.path, 'lib', 'src'));

/// Папка куда будут помещены преобразованные в TS файлы
final dirWebTsDart =
    Directory(p.join(Directory.current.absolute.path, 'web', 'ts', 'dart'));

void main(List<String> args) {
  final files = dirLibTs.listSync();
  final _l = files.length;

  for (var i = 0; i < _l; i++) {
    final file = files[i];
    if (file is File) {
      final fileData = file.readAsStringSync();
      final newDartFile = File(p.join(
          dirLibSrc.path, p.basenameWithoutExtension(file.path) + '.g.dart'));
      final newTsFile = File(p.join(
          dirWebTsDart.path, p.basenameWithoutExtension(file.path) + '.g.ts'));
      final classes = DartClass.getByString(fileData);
      final strDart = StringBuffer();
      final strTs = StringBuffer();
      for (final _class in classes) {
        strTs.writeln(_class.getTsInterface());
      }

      newDartFile.writeAsStringSync(strDart.toString());
      newTsFile.writeAsStringSync(strTs.toString());
    }
  }
}
