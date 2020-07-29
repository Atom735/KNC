import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:sass/sass.dart' as sass;
import 'package:package_resolver/package_resolver.dart';

Future main(List<String> args) async {
  print('sass begin watch!');
  final dir = Directory(p.join(Directory.current.path, 'web'));
  final packageResolver =
      await SyncPackageResolver.loadConfig(Uri.file('.packages'));
  //C:\Users\User4\AppData\Local\Pub\Cache\hosted\pub.dartlang.org

  await dir.list(recursive: true).listen((entity) async {
    if (entity is File && p.extension(entity.path) == '.scss') {
      try {
        final css = File(p.setExtension(entity.path, '.css'));
        await css.writeAsString(await sass.compileAsync(entity.path,
            packageResolver: packageResolver));
        print('sass: compiled ${entity.path} => ${css.path}');
      } catch (e) {
        print(e);
      }
    }
  }).asFuture();
  dir.watch(recursive: true).listen((event) async {
    if (p.extension(event.path) == '.scss') {
      final css = File(p.setExtension(event.path, '.css'));
      switch (event.type) {
        case FileSystemEvent.create:
        case FileSystemEvent.modify:
          try {
            await css.writeAsString(await sass.compileAsync(event.path,
                packageResolver: packageResolver));
            print('sass: compiled ${event.path} => ${css.path}');
          } catch (e) {
            print(e);
          }
          break;
        case FileSystemEvent.delete:
          try {
            await css.delete();
            print('sass: deleted ${css.path}');
          } catch (e) {
            print(e);
          }
          break;
        default:
      }
    }
  });
}
