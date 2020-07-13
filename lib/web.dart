import 'dart:io';

String getRequestDebugData(final HttpRequest request) {
  final string = StringBuffer();
  string.writeln('Received request ${request.method}: ${request.uri.path}');
  string.writeln('HTTP: ${request.protocolVersion}');
  string.writeln();
  string.writeln('= cookies begin =');
  for (var i = 0; i < request.cookies.length; i++) {
    string.writeln('[${i + 1}] = ${request.cookies[i]}');
  }
  string.writeln('= cookies end =');
  string.writeln();
  string.writeln('= headers begin =');
  request.headers.forEach((name, values) {
    if (values.length == 1) {
      string.writeln('$name: ${values[0]}');
    } else {
      string.writeln('$name:');
      values.forEach((value) {
        string.writeln('    $value');
      });
    }
  });
  string.writeln('= headers end =');
  return string.toString();
}
