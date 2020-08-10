import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as p;

main(List<String> args) {
  const pathIn = r'\\NAS\Public\common';
  const exts = ['.zip', '.rar', '.las', '.doc', '.docx', '.txt', '.dbf'];

  final dirOut = Directory(r'.ignore/file').absolute;
  if (dirOut.existsSync()) {
    dirOut.deleteSync(recursive: true);
  }
  dirOut.createSync(recursive: true);
  final out = File(p.join(dirOut.path, '__out.txt'))
      .openWrite(mode: FileMode.writeOnly, encoding: utf8);
  out.writeCharCode(unicodeBomCharacterRune);
  Directory(pathIn)
      .list(recursive: true)
      .listen((entity) {
        if (entity is File) {
          final ext = p.extension(entity.path);
          if (exts.contains(ext)) {
            final path = dirOut.path + entity.path.substring(pathIn.length);
            out.writeln(path);
            final dir = Directory(p.dirname(path));
            dir.createSync(recursive: true);
            entity.copy(path);
          }
        }
      })
      .asFuture()
      .then((_) async {
        await out.flush();
        await out.close();
        print('finish');
      });
}
