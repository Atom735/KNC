import 'dart:html';

import 'package:mdc_web/mdc_web.dart';
import 'package:js/js.dart';

final htmlValidator = NodeValidatorBuilder.common()
  ..allowElement('button', attributes: ['data-badge']);

final uri = Uri.tryParse(document.baseUri);

Element eGetById(final String id) => document.getElementById(id);

@JS('mdc')
extension MyMDCSnackbar on MDCSnackbar {
  external void open();
  external void close([String reason = '']);
}
