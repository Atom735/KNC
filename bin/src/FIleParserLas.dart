import 'knc.dart';
import 'las.dart';

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
    final listOfErrors = [];
    final listOfWarnings = [];
    final _dataLength = data.length;

    var bLas = false;
    var bNewLine = true;
    var iSymbol = 0;
    var iLine = 1;
    var iColumn = 1;

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
          // TODO: Warning: комментарий не в начале строки
        }
        rSkipToEndOfLine();
        rSkipWhiteSpaces();
      }
    }

    bool rSkipSection() {
      while (iSymbol < _dataLength) {
        rSkipWhiteSpacesAndComments();
        if (iSymbol >= _dataLength) {
          // TODO: Error: непредвиденный конец файла на неизвестной секции
          return true;
        } else if (data[iSymbol] == '~') {
          return false;
        }
      }
    }

    bool rBeginOfSection() {
      if (iColumn != 1) {
        // TODO: Warning: символ начала секции не в начале строки
      }
      rNextSymbol();
      if (iSymbol >= _dataLength) {
        // TODO: Error: непредвиденный конец файла
        return true;
      }
      switch (data[iSymbol]) {
        case 'I':
          break;
        default:
          // TODO: Warning: неизвестная секция
          if (rSkipSection()) {
            return true;
          } else {
            return rBeginOfSection();
          }
      }
      return false;
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
