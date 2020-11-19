import 'dart:io';

const _path_7Zip = [
  r'C:\Program Files\7-Zip\7z.exe',
  r'C:\Program Files (x86)\7-Zip\7z.exe'
];

/// Ищет где находися программа `7Zip.exe`
///
/// В случае неудачи, вернёт пустую строку
String get7ZipPathSync() {
  for (final _path in _path_7Zip) {
    final _e = File(_path);
    if (_e.existsSync()) {
      return _e.path;
    }
  }
  throw Exception('7Zip неудалось обнаружить');
}

/// Путь к программе `7z.exe`
final path7Zip = get7ZipPathSync();

/// Распаковывает архив [zip] в папку [dir]
Future<ProcessResult> exe7ZipExtract(final String zip, final String dir) =>
    Process.run(path7Zip, ['x', '-o$dir', zip]);

/// Добавляет всё содержимое папки [dir] в архив [zip]
Future<ProcessResult> exe7ZipAddToZip(final String zip, final String dir) =>
    Process.run(path7Zip, ['a', '-o$dir', zip, '*'], workingDirectory: dir);

const _exitCodes_7Zip = {
  0: 'No error',
  1: 'Warning (Non fatal error(s)). For example, one or more files were locked'
      'by some other application, so they were not compressed.',
  2: 'Fatal error',
  7: 'Command line error',
  8: 'Not enough memory for operation',
  255: 'User stopped the process',
};

/// Возвращает код ошибки в виде строки
String exe7ZipGetStringExitCode(int exitCode) =>
    _exitCodes_7Zip[exitCode] ?? '';
