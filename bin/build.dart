import 'dart:io';

import 'package:path/path.dart' as p;

const paths = [
  r'web\action.html',
  r'web\index.dart',
  r'web\index.html',
  r'web\main.css',
  r'web\main.dart',
  r'mappings',
  r'data',
];

const dartSdk = r'D:\ARGilyazeev\dart-sdk\bin\';

void main(List<String> args) {
  if (args.contains('release')) {
    final dirOut = Directory(r'release');
    if (dirOut.existsSync()) {
      dirOut.deleteSync(recursive: true);
    }
    dirOut.createSync();
    Process.runSync(dartSdk + 'dart2native.bat',
        ['bin/main.dart', '-k', 'exe', '-o', '${dirOut.path}/server.exe']);
    for (var path in paths) {
      switch (FileSystemEntity.typeSync(path)) {
        case FileSystemEntityType.file:
          final newPath = p.join(dirOut.path, path);
          Directory(p.dirname(newPath)).createSync(recursive: true);
          if (p.extension(path) == '.dart') {
            Process.runSync(dartSdk + 'dart2js.bat',
                ['-O4', '-o', '${newPath}.js', '${path}']);
          } else {
            File(path).copySync(newPath);
          }
          break;
        case FileSystemEntityType.directory:
          Directory(path).listSync(recursive: true).forEach((element) {
            if (element is File) {
              final newPath = p.join(dirOut.path, element.path);
              Directory(p.dirname(newPath)).createSync(recursive: true);
              element.copySync(newPath);
            }
          });
          break;
        default:
      }
    }
  } else {
    for (var path in paths) {
      switch (FileSystemEntity.typeSync(path)) {
        case FileSystemEntityType.file:
          if (p.extension(path) == '.dart') {
            Process.runSync(dartSdk + 'dart2js.bat',
                ['-O4', '-o', '${path}.js', '${path}']);
          }
          break;
        default:
      }
    }
  }
}
