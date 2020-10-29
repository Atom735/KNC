import 'dart:io';

import 'package:path/path.dart' as p;

main(List<String> args) {
  final _s = File(p.join('lib', 'src', 'charmaps', 'ruslang_freq_2letters.txt'))
      .readAsLinesSync();
  final _az = List<int>.filled(32 * 34, 0);
  for (var _i in _s) {
    if (_i.length > 2) {
      final _a1 = _i.codeUnitAt(0);
      final _a2 = _i.codeUnitAt(1);
      final _k = int.parse(_i.substring(2));
      if (_a1 == 0x0451) {
        _az[32 * 32 + _a2 - 0x430] = _k;
      } else if (_a2 == 0x451) {
        _az[32 * 33 + _a1 - 0x430] = _k;
      } else {
        _az[32 * (_a1 - 0x430) + _a2 - 0x430] = _k;
      }
    }
  }
  File(p.join('lib', 'src', 'charmaps', 'ruslang_freq_2letters.min.txt'))
      .writeAsStringSync(_az.join('\n'));
}
