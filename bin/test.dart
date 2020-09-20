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
