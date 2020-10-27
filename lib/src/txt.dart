/// Контейнер текста
class TxtCntainer {
  /// Указатель на данные
  final String data;

  /// Длина данных
  final int length;

  TxtCntainer(this.data) : length = data.length;
}

/// Указатель позиции текста
class TxtPos {
  /// Контейнер текста
  TxtCntainer txt;

  /// Номер символа
  int s = 0;

  /// Номер строки
  int l = 0;

  /// Номер стобца
  int c = 0;

  /// Создаёт указатель из контенера и перемещает его на [i] символов вперёд
  TxtPos(this.txt, [final int i = 0]) {
    skipSymbolsCount(i);
  }

  /// Создаёт указатель
  TxtPos.a(this.txt, [this.s = 0, this.l = 0, this.c = 0]);

  /// Создаёт копию указателя из другого указателя
  TxtPos.copy(final TxtPos _) {
    copyFrom(_);
  }

  /// Копирует данные из другого указателя в этот
  void copyFrom(final TxtPos _) {
    txt = _.txt;
    s = _.s;
    l = _.l;
    c = _.c;
  }

  @override
  String toString() => '[${l + 1}, ${c + 1}]';

  /// Возвращает расстояние между двумя указателями
  TxtPos distance(final TxtPos _) => TxtPos.a(txt, _.s - s, _.l - l, _.c - c);

  /// Предудыщий символ
  ///
  /// Возвращает `null` если невозможно получить символ
  String /*?*/ get prev => s >= 1 ? txt.data[s - 1] : null;

  /// Следующий символ
  ///
  /// Возвращает `null` если невозможно получить символ
  String /*?*/ get next => s < dataLength - 1 ? txt.data[s + 1] : null;

  /// Настоящий символ, куда указывает указатель
  ///
  /// Возвращает `null` если невозможно получить символ
  String /*?*/ get symbol => s < dataLength ? txt.data[s] : null;

  /// Получить символ который находится на отступе
  ///
  /// Возвращает `null` если невозможно получить символ
  String /*?*/ symbolAt(final int i) =>
      s + i < dataLength && s + i >= 0 ? txt.data[s + i] : null;

  /// Количество символов в контейнере
  int get dataLength => txt.length;

  /// Возвращает подстроку длины [_len]
  String substring(final int _len) => txt.data.substring(s, s + _len);

  /// Переход к следующему символу, возвращает этот следующий символ
  String /*?*/ nextSymbol() {
    if (symbol == null) {
      return null;
    }
    s++;
    c++;
    final _s = symbol;
    if (_s == null) {
      return _s;
    } else if (_s == '\n' || _s == '\r') {
      l++;
      c = 0;
      if (s >= 1 && _s == '\n' && prev == '\r') {
        // коррекция на Windows перевод строки
        l--;
      }
    }
    return _s;
  }

  /// Пропуск [_i] символов, возвращает символ находящийся на расстоянии [_i]
  /// символов от настоящего
  String /*?*/ skipSymbolsCount(final int _i) {
    var _s = symbol;
    for (var i = 0; i < _i && _s != null; ++i) {
      _s = nextSymbol();
    }
    return _s;
  }

  /// Пропуск всех символов содержащихся в [_a], возвращает первый символ не из
  /// [_a]
  String /*?*/ skipSymbolsInString(final String _a) {
    var _s = symbol;
    while (_a.contains(_s)) {
      _s = nextSymbol();
    }
    return _s;
  }

  /// Пропуск всех символов не содержащихся в [_a], возвращает первый
  /// встретившийся символ из [_a]
  String /*?*/ skipSymbolsOutString(final String _a) {
    var _s = symbol;
    while (_s != null && !_a.contains(_s)) {
      _s = nextSymbol();
    }
    return _s;
  }

  /// Пропуск пробелов, возвращает первый непробельный символ
  String /*?*/ skipWhiteSpaces() {
    var _s = symbol;
    while (
        _s != null && (_s == ' ' || _s == '\t' || _s == '\n' || _s == '\r')) {
      _s = nextSymbol();
    }
    return _s;
  }

  /// Пропуск пробелов до новой линии, возвращает первый непробельный символ,
  /// либо символ новой строки
  String /*?*/ skipWhiteSpacesOrToEndOfLine() {
    var _s = symbol;
    while (_s != null && (_s == ' ' || _s == '\t')) {
      _s = nextSymbol();
    }
    return _s;
  }

  /// Переход к концу линии
  void skipToEndOfLine() {
    var _s = symbol;
    while (_s != null && _s != '\n' && _s != '\r') {
      _s = nextSymbol();
    }
  }

  /// Переход к следующей линии, возвращает первый символ линии
  String /*?*/ skipToNextLine() {
    skipToEndOfLine();
    var _s = nextSymbol();
    // Если перевод строки как в Windows, то пропускаем второй символ
    if (_s == '\n' && prev == '\r') {
      return nextSymbol();
    }
    return _s;
  }
}

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
}

/// Заметка к тексту
class TxtNote {
  /// Указатель к позиции заметки
  final TxtPos p;

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

  String getDebugString() {
    final str = StringBuffer();
    switch (NTxtNoteType.values[t]) {
      case NTxtNoteType.info:
        str.write('INFO'.padRight(8));
        break;
      case NTxtNoteType.warn:
        str.write('WARN'.padRight(8));
        break;
      case NTxtNoteType.error:
        str.write('ERROR'.padRight(8));
        break;
      case NTxtNoteType.fatal:
        str.write('FATAL'.padRight(8));
        break;
      default:
        str.write('UNKNOWN'.padRight(8));
    }
    str.write('${p.l + 1}:${p.c + 1} ($l):'.padRight(16));
    str.write(s);
    return str.toString();
  }
}
