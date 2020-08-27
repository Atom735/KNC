import 'dart:html';

import 'package:mdc_web/mdc_web.dart';

import 'src/App.dart';
import 'src/DialogAddTask.dart';
import 'src/DialogLogin.dart';
import 'src/DialogRegistration.dart';

void main() async {
  await DialogAddTask.init();
  await DialogLogin.init();
  await DialogRegistration.init();
  autoInit();
  document.querySelectorAll('.mdc-icon-button').forEach((element) {
    MDCRipple(element).unbounded = true;
  });
  App();
}
