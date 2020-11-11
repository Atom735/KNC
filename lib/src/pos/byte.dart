import 'dart:convert';
import 'dart:typed_data';

import '../charmaps/index.dart';

import 'abstract.dart';

/// Указатель позиции текста
class BytePos extends AbstractPos {
  /// Контейнер текста
  @override
  final ByteData data;

  /// Создаёт указатель из контенера и перемещает его на [i] символов вперёд
  BytePos(this.data, [final int i = 0]) : super(data) {
    skipSymbolsCount(i);
  }

  /// Создаёт указатель
  BytePos.a(this.data, [int s = 0, int l = 0, int c = 0])
      : super(data, s, l, c);

  /// Создаёт копию указателя из другого указателя
  factory BytePos.copy(final BytePos _) => BytePos.a(_.data, _.s, _.l, _.c);

  /// Предудыщий символ
  ///
  /// Возвращает `-1` если невозможно получить символ
  @override
  int get prev => s >= 1 ? data.getUint8(s) : -1;

  /// Следующий символ
  ///
  /// Возвращает `-1` если невозможно получить символ
  @override
  int get next => s < dataLength - 1 ? data.getUint8(s + 1) : -1;

  /// Настоящий символ, куда указывает указатель
  ///
  /// Возвращает `-1` если невозможно получить символ
  @override
  int get symbol => s < dataLength ? data.getUint8(s) : -1;

  /// Получить символ который находится на отступе
  ///
  /// Возвращает пустую строку если невозможно получить символ
  @override
  int symbolAt(final int i) =>
      s + i < dataLength && s + i >= 0 ? data.getUint8(s + i) : -1;

  /// Количество символов в контейнере
  @override
  int get dataLength => data.lengthInBytes;

  /// Возвращает подстроку длины [_len]
  @override
  ByteData substring(final int _len) => ByteData.sublistView(data, s, s + _len);

  /// Переход к следующему символу, возвращает этот следующий символ
  @override
  int nextSymbol() {
    if (symbol == null) {
      return null;
    }
    s++;
    c++;
    final _s = symbol;
    if (_s == -1) {
      return _s;
    } else if (_s == 0x0A || _s == 0x0D) {
      l++;
      c = -1;
      if (s >= 1 && _s == 0x0A && prev == 0x0D) {
        // коррекция на Windows перевод строки
        l--;
      }
    }
    return _s;
  }

  /// Пропуск [_i] символов, возвращает символ находящийся на расстоянии [_i]
  /// символов от настоящего
  @override
  int skipSymbolsCount(final int _i) {
    var _s = symbol;
    for (var i = 0; i < _i && _s != -1; ++i) {
      _s = nextSymbol();
    }
    return _s;
  }

  /// Пропуск всех символов содержащихся в [_a], возвращает первый символ не из
  /// [_a]
  int skipBytesInList(final Uint8List _a) {
    var _s = symbol;
    while (_a.contains(_s)) {
      _s = nextSymbol();
    }
    return _s;
  }

  /// Пропуск всех символов не содержащихся в [_a], возвращает первый
  /// встретившийся символ из [_a]
  int skipBytesOutList(final Uint8List _a) {
    var _s = symbol;
    while (_s != -1 && !_a.contains(_s)) {
      _s = nextSymbol();
    }
    return _s;
  }

  /// Пропуск пробелов, возвращает первый непробельный символ
  @override
  int skipWhiteSpaces() {
    var _s = symbol;
    while (_s != -1 && (_s == 0x20 || _s == 0x09 || _s == 0x0A || _s == 0x0D)) {
      _s = nextSymbol();
    }
    return _s;
  }

  /// Пропуск пробелов до новой линии, возвращает первый непробельный символ,
  /// либо символ новой строки
  @override
  int skipWhiteSpacesOrToEndOfLine() {
    var _s = symbol;
    while (_s != -1 && (_s == 0x20 || _s == 0x09)) {
      _s = nextSymbol();
    }
    return _s;
  }

  /// Переход к концу линии
  @override
  void skipToEndOfLine() {
    var _s = symbol;
    while (_s != -1 && _s != 0x0A && _s != 0x0D) {
      _s = nextSymbol();
    }
  }

  /// Переход к следующей линии, возвращает первый символ линии
  @override
  int skipToNextLine() {
    skipToEndOfLine();
    var _s = nextSymbol();
    // Если перевод строки как в Windows, то пропускаем второй символ
    if (_s == 0x0A && prev == 0x0D) {
      return nextSymbol();
    }
    return _s;
  }

  /// Получает символ конца строки
  String getLineFeedSymbols() {
    final _l = dataLength;
    final p = Uint8List.sublistView(data);
    for (var i = 1; i < _l; i++) {
      if (p[i] == 0x0A) {
        if (p[i - 1] == 0x0D) {
          return '\r\n';
        } else {
          return '\n';
        }
      }
    }
    return '\n';
  }

  /// Получает кодировку текста
  Encoding getEncoding() => getEncodingCodec(Uint8List.sublistView(data));
}
