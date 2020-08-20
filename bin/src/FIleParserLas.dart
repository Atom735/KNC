import 'dart:convert';

import 'knc.dart';

class ParserFileLas extends OneFileData {
  // ParserFileLas._new(
  //     final String path,
  //     final String origin,
  //     final NOneFileDataType type,
  //     final int size,
  //     final String well,
  //     final List<OneFilesDataCurve> curves)
  //     : super(path, origin, type, size, well: well, curves: curves);

  factory ParserFileLas(final KncTask kncTask, final OneFileData fileData,
      final String data, final String encode) {
    // Нарезаем на линии
    final lines = LineSplitter.split(data);
  }
}
