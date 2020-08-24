enum NOneFileDataType { unknown, las }

/// Значения иследований
class OneFilesDataCurve {
  /// Наименоваине кривой (.ink - для инклинометрии)
  final String name;

  /// Глубина начальной точки кривой
  final String strt;

  /// Глубина конечной точки кривой
  final String stop;

  /// Шаг точек (null для инклинометрии)
  final String step;

  /// Значения в точках (у инклинометрии по три значения на точку)
  final List<String> data;

  OneFilesDataCurve(this.name, this.strt, this.stop, this.step, this.data);
  OneFilesDataCurve.byJson(Map<String, Object> json)
      : name = json['name'],
        strt = json['strt'],
        stop = json['stop'],
        step = json['step'],
        data = null;
  Map<String, Object> get json =>
      {'name': name, 'strt': strt, 'stop': stop, 'step': step};
}

class OneFileLineNote {
  /// Номер линии
  final int line;

  /// Номер символа в строке
  final int column;

  /// Текст заметки
  final String text;

  /// Доп. данные заметки (обычно то что записано в строке)
  final String data;

  OneFileLineNote(this.line, this.column, this.text, this.data);
  OneFileLineNote.byJson(Map<String, Object> json)
      : line = json['line'],
        column = json['column'],
        text = json['text'],
        data = json['data'];

  Map<String, Object> get json =>
      {'line': line, 'column': column, 'text': text, 'data': data};
}

class OneFileData {
  /// Путь к сущности обработанного файла
  final String path;

  /// Путь к оригинальной сущности файла
  final String origin;

  /// Тип файла
  final NOneFileDataType type;

  /// Размер файла в байтах
  final int size;

  /// Название кодировки
  final String encode;

  /// Наименование скважины
  final String well;

  /// Кривые найденные в файле
  final List<OneFilesDataCurve> curves;

  final List<OneFileLineNote> errors;
  final List<OneFileLineNote> warnings;

  OneFileData(this.path, this.origin, this.type, this.size,
      {this.well, this.curves, this.encode, this.errors, this.warnings});
  OneFileData.byJson(Map<String, Object> json)
      : path = json['path'],
        origin = json['origin'],
        type = NOneFileDataType.values[json['type']],
        size = json['size'],
        well = json['well'],
        curves = json['well'] == null
            ? null
            : (List<OneFilesDataCurve>.generate(
                (json['curves'] as List).length,
                (index) =>
                    OneFilesDataCurve.byJson((json['curves'] as List)[index]))),
        encode = json['encode'],
        errors = json['errors'] != null
            ? List<OneFileLineNote>(json['errors'])
            : null,
        warnings = json['warnings'] != null
            ? List<OneFileLineNote>(json['warnings'])
            : null;
  updateErrorsByJson(Map<String, Object> json) {
    if (json['errors'] != null) {
      for (var i = 0; i < errors.length; i++) {
        errors[i] = OneFileLineNote.byJson((json['errors'] as List<Object>)[i]);
      }
    }
    if (json['warnings'] != null) {
      for (var i = 0; i < warnings.length; i++) {
        warnings[i] =
            OneFileLineNote.byJson((json['warnings'] as List<Object>)[i]);
      }
    }
  }

  Map<String, Object> get jsonErrors => {}
    ..addAll(errors != null
        ? {
            'errors': errors.map((e) => e.json).toList(growable: false),
          }
        : {})
    ..addAll(warnings != null
        ? {
            'warnings': warnings.map((e) => e.json).toList(growable: false),
          }
        : {});

  Map<String, Object> get json => {
        'type': type.index,
        'path': path,
        'origin': origin,
        'size': size,
        'encode': encode,
      }
        ..addAll(well != null
            ? {
                'well': well,
                'curves': curves.map((e) => e.json).toList(growable: false)
              }
            : {})
        ..addAll(errors != null
            ? {
                'errors': errors.length,
              }
            : {})
        ..addAll(warnings != null
            ? {
                'warnings': warnings.length,
              }
            : {});
}