import 'dart:cli';

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

  test('futures', () {
    final f1 = Future.value(42);
    final f2 = f1.then((e) {
      print('f1 begin');
      return Future.delayed(Duration(milliseconds: 300), () {
        print('f1 begin inner 1');
        return Future.delayed(Duration(milliseconds: 333), () {
          print('f1 begin inner 2');
          return 'end';
        });
      });
    });
    final f3 = Future.delayed(Duration(milliseconds: 166), () {
      print('f3 complete');
      final f4 = Future.delayed(Duration(milliseconds: 666), () {
        print('f4');
        return Future.delayed(Duration(milliseconds: 33), () {
          print('f4 inner');
          return 'e2';
        });
      });
      print('f4 created');
      return f4;
    });
    final f5 = Future.wait([f1, f2, f3]).then((value) {
      print(value);
      print('its all');
    });
    print('test end');
    print(waitFor(f5));
  });
}
