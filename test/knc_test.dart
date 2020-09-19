import 'package:knc/src/OneFile.dart';
@TestOn('vm')
import 'package:test/test.dart';

void main() {
  test('Json Null safety', () {
    JOneFileData.byJson({
      JOneFileData.jsonKey_path: '#',
      JOneFileData.jsonKey_origin: '#',
      JOneFileData.jsonKey_type: 0,
      JOneFileData.jsonKey_size: null,
      JOneFileData.jsonKey_encode: null,
      JOneFileData.jsonKey_curves: null,
      // JOneFileData.jsonKey_notes] as List?)
    });
  });
}
