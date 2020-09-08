enum NOneFileDataType { unknown, las }

/// Значения иследований
class OneFilesDataCurve {
  /// Наименование скважины
  final String well;

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

  OneFilesDataCurve(
      this.well, this.name, this.strt, this.stop, this.step, this.data);
  OneFilesDataCurve.byJson(Map<String, Object> json)
      : well = json['well'],
        name = json['name'],
        strt = json['strt'],
        stop = json['stop'],
        step = json['step'],
        data = null;
  Map<String, Object> toJson() =>
      {'well': well, 'name': name, 'strt': strt, 'stop': stop, 'step': step};

  @override
  bool operator ==(Object _r) =>
      (_r is OneFilesDataCurve) &&
      well == _r.well &&
      name == _r.name &&
      strt == _r.strt &&
      stop == _r.stop &&
      step == _r.step;
}

class OneFileLineNote {
  /// Номер линии
  final int line;

  /// Номер символа в строке
  final int column;

  /// Текст заметки
  /// * `!E` - ошибка
  /// * `!W` - предупреждение
  /// * `!P` - разобранная строка, разделяется символом [msgRecordSeparator]
  final String text;

  /// Доп. данные заметки (обычно то что записано в строке)
  final String data;

  OneFileLineNote(this.line, this.column, this.text, this.data);
  OneFileLineNote.byJson(Map<String, Object> json)
      : line = json['line'],
        column = json['column'],
        text = json['text'],
        data = json['data'];

  Map<String, Object> toJson() =>
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

  /// Кривые найденные в файле
  final List<OneFilesDataCurve> curves;

  /// Заметки файла
  final List<OneFileLineNote> notes;

  /// Заметки в виде ошибок
  final int notesError;

  /// Заметки в виде предупрежений
  final int notesWarnings;

  OneFileData(this.path, this.origin, this.type, this.size,
      {this.curves,
      this.encode,
      this.notes,
      this.notesError,
      this.notesWarnings});

  /// Создаёт экземпляр класса, с пустыми заметками, но их верным количеством
  OneFileData.byJson(Map<String, Object> json)
      : path = json['path'],
        origin = json['origin'],
        type = NOneFileDataType.values[json['type']],
        size = json['size'],
        curves = json['curves'] == null
            ? null
            : (List<OneFilesDataCurve>.generate(
                (json['curves'] as List).length,
                (index) =>
                    OneFilesDataCurve.byJson((json['curves'] as List)[index]),
                growable: false)),
        encode = json['encode'],
        notes =
            json['notes'] != null ? List<OneFileLineNote>(json['notes']) : null,
        notesError = json['notes-errors'],
        notesWarnings = json['notes-warnings'];

  /// Создаёт экземпляр класса с полных json данных
  OneFileData.byJsonFull(Map<String, Object> json)
      : path = json['path'],
        origin = json['origin'],
        type = NOneFileDataType.values[json['type']],
        size = json['size'],
        curves = json['curves'] == null
            ? null
            : (List<OneFilesDataCurve>.generate(
                (json['curves'] as List).length,
                (index) =>
                    OneFilesDataCurve.byJson((json['curves'] as List)[index]),
                growable: false)),
        encode = json['encode'],
        notes = json['notes'] == null
            ? null
            : (List<OneFileLineNote>.generate(
                (json['notes'] as List).length,
                (index) =>
                    OneFileLineNote.byJson((json['notes'] as List)[index]),
                growable: false)),
        notesError = json['notes-errors'],
        notesWarnings = json['notes-warnings'];

  /// Обновляет заметки с помощью json данных о заметках
  void updateNotesByJson(Map<String, Object> json) {
    if (json['notes'] != null) {
      for (var i = 0; i < notes.length; i++) {
        notes[i] = OneFileLineNote.byJson((json['notes'] as List<Object>)[i]);
      }
    }
  }

  /// Получает json объект, без данных заметок
  Map<String, Object> toJson() => {
        'type': type.index,
        'path': path,
        'origin': origin,
        'size': size,
        'encode': encode,
        'notes-errors': notesError,
        'notes-warnings': notesWarnings,
      }
        ..addAll(curves != null ? {'curves': curves} : {})
        ..addAll(notes != null ? {'notes': notes.length} : {});

  /// Получает полный json объект, включающий в себя заметки
  Map<String, Object> toJsonFull() => {
        'type': type.index,
        'path': path,
        'origin': origin,
        'size': size,
        'encode': encode,
        'notes-errors': notesError,
        'notes-warnings': notesWarnings,
      }
        ..addAll(curves != null ? {'curves': curves} : {})
        ..addAll(notes != null ? {'notes': notes} : {});
}
