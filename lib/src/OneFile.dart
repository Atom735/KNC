enum NOneFileDataType { unknown, las, docx, ink_docx }

/// Значения иследований
class JOneFilesDataCurve {
  /// Наименование скважины
  final String well;
  static const jsonKey_well = r'well';

  /// Наименоваине кривой
  ///
  /// (.ink - для инклинометрии)
  /// - `.ink.data` - Угол склонения, Альтитуда
  /// - `.ink.depth` - Глубина
  /// - `.ink.angle` - Угол
  /// - `.ink.azimuth` - Азимут
  final String name;
  static const jsonKey_name = r'name';

  /// Глубина начальной точки кривой
  final num strt;
  static const jsonKey_strt = r'strt';

  /// Глубина конечной точки кривой
  final num stop;
  static const jsonKey_stop = r'stop';

  /// Шаг точек (0 для инклинометрии)
  final num step;
  static const jsonKey_step = r'step';

  /// Значения в точках (у инклинометрии по три значения на точку)
  final List<num> data;
  static const jsonKey_data = r'data';

  const JOneFilesDataCurve(
      this.well, this.name, this.strt, this.stop, this.step, this.data);
  JOneFilesDataCurve.byJson(final Map<String, dynamic> m)
      : well = m[jsonKey_well] as String,
        name = m[jsonKey_name] as String,
        strt = m[jsonKey_strt] as num,
        stop = m[jsonKey_stop] as num,
        step = m[jsonKey_step] as num,
        data = (m[jsonKey_data] as List)
            .map((e) => e as num)
            .toList(growable: false);
  Map<String, dynamic> toJson() => {
        jsonKey_well: well,
        jsonKey_name: name,
        jsonKey_strt: strt,
        jsonKey_stop: stop,
        jsonKey_step: step,
        jsonKey_data: data,
      };

  @override
  bool operator ==(Object _r) {
    if ((_r is JOneFilesDataCurve) &&
        well == _r.well &&
        name == _r.name &&
        strt == _r.strt &&
        stop == _r.stop &&
        step == _r.step &&
        data.length == _r.data.length) {
      final _l = data.length;
      for (var i = 0; i < _l; i++) {
        if (data[i] != _r.data[i]) {
          return false;
        }
      }
      return true;
    }
    return false;
  }
}

/// Заметка на одной линии
class JOneFileLineNote {
  /// Номер линии
  final int line;
  static const jsonKey_line = 'line';

  /// Номер символа в строке
  final int column;
  static const jsonKey_column = 'column';

  /// Текст заметки
  /// * `!E` - ошибка
  /// * `!W` - предупреждение
  /// * `!P` - разобранная строка, разделяется символом [msgRecordSeparator],
  final String text;
  static const jsonKey_text = 'text';

  /// Доп. данные заметки (обычно то что записано в строке)
  final String /*?*/ data;
  static const jsonKey_data = 'data';

  const JOneFileLineNote(this.line, this.column, this.text, [this.data]);

  const JOneFileLineNote.error(this.line, this.column, final String text,
      [this.data])
      : text = '!E$text';
  const JOneFileLineNote.warn(this.line, this.column, final String text,
      [this.data])
      : text = '!W$text';
  const JOneFileLineNote.parse(this.line, this.column, final String text,
      [this.data])
      : text = '!P$text';

  JOneFileLineNote.byJson(Map<String, dynamic> m)
      : line = m[jsonKey_line] as int,
        column = m[jsonKey_column] as int,
        text = m[jsonKey_text] as String,
        data = m[jsonKey_data] as String;

  Map<String, dynamic> toJson() => {
        jsonKey_line: line,
        jsonKey_column: column,
        jsonKey_text: text,
        jsonKey_data: data,
      };
}

/// Данные связанные с файлом.
///
/// Обычно хранятся рядом с самим файлом.
class JOneFileData {
  /// Путь к сущности обработанного файла
  final String path;
  static const jsonKey_path = 'path';

  /// Путь к оригинальной сущности файла
  final String origin;
  static const jsonKey_origin = 'origin';

  /// Тип файла
  final NOneFileDataType type;
  static const jsonKey_type = 'type';

  /// Размер файла в байтах
  final int size;
  static const jsonKey_size = 'size';

  /// Кодировка текстового файла
  final String /*?*/ encode;
  static const jsonKey_encode = 'encode';

  /// Кривые найденные в файле
  final List<JOneFilesDataCurve> /*?*/ curves;
  static const jsonKey_curves = 'curves';

  /// Заметки файла
  final List<JOneFileLineNote> /*?*/ notes;
  static const jsonKey_notes = 'notes';

  /// Количество ошибок
  final int /*?*/ notesError;
  static const jsonKey_notesError = 'n-errors';

  /// Количество предупрежений
  final int /*?*/ notesWarnings;
  static const jsonKey_notesWarnings = 'n-warn';

  static const empty = JOneFileData('', '', NOneFileDataType.unknown, 0);
  const JOneFileData(this.path, this.origin, this.type, this.size,
      {this.curves,
      this.encode,
      this.notes,
      this.notesError,
      this.notesWarnings});
  JOneFileData.byJson(final Map<String, dynamic> m)
      : path = m[jsonKey_path] as String,
        origin = m[jsonKey_origin] as String,
        type = NOneFileDataType.values[m[jsonKey_type] as int],
        size = m[jsonKey_size] as int,
        encode = m[jsonKey_encode] as String /*?*/,
        curves = (m[jsonKey_curves] as List /*?*/)
            ?.map((e) => JOneFilesDataCurve.byJson(e))
            ?.toList(growable: false),
        notes = (m[jsonKey_notes] as List /*?*/)
            ?.map((e) => JOneFileLineNote.byJson(e))
            ?.toList(growable: false),
        notesError = m[jsonKey_notesError] as int /*?*/,
        notesWarnings = m[jsonKey_notesWarnings] as int /*?*/;
  Map<String, dynamic> toJson(
          {bool withoutCurves = false, bool withoutNotes = false}) =>
      {
        jsonKey_path: path,
        jsonKey_origin: origin,
        jsonKey_type: type.index,
        jsonKey_size: size,
        jsonKey_encode: encode,
        jsonKey_curves: withoutCurves ? null : curves,
        jsonKey_notes: withoutNotes ? null : notes,
        jsonKey_notesError: notesError,
        jsonKey_notesWarnings: notesWarnings,
      };
}
