import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as p;

void copy(String pathIn, List<String> exts, Directory dirOut) async {
  if (dirOut.existsSync()) {
    dirOut.deleteSync(recursive: true);
  }
  dirOut.createSync(recursive: true);
  final out = File(p.join(dirOut.path, '__out.txt'))
      .openWrite(mode: FileMode.writeOnly);
  out.writeCharCode(unicodeBomCharacterRune);
  final outErr = File(p.join(dirOut.path, '__outErr.txt'))
      .openWrite(mode: FileMode.writeOnly);
  outErr.writeCharCode(unicodeBomCharacterRune);
  await Directory(pathIn).list(recursive: true).listen((entity) {
    if (entity is File) {
      final ext = p.extension(entity.path).toLowerCase();
      if (exts.contains(ext)) {
        final path = dirOut.path + entity.path.substring(pathIn.length);
        out.writeln(path);
        final dir = Directory(p.dirname(path));
        dir.createSync(recursive: true);
        try {
          entity.copySync(path);
        } catch (e, st) {
          outErr.writeln(e);
          outErr.writeln(st);
          outErr.writeln();
        }
      }
    }
  }).asFuture();

  await out.close();
  await outErr.close();
}

void main(List<String> args) async {
  const pathIn = r'\\NAS\Public\common';

  copy(pathIn, ['.txt'], Directory(p.join('.ignore', 'files', 'txt')).absolute);
  copy(pathIn, ['.dbf'], Directory(p.join('.ignore', 'files', 'dbf')).absolute);
  copy(pathIn, ['.doc', '.docx'],
      Directory(p.join('.ignore', 'files', 'doc')).absolute);
  copy(pathIn, ['.las'], Directory(p.join('.ignore', 'files', 'las')).absolute);
}
