import 'package:knc/src/ink.g.dart';

/// Тип файла [OneFile]
enum NOneFileDataType {
  /// Неизсветсный тип данных,
  /// [datas] отсутсвует
  unknown,

  /// Текстовый файл,
  /// [datas] отсутсвует
  txt,

  /// `DOC` файл,
  /// [datas] отсутсвует
  doc,

  /// `DOCX` файл,
  /// [datas] отсутсвует
  docx,

  /// `DBF` файл,
  /// [datas] указывать на [OneFileDbf]
  dbf,

  /// Бинарный файл,
  /// [datas] отсутсвует
  bin,

  /// `LAS` файл версии `1.2`,
  /// [datas] указывает на [OneFileLasData]
  las_1,

  /// `LAS` файл версии `2.0`,
  /// [datas] указывает на [OneFileLasData]
  las_2,

  /// `LAS` файл версии `3.0`,
  /// [datas] указывает на [OneFileLasData]
  las_3,

  /// `DBF` файл содержащий инклинометрию,
  /// [datas] указывать на [OneFileInkDataDbf]
  ink_dbf,

  /// `DOC` файл содержащий инклинометрию,
  /// [datas] указывать на [OneFileInkDataDoc]
  ink_doc,

  /// `DOCX` файл содержащий инклинометрию,
  /// [datas] указывать на [OneFileInkDataDoc]
  ink_docx,

  /// Текстовый файл содержащий инклинометрию,
  /// [datas] указывать на [OneFileInkDataDoc]
  ink_txt,
}

/// Данные связанные с файлом.
///
/// Обычно хранятся рядом с самим файлом.
class OneFile {
  /// Версия данных
  int version;

  /// Тип файла, является индексом [NOneFileDataType]
  int type;

  /// Размер файла в байтах
  int size;

  /// Путь к сущности обработанного файла
  /// - На сервере храниться как абсолютный путь
  /// - Если он является частью задачи, то указывается как относительный путь
  /// - При хранении рядом с файлом, хранится только локальный относительный
  /// путь относительно рабочей копии
  String path;

  /// Путь к сущности рабочей копии файла
  /// - На сервере храниться как абсолютный путь
  /// - Если он является частью задачи, то указывается как относительный путь
  /// - При хранении рядом с файлом, хранится только локальный относительный
  /// путь относительно рабочей копии
  String copy;

  /// Путь к оригинальной сущности файла
  /// - На сервере храниться как абсолютный путь
  /// - Если он является частью задачи, то указывается как относительный путь
  /// - При хранении рядом с файлом, хранится только локальный относительный
  /// путь относительно рабочей копии
  String origin;

  /// Кодировка файла
  /// - `DOCX` - для `.docx` файлов
  /// - `BIN` - для двоичных файлов
  /// - `DBF` - для `.dbf` файлов
  /// - `ASCII` - для текстовых файлов с `ASCII` кодировкой
  /// - `UNKNOWN` - для текстовых файлов с неопределённой кодировкой
  String encode;

  /// Путь к дополнительным данным файла
  /// - На сервере храниться как абсолютный путь
  /// - Если он является частью задачи, то указывается как относительный путь
  /// - При хранении рядом с файлом, хранится только локальный относительный
  /// путь относительно рабочей копии
  String datas;
}
