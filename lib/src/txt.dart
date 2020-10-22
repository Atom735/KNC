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

  TxtPos(this.txt);

  TxtPos.fromTxtPos(this.txt, final int p) {
    skipSymbolsCount(p);
  }

  TxtPos.copy(final TxtPos _) {
    txt = _.txt;
    s = _.s;
    l = _.l;
    c = _.c;
  }

  String /*?*/ get prev => s >= 1 ? txt.data[s - 1] : null;
  String /*?*/ get next => s < dataLength - 1 ? txt.data[s + 1] : null;
  String /*?*/ get symbol => s < dataLength ? txt.data[s] : null;
  String /*?*/ symbolAt(final int i) =>
      s + i < dataLength && s + i >= 0 ? txt.data[s + i] : null;
  int get dataLength => txt.length;

  /// Переход к следующему символу
  String /*?*/ nextSymbol() {
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

  /// Пропуск всех символов не содержащихся в [_a], возвращает первый символ не из
  /// [_a]
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

  /// Переход к концу линии
  void skipToEndOfLine() {
    var _s = symbol;
    while (_s != null && _s != '\n' && _s != '\r') {
      _s = nextSymbol();
    }
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
}
