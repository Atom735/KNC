import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:sass/sass.dart' as sass;
import 'package:package_resolver/package_resolver.dart';

const map = <String, List<String>>{
  'main.scss': ['_app.scss']
};

Future main(List<String> args) async {
  print('sass begin watch/*!*/');
  final packageResolver =
      await SyncPackageResolver.loadConfig(Uri.file('.packages'));
  final dir = Directory(p.join(Directory.current.path, 'web'));

  Future sassCompile(String path) async {
    final relative = path.substring(dir.path.length + 1);
    try {
      final css = File(p.setExtension(path, '.css'));
      await css.writeAsString(
          await sass.compileAsync(path, packageResolver: packageResolver));
      print('sass: compiled ${path} => ${css.path}');
      final list = <String>[];
      map.forEach((key, value) {
        if (value.contains(relative)) {
          list.add(key);
        }
      });
      for (final l in list) {
        await sassCompile(p.join(dir.path, l));
      }
    } catch (e) {
      print(e);
    }
  }

  await dir.list(recursive: true).listen((entity) async {
    if (entity is File && p.extension(entity.path) == '.scss') {
      await sassCompile(entity.path);
    }
  }).asFuture();
  await dir.watch(recursive: true).listen((event) async {
    if (p.extension(event.path) == '.scss') {
      switch (event.type) {
        case FileSystemEvent.create:
        case FileSystemEvent.modify:
          await sassCompile(event.path);
          break;
        default:
      }
    }
  }).asFuture();
}
