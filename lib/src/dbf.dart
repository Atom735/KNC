import 'dart:typed_data';
import 'dbf.g.dart';

extension IDbfHead on DbfHead {
  static DbfHead /*?*/ createByByteData(final ByteData bytes) {
    if (bytes.lengthInBytes < 32) {
      return null;
    }
    return DbfHead(
        bytes.getUint8(0),
        bytes.getUint8(1),
        bytes.getUint8(2),
        bytes.getUint8(3),
        bytes.getUint32(4, Endian.little),
        bytes.getUint16(8, Endian.little),
        bytes.getUint16(10, Endian.little),
        bytes.getUint16(12, Endian.little),
        bytes.getUint8(14),
        bytes.getUint8(15),
        bytes.getUint32(16, Endian.little),
        bytes.getUint32(20, Endian.little),
        bytes.getUint32(24, Endian.little),
        bytes.getUint8(28),
        bytes.getUint8(29),
        bytes.getUint16(30),
        '',
        0);
  }
}

extension IDbfFieldStruct on DbfFieldStruct {
  static DbfFieldStruct /*?*/ createByByteData(final ByteData bytes) {
    if (bytes.lengthInBytes < 32) {
      return null;
    }
    var ij = -1;
    for (var i = 0; i <= 10 && ij == -1; i++) {
      if (bytes.getUint8(i) == 0) {
        ij = i;
      }
    }
    if (ij == -1) {
      ij = 11;
    }
    final _name =
        String.fromCharCodes(bytes.buffer.asInt8List(bytes.offsetInBytes, ij));
    final _type = String.fromCharCode(bytes.getUint8(11));
    return DbfFieldStruct(
        _name,
        _type,
        bytes.getUint32(12, Endian.little),
        bytes.getUint8(16),
        bytes.getUint8(17),
        bytes.getUint8(18),
        bytes.getUint32(19, Endian.little),
        bytes.getUint8(23),
        bytes.getUint32(24, Endian.little),
        bytes.getUint32(28, Endian.little));
  }
}

extension IDbfRecord on DbfRecord {
  static DbfRecord /*?*/ createByByteData(
      final ByteData bytes, final List<DbfFieldStruct> fields) {}
}

extension IOneFileDbf on OneFileDbf {
  /// Загружает данные из буфера байтов
  static OneFileDbf /*?*/ createByByteData(final ByteData bytes) {
    /// Если в базе данных отсутсвует заголовок и хотяб одно поле
    if (bytes.lengthInBytes < 65) {
      return null;
    }
    final _head = IDbfHead.createByByteData(bytes);

    /// Если размеры не соответсуют укзаанным
    if (bytes.lengthInBytes <
        _head.lengthOfHeader +
            _head.lengthOfEachRecord * _head.numberOfRecords) {
      return null;
    }
    final _fields = <DbfFieldStruct>[];

    var offset = 32;
    while (bytes.getUint8(offset) != 0x0D) {
      _fields.add(IDbfFieldStruct.createByByteData(
          ByteData.sublistView(bytes, offset, offset + 32)));
      offset += 32;
    }
    final _records = List<DbfRecord>.generate(_head.numberOfRecords, (i) {
      offset = _head.lengthOfHeader + _head.lengthOfEachRecord * i;
      return IDbfRecord.createByByteData(
          ByteData.sublistView(
              bytes, offset, offset + _head.lengthOfEachRecord),
          _fields);
    });
    return OneFileDbf(_head, _fields, _records);
  }
}
