import 'package:knc/SocketWrapper.dart';

class ArchiverOutput {
  /// Имя выходного файла
  final int exitCode;
  final String pathOut;
  final String stdOut;
  final String stdIn;
  ArchiverOutput(this.exitCode, this.pathOut, [this.stdOut, this.stdIn]);

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

  factory ArchiverOutput.fromWrapperMsg(final String msg) {
    final i0 = msg.indexOf(msgRecordSeparator);
    final exitCode = int.tryParse(msg.substring(0, i0));
    if (exitCode == 0) {
      return ArchiverOutput(
          exitCode, msg.substring(i0 + msgRecordSeparator.length));
    } else {
      return ArchiverOutput(
          exitCode,
          null,
          msg.substring(0, i0),
          msg.substring(i0 + msgRecordSeparator.length,
              msg.indexOf(msgRecordSeparator, i0 + msgRecordSeparator.length)));
    }
  }

  String toWrapperMsg() => exitCode == 0
      ? '$exitCode$msgRecordSeparator$pathOut'
      : '$exitCode$msgRecordSeparator$stdOut$msgRecordSeparator$stdIn';
}
