import 'package:knc/knc.dart';
import 'package:test/test.dart';

void main() {
  test('calculate', () {
    expect(calculate(), 42);
  });

  test('string split', () {
    final str =
        '  1111.111  2222    444 333.412 666   809123.213 123       1923 81 94.3';
    print(str.split(' '));
    var i = 0;
    str.split(' ').forEach((e) {
      if (e.isNotEmpty) {
        i += 1;
        print('$i: "$e"');
      }
    });
  });
}
