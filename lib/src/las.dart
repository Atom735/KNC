import 'package:knc/src/txt.dart';

import 'las.g.dart';

/// - 1 - Section name
/// - 2 - Section body
final reLasSections = RegExp(r'^\s*(\~[VWCPO].*?)$\s*?^(.+?$)\s*?(?=\~)',
    dotAll: true, multiLine: true);

/// - 1 - Comment or data string
/// - 2 - Mnem
/// - 3 - Unit
/// - 4 - Data
/// - 5 - Desc
final reLasSectionData =
    RegExp(r'^\s*(#.+|(\w+)\s*\.(\S*)\s+(.*):(.+))$', multiLine: true);

/// Тип линии [LasParserLine]
enum NLasParserLineType {
  /// Непонятная линия
  unknown,

  /// Пустая линия
  empty,

  /// Комментарий
  comment,

  /// Заголовок неизвестной секции
  section_unknown,

  /// Заголовок секции `VERSION`
  section_v,

  /// Заголовок секции `WELL`
  section_w,

  /// Заголовок секции `CURVE`
  section_c,

  /// Заголовок секции `PARAMETER`
  section_p,

  /// Заголовок секции `OTHER`
  section_o,

  /// Заголовок секции `ASCII DATA`
  section_a,

  /// Сырая линия из секции `VERSION`
  raw_v,

  /// Сырая линия из секции `WELL`
  raw_w,

  /// Сырая линия из секции `CURVE`
  raw_c,

  /// Сырая линия из секции `PARAMETER`
  raw_p,

  /// Сырая линия из секции `ASCII DATA`
  raw_a,

  /// Линия из секции `OTHER`
  other,

  /// Разобранная линия из секции `ASCII DATA`
  ascii,

  /// Строка с версией файла
  v_vers,

  /// Строка с типом перевода строки
  v_wrap,
}

/// Данные о разбираемой линии
class LasParserLine extends TxtPos {
  /// Длина линии
  final int len;

  /// Тип линии, индекс из [NLasParserLineType]
  final int type;

  LasParserLine.a(final TxtPos _, this.len, [this.type = 0]) : super.copy(_);

  factory LasParserLine(
      final TxtPos _begin, final int _len, final LasParserContext _ctx) {
    final _firstNonSpace = TxtPos.copy(_begin)..skipWhiteSpacesOrToEndOfLine();
    final _firstSymbol = _firstNonSpace.symbol;

    if (_firstSymbol == '#' && _ctx.section != 'O') {
      if (_ctx.section == 'A') {
        _ctx.notes.add(TxtNote.error(
            _begin, 'Внутри ASCII секции запрещены комментарии', _len));
      }
      if (_begin.distance(_firstNonSpace).s != 0) {
        _ctx.notes.add(TxtNote.warn(_firstNonSpace,
            'Символ начала комментария находится не в самом начале строки', 1));
      }
      return LasParserLine.a(_begin, _len, NLasParserLineType.comment.index);
    } else if (_firstSymbol == '~') {
      if (_ctx.section == 'A') {
        _ctx.notes.add(TxtNote.error(
            _begin, 'Внутри ASCII секции запрещены новые секции', _len));
      }
      if (_begin.distance(_firstNonSpace).s != 0) {
        _ctx.notes.add(TxtNote.warn(_firstNonSpace,
            'Символ начала секции находится не в самом начале строки', 1));
      }
      final _sectionSymbol = _firstNonSpace.next;
      _ctx.section = _sectionSymbol;
      LasParserLine o;
      switch (_sectionSymbol) {
        case 'V':
          o = LasParserLine.a(_begin, _len, NLasParserLineType.section_v.index);
          break;
        case 'W':
          o = LasParserLine.a(_begin, _len, NLasParserLineType.section_w.index);
          break;
        case 'C':
          o = LasParserLine.a(_begin, _len, NLasParserLineType.section_c.index);
          break;
        case 'P':
          o = LasParserLine.a(_begin, _len, NLasParserLineType.section_p.index);
          break;
        case 'O':
          o = LasParserLine.a(_begin, _len, NLasParserLineType.section_o.index);
          break;
        case 'A':
          o = LasParserLine.a(_begin, _len, NLasParserLineType.section_a.index);
          break;
        default:
          o = LasParserLine.a(
              _begin, _len, NLasParserLineType.section_unknown.index);
      }
      if (_ctx.sections.containsKey(_sectionSymbol)) {
        _ctx.notes.add(TxtNote.error(
            _begin,
            'Недопустимо повторное объявление секций\n'
            'Секция объявлена в ${_ctx.sections[_sectionSymbol].toString()}',
            _len));
      } else {
        _ctx.sections[_sectionSymbol] = o;
      }
      return o;
    } else if (_ctx.section == 'A') {
      return LasParserLine.a(_begin, _len, NLasParserLineType.raw_a.index);
    } else if (_ctx.section == 'V') {
      return LasParserLine.a(_begin, _len, NLasParserLineType.raw_v.index);
    } else if (_ctx.section == 'W') {
      return LasParserLine.a(_begin, _len, NLasParserLineType.raw_w.index);
    } else if (_ctx.section == 'P') {
      return LasParserLine.a(_begin, _len, NLasParserLineType.raw_p.index);
    } else if (_ctx.section == 'C') {
      return LasParserLine.a(_begin, _len, NLasParserLineType.raw_c.index);
    } else if (_ctx.section == 'O') {
      return LasParserLine.a(_begin, _len, NLasParserLineType.other.index);
    } else if (_firstSymbol == '\r' ||
        _firstSymbol == '\n' ||
        _firstSymbol == null) {
      return LasParserLine.a(_begin, _len, NLasParserLineType.empty.index);
    } else {
      return LasParserLine.a(_begin, _len, NLasParserLineType.unknown.index);
    }
  }
}

class LasParserLineAscii extends LasParserLine {
  final List<double> values;

  LasParserLineAscii(final TxtPos _, final int _len, this.values)
      : super.a(_, _len, NLasParserLineType.ascii.index);
}

/// Контекст парсера LAS файлов
class LasParserContext {
  /// Контейнер с разбираемым текстом
  final TxtCntainer textContainer;

  /// Позиция указателя где преостановлен разбор
  final TxtPos thisPoint;

  /// Заметки разбора файла
  final notes = <TxtNote>[];

  /// Список разобранных линий
  final lines = <LasParserLine>[];

  /// Мап с расположением секций
  final sections = <String, LasParserLine>{};

  /// Разбираемая секция
  String section = '';

  factory LasParserContext(final String data) =>
      LasParserContext._(TxtCntainer(data));

  LasParserContext._(final TxtCntainer _tc)
      : textContainer = _tc,
        thisPoint = TxtPos(_tc) {
    while (thisPoint.symbol != null) {
      final _begin = TxtPos.copy(thisPoint);
      thisPoint.skipToEndOfLine();
      lines.add(LasParserLine(_begin, _begin.distance(thisPoint).s, this));
      thisPoint.skipToNextLine();
    }
  }
}

extension IOneFileLasData on OneFileLasData {
  static OneFileLasData /*?*/ createByString(final String data) {
    final o = OneFileLasDataFile();
    return o;
  }

  String getDebugString() {
    final str = StringBuffer();

    return str.toString();
  }
}
