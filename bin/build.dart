import 'dart:io';

import 'package:path/path.dart' as p;

const dartSdk = r'D:\ARGilyazeev\dart-sdk\bin\';

String dartType2TsType(String type) => type == 'String'
    ? 'string'
    : type == 'num'
        ? 'number'
        : type == 'int'
            ? 'number'
            : type == 'double'
                ? 'number'
                : type == 'bool'
                    ? 'boolean'
                    : type == 'dynamic'
                        ? 'any'
                        : type == 'List'
                            ? 'Array'
                            : type;

List<String> getDocComments(String data) => data
    .trim()
    .split('\n')
    .map((e) => e.trim())
    .where((e) => e.startsWith('///'))
    .map((e) => e.substring(3))
    .toList(growable: false);

String wrtieDocCommentsTs(List<String> comments, [tabs = 0]) =>
    ''.padLeft(tabs, '\t') +
    '/**\r\n' +
    comments.map((e) => ''.padLeft(tabs, '\t') + ' *' + e).join('\r\n') +
    '\r\n' +
    ''.padLeft(tabs, '\t') +
    ' */';

String wrtieDocCommentsDart(List<String> comments, [tabs = 0]) =>
    comments.map((e) => ''.padLeft(tabs, '\t') + '///' + e).join('\r\n');

// ignore: slash_for_doc_comments
/**
```regexp
((?:^\s*\/\/\/.*\r?\n)*)\s*
?enum\s+(\w+)
?\s*\{
```
- 1 - doc comment
- 2 - enum ident
*/
final reEnumHead = RegExp(
    r'((?:^\s*\/\/\/.*\r?\n)*)\s*'
    r'enum\s+(\w+)'
    r'\s*\{',
    multiLine: true);

// ignore: slash_for_doc_comments
/**
```regexp
((?:^\s*\/\/\/.*\r?\n)*)\s*
?(\w+)
```
- 1 - doc comment
- 2 - member ident
*/
final reEnumMember = RegExp(
    r'((?:^\s*\/\/\/.*\r?\n)*)\s*'
    r'(\w+)(?:\s*,)?',
    multiLine: true);

class DartEnum {
  /// Комментарии Enum
  List<String> /*?*/ docComments;

  /// Наименование Enum
  String ident;

  /// Комментарии Enum
  List<List<String> /*?*/ > namesDocComments;

  /// Список нименований
  List<String> names;

  static DartEnum getByRegExpMatch(final RegExpMatch match) {
    final o = DartEnum();
    final _docComments = match.group(1);
    o.ident = match.group(2);
    if (_docComments != null && _docComments.trim().isNotEmpty) {
      o.docComments = getDocComments(_docComments);
    }
    final _input = match.input;
    final _body =
        _input.substring(match.end, _input.indexOf('}', match.end)).trim();

    o.names = [];
    o.namesDocComments = [];
    if (_body.isNotEmpty) {
      final matches = reEnumMember.allMatches(_body);
      for (var match in matches) {
        final _docComments = match.group(1);
        o.names.add(match.group(2));
        if (_docComments != null && _docComments.trim().isNotEmpty) {
          o.namesDocComments.add(getDocComments(_docComments));
        } else {
          o.namesDocComments.add(null);
        }
      }
    }
    return o;
  }

  /// Распарсить Dart файл
  static List<DartEnum> getByString(String data) {
    final o = <DartEnum>[];
    final matches = reEnumHead.allMatches(data);
    for (var match in matches) {
      o.add(getByRegExpMatch(match));
    }
    return o;
  }

  /// Получить строку как TS интерфейс
  String getTsInterface([int tabs = 0]) {
    final str = StringBuffer();
    if (docComments != null && docComments.isNotEmpty) {
      str.writeln(wrtieDocCommentsTs(docComments, tabs));
    }
    str.writeln(''.padLeft(tabs, '\t') + 'export enum $ident {');
    final _l = names.length;
    for (var i = 0; i < _l; i++) {
      final _docComments = namesDocComments[i];
      if (_docComments != null && _docComments.isNotEmpty) {
        str.writeln(wrtieDocCommentsTs(_docComments, tabs + 1));
      }
      str.writeln(''.padLeft(tabs + 1, '\t') + names[i] + ',');
    }
    str.writeln(''.padLeft(tabs, '\t') + '}');
    return str.toString();
  }

  String getDartEnum([int tabs = 0]) {
    final str = StringBuffer();
    if (docComments != null && docComments.isNotEmpty) {
      str.writeln(wrtieDocCommentsDart(docComments, tabs));
    }
    str.writeln(''.padLeft(tabs, '\t') + 'enum $ident {');
    final _l = names.length;
    for (var i = 0; i < _l; i++) {
      final _docComments = namesDocComments[i];
      if (_docComments != null && _docComments.isNotEmpty) {
        str.writeln(wrtieDocCommentsDart(_docComments, tabs + 1));
      }
      str.writeln(''.padLeft(tabs + 1, '\t') + names[i] + ',');
    }
    str.writeln(''.padLeft(tabs, '\t') + '}');
    return str.toString();
  }
}

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
    r'(\w+(?:\s*\<\w+\>)?(?:\s*\/\*\?\*\/)?)'
    r'\s+(\w+);',
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

  /// Унаследован ли
  bool inherited;

  static DartClassMember inherite(DartClassMember m, DartClass from) {
    final o = DartClassMember();
    o.docComments = m.docComments;
    // o.type = m.type;
    // o.typeGenericsNames = m.typeGenericsNames;
    o.ident = m.ident;
    o.canBeNull = m.canBeNull;
    o.inherited = true;

    final _super = from.superClass;

    o.type = m.type;
    if (_super.genericsNames != null && _super.genericsNames.contains(m.type)) {
      final i0 = _super.genericsNames.indexOf(m.type);
      if (from.superClassGenericsNames != null &&
          from.superClassGenericsNames.length > i0) {
        o.type = from.superClassGenericsNames[i0];
      } else {
        o.type = 'dynamic';
      }
    }

    o.typeGenericsNames = m.typeGenericsNames;
    if (m.typeGenericsNames != null && m.typeGenericsNames.isNotEmpty) {
      o.typeGenericsNames = m.typeGenericsNames.map((e) {
        if (_super.genericsNames != null && _super.genericsNames.contains(e)) {
          final i0 = _super.genericsNames.indexOf(e);
          if (from.superClassGenericsNames != null &&
              from.superClassGenericsNames.length > i0) {
            return from.superClassGenericsNames[i0];
          }
        }
        return 'dynamic';
      }).toList(growable: false);
    }
    return o;
  }

  static DartClassMember getByRegExpMatch(final RegExpMatch match) {
    final o = DartClassMember();
    final _docComments = match.group(1);
    var _type = match.group(2);
    o.ident = match.group(3);
    if (_docComments != null && _docComments.trim().isNotEmpty) {
      o.docComments = getDocComments(_docComments);
    }
    if (_type.endsWith('/*?*/')) {
      _type = _type.substring(0, _type.length - 5).trim();
      o.canBeNull = true;
    } else {
      o.canBeNull = false;
    }
    final i0 = _type.indexOf('<');
    if (i0 != -1) {
      o.typeGenericsNames = _type
          .substring(i0 + 1, _type.lastIndexOf('>'))
          .split(',')
          .map((e) => e.trim())
          .toList(growable: false);
      o.type = _type.substring(0, i0).trim();
    } else {
      o.type = _type;
    }
    o.inherited = false;
    return o;
  }

  /// Распарсить Dart class Body
  static List<DartClassMember> getByString(String data) {
    final o = <DartClassMember>[];
    final matches = reClassMember.allMatches(data);
    for (var match in matches) {
      o.add(getByRegExpMatch(match));
    }
    return o;
  }

  /// Получить строку как член TS интерфейса
  String getTsInterface([int tabs = 1]) {
    final str = StringBuffer();
    if (docComments != null && docComments.isNotEmpty) {
      str.writeln(wrtieDocCommentsTs(docComments, tabs));
    }
    str.writeln(''.padLeft(tabs, '\t') +
        ident +
        (canBeNull ? '?: ' : ': ') +
        dartType2TsType(type) +
        (typeGenericsNames != null && typeGenericsNames.isNotEmpty
            ? '<' +
                typeGenericsNames.map((e) => dartType2TsType(e)).join(', ') +
                '>'
            : '') +
        ';');
    return str.toString();
  }

  /// Получить строку как член Dart класса
  String getDartMember([int tabs = 1]) {
    final str = StringBuffer();
    if (docComments != null && docComments.isNotEmpty) {
      str.writeln(wrtieDocCommentsDart(docComments, tabs));
    }
    str.writeln(''.padLeft(tabs, '\t') +
        type +
        (typeGenericsNames != null && typeGenericsNames.isNotEmpty
            ? '<' + typeGenericsNames.join(', ') + '>'
            : '') +
        (canBeNull ? ' /*?*/ ' : ' ') +
        ident +
        ';');
    return str.toString();
  }

  /// Получить строку как установка значения Dart члена с помощью json данных
  String getDartJsonGetter([String json = '_json']) =>
      '$ident = $json[\'$ident\'] as $type' + (canBeNull ? ' /*?*/' : '');

  /// Получить строку как установка значения json поля
  String getDartJsonSetter([int tabs = 2]) =>
      ''.padLeft(tabs, '\t') + '\'$ident\': $ident,';
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

  /// Супер класс
  DartClass /*?*/ superClass;

  static DartClass getByRegExpMatch(final RegExpMatch match,
      [final List<DartClass> ctx]) {
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
      if (ctx != null &&
          ctx.isNotEmpty &&
          ctx.any((e) => e.ident == o.superClassName)) {
        o.superClass = ctx.firstWhere((e) => e.ident == o.superClassName);
        final _superMembers = o.superClass.members;
        if (_superMembers != null && _superMembers.isNotEmpty) {
          o.members =
              _superMembers.map((e) => DartClassMember.inherite(e, o)).toList();
        }
      }
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
      o.genericsNames = _genParams.map((e) => e[0]).toList(growable: false);
      o.genericsExtends = _genParams
          .map((e) => e.length > 1 ? e[1] : null)
          .toList(growable: false);
    }

    final _input = match.input;
    final _body =
        _input.substring(match.end, _input.indexOf('}', match.end)).trim();
    if (_body.isNotEmpty) {
      if (o.members != null) {
        o.members.addAll(DartClassMember.getByString(_body));
      } else {
        o.members = DartClassMember.getByString(_body);
      }
    }
    return o;
  }

  /// Распарсить Dart файл
  static List<DartClass> getByString(String data) {
    final o = <DartClass>[];
    final matches = reClassHead.allMatches(data);
    for (var match in matches) {
      o.add(getByRegExpMatch(match, o));
    }
    return o;
  }

  /// Получить строку как TS интерфейс
  String getTsInterface([int tabs = 0]) {
    final str = StringBuffer();
    if (docComments != null && docComments.isNotEmpty) {
      str.writeln(wrtieDocCommentsTs(docComments, tabs));
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
        if (!member.inherited) {
          str.writeln(member.getTsInterface(tabs + 1));
        }
      }
    }
    str.writeln('}');
    return str.toString();
  }

  String getDartClassConstructorDefault([int tabs = 1]) {
    final str = StringBuffer();
    str.writeln(''.padLeft(tabs, '\t') + ident + '({');
    if (members != null && members.isNotEmpty) {
      for (var member in members) {
        if (member.inherited) {
          str.writeln(''.padLeft(tabs + 1, '\t') +
              '${member.type} ${member.canBeNull ? '/*?*/ ' : ''} ${member.ident},');
        } else {
          str.writeln(''.padLeft(tabs + 1, '\t') + 'this.${member.ident},');
        }
      }
    }
    str.write(''.padLeft(tabs, '\t') + '})');
    if (superClassName != null && superClassName.isNotEmpty) {
      str.writeln(' : super(');
      if (members != null && members.isNotEmpty) {
        for (var member in members) {
          if (member.inherited) {
            str.writeln(''.padLeft(tabs + 4, '\t') +
                '${member.ident} : ${member.ident},');
          }
        }
      }
      str.writeln(''.padLeft(tabs + 3, '\t') + ');');
    } else {
      str.writeln(';');
    }
    return str.toString();
  }

  String getDartClassConstructorArray([int tabs = 1]) {
    final str = StringBuffer();
    str.writeln(''.padLeft(tabs, '\t') + ident + '.a([');
    if (members != null && members.isNotEmpty) {
      for (var member in members) {
        if (member.inherited) {
          str.writeln(''.padLeft(tabs + 1, '\t') +
              '${member.type} ${member.canBeNull ? '/*?*/ ' : ''} ${member.ident},');
        } else {
          str.writeln(''.padLeft(tabs + 1, '\t') + 'this.${member.ident},');
        }
      }
    }
    str.write(''.padLeft(tabs, '\t') + '])');
    if (superClassName != null && superClassName.isNotEmpty) {
      str.writeln(' : super.a(');
      if (members != null && members.isNotEmpty) {
        for (var member in members) {
          if (member.inherited) {
            str.writeln(''.padLeft(tabs + 4, '\t') + '${member.ident},');
          }
        }
      }
      str.writeln(''.padLeft(tabs + 3, '\t') + ');');
    } else {
      str.writeln(';');
    }
    return str.toString();
  }

  String getDartClassConstructorJson([int tabs = 1, String json = '_json']) {
    final str = StringBuffer();
    str.writeln(
        ''.padLeft(tabs, '\t') + ident + '.byJson(Map<String,dynamic> $json)');
    var bFirst = true;
    if (members != null && members.isNotEmpty) {
      for (var member in members) {
        if (!member.inherited) {
          if (bFirst) {
            str.write(''.padLeft(tabs + 2, '\t') +
                ': ' +
                member.getDartJsonGetter(json));
            bFirst = false;
          } else {
            str.writeln(',');
            str.write(''.padLeft(tabs + 2, '\t') +
                '  ' +
                member.getDartJsonGetter(json));
          }
        }
      }
    }
    if (superClassName != null && superClassName.isNotEmpty) {
      if (bFirst) {
        str.write(''.padLeft(tabs + 2, '\t') + ': super.byJson($json)');
        bFirst = false;
      } else {
        str.writeln(',');
        str.write(''.padLeft(tabs + 2, '\t') + '  super.byJson($json)');
      }
    }
    str.writeln(';');
    return str.toString();
  }

  String getDartClassJsonGenerator([int tabs = 1]) {
    final str = StringBuffer();
    str.writeln(''.padLeft(tabs, '\t') + 'Map<String, dynamic> toJson() => {');
    if (members != null && members.isNotEmpty) {
      final _l = members.length;
      for (var i = 0; i < _l; i++) {
        str.writeln(members[i].getDartJsonSetter(tabs + 3));
      }
    }
    str.writeln(''.padLeft(tabs + 2, '\t') + '};');
    return str.toString();
  }

  String getDartClass([int tabs = 0]) {
    final str = StringBuffer();
    if (docComments != null && docComments.isNotEmpty) {
      str.writeln(wrtieDocCommentsDart(docComments, tabs));
    }
    str.write(''.padLeft(tabs, '\t') + 'class $ident');
    if (genericsNames != null && genericsNames.isNotEmpty) {
      str.write('<' + genericsNames[0]);
      if (genericsExtends[0] != null && genericsExtends[0].isNotEmpty) {
        str.write(' extends ' + genericsExtends[0]);
      }
      final _l = genericsNames.length;
      for (var i = 1; i < _l; i++) {
        str.write(', ' + genericsNames[i]);
        if (genericsExtends[i] != null && genericsExtends[i].isNotEmpty) {
          str.write(' extends ' + genericsExtends[i]);
        }
      }
      str.write('>');
    }
    if (superClassName != null && superClassName.isNotEmpty) {
      str.write(' extends ' + superClassName);
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
        if (!member.inherited) {
          str.writeln(member.getDartMember(tabs + 1));
        }
      }
    }
    str.writeln(getDartClassConstructorDefault());
    str.writeln(getDartClassConstructorArray());
    str.writeln(getDartClassConstructorJson());
    str.writeln(getDartClassJsonGenerator());
    str.writeln('}');
    return str.toString();
  }
}

/// Папка содержащие файлы которые неоходимо преобразовать
final dirLibT =
    Directory(p.join(Directory.current.absolute.path, 'lib', 'src'));

/// Папка куда будут помещены преобразованные в Dart файлы
final dirLibSrc =
    Directory(p.join(Directory.current.absolute.path, 'lib', 'src'));

/// Папка куда будут помещены преобразованные в TS файлы
final dirWebTsDart =
    Directory(p.join(Directory.current.absolute.path, 'web', 'ts', 'dart'));

void main(List<String> args) {
  final files = dirLibT.listSync();
  final _l = files.length;

  for (var i = 0; i < _l; i++) {
    final file = files[i];
    if (file is File && p.extension(file.path, 2).toLowerCase() == '.t.dart') {
      final fileData = file.readAsStringSync();
      final fileName =
          p.basenameWithoutExtension(p.basenameWithoutExtension(file.path));
      final newDartFile = File(p.join(dirLibSrc.path, fileName + '.g.dart'));
      final newTsFile = File(p.join(dirWebTsDart.path, fileName + '.g.ts'));
      final classes = DartClass.getByString(fileData);
      final enums = DartEnum.getByString(fileData);
      final strDart = StringBuffer();
      final strTs = StringBuffer();
      for (final _enum in enums) {
        strDart.writeln(_enum.getDartEnum());
        strTs.writeln(_enum.getTsInterface());
      }
      for (final _class in classes) {
        strDart.writeln(_class.getDartClass());
        strTs.writeln(_class.getTsInterface());
      }

      newDartFile.writeAsStringSync(strDart.toString());
      newTsFile.writeAsStringSync(strTs.toString());
    }
  }
}
