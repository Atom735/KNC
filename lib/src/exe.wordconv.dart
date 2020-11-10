import 'dart:io';

import 'package:path/path.dart' as p;

const _path_WordConv = [
  r'C:\Program Files\Microsoft Office',
  r'C:\Program Files (x86)\Microsoft Office'
];

/// Ищет где находися программа `WordConv.exe`
///
/// В случае неудачи, вернёт пустую строку
String getWordConvPathSync() {
  for (final _path in _path_WordConv) {
    final _dir = Directory(_path);
    if (_dir.existsSync()) {
      final _es = _dir.listSync(recursive: true, followLinks: false);
      for (final _e in _es) {
        if (_e is File && p.basename(_e.path).toLowerCase() == 'wordconv.exe') {
          return _e.path;
        }
      }
    }
  }
  return '';
}

/// Путь к программе `WordConv.exe`
final pathWordConv = getWordConvPathSync();

/// Конвертирует старый `.doc` файл в новый `.docx`
Future<ProcessResult> exeWordConv(final String doc, final String docx) =>
    Process.run(pathWordConv, ['-oice', '-nme', doc, docx]);
