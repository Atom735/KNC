import 'dart:math';

import '../structs.dart';

extension DbfRecordExt on DbfRecord {
  String debugString(final List<DbfField> fields, [bool head = false]) {
    final str = StringBuffer();
    final _filedsLength = fields.length;
    if (head) {
      str.write('#');
      for (var i = 0; i < _filedsLength; i++) {
        str.write('|' +
            fields[i]
                .name
                .padRight(max(fields[i].name.length, fields[i].length)));
      }
    } else {
      str.write(deleted ? 'x' : ' ');
      for (var i = 0; i < _filedsLength; i++) {
        final _type = fields[i].type;
        switch (_type) {
          case 'N':
            str.write('|' +
                (value(fields[i]) as double)
                    .toStringAsFixed(fields[i].decimalCount)
                    .padLeft(max(fields[i].name.length, fields[i].length)));
            break;
          default:
            str.write('|' +
                value(fields[i])
                    .toString()
                    .padRight(max(fields[i].name.length, fields[i].length)));
        }
      }
    }

    return str.toString();
  }
}
