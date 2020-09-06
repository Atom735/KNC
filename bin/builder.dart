import 'dart:async';
import 'dart:convert';
import 'dart:io';

Completer completer;

void rebuild() {
  completer = Completer();
  print('+completer created');
  completer.future.then(func);
  Process.start(
          'webdev.bat', ['build', '--no-release', '--output', 'web:build'],
          workingDirectory: Directory.current.path)
      .then((_) {
    final s = StringBuffer();
    _.stdout.listen((e) {
      final _e = utf8.decode(e);
      print(_e);
      s.write(_e);
    });
    _.exitCode.then((e) {
      if (s.toString().contains('Exception')) {
        recompile = true;
      }
      completer?.complete(e);
    });
  });
}

var recompile = false;

void func(_) {
  completer = null;
  print('+completer closed');
  if (recompile) {
    recompile = false;
    rebuild();
  }
}

Future<int> main(List<String> args) async {
  final dirWeb = Directory('web');
  dirWeb.watch(recursive: true).listen((event) {
    print('+event');
    if (completer == null) {
      rebuild();
    } else {
      recompile = true;
    }
  });
  print('+start');
  await rebuild();
  return 0;
}
