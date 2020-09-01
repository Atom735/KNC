import 'package:knc/knc.dart';

import 'IsoTask.dart';

Future<OneFileData> parserFileLas(final IsoTask kncTask,
    final OneFileData fileData, final String data, final String encode) async {
  final _dataLength = data.length;
  final _notes = <OneFileLineNote>[];

  var bNewLine = true;
  var iSymbol = 0;
  var iLine = 1;
  var iColumn = 1;

  void _addNoteError(final String _text, [final String _data]) =>
      _notes.add(OneFileLineNote(iLine, iColumn, '!E$_text', _data));
  void _addNoteWarning(final String _text, [final String _data]) =>
      _notes.add(OneFileLineNote(iLine, iColumn, '!W$_text', _data));
  void _addNoteParsed(final List<String> _text, [final String _data]) =>
      _notes.add(OneFileLineNote(
          iLine, iColumn, '!P${_text.join(msgRecordSeparator)}', _data));

  int _v_iSymbol;
  int _v_vers;
  bool _v_wrap;

  int _w_iSymbol;
  String _w_strt;
  double _w_strt_n;
  String _w_stop;
  double _w_stop_n;
  String _w_step;
  double _w_step_n;
  String _w_null;
  double _w_null_n;
  String _w_well;
  String _w_well_desc;

  int _c_iSymbol;
  final _c_mnems = <String>[];
  List<String> _c_strt_s;
  List<String> _c_stop_s;
  List<double> _c_strt_n;
  List<double> _c_stop_n;
  List<int> _c_strt_i;
  List<int> _c_stop_i;

  int _a_iSymbol;
  var _a_iNum = 0;
  List<List<String>> _a_data_s;
  List<List<double>> _a_data_n;

  void rNextSymbol() {
    iSymbol++;
    iColumn++;
  }

  void rSkipWhiteSpaces() {
    while (iSymbol < _dataLength &&
        (data[iSymbol] == ' ' ||
            data[iSymbol] == '\t' ||
            data[iSymbol] == '\n' ||
            data[iSymbol] == '\r')) {
      if (data[iSymbol] == '\n' || data[iSymbol] == '\r') {
        bNewLine = true;
        iLine++;
        iColumn = 0;
        if (iSymbol >= 1 &&
            data[iSymbol] == '\n' &&
            data[iSymbol - 1] == '\r') {
          // коррекция на Windows перевод строки
          iLine--;
        }
      }
      rNextSymbol();
    }
  }

  void rSkipToEndOfLine() {
    while (iSymbol < _dataLength &&
        data[iSymbol] != '\n' &&
        data[iSymbol] != '\r') {
      rNextSymbol();
    }
  }

  void rSkipWhiteSpacesAndComments() {
    rSkipWhiteSpaces();
    while (iSymbol < _dataLength && bNewLine && data[iSymbol] == '#') {
      if (iColumn != 1) {
        _addNoteWarning('комментарий не в начале строки');
      }
      rSkipToEndOfLine();
      _addNoteParsed(['ignore']);
      rSkipWhiteSpaces();
    }
  }

  bool rSkipSection() {
    while (iSymbol < _dataLength) {
      rSkipWhiteSpacesAndComments();
      if (iSymbol >= _dataLength) {
        break;
      } else if (data[iSymbol] == '~') {
        return false;
      } else {
        _addNoteParsed(['ignore']);
        rSkipToEndOfLine();
      }
    }
    _addNoteError('непредвиденный конец файла на неизвестной секции');
    return true;
  }

  void rV_VERS(final int iSeparatorDot, final int iLineEndSymbol) {
    if (_v_vers != null) {
      _addNoteWarning('переопределение');
    }
    if (data[iSeparatorDot + 1] != ' ') {
      _addNoteWarning('отсуствует пробел после точки');
    }
    final iSeparatorColon = data.indexOf(':', iSeparatorDot);
    if (iSeparatorColon == -1 || iSeparatorColon >= iLineEndSymbol) {
      _addNoteWarning('отсутсвует двоеточие');
    }
    final _value = data
        .substring(
            iSeparatorDot + 1,
            iSeparatorColon == -1 || iSeparatorColon >= iLineEndSymbol
                ? iLineEndSymbol
                : iSeparatorColon)
        .trim();
    switch (_value) {
      case '1.20':
        _v_vers = 1;
        _addNoteParsed(['VERS', '1.20']);
        return;
      case '2.0':
        _v_vers = 2;
        _addNoteParsed(['VERS', '2.0']);
        return;
      default:
        final _vd = double.tryParse(_value);
        if (_vd == null) {
          _addNoteWarning(
              'неудалось разобрать версию файла, считается что версия файла 1.20');
          _v_vers = 1;
          _addNoteParsed(['VERS', '1.20']);
        } else {
          if (_vd == 1.2) {
            _addNoteWarning('несовсем корректная запись версии файла 1.20');
            _v_vers = 1;
            _addNoteParsed(['VERS', '1.20']);
            return;
          } else if (_vd == 2.0) {
            _addNoteWarning('несовсем корректная запись версии файла 2.0');
            _v_vers = 2;
            _addNoteParsed(['VERS', '2.0']);
            return;
          } else if (_vd >= 1.0 && _vd < 2.0) {
            _addNoteWarning('неизвестное число в записи версии файла 1.20');
            _v_vers = 1;
            _addNoteParsed(['VERS', '1.20']);
            return;
          } else if (_vd >= 2.0 && _vd < 3.0) {
            _addNoteWarning('неизвестное число в записи версии файла 2.0');
            _v_vers = 2;
            _addNoteParsed(['VERS', '2.0']);
            return;
          } else {
            _addNoteWarning(
                'неизвестное число в записи версии файла, считается что версия файла 1.20');
            _v_vers = 1;
            _addNoteParsed(['VERS', '1.20']);
            return;
          }
        }
    }
  }

  void rV_WRAP(final int iSeparatorDot, final int iLineEndSymbol) {
    if (_v_wrap != null) {
      _addNoteWarning('переопределение');
    }
    if (data[iSeparatorDot + 1] != ' ') {
      _addNoteWarning('отсуствует пробел после точки');
    }
    final iSeparatorColon = data.indexOf(':', iSeparatorDot);
    if (iSeparatorColon == -1 || iSeparatorColon >= iLineEndSymbol) {
      _addNoteWarning('отсутсвует двоеточие');
    }
    final _value = data
        .substring(
            iSeparatorDot + 1,
            iSeparatorColon == -1 || iSeparatorColon >= iLineEndSymbol
                ? iLineEndSymbol
                : iSeparatorColon)
        .trim();
    switch (_value) {
      case 'YES':
        _v_wrap = true;
        _addNoteParsed(['WRAP', 'YES']);
        return;
      case 'NO':
        _v_wrap = false;
        _addNoteParsed(['WRAP', 'NO']);
        return;
      default:
        final _value_u = _value.toUpperCase();
        switch (_value_u) {
          case 'YES':
            _addNoteWarning('запись не в верхнем регистре');
            _v_wrap = true;
            _addNoteParsed(['WRAP', 'YES']);
            return;
          case 'NO':
            _addNoteWarning('запись не в верхнем регистре');
            _v_wrap = false;
            _addNoteParsed(['WRAP', 'NO']);
            return;
          default:
            _addNoteWarning(
                'неизвестное значение перевода строки, считается что разделение строки включено');
            _v_wrap = true;
            _addNoteParsed(['WRAP', 'YES']);
            return;
        }
    }
  }

  bool rSectionV() {
    if (_v_iSymbol != null) {
      _addNoteWarning('повтороная секция');
    }
    _v_iSymbol = iSymbol;
    loop:
    while (iSymbol < _dataLength) {
      rSkipWhiteSpacesAndComments();
      if (iSymbol >= _dataLength) {
        _addNoteError('непредвиденный конец файла');
        return true;
      }
      if (data[iSymbol] == '~') {
        return false;
      }
      final iLineBeginSymbol = iSymbol;
      rSkipToEndOfLine();
      final iLineEndSymbol = iSymbol;
      final iSeparatorDot = data.indexOf('.', iLineBeginSymbol);
      if (iSeparatorDot == -1 || iSeparatorDot >= iLineEndSymbol) {
        _addNoteError('отсутсвует точка');
        continue loop;
      } else {
        final _mnem =
            data.substring(iLineBeginSymbol, iSeparatorDot).trimRight();
        switch (_mnem) {
          case 'VERS':
            rV_VERS(iSeparatorDot, iLineEndSymbol);
            continue loop;
          case 'WRAP':
            rV_WRAP(iSeparatorDot, iLineEndSymbol);
            continue loop;
          default:
            final _mnem_u = _mnem.toUpperCase();
            switch (_mnem_u) {
              case 'VERS':
                _addNoteWarning('мнемоника не в верхнем регистре');
                rV_VERS(iSeparatorDot, iLineEndSymbol);
                continue loop;
              case 'WRAP':
                _addNoteWarning('мнемоника не в верхнем регистре');
                rV_WRAP(iSeparatorDot, iLineEndSymbol);
                continue loop;
              default:
                // _addNoteWarning('проигнорированная строка');
                _addNoteParsed(['ignore']);
                continue loop;
            }
        }
      }
    }
    _addNoteError('непредвиденный конец файла');
    return true;
  }

  void rW_STxx(
      final int iSeparatorDot, final int iLineEndSymbol, final String mnem) {
    if (mnem == 'STRT' && _w_strt != null) {
      _addNoteWarning('переопределение $mnem');
    }
    if (mnem == 'STOP' && _w_stop != null) {
      _addNoteWarning('переопределение $mnem');
    }
    if (mnem == 'STEP' && _w_step != null) {
      _addNoteWarning('переопределение $mnem');
    }
    if (mnem == 'NULL' && _w_null != null) {
      _addNoteWarning('переопределение $mnem');
    }
    final iSeparatorSpace = data.indexOf(' ', iSeparatorDot);
    if (iSeparatorSpace == -1 || iSeparatorSpace >= iLineEndSymbol) {
      _addNoteWarning('отсутсвует пробел');
    }
    final iSeparatorColon = data.indexOf(':', iSeparatorDot);
    if (iSeparatorColon == -1 || iSeparatorColon >= iLineEndSymbol) {
      _addNoteWarning('отсутсвует двоеточие');
    }
    final _unit = data.substring(
        iSeparatorDot + 1,
        iSeparatorSpace == -1 ||
                iSeparatorSpace >= iLineEndSymbol ||
                (iSeparatorColon != -1 && iSeparatorSpace >= iSeparatorColon)
            ? (iSeparatorColon == -1 || iSeparatorColon >= iLineEndSymbol
                ? iLineEndSymbol
                : iSeparatorColon)
            : iSeparatorSpace);
    if (_unit.isEmpty) {
      if (mnem != 'NULL') {
        _addNoteWarning('отсутсвует размерность');
      }
    } else {
      if (mnem == 'NULL') {
        _addNoteWarning('отсутсвует пробел после точки');
      }
      final _unit_n = double.tryParse(_unit);
      if (_unit_n == null) {
        if (_unit == 'M' || _unit == 'm') {
        } else {
          _addNoteWarning('не каноничное значение размерности, игнорируется');
        }
      } else {
        _addNoteWarning('размерность взята как значение');
        switch (mnem) {
          case 'NULL':
            _w_null = _unit;
            _w_null_n = _unit_n;
            _addNoteParsed(['NULL', _w_null_n.toString()]);
            return;
          case 'STRT':
            _w_strt = _unit;
            _w_strt_n = _unit_n;
            _addNoteParsed(['STRT', _w_strt_n.toString()]);
            return;
          case 'STOP':
            _w_stop = _unit;
            _w_stop_n = _unit_n;
            _addNoteParsed(['STOP', _w_stop_n.toString()]);
            return;
          case 'STEP':
            _w_step = _unit;
            _w_step_n = _unit_n;
            _addNoteParsed(['STEP', _w_step_n.toString()]);
            return;
        }
      }
    }
    final _iEl = iSeparatorColon == -1 || iSeparatorColon >= iLineEndSymbol
        ? iLineEndSymbol
        : iSeparatorColon;
    final _value = data
        .substring(
            iSeparatorSpace >= _iEl || iSeparatorSpace == -1
                ? iSeparatorDot + 1
                : iSeparatorSpace + 1,
            _iEl)
        .trim();
    final _value_n = double.tryParse(_value);
    if (_value_n == null) {
      _addNoteError('неудалось разобрать число');
    } else {
      switch (mnem) {
        case 'NULL':
          _w_null = _value;
          _w_null_n = _value_n;
          _addNoteParsed(['NULL', _w_null_n.toString()]);
          return;
        case 'STRT':
          _w_strt = _value;
          _w_strt_n = _value_n;
          _addNoteParsed(['STRT', _w_strt_n.toString()]);
          return;
        case 'STOP':
          _w_stop = _value;
          _w_stop_n = _value_n;
          _addNoteParsed(['STOP', _w_stop_n.toString()]);
          return;
        case 'STEP':
          _w_step = _value;
          _w_step_n = _value_n;
          _addNoteParsed(['STEP', _w_step_n.toString()]);
          return;
      }
    }
  }

  void rW_WELL(final int iSeparatorDot, final int iLineEndSymbol) {
    if (_w_well != null) {
      _addNoteWarning('переопределение');
    }
    if (data[iSeparatorDot + 1] != ' ') {
      _addNoteWarning('отсуствует пробел после точки');
    }
    bool _colon;
    final iSeparatorColon = data.indexOf(':', iSeparatorDot);
    if (_colon = (iSeparatorColon == -1 || iSeparatorColon >= iLineEndSymbol)) {
      _addNoteWarning('отсутсвует двоеточие');
    }
    _w_well = data
        .substring(iSeparatorDot + 1, _colon ? iLineEndSymbol : iSeparatorColon)
        .trim();
    _w_well_desc = data
        .substring(
            _colon ? iLineEndSymbol : iSeparatorColon + 1, iLineEndSymbol)
        .trim();
    // TODO: обработка well
    _addNoteParsed(['WELL', _w_well]);
  }

  bool rSectionW() {
    if (_w_iSymbol != null) {
      _addNoteWarning('повтороная секция');
    }
    _w_iSymbol = iSymbol;
    loop:
    while (iSymbol < _dataLength) {
      rSkipWhiteSpacesAndComments();
      if (iSymbol >= _dataLength) {
        _addNoteError('непредвиденный конец файла');
        return true;
      }
      if (data[iSymbol] == '~') {
        return false;
      }
      final iLineBeginSymbol = iSymbol;
      rSkipToEndOfLine();
      final iLineEndSymbol = iSymbol;
      final iSeparatorDot = data.indexOf('.', iLineBeginSymbol);
      if (iSeparatorDot == -1 || iSeparatorDot >= iLineEndSymbol) {
        _addNoteError('отсутсвует точка');
        continue loop;
      } else {
        final _mnem =
            data.substring(iLineBeginSymbol, iSeparatorDot).trimRight();
        switch (_mnem) {
          case 'STRT':
          case 'STOP':
          case 'STEP':
          case 'NULL':
            rW_STxx(iSeparatorDot, iLineEndSymbol, _mnem);
            continue loop;
          case 'WELL':
            rW_WELL(iSeparatorDot, iLineEndSymbol);
            continue loop;
          default:
            final _mnem_u = _mnem.toUpperCase();
            switch (_mnem_u) {
              case 'STRT':
              case 'STOP':
              case 'STEP':
              case 'NULL':
                _addNoteWarning('мнемоника не в верхнем регистре');
                rW_STxx(iSeparatorDot, iLineEndSymbol, _mnem_u);
                continue loop;
              case 'WELL':
                rW_WELL(iSeparatorDot, iLineEndSymbol);
                continue loop;
              default:
                // _addNoteWarning('проигнорированная строка');
                _addNoteParsed(['ignore']);
                continue loop;
            }
        }
      }
    }
    _addNoteError('непредвиденный конец файла');
    return true;
  }

  bool rSectionC() {
    if (_c_iSymbol != null) {
      _addNoteWarning('повтороная секция');
    }
    _c_iSymbol = iSymbol;
    loop:
    while (iSymbol < _dataLength) {
      rSkipWhiteSpacesAndComments();
      if (iSymbol >= _dataLength) {
        _addNoteError('непредвиденный конец файла');
        return true;
      }
      if (data[iSymbol] == '~') {
        return false;
      }
      final iLineBeginSymbol = iSymbol;
      rSkipToEndOfLine();
      final iLineEndSymbol = iSymbol;
      final iSeparatorDot = data.indexOf('.', iLineBeginSymbol);
      if (iSeparatorDot == -1 || iSeparatorDot >= iLineEndSymbol) {
        _addNoteError('отсутсвует точка');
        continue loop;
      } else {
        final iSeparatorSpace = data.indexOf(' ', iSeparatorDot);
        if (iSeparatorSpace == -1 || iSeparatorSpace >= iLineEndSymbol) {
          _addNoteWarning('отсутсвует пробел');
        }
        final iSeparatorColon = data.indexOf(':', iSeparatorDot);
        if (iSeparatorColon == -1 || iSeparatorColon >= iLineEndSymbol) {
          _addNoteWarning('отсутсвует двоеточие');
        }
        _c_mnems
            .add(data.substring(iLineBeginSymbol, iSeparatorDot).trimRight());
      }
    }
    _addNoteError('непредвиденный конец файла');
    return true;
  }

  bool rSectionA() {
    final _curves = _c_mnems.length;
    if (_a_iSymbol != null) {
      _addNoteWarning('повтороная секция');
    } else {
      _c_strt_s = List(_curves);
      _c_stop_s = List(_curves);
      _c_strt_n = List(_curves);
      _c_stop_n = List(_curves);
      _c_strt_i = List(_curves);
      _c_stop_i = List(_curves);
      _a_data_s = List.generate(_curves, (_) => []);
      _a_data_n = List.generate(_curves, (_) => []);
    }
    _a_iSymbol = iSymbol;
    rSkipToEndOfLine();
    loop:
    while (iSymbol < _dataLength) {
      rSkipWhiteSpacesAndComments();
      if (iSymbol >= _dataLength) {
        // _addError('непредвиденный конец файла');
        return true;
      }
      if (data[iSymbol] == '~') {
        return false;
      }
      final iLineBeginSymbol = iSymbol;
      final iLineBeginColumn = iColumn;
      rSkipToEndOfLine();
      final iLineEndSymbol = iSymbol;
      if (_v_wrap == false) {
        final _nums = data
            .substring(iLineBeginSymbol, iLineEndSymbol)
            .split(' ')
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .toList(growable: false);
        if (_nums.length != _curves) {
          _addNoteError(
              'количество чисел в строке не совподает с количеством объявленных кривых');
          continue loop;
        } else {
          final _depth_s = _nums[0];
          final _depth_n = double.tryParse(_depth_s);
          final _index = _a_data_s[0].length;
          for (var i = 0; i < _curves; i++) {
            final _val = double.tryParse(_nums[i]);
            if (_val == null) {
              _addNoteError('невозможно разобрать число');
            }
            _a_data_s[i].add(_nums[i]);
            _a_data_n[i].add(_val);
            if (_val != null && _val != _w_null_n) {
              if (_c_strt_s[i] == null) {
                _c_strt_i[i] = _index;
                _c_strt_s[i] = _depth_s;
                _c_strt_n[i] = _depth_n;
              }
              _c_stop_i[i] = _index;
              _c_stop_s[i] = _depth_s;
              _c_stop_n[i] = _depth_n;
            }
          }
        }
      } else {
        // TODO: научиться работать с WRAP: YES
        _addNoteError(
            'включён перенос строки, но мы пока не умеем с ним работать');
        return true;
      }
    }
    return true;
  }

  bool rBeginOfSection() {
    if (iColumn != 1) {
      _addNoteWarning('символ начала секции не в начале строки');
    }
    rNextSymbol();
    if (iSymbol >= _dataLength) {
      _addNoteError('непредвиденный конец файла');
      return true;
    }
    // ~V - contains version and wrap mode information
    // ~W - contains well identification
    // ~C - contains curve information
    // ~P - contains parameters or constants
    // ~O - contains other information such as comments
    // ~A - contains ASCII log data
    _addNoteParsed(['section']);
    switch (data[iSymbol]) {
      case 'V':
        rSkipToEndOfLine();
        return rSectionV();
      case 'W':
        rSkipToEndOfLine();
        return rSectionW();
      case 'C':
        rSkipToEndOfLine();
        return rSectionC();
      case 'P':
      case 'O':
        // _addNoteWarning('пропуск секции');
        if (rSkipSection()) {
          return true;
        }
        return rBeginOfSection();
      case 'A':
        return rSectionA();
      default:
        _addNoteError('неизвестная секция, пропуск секции');
        if (rSkipSection()) {
          return true;
        }
        return rBeginOfSection();
    }
  }

  rSkipWhiteSpacesAndComments();
  if (iSymbol < _dataLength && data[iSymbol] != '~' || iSymbol >= _dataLength) {
    // Это не LAS файл, так как первый символ не начало секции
    return null;
  }
  if (iSymbol >= _dataLength) {
    // Это не LAS файл, так как вообще остуствует символ начала секции
    return null;
  }
  while (iSymbol < _dataLength && !rBeginOfSection()) {}

  final well = _w_well;

  final curves = List<OneFilesDataCurve>.generate(
      _c_mnems.length,
      (_index) => OneFilesDataCurve(
          _c_mnems[_index],
          _c_strt_s[_index],
          _c_stop_s[_index],
          _w_step,
          List.generate(_c_stop_i[_index] - _c_strt_i[_index],
              (_i) => _a_data_s[_index][_i + _c_strt_i[_index]])));

  return OneFileData(
      fileData.path, fileData.origin, NOneFileDataType.las, fileData.size,
      well: well, curves: curves, encode: encode, notes: _notes);
  // TODO: вернуть обработанный файл
}
