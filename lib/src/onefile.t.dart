/// Тип файла [OneFile]
enum NOneFileDataType {
  unknown,
  txt,
  doc,
  dbf,
  bin,
  zip,
  las_1,
  las_2,
  las_3,
  ink_dbf,
  ink_doc,
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
