import 'package:knc/src/txt.dart';

import 'las.g.dart';

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
  w_lic,

  w_ext,
}

final int nNLasParserLineType_stringLen =
    NLasParserLineType.values[0].toString().indexOf('.');
String nNLasParserLineType_string(final int i) =>
    NLasParserLineType.values.length > i
        ? NLasParserLineType.values[i]
            .toString()
            .substring(nNLasParserLineType_stringLen)
        : nNLasParserLineType_string(0);

/// Данные о разбираемой линии
class LasParserLine extends TxtPos {
  /// Длина линии
  final int len;

  /// Тип линии, индекс из [NLasParserLineType]
  final int type;

  /// Получает строку линии
  String get string => substring(len);

  @override
  String toString() =>
      '${super.toString()} ${nNLasParserLineType_string(type)}\n"$string"';

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
        _ctx.notes.add(TxtNote.fatal(
            _begin, 'Внутри ASCII секции запрещены новые секции', _len));
        if (_firstNonSpace.next != 'A') {
          _ctx.notes.add(TxtNote.info(
              _begin, 'Начинаем разбирать как следующий файл', _len));
          _ctx.next =
              LasParserContext(_ctx.textContainer.data.substring(_begin.s));
        }
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
      final o = LasParserLine.a(_begin, _len, NLasParserLineType.raw_a.index);
      final _str = o.string;
      if (_str.codeUnits.any((e) => e >= 128)) {
        _ctx.notes.add(TxtNote.fatal(_begin, 'Кракозябра в строке', _len));
        final _end = _str.indexOf(
            String.fromCharCode(_str.codeUnits.firstWhere((e) => e >= 128)));

        final _data = _ctx.textContainer.data.substring(_begin.s + _end);
        final _beginData = _data.indexOf('~V');
        if (_beginData != -1) {
          _ctx.notes.add(TxtNote.info(
              _begin, 'Начинаем разбирать как следующий файл', _len));
          _ctx.next = LasParserContext(_data.substring(_beginData));
        }

        return LasParserLine.a(_begin, _end, NLasParserLineType.raw_a.index);
      }
      return o;
    } else if (_ctx.section == 'V') {
      return LasParserLineParsed.parse(
          LasParserLine.a(_begin, _len, NLasParserLineType.raw_v.index), _ctx);
    } else if (_ctx.section == 'W') {
      return LasParserLineParsed.parse(
          LasParserLine.a(_begin, _len, NLasParserLineType.raw_w.index), _ctx);
    } else if (_ctx.section == 'P') {
      return LasParserLineParsed.parse(
          LasParserLine.a(_begin, _len, NLasParserLineType.raw_p.index), _ctx);
    } else if (_ctx.section == 'C') {
      return LasParserLineParsed.parse(
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

class LasParserLineParsed extends LasParserLine {
  final String mnem;
  final String unit;
  final String data;
  final String desc;

  @override
  String toString() => '${super.toString()}\n$mnem.$unit $data:$desc';

  LasParserLineParsed.a(
      final LasParserLine _, this.mnem, this.unit, this.data, this.desc,
      [final int type])
      : super.a(_, _.len, type ?? _.type);
  LasParserLineParsed.copy(final LasParserLineParsed _, final int type)
      : this.a(_, _.mnem, _.unit, _.data, _.desc, type);

  static LasParserLine parse(LasParserLine _, final LasParserContext _ctx) {
    /// Доходим до начала мнемоники
    final _pMnem = TxtPos.copy(_)..skipWhiteSpacesOrToEndOfLine();

    /// Осутсвует мнемоника
    if (_pMnem.symbol == '\r' || _pMnem.symbol == '\n') {
      _ctx.notes.add(TxtNote.warn(_, 'Пустая строка', _.len));
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
    }

    LasParserLineParsed _dd(TxtPos _pUnitsEnd, [String /*?*/ _units]) {
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
          return LasParserLineParsed.a(_, _mnem, _units, _data, '');
        }
        return LasParserLineParsed.a(_, _mnem, '', '', '');
      }
      if (_ctx.version?.value == 2) {
        var _pDDotNext = TxtPos.copy(_pDDot)
          ..nextSymbol()
          ..skipSymbolsOutString(':\r\n');
        if (_pDDotNext.symbol == ':') {
          _ctx.notes
              .add(TxtNote.warn(_, 'В строке несколько двоеточий', _.len));
        }
        while (_pDDotNext.symbol == ':') {
          _pDDot = _pDDotNext;
          _pDDotNext = TxtPos.copy(_pDDot)
            ..nextSymbol()
            ..skipSymbolsOutString(':\r\n');
        }
      }
      final _data = _pUnitsEnd.substring(_pUnitsEnd.distance(_pDDot).s).trim();
      final _pDesc = TxtPos.copy(_pDDot)..nextSymbol();
      final _desc = _pDesc
          .substring(_pDesc.distance(TxtPos.copy(_pDesc)..skipToEndOfLine()).s)
          .trim();
      return LasParserLineParsed.a(_, _mnem, _units ?? '', _data, _desc);
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
        return LasParserLineParsed.a(_, _mnem, '', _data, '');
      }
      final _units = _pDot.substring(_pDot.distance(_pUnitsEnd).s);
      return _dd(_pUnitsEnd, _units);
    }
  }
}

class LasParserLine_V_VERS extends LasParserLineParsed {
  /// Версия файла
  /// - `1` - `VERS. 1.2: CWLS LOG ASCII STANDARD - VERSION 1.2`
  /// http://www.cwls.org/wp-content/uploads/2014/09/LAS12_Standards.txt
  /// - `2` - `VERS. 2.0 : CWLS log ASCII Standard - VERSION 2.0`
  /// http://www.cwls.org/wp-content/uploads/2017/02/Las2_Update_Feb2017.pdf
  /// - `3` - `3.0`
  /// http://www.cwls.org/wp-content/uploads/2014/09/LAS_3_File_Structure.pdf
  final int /*?*/ value;
  LasParserLine_V_VERS.a(final LasParserLineParsed _, this.value)
      : super.copy(_, NLasParserLineType.v_vers.index);

  @override
  String toString() =>
      '${super.toString()}\n' +
      (value == 1
          ? 'VERS. 1.2: CWLS LOG ASCII STANDARD - VERSION 1.2'
          : (value == 2
              ? 'VERS. 2.0: CWLS log ASCII Standard - VERSION 2.0'
              : (value == 3 ? 'VERS. 3.0:' : 'VERS. UNKNOWN:ERROR')));

  static LasParserLine parse(LasParserLine _, final LasParserContext _ctx) {
    if (_ is LasParserLineParsed &&
        _.type == NLasParserLineType.raw_v.index &&
        _.mnem.toUpperCase() == 'VERS' &&
        _.data.isNotEmpty) {
      if (_.mnem != 'VERS') {
        _ctx.notes
            .add(TxtNote.error(_, 'Мнемоника не в верхнем регистре', _.len));
      }
      int /*?*/ val;
      val = double.tryParse(_.data)?.toInt();
      val ??= int.tryParse(_.data[0]);
      if (val == null) {
        _ctx.notes
            .add(TxtNote.fatal(_, 'Невозможно разобрать значение', _.len));
      }
      return _ctx.version = LasParserLine_V_VERS.a(_, val);
    }
    return _;
  }
}

class LasParserLine_V_WRAP extends LasParserLineParsed {
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
  LasParserLine_V_WRAP.a(final LasParserLineParsed _, this.value)
      : super.copy(_, NLasParserLineType.v_wrap.index);

  @override
  String toString() =>
      '${super.toString()}\n' +
      (value == true
          ? 'WRAP. YES: Multiple lines per depth step'
          : (value == false
              ? 'WRAP. NO:  One line per depth step'
              : 'WRAP. UNKNOWN:ERROR'));

  static LasParserLine parse(LasParserLine _, final LasParserContext _ctx) {
    if (_ is LasParserLineParsed &&
        _.type == NLasParserLineType.raw_v.index &&
        _.mnem.toUpperCase() == 'WRAP' &&
        _.data.isNotEmpty) {
      if (_.mnem != 'WRAP') {
        _ctx.notes
            .add(TxtNote.error(_, 'Мнемоника не в верхнем регистре', _.len));
      }
      bool /*?*/ val;
      if (_.data[0] == 'Y' ||
          _.data[0] == 'y' ||
          _.data[0] == 'T' ||
          _.data[0] == 't' ||
          _.data[0] == '+') {
        if (_.data != 'YES') {
          _ctx.notes
              .add(TxtNote.error(_, 'Не совсем корректное значение', _.len));
        }
        val = true;
      } else if (_.data[0] == 'N' ||
          _.data[0] == 'n' ||
          _.data[0] == 'F' ||
          _.data[0] == 'f' ||
          _.data[0] == '-') {
        if (_.data != 'NO') {
          _ctx.notes
              .add(TxtNote.error(_, 'Не совсем корректное значение', _.len));
        }
        val = false;
      }
      if (val == null) {
        _ctx.notes
            .add(TxtNote.fatal(_, 'Невозможно разобрать значение', _.len));
      }
      return _ctx.wrap = LasParserLine_V_WRAP.a(_, val);
    }
    return _;
  }
}

class LasParserLine_W_STRT extends LasParserLineParsed {
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
  LasParserLine_W_STRT.a(final LasParserLineParsed _, this.value)
      : super.copy(_, NLasParserLineType.w_strt.index);

  @override
  String toString() =>
      '${super.toString()}\n' +
      (value != null
          ? 'STRT. ${value.toStringAsFixed(6)}: START DEPTH'
          : 'STRT. UNKNOWN:ERROR');

  static LasParserLine parse(
      LasParserLineParsed _, final LasParserContext _ctx) {
    if (_ is LasParserLineParsed &&
        _.type == NLasParserLineType.raw_w.index &&
        _.mnem.toUpperCase() == 'STRT' &&
        _.data.isNotEmpty) {
      if (_.mnem != 'STRT') {
        _ctx.notes
            .add(TxtNote.error(_, 'Мнемоника не в верхнем регистре', _.len));
      }

      final val = double.tryParse(_.data);
      if (val == null) {
        _ctx.notes
            .add(TxtNote.fatal(_, 'Невозможно разобрать значение', _.len));
      }
      return _ctx.strt = LasParserLine_W_STRT.a(_, val);
    }
    return _;
  }
}

class LasParserLine_W_STOP extends LasParserLineParsed {
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
  LasParserLine_W_STOP.a(final LasParserLineParsed _, this.value)
      : super.copy(_, NLasParserLineType.w_stop.index);

  @override
  String toString() =>
      '${super.toString()}\n' +
      (value != null
          ? 'STOP. ${value.toStringAsFixed(6)}: STOP DEPTH'
          : 'STOP. UNKNOWN:ERROR');

  static LasParserLine parse(
      LasParserLineParsed _, final LasParserContext _ctx) {
    if (_ is LasParserLineParsed &&
        _.type == NLasParserLineType.raw_w.index &&
        _.mnem.toUpperCase() == 'STOP' &&
        _.data.isNotEmpty) {
      if (_.mnem != 'STOP') {
        _ctx.notes
            .add(TxtNote.error(_, 'Мнемоника не в верхнем регистре', _.len));
      }
      final val = double.tryParse(_.data);
      if (val == null) {
        _ctx.notes
            .add(TxtNote.fatal(_, 'Невозможно разобрать значение', _.len));
      }
      return _ctx.stop = LasParserLine_W_STOP.a(_, val);
    }
    return _;
  }
}

class LasParserLine_W_STEP extends LasParserLineParsed {
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
  LasParserLine_W_STEP.a(final LasParserLineParsed _, this.value)
      : super.copy(_, NLasParserLineType.w_step.index);

  @override
  String toString() =>
      '${super.toString()}\n' +
      (value != null
          ? 'STEP. ${value.toStringAsFixed(6)}: STEP'
          : 'STEP. UNKNOWN:ERROR');

  static LasParserLine parse(
      LasParserLineParsed _, final LasParserContext _ctx) {
    if (_ is LasParserLineParsed &&
        _.type == NLasParserLineType.raw_w.index &&
        _.mnem.toUpperCase() == 'STEP' &&
        _.data.isNotEmpty) {
      if (_.mnem != 'STEP') {
        _ctx.notes
            .add(TxtNote.error(_, 'Мнемоника не в верхнем регистре', _.len));
      }
      final val = double.tryParse(_.data);
      if (val == null) {
        _ctx.notes
            .add(TxtNote.fatal(_, 'Невозможно разобрать значение', _.len));
      }
      return _ctx.step = LasParserLine_W_STEP.a(_, val);
    }
    return _;
  }
}

class LasParserLine_W_NULL extends LasParserLineParsed {
  /// `NULL. -nnn.nn:`
  ///  - [1.2]
  /// Относится к нулевым значениям. Обычно используются два типа `-9999` и
  /// `-999,25`.
  /// - [2.0] -  `-9999.25`
  final double /*?*/ value;
  LasParserLine_W_NULL.a(final LasParserLineParsed _, this.value)
      : super.copy(_, NLasParserLineType.w_null.index);

  @override
  String toString() =>
      '${super.toString()}\n' +
      (value != null
          ? 'NULL. ${value.toStringAsFixed(6)}: NULL VALUE'
          : 'NULL. UNKNOWN:ERROR');

  static LasParserLine parse(
      LasParserLineParsed _, final LasParserContext _ctx) {
    if (_ is LasParserLineParsed &&
        _.type == NLasParserLineType.raw_w.index &&
        _.mnem.toUpperCase() == 'NULL' &&
        _.data.isNotEmpty) {
      if (_.mnem != 'NULL') {
        _ctx.notes
            .add(TxtNote.error(_, 'Мнемоника не в верхнем регистре', _.len));
      }
      final val = double.tryParse(_.data);
      if (val == null) {
        _ctx.notes
            .add(TxtNote.fatal(_, 'Невозможно разобрать значение', _.len));
      }
      return _ctx.undef = LasParserLine_W_NULL.a(_, val);
    }
    return _;
  }
}

class LasParserLine_W_ extends LasParserLineParsed {
  final String /*?*/ value;
  LasParserLine_W_.a(final LasParserLineParsed _, this.value, [int type])
      : super.copy(_, type ?? NLasParserLineType.w_ext.index);

  @override
  String toString() {
    switch (NLasParserLineType.values[type]) {
      case NLasParserLineType.w_comp:
        return '${super.toString()}\n' +
            (value != null ? 'COMP. $value: COMPANY' : 'COMP. UNKNOWN:ERROR');
      case NLasParserLineType.w_well:
        return '${super.toString()}\n' +
            (value != null ? 'WELL. $value: WELL' : 'WELL. UNKNOWN:ERROR');
      case NLasParserLineType.w_fld:
        return '${super.toString()}\n' +
            (value != null ? 'FLD. $value: FIELD' : 'FLD. UNKNOWN:ERROR');
      case NLasParserLineType.w_loc:
        return '${super.toString()}\n' +
            (value != null ? 'LOC. $value: LOCATION' : 'LOC. UNKNOWN:ERROR');
      case NLasParserLineType.w_prov:
        return '${super.toString()}\n' +
            (value != null ? 'PROV. $value: PROVINCE' : 'PROV. UNKNOWN:ERROR');
      case NLasParserLineType.w_cnty:
        return '${super.toString()}\n' +
            (value != null ? 'CNTY. $value: COUNTY' : 'CNTY. UNKNOWN:ERROR');
      case NLasParserLineType.w_stat:
        return '${super.toString()}\n' +
            (value != null ? 'STAT. $value: STATE' : 'STAT. UNKNOWN:ERROR');
      case NLasParserLineType.w_ctry:
        return '${super.toString()}\n' +
            (value != null ? 'CTRY. $value: COUNTRY' : 'CTRY. UNKNOWN:ERROR');
      case NLasParserLineType.w_srvc:
        return '${super.toString()}\n' +
            (value != null
                ? 'SRVC. $value: SERVICE COMPANY'
                : 'SRVC. UNKNOWN:ERROR');
      case NLasParserLineType.w_date:
        return '${super.toString()}\n' +
            (value != null ? 'DATE. $value: DATE' : 'DATE. UNKNOWN:ERROR');
      case NLasParserLineType.w_uwi:
        return '${super.toString()}\n' +
            (value != null
                ? 'UWI. $value:  UNIQUE WELL ID'
                : 'UWI. UNKNOWN:ERROR');
      case NLasParserLineType.w_api:
        return '${super.toString()}\n' +
            (value != null ? 'API. $value: API NUMBER' : 'API. UNKNOWN:ERROR');
      case NLasParserLineType.w_lic:
        return '${super.toString()}\n' +
            (value != null
                ? 'LIC. $value: LICENCE NUMBER'
                : 'LIC. UNKNOWN:ERROR');
      default:
        return super.toString();
    }
  }

  static LasParserLine parse(
      LasParserLineParsed _, final LasParserContext _ctx) {
    if (_ is LasParserLineParsed && _.type == NLasParserLineType.raw_w.index) {
      final val = _ctx.sV.version == 1 ? _.desc : _.data;
      switch (_.mnem.toUpperCase()) {
        case 'COMP':
          if (_.mnem != _.mnem.toUpperCase()) {
            _ctx.notes.add(
                TxtNote.error(_, 'Мнемоника не в верхнем регистре', _.len));
          }
          _ctx.sW.company = val;
          return LasParserLine_W_.a(_, val, NLasParserLineType.w_comp.index);
        case 'WELL':
          if (_.mnem != _.mnem.toUpperCase()) {
            _ctx.notes.add(
                TxtNote.error(_, 'Мнемоника не в верхнем регистре', _.len));
          }
          _ctx.sW.well = val;
          return _ctx.well =
              LasParserLine_W_.a(_, val, NLasParserLineType.w_well.index);
        case 'FLD':
          if (_.mnem != _.mnem.toUpperCase()) {
            _ctx.notes.add(
                TxtNote.error(_, 'Мнемоника не в верхнем регистре', _.len));
          }
          _ctx.sW.field = val;
          return LasParserLine_W_.a(_, val, NLasParserLineType.w_fld.index);
        case 'LOC':
          if (_.mnem != _.mnem.toUpperCase()) {
            _ctx.notes.add(
                TxtNote.error(_, 'Мнемоника не в верхнем регистре', _.len));
          }
          _ctx.sW.location = val;
          return LasParserLine_W_.a(_, val, NLasParserLineType.w_loc.index);
        case 'PROV':
          if (_.mnem != _.mnem.toUpperCase()) {
            _ctx.notes.add(
                TxtNote.error(_, 'Мнемоника не в верхнем регистре', _.len));
          }
          _ctx.sW.province = val;
          return LasParserLine_W_.a(_, val, NLasParserLineType.w_prov.index);
        case 'CNTY':
          if (_.mnem != _.mnem.toUpperCase()) {
            _ctx.notes.add(
                TxtNote.error(_, 'Мнемоника не в верхнем регистре', _.len));
          }
          return LasParserLine_W_.a(_, val, NLasParserLineType.w_cnty.index);
        case 'STAT':
          if (_.mnem != _.mnem.toUpperCase()) {
            _ctx.notes.add(
                TxtNote.error(_, 'Мнемоника не в верхнем регистре', _.len));
          }
          return LasParserLine_W_.a(_, val, NLasParserLineType.w_stat.index);
        case 'CTRY':
          if (_.mnem != _.mnem.toUpperCase()) {
            _ctx.notes.add(
                TxtNote.error(_, 'Мнемоника не в верхнем регистре', _.len));
          }
          return LasParserLine_W_.a(_, val, NLasParserLineType.w_ctry.index);
        case 'SRVC':
          if (_.mnem != _.mnem.toUpperCase()) {
            _ctx.notes.add(
                TxtNote.error(_, 'Мнемоника не в верхнем регистре', _.len));
          }
          _ctx.sW.serviceCompany = val;
          return LasParserLine_W_.a(_, val, NLasParserLineType.w_srvc.index);
        case 'DATE':
          if (_.mnem != _.mnem.toUpperCase()) {
            _ctx.notes.add(
                TxtNote.error(_, 'Мнемоника не в верхнем регистре', _.len));
          }
          _ctx.sW.date = val;
          return LasParserLine_W_.a(_, val, NLasParserLineType.w_date.index);
        case 'UWI':
          if (_.mnem != _.mnem.toUpperCase()) {
            _ctx.notes.add(
                TxtNote.error(_, 'Мнемоника не в верхнем регистре', _.len));
          }
          _ctx.sW.uniqueWellId = val;
          return LasParserLine_W_.a(_, val, NLasParserLineType.w_uwi.index);
        case 'API':
          if (_.mnem != _.mnem.toUpperCase()) {
            _ctx.notes.add(
                TxtNote.error(_, 'Мнемоника не в верхнем регистре', _.len));
          }
          return LasParserLine_W_.a(_, val, NLasParserLineType.w_api.index);
        case 'LIC':
          if (_.mnem != _.mnem.toUpperCase()) {
            _ctx.notes.add(
                TxtNote.error(_, 'Мнемоника не в верхнем регистре', _.len));
          }
          return LasParserLine_W_.a(_, val, NLasParserLineType.w_lic.index);
        default:
          return LasParserLine_W_.a(_, val);
      }
    }
    return _;
  }
}

class LasParserLine_C_ extends LasParserLineParsed {
  double /*?*/ strt;
  double /*?*/ stop;
  double /*?*/ step;
  int /*?*/ indexStrt;
  int /*?*/ indexStop;
  final values = <double>[];
  LasParserLine_C_.a(final LasParserLineParsed _, [int type])
      : super.copy(_, type ?? NLasParserLineType.curve.index);

  @override
  String toString() => '${super.toString()}\n'
      '\tSTRT = ${strt?.toStringAsFixed(6) ?? 'null'}\n'
      '\tSTOP = ${stop?.toStringAsFixed(6) ?? 'null'}\n'
      '\tSTEP = ${step?.toStringAsFixed(6) ?? 'null'}';

  static LasParserLine parse(
      LasParserLineParsed _, final LasParserContext _ctx) {
    if (_ is LasParserLineParsed && _.type == NLasParserLineType.raw_c.index) {
      final o = LasParserLine_C_.a(_);
      _ctx.curves.add(o);
      return o;
    }
    return _;
  }
}

/// Контекст парсера LAS файлов
class LasParserContext {
  /// Следующий контекст парсера, если найден сдвоенный файл
  LasParserContext /*?*/ next;

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

  LasParserLine_V_VERS /*?*/ version;
  LasParserLine_V_WRAP /*?*/ wrap;

  LasParserLine_W_STRT /*?*/ strt;

  LasParserLine_W_STOP /*?*/ stop;

  LasParserLine_W_STEP /*?*/ step;
  LasParserLine_W_NULL /*?*/ undef;
  LasParserLineParsed /*?*/ well;

  bool exception = false;

  final curves = <LasParserLine_C_>[];
  final ascii = <LasParserLine>[];

  /// Дополнительные линии
  List<OneFileLasDataSectionLine> /*?*/ extLines;

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
    try {
      while (thisPoint.symbol != null) {
        if (next != null) {
          break;
        }
        final _begin = TxtPos.copy(thisPoint);
        thisPoint.skipToEndOfLine();
        lines.add(LasParserLine(_begin, _begin.distance(thisPoint).s, this));
        thisPoint.skipToNextLine();
      }
      final __l = lines.length;
      for (var i = 0; i < __l; i++) {
        final _line = lines[i];
        if (_line is LasParserLineParsed) {
          if (_line.type == NLasParserLineType.raw_v.index) {
            lines[i] = LasParserLine_V_VERS.parse(_line, this);
            lines[i] = LasParserLine_V_WRAP.parse(_line, this);
          } else if (_line.type == NLasParserLineType.raw_w.index) {
            lines[i] = LasParserLine_W_STRT.parse(_line, this);
            lines[i] = LasParserLine_W_STOP.parse(_line, this);
            lines[i] = LasParserLine_W_STEP.parse(_line, this);
            lines[i] = LasParserLine_W_NULL.parse(_line, this);
            lines[i] = LasParserLine_W_.parse(_line, this);
          } else if (_line.type == NLasParserLineType.raw_c.index) {
            lines[i] = LasParserLine_C_.parse(_line, this);
          }
        } else if (_line.type == NLasParserLineType.raw_a.index) {
          ascii.add(_line);
        }
      }
      bool _wrap;
      _wrap = wrap?.value;

      final _l = ascii.length;
      final _llc = curves.length;
      if (_wrap == false) {
        for (var i = 0; i < _l; i++) {
          final _line = ascii[i];
          final _str = _line.string.split(' ')..removeWhere((e) => e.isEmpty);
          if (_str.length == curves.length) {
            final _parsed =
                _str.map((e) => double.tryParse(e)).toList(growable: false);
            if (_parsed.contains(null)) {
              notes.add(
                  TxtNote.error(_line, 'Неудалось разобрать число', _line.len));
            }
            for (var j = 0; j < _llc; j++) {
              curves[j].values.add(_parsed[j] ?? undef?.value);
            }
          } else {
            notes.add(TxtNote.fatal(
                _line,
                'Количество значений не совпадает с количеством кривых',
                _line.len));
          }
        }
      } else {
        var iIndex = 0;
        for (var i = 0; i < _l; i++) {
          final _line = ascii[i];
          final _str = _line.string.split(' ')..removeWhere((e) => e.isEmpty);
          final _parsed =
              _str.map((e) => double.tryParse(e)).toList(growable: false);
          if (_parsed.contains(null)) {
            notes.add(
                TxtNote.error(_line, 'Неудалось разобрать число', _line.len));
          }
          final _ll = _parsed.length;
          if (iIndex + _ll > _llc) {
            notes.add(
                TxtNote.error(_line, 'Переизбыток чисел в блоке', _line.len));
          } else {
            for (var j = 0; j < _ll; j++) {
              curves[j + iIndex].values.add(_parsed[j] ?? undef?.value);
            }
          }
          iIndex += _ll;
          if (iIndex >= _llc) {
            iIndex = 0;
          }
        }
      }
      final _strt = curves.first.values.first;
      final _stop = curves.first.values.last;
      final _ld = curves.first.values.length;
      var _step = curves.first.values[1] - _strt;
      for (var i = 1; i < _ld; i++) {
        if (_step != curves.first.values[i] - curves.first.values[i - 1]) {
          _step = 0.0;
          break;
        }
      }
      for (var j = 0; j < _llc; j++) {
        curves[j].strt = _strt;
        curves[j].stop = _stop;
        curves[j].step = _step;
        curves[j].indexStrt = 0;
        curves[j].indexStop = _llc - 1;
      }
      for (var j = 1; j < _llc; j++) {
        final _l = curves[j].values.length;
        var _indexStrt = -1;
        var _indexStop = 0;
        for (var i = 0; i < _l; i++) {
          final _val = curves[j].values[i];
          if (_val != undef?.value) {
            if (_indexStrt == -1) {
              _indexStrt = i;
            }
            _indexStop = i;
          }
        }
        if (_indexStrt != -1) {
          curves[j].strt = curves[0].values[_indexStrt];
          curves[j].stop = curves[0].values[_indexStop];
          curves[j].step = 0.0;
          final _d = curves[0].values.sublist(_indexStrt, _indexStop + 1);
          final _ll = _d.length;
          if (_ll > 1) {
            curves[j].step = _d[1] - _d[0];
            for (var i = 1; i < _ll; i++) {
              if (curves[j].step != _d[i] - _d[i - 1]) {
                curves[j].step = 0.0;
                break;
              }
            }
          }
          final _c = curves[j].values.sublist(_indexStrt, _indexStop + 1);
          curves[j].values.clear();
          curves[j].values.addAll(_c);
          curves[j].indexStrt = _indexStrt;
          curves[j].indexStop = _indexStop;
        } else {
          curves[j].strt = 0.0;
          curves[j].stop = 0.0;
          curves[j].step = 0.0;
          curves[j].indexStrt = 0;
          curves[j].indexStop = 0;
          curves[j].values.clear();
        }
      }
      ofd = OneFileLasData(
          v: sV,
          a: sA,
          w: sW,
          c: sC,
          p: sP.isNotEmpty ? sP : null,
          o: sO.isNotEmpty ? sO : null);
    } catch (e, bt) {
      notes.add(TxtNote.exception(thisPoint, '$e\n$bt'));
      exception = true;
    }
  }
}

extension IOneFileLasData on LasParserContext {
  static LasParserContext /*?*/ createByString(final String data) =>
      LasParserContext(data);

  String get getDebugString {
    final str = StringBuffer();
    str.writeln('РАЗОБРАННЫЙ LAS ФАЙЛ');
    str.writeln('Заметки:');
    for (var note in notes) {
      str.writeln(note.debugString);
    }
    str.writeln('VERS:'.padRight(24) + (version?.value?.toString() ?? 'null'));
    str.writeln('WRAP:'.padRight(24) + (wrap?.value?.toString() ?? 'null'));
    str.writeln('WELL:'.padRight(24) + (well?.data?.toString() ?? 'null'));
    str.writeln('STRT:'.padRight(24) + (strt?.value?.toString() ?? 'null'));
    str.writeln('STOP:'.padRight(24) + (stop?.value?.toString() ?? 'null'));
    str.writeln('STEP:'.padRight(24) + (step?.value?.toString() ?? 'null'));
    str.writeln('NULL:'.padRight(24) + (undef?.value?.toString() ?? 'null'));
    str.writeln('Кривые:');
    for (var c in curves) {
      str.writeln(c);
    }

    if (next != null) {
      str.writeln('ВНИМАНИЕ! ВЛОЖЕННЫЙ LAS ФАЙЛ:');
      str.writeln(next.getDebugString);
    }

    str.writeln();
    str.writeln('Разобранные строки:');
    for (var c in lines) {
      str.writeln(c);
    }

    return str.toString();
  }
}
