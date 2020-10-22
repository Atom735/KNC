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

  /// Линия из секции `OTHER`
  other,

  /// Разобранная линия из секции `ASCII DATA`
  ascii,

  /// Разобранная линия из секции `CURVE`
  curve,

  /// Разобранная линия из секции `PARAMETER`
  parameter,

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

  v_vers,
  v_wrap,

  w_strt,
  w_stop,
  w_step,
  w_null,
  w_comp,
  w_well,
  w_fld,
  w_loc,
  w_prov,
  w_cnty,
  w_stat,
  w_ctry,
  w_srvc,
  w_date,
  w_uwi,
  w_api,

  w_ext,
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
      return LasParserLine_Parsed.parse(
          LasParserLine.a(_begin, _len, NLasParserLineType.raw_v.index), _ctx);
    } else if (_ctx.section == 'W') {
      return LasParserLine_Parsed.parse(
          LasParserLine.a(_begin, _len, NLasParserLineType.raw_w.index), _ctx);
    } else if (_ctx.section == 'P') {
      return LasParserLine_Parsed.parse(
          LasParserLine.a(_begin, _len, NLasParserLineType.raw_p.index), _ctx);
    } else if (_ctx.section == 'C') {
      return LasParserLine_Parsed.parse(
          LasParserLine.a(_begin, _len, NLasParserLineType.raw_c.index), _ctx);
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

class LasParserLine_Parsed extends LasParserLine {
  final String mnem;
  final String unit;
  final String data;
  final String desc;

  LasParserLine_Parsed.a(
      final LasParserLine _, this.mnem, this.unit, this.data, this.desc,
      [final int type])
      : super.a(_, _.len, type ?? _.type);
  LasParserLine_Parsed.b(final LasParserLine_Parsed _, final int type)
      : this.a(_, _.mnem, _.unit, _.data, _.desc, type);

  static LasParserLine parse(LasParserLine _, final LasParserContext _ctx) {
    /// Доходим до начала мнемоники
    final _pMnem = TxtPos.copy(_)..skipWhiteSpacesOrToEndOfLine();

    /// Осутсвует мнемоника
    if (_pMnem.symbol == '\r' || _pMnem.symbol == '\n') {
      _ctx.notes.add(TxtNote.error(_, 'Пустая строка', _.len));
      return _;
    }

    /// Доходим до точки
    final _pDot = TxtPos.copy(_pMnem)..skipSymbolsOutString('.\r\n');

    /// Отсутсвует точка
    if (_pDot.symbol != '.') {
      _ctx.notes.add(
          TxtNote.error(_, 'Отсуствует разделительная точка в строке', _.len));
      return _;
    }
    final _mnem = _pMnem.substring(_pMnem.distance(_pDot).s).trim();
    var _bUnits = true;
    if (_.type == NLasParserLineType.raw_v.index) {
      _bUnits = false;
    } else if (_.type == NLasParserLineType.raw_w.index) {
      _bUnits = false;
      switch (_mnem) {
        case 'STRT':
        case 'STOP':
        case 'STEP':
          _bUnits = true;
          break;
        default:
      }
    }

    LasParserLine_Parsed _dd(TxtPos _pUnitsEnd, [String /*?*/ _units]) {
      /// Доходим до двоеточия
      var _pDDot = TxtPos.copy(_pUnitsEnd)..skipSymbolsOutString(':\r\n');
      if (_pDDot.symbol != ':') {
        _ctx.notes.add(TxtNote.error(
            _pUnitsEnd, 'Отсуствует разделительное двоеточие в строке', 1));
        if (_units != null) {
          final _data = _pUnitsEnd
              .substring(_pUnitsEnd
                  .distance(TxtPos.copy(_pUnitsEnd)..skipToEndOfLine())
                  .s)
              .trim();
          return LasParserLine_Parsed.a(_, _mnem, _units, _data, '');
        }
        return LasParserLine_Parsed.a(_, _mnem, '', '', '');
      }
      final _data = _pUnitsEnd.substring(_pUnitsEnd.distance(_pDDot).s).trim();
      final _pDesc = TxtPos.copy(_pDDot)..nextSymbol();
      final _desc = _pDesc
          .substring(
              _pUnitsEnd.distance(TxtPos.copy(_pDesc)..skipToEndOfLine()).s)
          .trim();
      return LasParserLine_Parsed.a(_, _mnem, _units ?? '', _data, _desc);
    }

    if (_pDot.next != ' ' && _pDot.next != '\t' && !_bUnits) {
      _ctx.notes.add(
          TxtNote.error(_pDot, 'Отсуствует пробел после точки в строке', 1));

      final _pUnitsEnd = TxtPos.copy(_pDot)..nextSymbol();
      return _dd(_pUnitsEnd);
    } else {
      final _pUnits = TxtPos.copy(_pDot)..nextSymbol();
      final _pUnitsEnd = TxtPos.copy(_pUnits)..skipSymbolsOutString(' \t:\r\n');
      if (_pUnitsEnd.next != ' ' && _pUnitsEnd.next != '\t') {
        _ctx.notes.add(TxtNote.error(_pUnitsEnd,
            'Отсуствует пробел после определения размерности данных', 1));
        final _data = _pUnitsEnd
            .substring(_pUnitsEnd
                .distance(TxtPos.copy(_pUnitsEnd)..skipToEndOfLine())
                .s)
            .trim();
        return LasParserLine_Parsed.a(_, _mnem, '', _data, '');
      }
      final _units = _pDot.substring(_pDot.distance(_pUnitsEnd).s);
      return _dd(_pUnitsEnd, _units);
    }
  }
}

class LasParserLine_V_VERS extends LasParserLine_Parsed {
  /// Версия файла
  /// - `1` - `VERS. 1.2: CWLS LOG ASCII STANDARD - VERSION 1.2`
  /// http://www.cwls.org/wp-content/uploads/2014/09/LAS12_Standards.txt
  /// - `2` - `VERS. 2.0 : CWLS log ASCII Standard - VERSION 2.0`
  /// http://www.cwls.org/wp-content/uploads/2017/02/Las2_Update_Feb2017.pdf
  /// - `3` - `3.0`
  /// http://www.cwls.org/wp-content/uploads/2014/09/LAS_3_File_Structure.pdf
  final int /*?*/ value;
  LasParserLine_V_VERS.a(final LasParserLine_Parsed _, this.value)
      : super.b(_, NLasParserLineType.v_vers.index);

  static LasParserLine parse(LasParserLine _, final LasParserContext _ctx) {
    if (_ is LasParserLine_Parsed &&
        _.type == NLasParserLineType.raw_v.index &&
        _.mnem == 'VERS' &&
        _.data.isNotEmpty) {
      int /*?*/ val;
      val = double.tryParse(_.data)?.toInt();
      val ??= int.tryParse(_.data[0]);
      _ctx.sV.version = val;
      return LasParserLine_V_VERS.a(_, val);
    }
    return _;
  }
}

class LasParserLine_V_WRAP extends LasParserLine_Parsed {
  /// - `true` - `WRAP. YES: Multiple lines per depth step`
  /// - `false` - `WRAP. NO:  One line per depth step`
  /// - [1.2]
  /// Указывает, использовался ли в разделе данных режим циклического переноса.
  /// Если режим переноса не используется, строка будет иметь максимальную длину
  /// 256 символов (включая возврат каретки и перевод строки). Если используется
  /// режим переноса, значение глубины будет в отдельной строке, и все строки
  /// данных не будут длиннее 80 символов (включая возврат каретки и перевод
  /// строки).
  /// - [2.0]
  /// Указывает, использовался ли в разделе данных режим циклического переноса.
  /// Если режим переноса `NO`, длина строки не ограничена. Если используется
  /// режим переноса, значение глубины будет в отдельной строке, и все строки
  /// данных не будут длиннее 80 символов (включая возврат каретки и перевод
  /// строки).
  final bool /*?*/ value;
  LasParserLine_V_WRAP.a(final LasParserLine_Parsed _, this.value)
      : super.b(_, NLasParserLineType.v_wrap.index);

  static LasParserLine parse(LasParserLine _, final LasParserContext _ctx) {
    if (_ is LasParserLine_Parsed &&
        _.type == NLasParserLineType.raw_v.index &&
        _.mnem == 'WRAP' &&
        _.data.isNotEmpty) {
      bool /*?*/ val;
      if (_.data[0] == 'Y' ||
          _.data[0] == 'y' ||
          _.data[0] == 'T' ||
          _.data[0] == 't') {
        val = true;
      } else if (_.data[0] == 'N' ||
          _.data[0] == 'n' ||
          _.data[0] == 'F' ||
          _.data[0] == 'f') {
        val = true;
      }
      _ctx.sV.wrap = val;
      return LasParserLine_V_WRAP.a(_, val);
    }
    return _;
  }
}

class LasParserLine_W_STRT extends LasParserLine_Parsed {
  /// `STRT.M nnn.nn: START DEPTH`
  /// - [1.2]
  /// Относится к первой глубине файла. `nnn.nn` относится к значению глубины.
  /// Количество десятичных знаков не ограничено. `.M` указывает метры и может
  /// быть заменен при использовании других единиц. Начальная глубина может быть
  /// больше или меньше глубины остановки.
  /// - [2.0]
  /// Относится к первой глубине (или времени, или порядковому номеру) в файле.
  /// `nnn.nn` относится к значению глубины (или времени, или индекса). Значение
  /// должно быть идентично по значению первой глубине (время, индекс) в разделе
  /// `~ASCII`, хотя его формат может меняться
  /// (`123,45` эквивалентно `123,45000`).
  /// Количество десятичных знаков не ограничено. Если индекс - глубина, единицы
  /// измерения должны быть `M` (метры), `F` (футы) или `FT` (футы). Единицы
  /// должны совпадать в строках, относящихся к `STRT`, `STOP`, `STEP` и
  /// индексному (первому) каналу в разделе `~C`. Если время или индекс,
  /// единицами измерения могут быть любые единицы, которые приводят к
  /// представлению времени или номера индекса в виде числа с плавающей запятой.
  /// (форматы `дд/мм/гг` или `чч:мм:сс` не поддерживаются). Логическая глубина,
  /// время или порядок индекса могут увеличиваться или уменьшаться. Значение
  /// начальной глубины (или времени, или индекса) при делении на значение
  /// глубины шага (или времени, или индекса) должно быть целым числом.
  final double /*?*/ value;
  LasParserLine_W_STRT.a(final LasParserLine_Parsed _, this.value)
      : super.b(_, NLasParserLineType.w_strt.index);

  static LasParserLine parse(
      LasParserLine_Parsed _, final LasParserContext _ctx) {
    if (_ is LasParserLine_Parsed &&
        _.type == NLasParserLineType.raw_w.index &&
        _.mnem == 'STRT' &&
        _.data.isNotEmpty) {
      final val = double.tryParse(_.data);
      _ctx.sW.strt = val;
      return LasParserLine_W_STRT.a(_, val);
    }
    return _;
  }
}

class LasParserLine_W_STOP extends LasParserLine_Parsed {
  /// `STOP.M nnn.nn: STOP DEPTH`
  /// - [1.2]
  /// Относится к последней глубине файла. `nnn.nn` относится к значению глубины.
  /// Количество десятичных знаков не ограничено. `.M` указывает метры и может
  /// быть заменен при использовании других единиц. Начальная глубина может быть
  /// больше или меньше глубины остановки.
  /// - [2.0]
  /// Те же комментарии, что и для `STRT`, за исключением того, что это значение
  /// представляет ПОСЛЕДНЮЮ строку данных в разделе данных журнала `~ASCII`.
  /// Значение глубины остановки (или времени, или индекса) при делении на
  /// значение глубины шага (или времени, или индекса) должно быть целым числом.
  final double /*?*/ value;
  LasParserLine_W_STOP.a(final LasParserLine_Parsed _, this.value)
      : super.b(_, NLasParserLineType.w_stop.index);

  static LasParserLine parse(
      LasParserLine_Parsed _, final LasParserContext _ctx) {
    if (_ is LasParserLine_Parsed &&
        _.type == NLasParserLineType.raw_w.index &&
        _.mnem == 'STOP' &&
        _.data.isNotEmpty) {
      final val = double.tryParse(_.data);
      _ctx.sW.stop = val;
      return LasParserLine_W_STOP.a(_, val);
    }
    return _;
  }
}

class LasParserLine_W_STEP extends LasParserLine_Parsed {
  /// `STEP.M nnn.nn: STEP`
  ///  - [1.2]
  /// Относится к используемому приращению глубины. Знак минус должен
  /// предшествовать значению шага, если начальная глубина больше, чем глубина
  /// остановки. Нулевое значение шага указывает на переменный шаг.
  /// - [2.0] Те же комментарии, что и для `STRT`, за исключением того, что это
  /// значение представляет фактическую разницу между всеми последовательными
  /// значениями глубины, времени или индекса в разделе данных журнала `~ASCII`.
  /// Знак (`+` или `-`) представляет логическую разницу между каждым
  /// последующим значением индекса. (+ для увеличения значений индекса).
  /// Шаг должен быть идентичным по значению между всеми значениями индекса во
  /// всем файле. Если приращение шага не совсем согласовано между каждой
  /// выборкой глубины, времени или индекса, тогда шаг должен иметь значение 0.
  final double /*?*/ value;
  LasParserLine_W_STEP.a(final LasParserLine_Parsed _, this.value)
      : super.b(_, NLasParserLineType.w_step.index);

  static LasParserLine parse(
      LasParserLine_Parsed _, final LasParserContext _ctx) {
    if (_ is LasParserLine_Parsed &&
        _.type == NLasParserLineType.raw_w.index &&
        _.mnem == 'STEP' &&
        _.data.isNotEmpty) {
      final val = double.tryParse(_.data);
      _ctx.sW.step = val;
      return LasParserLine_W_STEP.a(_, val);
    }
    return _;
  }
}

class LasParserLine_W_NULL extends LasParserLine_Parsed {
  /// `NULL. -nnn.nn:`
  ///  - [1.2]
  /// Относится к нулевым значениям. Обычно используются два типа `-9999` и
  /// `-999,25`.
  /// - [2.0] -  `-9999.25`
  final double /*?*/ value;
  LasParserLine_W_NULL.a(final LasParserLine_Parsed _, this.value)
      : super.b(_, NLasParserLineType.w_null.index);

  static LasParserLine parse(
      LasParserLine_Parsed _, final LasParserContext _ctx) {
    if (_ is LasParserLine_Parsed &&
        _.type == NLasParserLineType.raw_w.index &&
        _.mnem == 'NULL' &&
        _.data.isNotEmpty) {
      final val = double.tryParse(_.data);
      _ctx.sW.undef = val;
      return LasParserLine_W_NULL.a(_, val);
    }
    return _;
  }
}

class LasParserLine_W_ extends LasParserLine_Parsed {
  final String /*?*/ value;
  LasParserLine_W_.a(final LasParserLine_Parsed _, this.value, [int type])
      : super.b(_, type ?? NLasParserLineType.w_ext.index);

  static LasParserLine parse(
      LasParserLine_Parsed _, final LasParserContext _ctx) {
    if (_ is LasParserLine_Parsed &&
        _.type == NLasParserLineType.raw_w.index &&
        (_ctx.sV.version == 1 ? _.desc.isNotEmpty : _.data.isNotEmpty)) {
      final val = _ctx.sV.version == 1 ? _.desc : _.data;
      switch (_.mnem) {
        case 'COMP':
          _ctx.sW.company = val;
          return LasParserLine_W_.a(_, val, NLasParserLineType.w_comp.index);
        case 'WELL':
          _ctx.sW.well = val;
          return LasParserLine_W_.a(_, val, NLasParserLineType.w_well.index);
        case 'FLD':
          _ctx.sW.field = val;
          return LasParserLine_W_.a(_, val, NLasParserLineType.w_fld.index);
        case 'LOC':
          _ctx.sW.location = val;
          return LasParserLine_W_.a(_, val, NLasParserLineType.w_loc.index);
        case 'PROV':
          _ctx.sW.province = val;
          return LasParserLine_W_.a(_, val, NLasParserLineType.w_prov.index);
        case 'CNTY':
          return LasParserLine_W_.a(_, val, NLasParserLineType.w_cnty.index);
        case 'STAT':
          return LasParserLine_W_.a(_, val, NLasParserLineType.w_stat.index);
        case 'CTRY':
          return LasParserLine_W_.a(_, val, NLasParserLineType.w_ctry.index);
        case 'SRVC':
          _ctx.sW.serviceCompany = val;
          return LasParserLine_W_.a(_, val, NLasParserLineType.w_srvc.index);
        case 'DATE':
          _ctx.sW.date = val;
          return LasParserLine_W_.a(_, val, NLasParserLineType.w_date.index);
        case 'UWI':
          _ctx.sW.uniqueWellId = val;
          return LasParserLine_W_.a(_, val, NLasParserLineType.w_uwi.index);
        case 'API':
          return LasParserLine_W_.a(_, val, NLasParserLineType.w_api.index);
        default:
          return LasParserLine_W_.a(_, val);
      }
    }
    return _;
  }
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

  final sV = OneFileLasDataSectionV();
  final sW = OneFileLasDataSectionW();
  final sC = <OneFileLasDataSectionLine>[];
  final sP = <OneFileLasDataSectionLine>[];
  final sO = <String>[];
  final sA = <double>[];
  OneFileLasData ofd;

  /// Разбираемая секция
  String section = '';

  factory LasParserContext /*?*/ (final String data) {
    final _v = data.indexOf('~V');
    final _w = data.indexOf('~W');
    final _c = data.indexOf('~C');
    final _a = data.indexOf('~A');
    if (_v == -1 || _w == -1 || _c == -1 || _a == -1) {
      return null;
    }
    return LasParserContext._(TxtCntainer(data));
  }

  LasParserContext._(final TxtCntainer _tc)
      : textContainer = _tc,
        thisPoint = TxtPos(_tc) {
    while (thisPoint.symbol != null) {
      final _begin = TxtPos.copy(thisPoint);
      thisPoint.skipToEndOfLine();
      lines.add(LasParserLine(_begin, _begin.distance(thisPoint).s, this));
      thisPoint.skipToNextLine();
    }
    final _l = lines.length;
    for (var i = 0; i < _l; i++) {
      final _line = lines[i];
      if (_line is LasParserLine_Parsed) {
        if (_line.type == NLasParserLineType.raw_v.index) {
          lines[i] = LasParserLine_V_VERS.parse(lines[i], this);
          lines[i] = LasParserLine_V_WRAP.parse(lines[i], this);
        } else if (_line.type == NLasParserLineType.raw_w.index) {
          lines[i] = LasParserLine_W_STRT.parse(lines[i], this);
          lines[i] = LasParserLine_W_STOP.parse(lines[i], this);
          lines[i] = LasParserLine_W_STEP.parse(lines[i], this);
          lines[i] = LasParserLine_W_NULL.parse(lines[i], this);
          lines[i] = LasParserLine_W_.parse(lines[i], this);
        }
      }
    }
    ofd = OneFileLasData(
        v: sV,
        a: sA,
        w: sW,
        c: sC,
        p: sP.isNotEmpty ? sP : null,
        o: sO.isNotEmpty ? sO : null);
  }
}

extension IOneFileLasData on LasParserContext {
  static LasParserContext /*?*/ createByString(final String data) =>
      LasParserContext(data);

  String getDebugString() {
    final str = StringBuffer();

    return str.toString();
  }
}
