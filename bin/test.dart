import 'dart:io';

import 'package:path/path.dart' as p;

class S {
  final int i;

  S(this.i) {
    print('$runtimeType: $hashCode created with($i)');
  }
}

final _final = S(512);

class App {
  const App._create();
  @override
  String toString() => '${runtimeType.toString()}($hashCode)';
  static const App _instance = App._create();
  factory App() => _instance;
}

void main() {
  final p1 = File('bin/src/file').absolute.path;
  final p2 = Directory('lib/src').absolute.path;
  final p3 = Directory('lib/src').path;
  final p4 = Directory('.').path;
  final p5 = Directory.current.absolute.path;
  print('1: $p1');
  print('2: $p2');
  print('3: $p3');
  print('4: $p4');
  print('5: $p5');

  print('*2: ${p.relative(p1, from: p2)}');
  print('*3: ${p.relative(p1, from: p3)}');
  print('*4: ${p.relative(p1, from: p4)}');
  print('*5: ${p.relative(p1, from: p5)}');

  {
    final _final = S(128);
    print('begin');
    print('use class ${_final.i}');
    print('end');
  }
  print('begin');
  print('use class ${_final.i}');
  print('end');
  App();
}
