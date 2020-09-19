import 'SocketWrapper.dart';

class ArchiverOutput {
  /// Имя выходного файла
  final int exitCode;
  final String pathIn;
  final String pathOut;
  final String stdOut;
  final String stdErr;
  ArchiverOutput(
      {required this.exitCode,
      required this.pathIn,
      required this.pathOut,
      required this.stdOut,
      required this.stdErr});

  String get resultString {
    switch (exitCode) {
      case 0:
        return r'OK';
      case 1:
        return r'(Non fatal error(s)). For example, one or more files were locked by some other application, so they were not compressed.';
      case 2:
        return r'Fatal error';
      case 7:
        return r'Command line error';
      case 8:
        return r'Not enough memory for operation';
      case 255:
        return r'User stopped the process';
      default:
        return r'Unknown error';
    }
  }

  @override
  String toString() => '$resultString\n=> STDOUT\n$stdOut\n=> STDERR\n$stdErr';

  factory ArchiverOutput.fromWrapperMsg(final String msg) {
    final i0 = msg.indexOf(msgRecordSeparator);
    final i1 = msg.indexOf(msgRecordSeparator, i0 + msgRecordSeparator.length);
    final exitCode = int.tryParse(msg.substring(0, i0));
    if (exitCode == 0) {
      return ArchiverOutput(
          exitCode: exitCode,
          pathIn: msg.substring(i0 + msgRecordSeparator.length, i1),
          pathOut: msg.substring(i1 + msgRecordSeparator.length));
    } else {
      final i2 =
          msg.indexOf(msgRecordSeparator, i1 + msgRecordSeparator.length);
      return ArchiverOutput(
          exitCode: exitCode,
          pathIn: msg.substring(i0 + msgRecordSeparator.length, i1),
          stdOut: msg.substring(i1 + msgRecordSeparator.length, i2),
          stdErr: msg.substring(i2 + msgRecordSeparator.length));
    }
  }

  String toWrapperMsg() => exitCode == 0
      ? '$exitCode$msgRecordSeparator$pathIn$msgRecordSeparator$pathOut'
      : '$exitCode$msgRecordSeparator$pathIn$msgRecordSeparator$stdOut$msgRecordSeparator$stdErr';
}
