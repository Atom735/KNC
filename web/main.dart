import 'dart:html';

import 'package:mdc_web/mdc_web.dart';

import 'src/App.dart';

void main() {
  autoInit();
  document.querySelectorAll('.mdc-icon-button').forEach((element) {
    MDCRipple(element).unbounded = true;
  });
  App();
}
