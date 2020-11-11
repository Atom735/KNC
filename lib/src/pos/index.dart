export 'byte.dart';
export 'txt.dart';

import 'abstract.dart';

/// Тип заметки [TxtNote]
enum NTxtNoteType {
  /// Неизвестный, произвольный тип
  unknown,

  /// Информативное сообщение
  info,

  /// Предупреждение
  warn,

  /// Ошибка
  error,

  /// Фатальная ошибка
  fatal,

  /// Выбрашенное исключение
  exception,
}

/// Заметка к тексту
class TxtNote {
  /// Указатель к позиции заметки
  final AbstractPos p;

  /// Тип заметки, является индексом [NTxtNoteType]
  final int t;

  /// Длина заметки
  final int l;

  /// Текст заметки
  final String s;

  TxtNote(this.p, this.t, this.s, [this.l = 0]);

  /// Создать информационную заметку
  TxtNote.info(this.p, this.s, [this.l = 0]) : t = NTxtNoteType.info.index;

  /// Создать предупреждающую заметку
  TxtNote.warn(this.p, this.s, [this.l = 0]) : t = NTxtNoteType.warn.index;

  /// Создать заметку об ошибки
  TxtNote.error(this.p, this.s, [this.l = 0]) : t = NTxtNoteType.error.index;

  /// Создать заметку о фатальной ошибки
  TxtNote.fatal(this.p, this.s, [this.l = 0]) : t = NTxtNoteType.fatal.index;

  /// Создать заметку о фатальной ошибки
  TxtNote.exception(this.p, this.s, [this.l = 0])
      : t = NTxtNoteType.exception.index;

  String get debugString {
    final str = StringBuffer();
    switch (NTxtNoteType.values[t]) {
      case NTxtNoteType.info:
        str.write('INFO'.padRight(10));
        break;
      case NTxtNoteType.warn:
        str.write('WARN'.padRight(10));
        break;
      case NTxtNoteType.error:
        str.write('ERROR'.padRight(10));
        break;
      case NTxtNoteType.fatal:
        str.write('FATAL'.padRight(10));
        break;
      case NTxtNoteType.exception:
        str.write('EXCEPTION'.padRight(10));
        break;
      default:
        str.write('UNKNOWN'.padRight(10));
    }
    str.write('$p ($l):'.padRight(16));
    str.write(s);
    return str.toString();
  }
}
