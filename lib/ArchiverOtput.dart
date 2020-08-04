class ArchiverOutput {
  /// Имя выходного файла
  final String pathOut;
  final int exitCode;
  final String stdOut;
  final String stdIn;
  ArchiverOutput(this.pathOut, this.exitCode, this.stdOut, this.stdIn);

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
}
