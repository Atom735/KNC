import 'dart:typed_data';

const signatureTypeUnknown = 0x00;
const signatureTypeArchive = 0x01;
const signatureTypeMsOfficeBinary = 0x02;

class Signature {
  /// Тип сигнатуры
  final int type;

  /// Описание
  final String desc;

  /// Расширение файла
  final List<String> ext;

  /// Список сигнатур
  final List<List<int>> hex;

  const Signature(this.desc, this.ext, this.hex,
      [this.type = signatureTypeUnknown]);

  /// Проверка на сигнатуру
  bool validate(List<int> bytes) {
    final _l = hex.length;
    final _lb = bytes.length;
    for (var i = 0; i < _l; i++) {
      final _hex = hex[i];
      final _l2 = hex.length;
      var _b = _l2 <= _lb;
      for (var j = 0; j < _l2 && _b; j++) {
        _b = bytes[j] == _hex[j];
      }
      if (_b) {
        return true;
      }
    }
    return false;
  }
}

const signatures = {
  'gzip': Signature(
      'GZIP compressed file',
      ['.gz', '.tar.gz'],
      [
        [0x1F, 0x8B]
      ],
      signatureTypeArchive),
  'lzw': Signature(
      'compressed file (often tar zip)\n'
      'using Lempel-Ziv-Welch algorithm',
      ['.z', '.tar.z'],
      [
        [0x1F, 0x9D]
      ],
      signatureTypeArchive),
  'lzh': Signature(
      'Compressed file (often tar zip)\n'
      'using LZH algorithm',
      ['.z', '.tar.z'],
      [
        [0x1F, 0xA0]
      ],
      signatureTypeArchive),
  'xml': Signature(
      'eXtensible Markup Language when using the ASCII character encoding', [
    '.xml',
  ], [
    [0x3c, 0x3f, 0x78, 0x6d, 0x6c, 0x20]
  ]),
  'lz4': Signature(
      'LZ4 Frame Format\n'
      'Remark: LZ4 block format does not offer any magic bytes.',
      [
        '.lz4',
      ],
      [
        [0x04, 0x22, 0x4D, 0x18]
      ],
      signatureTypeArchive),
  'lzip': Signature(
      'lzip compressed file',
      [
        '.lz',
      ],
      [
        [0x4C, 0x5A, 0x49, 0x50]
      ],
      signatureTypeArchive),
  'oar': Signature(
      'OAR file archive format, where ?? is the format version.',
      [
        '.oar',
      ],
      [
        [0x4F, 0x41, 0x52]
      ],
      signatureTypeArchive),
  'zst': Signature(
      'Zstandard compressed file',
      [
        '.zst',
      ],
      [
        [0x28, 0xB5, 0x2F, 0xFD]
      ],
      signatureTypeArchive),
  '7z': Signature(
      '7-Zip File Format',
      [
        '.7z',
      ],
      [
        [0x37, 0x7A, 0xBC, 0xAF, 0x27, 0x1C]
      ],
      signatureTypeArchive),
  'bz2': Signature(
      'Compressed file using Bzip2 algorithm',
      [
        '.bz2',
      ],
      [
        [0x42, 0x5A, 0x68]
      ],
      signatureTypeArchive),
  'zip': Signature(
      'zip file format and formats based on it, such as EPUB, JAR, ODF, OOXML',
      [
        '.zip',
        '.aar',
        '.apk',
        '.docx',
        '.epub',
        '.ipa',
        '.jar',
        '.kmz',
        '.maff',
        '.odp',
        '.ods',
        '.odt',
        '.pk3',
        '.pk4',
        '.pptx',
        '.usdz',
        '.vsdx',
        '.xlsx',
        '.xpi',
      ],
      [
        [0x50, 0x4B, 0x03, 0x04],
      ],
      signatureTypeArchive),
  'zip empty': Signature(
      'zip file format and formats based on it, such as EPUB, JAR, ODF, OOXML (empty archive)',
      [
        '.zip',
        '.aar',
        '.apk',
        '.docx',
        '.epub',
        '.ipa',
        '.jar',
        '.kmz',
        '.maff',
        '.odp',
        '.ods',
        '.odt',
        '.pk3',
        '.pk4',
        '.pptx',
        '.usdz',
        '.vsdx',
        '.xlsx',
        '.xpi',
      ],
      [
        [0x50, 0x4B, 0x05, 0x06],
      ],
      signatureTypeArchive),
  'zip spanned': Signature(
      'zip file format and formats based on it, such as EPUB, JAR, ODF, OOXML (spanned archive)',
      [
        '.zip',
        '.aar',
        '.apk',
        '.docx',
        '.epub',
        '.ipa',
        '.jar',
        '.kmz',
        '.maff',
        '.odp',
        '.ods',
        '.odt',
        '.pk3',
        '.pk4',
        '.pptx',
        '.usdz',
        '.vsdx',
        '.xlsx',
        '.xpi',
      ],
      [
        [0x50, 0x4B, 0x07, 0x08],
      ],
      signatureTypeArchive),
  'rar 1.50': Signature(
      'RAR archive version 1.50 onwards',
      [
        '.rar',
      ],
      [
        [0x52, 0x61, 0x72, 0x21, 0x1A, 0x07, 0x00],
      ],
      signatureTypeArchive),
  'rar 5.0': Signature(
      'RAR archive version 5.0 onwards',
      [
        '.rar',
      ],
      [
        [0x52, 0x61, 0x72, 0x21, 0x1A, 0x07, 0x01, 0x00],
      ],
      signatureTypeArchive),
  'tar': Signature(
      'tar archive',
      [
        '.tar',
      ],
      [
        [0x75, 0x73, 0x74, 0x61, 0x72, 0x00, 0x30, 0x30],
        [0x75, 0x73, 0x74, 0x61, 0x72, 0x20, 0x20, 0x00],
      ],
      signatureTypeArchive),
  'zlib 0': Signature(
      'No Compression (no preset dictionary)',
      [
        '.zlib',
      ],
      [
        [0x78, 0x01],
      ],
      signatureTypeArchive),
  'zlib 1': Signature(
      'Best speed (no preset dictionary)',
      [
        '.zlib',
      ],
      [
        [0x78, 0x5E],
      ],
      signatureTypeArchive),
  'zlib 2': Signature(
      'Default Compression (no preset dictionary)',
      [
        '.zlib',
      ],
      [
        [0x78, 0x9C],
      ],
      signatureTypeArchive),
  'zlib 3': Signature(
      'Best Compression (no preset dictionary)',
      [
        '.zlib',
      ],
      [
        [0x78, 0xDA],
      ],
      signatureTypeArchive),
  'zlib 0+': Signature(
      'No Compression (with preset dictionary)',
      [
        '.zlib',
      ],
      [
        [0x78, 0x20],
      ],
      signatureTypeArchive),
  'zlib 1+': Signature(
      'Best speed (with preset dictionary)',
      [
        '.zlib',
      ],
      [
        [0x78, 0x7D],
      ],
      signatureTypeArchive),
  'zlib 2+': Signature(
      'Default Compression (with preset dictionary)',
      [
        '.zlib',
      ],
      [
        [0x78, 0xBB],
      ],
      signatureTypeArchive),
  'zlib 3+': Signature(
      'Best Compression (with preset dictionary)',
      [
        '.zlib',
      ],
      [
        [0x78, 0xF9],
      ],
      signatureTypeArchive),
  'xar': Signature(
      'eXtensible ARchive format',
      [
        '.xar',
      ],
      [
        [0x78, 0x61, 0x72, 0x21],
      ],
      signatureTypeArchive),
  'ms-office.bin': Signature(
      'Compound File Binary Format, a container format used for document by older versions of Microsoft Office.'
      ' It is however an open format used by other programs as well.',
      [
        '.doc',
        '.xls',
        '.ppt',
        '.msg',
      ],
      [
        [0xD0, 0xCF, 0x11, 0xE0, 0xA1, 0xB1, 0x1A, 0xE1],
      ],
      signatureTypeMsOfficeBinary),
  'xz': Signature(
      'XZ compression utility\n'
      'using LZMA2 compression',
      ['.xz', '.tar.xz'],
      [
        [0xFD, 0x37, 0x7A, 0x58, 0x5A, 0x00],
      ],
      signatureTypeArchive),
};

/// Возвращает сигнатуру файла
Signature /*?*/ getSignatureOfData(List<int> bytes) {
  for (var s in signatures.values) {
    if (s.validate(bytes)) {
      return s;
    }
  }
  return null;
}
