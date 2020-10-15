import 'dart:typed_data';


extension ExtDbfFieldDesc on DbfFieldDesc {
  /*late*/ String name;
  /*late*/ String type;
  /*late*/ int address;
  /*late*/ int length;
  /*late*/ int decimalCount;

  /// Загружает данные из буффера байтов
  ///
  /// Возвращает `true`  если получилось разобрать байты корректно
  bool loadByByteData(final ByteData bytes) {
    if (bytes.lengthInBytes < 32) {
      return false;
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
    name =
        String.fromCharCodes(bytes.buffer.asInt8List(bytes.offsetInBytes, ij));
    type = String.fromCharCode(bytes.getUint8(11));
    address = bytes.getUint32(12, Endian.little);
    length = bytes.getUint8(16);
    decimalCount = bytes.getUint8(17);
    return true;
  }
}

extension ExtDbfFieldDesc on DbfFieldDesc {
  /// Загружает данные из буффера байтов
  ///
  /// Возвращает `true`  если получилось разобрать байты корректно
  bool loadByByteData(final ByteData bytes) {
    if (bytes.lengthInBytes < 30) {
      return false;
    }
    signature = bytes.getUint8(0);
    if (signature != 3) {
      return false;
    }
    lastUpdateYY = bytes.getUint8(1);
    lastUpdateMM = bytes.getUint8(2);
    lastUpdateDD = bytes.getUint8(3);
    numberOfRecords = bytes.getUint32(4, Endian.little);
    lengthOfHeader = bytes.getUint16(8, Endian.little);
    lengthOfEachRecord = bytes.getUint16(10, Endian.little);
    incompleteTransac = bytes.getUint8(14);
    ecryptionFlag = bytes.getUint8(15);
    freeRecordThread = bytes.getUint32(16, Endian.little);
    mdxFlag = bytes.getUint8(28);
    laguageDriver = bytes.getUint8(29);
    var offset = 32;
    while (bytes.getUint8(offset) != 0x0D) {
      final field = DbfFieldDesc();
      if (!field
          .loadByByteData(ByteData.sublistView(bytes, offset, offset + 32))) {
        return false;
      }
      fields.add(field);
      offset += 32;
    }

    if (bytes.lengthInBytes <
        lengthOfHeader + lengthOfEachRecord * numberOfRecords) {
      return false;
    }

    offset = lengthOfHeader;
    final _filedsLength = fields.length;
    // final _recordOffset = fields.fold<int>(1, (v, e) => v += e.length);
    records = List.generate(numberOfRecords, (i) {
      final _list = List.filled(_filedsLength + 1, '');
      offset = lengthOfHeader + lengthOfEachRecord * i;
      _list[0] = String.fromCharCode(bytes.getUint8(offset));
      offset += 1;
      for (var j = 0; j < _filedsLength; j++) {
        _list[j + 1] = String.fromCharCodes(bytes.buffer
            .asUint8List(bytes.offsetInBytes + offset, fields[j].length));
        offset += fields[j].length;
      }
      return _list;
    });

    return true;
  }
}
