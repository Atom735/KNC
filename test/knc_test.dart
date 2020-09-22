import 'package:knc/src/OneFile.dart';
@TestOn('vm')
import 'package:test/test.dart';

class S {
  final int i;

  S(this.i) {
    print('$runtimeType: $hashCode created with($i)');
  }
}

final _final = S(512);

void main() {
  print('begin');
  print('use class ${_final.i}');
  print('end');

  test('Json Null safety', () {
    JOneFileData.byJson({
      JOneFileData.jsonKey_path: '#',
      JOneFileData.jsonKey_origin: '#',
      JOneFileData.jsonKey_type: 0,
      JOneFileData.jsonKey_size: null,
      JOneFileData.jsonKey_encode: null,
      JOneFileData.jsonKey_curves: null,
      // JOneFileData.jsonKey_notes] as List/*?*/)
    });
  });
}
