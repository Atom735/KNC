import 'dart:typed_data';

import 'package:knc/src/dbf/index.dart';

import 'field.dart';

/// Структура записи DBF
class DbfRecord {
  /// Указатель на базу данных
  final Dbf dbf;

  /// Отображение памяти
  final ByteData byteData;

  /// Заголовочный байт. Может принимать одно из следующих значений:
  /// - `0x20` `32` - обычная запись;
  /// - `0x2A` `42` - удаленная запись
  bool get deleted => byteData.getUint8(0) == 0x2A;
  set deleted(bool i) => byteData.setUint8(0, i ? 0x2A : 0x20);

  /// Получить значение по полю
  dynamic value(DbfField field) {
    final _type = field.type;
    switch (_type) {
      case 'C':
        return String.fromCharCodes(Uint8List.sublistView(
                byteData, field.address, field.address + field.length))
            .trim();
      case 'N':
        return double.tryParse(String.fromCharCodes(Uint8List.sublistView(
                byteData, field.address, field.address + field.length))) ??
            double.nan;
      default:
        return String.fromCharCodes(Uint8List.sublistView(
                byteData, field.address, field.address + field.length))
            .trim();
    }
  }

  DbfRecord(this.byteData, this.dbf);
}
