import 'knc.dart';

class ParserFileLas extends OneFileData {
  ParserFileLas._new(
      final String path,
      final String origin,
      final NOneFileDataType type,
      final int size,
      final String well,
      final List<OneFilesDataCurve> curves)
      : super(path, origin, type, size, well: well, curves: curves);

  static Future<ParserFileLas> get(
      final KncTask kncTask,
      final OneFileData fileData,
      final String data,
      final String encode) async {
    final _dataLength = data.length;
    final _errors = <OneFileLineNote>[];
    final _warnings = <OneFileLineNote>[];

    var bLas = false;
    var bNewLine = true;
    var iSymbol = 0;
    var iLine = 1;
    var iColumn = 1;

    void _addError(final String _text, [final String _data]) =>
        _errors.add(OneFileLineNote(iLine, iColumn, _text, _data));
    void _addWarning(final String _text, [final String _data]) =>
        _warnings.add(OneFileLineNote(iLine, iColumn, _text, _data));

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
        if (iSymbol != 1) {
          _addWarning('комментарий не в начале строки');
        }
        rSkipToEndOfLine();
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
          rSkipToEndOfLine();
        }
      }
      _addError('непредвиденный конец файла на неизвестной секции');
      return true;
    }

    void rV_VERS(final int iSeparatorDot, final int iLineEndSymbol) {
      if (_v_vers != null) {
        _addWarning('переопределение версии файла');
      }
      if (data[iSeparatorDot + 1] != ' ') {
        _addWarning('отсуствует пробел после точки');
      }
      final iSeaparatorColon = data.indexOf(':', iSeparatorDot);
      if (iSeaparatorColon == -1 || iSeaparatorColon >= iLineEndSymbol) {
        _addWarning('отсутсвует двоеточие');
      }
      final _value = data
          .substring(
              iSeparatorDot + 1,
              iSeaparatorColon == -1 || iSeaparatorColon >= iLineEndSymbol
                  ? iLineEndSymbol
                  : iSeaparatorColon)
          .trim();
      switch (_value) {
        case '1.2':
          _v_vers = 1;
          return;
        case '2.0':
          _v_vers = 2;
          return;
        default:
          final _vd = double.tryParse(_value);
          if (_vd == null) {
            _addWarning(
                'неудалось разобрать версию файла, считается что версия файла 1.2');
            _v_vers = 1;
          } else {
            if (_vd == 1.2) {
              _addWarning('несовсем корректная запись версии файла 1.2');
              _v_vers = 1;
              return;
            } else if (_vd == 2.0) {
              _addWarning('несовсем корректная запись версии файла 2.0');
              _v_vers = 2;
              return;
            } else if (_vd >= 1.0 && _vd < 2.0) {
              _addWarning('неизвестное число в записи версии файла 1.2');
              _v_vers = 1;
              return;
            } else if (_vd >= 2.0 && _vd < 3.0) {
              _addWarning('неизвестное число в записи версии файла 2.0');
              _v_vers = 2;
              return;
            } else {
              _addWarning(
                  'неизвестное число в записи версии файла, считается что версия файла 1.2');
              _v_vers = 1;
              return;
            }
          }
      }
    }

    void rV_WRAP(final int iSeparatorDot, final int iLineEndSymbol) {
      if (_v_wrap != null) {
        _addWarning('переопределение разделения строк');
      }
      if (data[iSeparatorDot + 1] != ' ') {
        _addWarning('отсуствует пробел после точки');
      }
      final iSeaparatorColon = data.indexOf(':', iSeparatorDot);
      if (iSeaparatorColon == -1 || iSeaparatorColon >= iLineEndSymbol) {
        _addWarning('отсутсвует двоеточие');
      }
      final _value = data
          .substring(
              iSeparatorDot + 1,
              iSeaparatorColon == -1 || iSeaparatorColon >= iLineEndSymbol
                  ? iLineEndSymbol
                  : iSeaparatorColon)
          .trim();
      switch (_value) {
        case 'YES':
          _v_wrap = true;
          return;
        case 'NO':
          _v_wrap = false;
          return;
        default:
          final _value_u = _value.toUpperCase();
          switch (_value_u) {
            case 'YES':
              _addWarning('запись не в верхнем регистре');
              _v_wrap = true;
              return;
            case 'NO':
              _addWarning('запись не в верхнем регистре');
              _v_wrap = false;
              return;
            default:
              _addWarning(
                  'неизвестное значение перевода строки, считается что разделение строки включено');
              _v_wrap = true;
              return;
          }
      }
    }

    bool rSectionV() {
      if (_v_iSymbol != null) {
        _addWarning('повтороная секция');
      }
      _v_iSymbol = iSymbol;
      loop:
      while (iSymbol < _dataLength) {
        rSkipWhiteSpacesAndComments();
        if (iSymbol >= _dataLength) {
          _addError('непредвиденный конец файла');
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
          _addError('отсутсвует точка');
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
              final _menm_u = _mnem.toUpperCase();
              switch (_menm_u) {
                case 'VERS':
                  _addWarning('мнемоника не в верхнем регистре');
                  rV_VERS(iSeparatorDot, iLineEndSymbol);
                  continue loop;
                case 'WRAP':
                  _addWarning('мнемоника не в верхнем регистре');
                  rV_WRAP(iSeparatorDot, iLineEndSymbol);
                  continue loop;
                default:
                  _addWarning('проигнорированная строка');
                  continue loop;
              }
          }
        }
      }
      _addError('непредвиденный конец файла');
      return true;
    }

    bool rSectionW() {
      if (_w_iSymbol != null) {
        _addWarning('повтороная секция');
      }
      _w_iSymbol = iSymbol;
      loop:
      while (iSymbol < _dataLength) {
        rSkipWhiteSpacesAndComments();
        if (iSymbol >= _dataLength) {
          _addError('непредвиденный конец файла');
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
          _addError('отсутсвует точка');
          continue loop;
        } else {
          final mnem =
              data.substring(iLineBeginSymbol, iSeparatorDot).trimRight();
          switch (mnem) {
            case 'STRT':
              continue loop;
            default:
              _addWarning('проигнорированная строка');
              continue loop;
          }
        }
      }
      _addError('непредвиденный конец файла');
      return true;
    }

    bool rBeginOfSection() {
      if (iColumn != 1) {
        _addWarning('символ начала секции не в начале строки');
      }
      rNextSymbol();
      if (iSymbol >= _dataLength) {
        _addError('непредвиденный конец файла');
        return true;
      }
      // ~V - contains version and wrap mode information
      // ~W - contains well identification
      // ~C - contains curve information
      // ~P - contains parameters or constants
      // ~O - contains other information such as comments
      // ~A - contains ASCII log data
      switch (data[iSymbol]) {
        case 'V':
          rSkipToEndOfLine();
          return rSectionV();
        case 'W':
          rSkipToEndOfLine();
          return rSectionW();
        default:
          _addWarning('неизвестная секция, пропуск секции');
          if (rSkipSection()) {
            return true;
          } else {
            return rBeginOfSection();
          }
      }
    }

    rSkipWhiteSpacesAndComments();
    if (iSymbol < _dataLength && data[iSymbol] != '~' ||
        iSymbol >= _dataLength) {
      // Это не LAS файл, так как первый символ не начало секции
      return null;
    }
    if (iSymbol >= _dataLength) {
      // Это не LAS файл, так как вообще остуствует символ начала секции
      return null;
    }
    while (iSymbol < _dataLength && !rBeginOfSection()) {}

    // TODO: вернуть обработанный файл
  }
}
