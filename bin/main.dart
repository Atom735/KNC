import 'dart:io';

import 'src/app.dart';

void main(List<String> args) {
  App(Directory(r'web')).run(80);
}
