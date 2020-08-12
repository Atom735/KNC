import 'dart:html';
import 'package:mdc_web/mdc_web.dart';

void main() {
  autoInit();
  querySelectorAll('.mdc-button').forEach(MDCRipple.attachTo);
  querySelectorAll('.mdc-icon-button').forEach(MDCRipple.attachTo);

  querySelector('#output').text = 'Your Dart app is running.';
}
