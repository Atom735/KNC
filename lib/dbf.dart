import 'dart:typed_data';

/// https://www.clicketyclick.dk/databases/xbase/format/dbf.html
/// http://www.dbase.com/Knowledgebase/INT/db7_file_fmt.htm
/// https://www.dbf2002.com/dbf-file-format.html
/// http://www.autopark.ru/ASBProgrammerGuide/DBFSTRUC.HTM

class DbfFieldDesc {
  String name;
  String type;
  int address;
  int length;
  int decimalCount;

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

class DbfFile {
  /// Путь к оригиналу файла
  String origin;

  int version;
  int lastUpdateYY;
  int lastUpdateMM;
  int lastUpdateDD;
  int numberOfRecords;
  int lengthOfHeader;
  int lengthOfEachRecord;
  int incompleteTransac;
  int ecryptionFlag;
  int freeRecordThread;
  int mdxFlag;
  int laguageDriver;

  final fields = <DbfFieldDesc>[];

  List<List<String>> records;

  /// Загружает данные из буффера байтов
  ///
  /// Возвращает `true`  если получилось разобрать байты корректно
  bool loadByByteData(final ByteData bytes) {
    if (bytes.lengthInBytes < 30) {
      return false;
    }
    version = bytes.getUint8(0);
    if (version != 3) {
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
    records = List(numberOfRecords);
    for (var i = 0; i < numberOfRecords; i++) {
      records[i] = List(fields.length + 1);
      records[i][0] = String.fromCharCode(bytes.getUint8(offset));
      offset += 1;
      for (var j = 0; j < fields.length; j++) {
        records[i][j + 1] = String.fromCharCodes(bytes.buffer
            .asUint8List(bytes.offsetInBytes + offset, fields[j].length));
        offset += fields[j].length;
      }
    }

    return true;
  }
}
