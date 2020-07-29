import 'dart:io';

Future<int> main(List<String> args) async {
  final dirBuild = Directory('build');
  if (!(await dirBuild.exists())) {
    await dirBuild.create();
  }
  final dirWeb = Directory('build/web');
  if (!(await dirWeb.exists())) {
    await dirWeb.create();
  }
  await Process.run(
      'dartdevc.bat', ['-k', '-o', 'build/web/main.dart.js', 'web/main.dart']);
  return 0;
}
