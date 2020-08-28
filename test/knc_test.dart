import 'dart:async';
import 'dart:cli';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:knc/knc.dart';
import 'package:test/test.dart';

import 'package:path/path.dart' as p;

void main() {
  test('Async Queue', () async {
    final sw = Stopwatch();
    final q = AsyncTaskQueue();
    sw.start();
    final list = <Future>[];
    for (var i = 0; i < 30; i++) {
      print('${sw.elapsedMilliseconds.toString().padLeft(32)} strt $i');
      list.add(q.addTask(() {
        print('${sw.elapsedMilliseconds.toString().padLeft(32)} work $i');
        return Future.delayed(Duration(milliseconds: 200));
      }).then((value) =>
          print('${sw.elapsedMilliseconds.toString().padLeft(32)} stop $i')));
    }
    q.pause = false;
    await Future.wait(list);
    sw.stop();
  }, timeout: Timeout.factor(10));

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

  test('file path test', () {
    print(r'\\NAS\Public\common\Gilyazeev\Ð“Ð˜Ð¡\?1\2006Ð³\?2\las1\GZ3.las'
        .split(r'/')
        .expand((e) => e.split(r'\'))
        .toList());
  });

  test('parse double', () {
    print(double.tryParse(r'132.4123 exasd'));
  });
  test('Las ignore', () async {
    var map = {
      'W~WELL': ['WELL', 'Well']
    };
    var io = File(r'data\las.ignore.json')
        .openWrite(encoding: utf8, mode: FileMode.writeOnly);
    io.writeCharCode(unicodeBomCharacterRune);
    var json = JsonCodec();
    io.write(json.encode(map));
    await io.flush();
    await io.close();
  });
}
