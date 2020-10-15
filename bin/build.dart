import 'dart:io';

import 'package:path/path.dart' as p;

const dartSdk = r'D:\ARGilyazeev\dart-sdk\bin\';

String dartType2TsType(String type) {
  type = type
      .trim()
      .replaceAll('String', 'string')
      .replaceAll('num', 'number')
      .replaceAll('int', 'number')
      .replaceAll('double', 'number')
      .replaceAll('bool', 'boolean')
      .replaceAll('List', 'Array');
  return type.endsWith('/*?*/') ? '?: $type' : ': $type';
}

String dartTypeFromJson(String type) {
  type = type
      .trim()
      .replaceAll('String', 'string')
      .replaceAll('num', 'number')
      .replaceAll('int', 'number')
      .replaceAll('double', 'number')
      .replaceAll('bool', 'boolean')
      .replaceAll('List', 'Array');
  return type.endsWith('/*?*/') ? '?: $type' : ': $type';
}

void main(List<String> args) {
  final dirLibTs =
      Directory(p.join(Directory.current.absolute.path, 'lib', 'ts'));
  final dirLibSrc =
      Directory(p.join(Directory.current.absolute.path, 'lib', 'src'));
  final dirWebTsDart =
      Directory(p.join(Directory.current.absolute.path, 'web', 'ts', 'dart'));
  final files = dirLibTs.listSync();
  final _l = files.length;

  /// 1 - doc comment
  /// 2 - name
  /// 3 - body of class
  final reClassHead = RegExp(
      r'((?:^\s*\/\/\/.*\r?\n)*)\s*class\s+(\w+)\s*{([\s\S]*?)}',
      multiLine: true);

  /// 1 - doc comment
  /// 2 - type
  /// 3 - ident
  final reClassMem = RegExp(
      r'((?:^\s*\/\/.*\r?\n)*)\s*(\w+(?:\s*\<\s*\w*(?:\s*\/\*\?\*\/)?\>)?(?:\s*\/\*\?\*\/)?)\s+(\w+)\s*;',
      multiLine: true);

  for (var i = 0; i < _l; i++) {
    final file = files[i];
    if (file is File) {
      final fileData = file.readAsStringSync();
      final newDartFile = File(p.join(
          dirLibSrc.path, p.basenameWithoutExtension(file.path) + '.g.dart'));
      final newTsFile = File(p.join(
          dirWebTsDart.path, p.basenameWithoutExtension(file.path) + '.g.ts'));
      final classes = reClassHead.allMatches(fileData);
      final strDart = StringBuffer();
      final strTs = StringBuffer();
      for (final match in classes) {
        final classComment = match.group(1);
        final className = match.group(2);
        strDart.write(classComment);
        strDart.write('class $className {\r\n');
        strTs.write(classComment);
        strTs.write('export interface $className {\r\n');

        final classBody = match.group(3);
        final members = reClassMem.allMatches(classBody);
        final memTypes = <String>[];
        final memNames = <String>[];
        for (final member in members) {
          final memComment = member.group(1);
          final memType = member.group(2);
          final memName = member.group(3);
          memTypes.add(memType);
          memNames.add(memName);

          strDart.write(memComment);
          strDart.write('  $memType $memName;');

          strTs.write(memComment);
          strTs.write('    $memName${dartType2TsType(memType)};');
        }
        strTs.write('\r\n}\r\n');

        /// Начало конструктора по умолчанию
        strDart.write('\r\n  $className(');
        final _lMem = memNames.length;
        var optMem = false;
        var jA = false;
        for (var j = 0; j < _lMem; j++) {
          final memType = memTypes[j];
          final memName = memNames[j];
          if (!memType.endsWith('/*?*/')) {
            if (jA) {
              strDart.write(', ');
            }
            strDart.write('this.$memName');
            jA = true;
          } else {
            optMem = true;
          }
        }
        if (optMem) {
          if (jA) {
            strDart.write(', {');
          }
          jA = false;
          for (var j = 0; j < _lMem; j++) {
            final memType = memTypes[j];
            final memName = memNames[j];
            if (memType.endsWith('/*?*/')) {
              if (jA) {
                strDart.write(', ');
              }
              strDart.write('this.$memName');
              jA = true;
            }
          }
          strDart.write('}');
        }

        strDart.write(');\r\n');
        // Конец конструктора по умолчанию

        /// Начало конструктора от `JSON`
        strDart.write('  $className.byJSON(Map<String, dynamic> m)\r\n');
        jA = false;
        for (var j = 0; j < _lMem; j++) {
          final memType = memTypes[j];
          final memName = memNames[j];
          if (!jA) {
            strDart.write('      : ');
          } else {
            strDart.write(',\r\n        ');
          }
          strDart.write('$memName = m[\'$memName\'] as $memType');
          jA = true;
        }
        strDart.write(';\r\n');
        // Конец конструктора от `JSON`

        /// Начало генератора `JSON`
        strDart.write('  Map<String, dynamic> toJson() => {\r\n');
        for (var j = 0; j < _lMem; j++) {
          final memName = memNames[j];
          strDart.write('        \'$memName\': $memName,\r\n');
        }
        strDart.write('\r\n      };\r\n');
        // Конец генератора `JSON`

        strDart.write('}\r\n');
      }

      newDartFile.writeAsStringSync(strDart.toString());
      newTsFile.writeAsStringSync(strTs.toString());
    }
  }
}
