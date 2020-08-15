@JS('mdc.snackbar')
library snackbar;

import 'dart:html';
import 'package:js/js.dart';
import 'package:mdc_web/src/mdc_web/base.dart';

/// Snackbars provide brief messages about app processes at the bottom of the
/// screen.
///
/// Javascript: `mdc.snackbar.MDCSnackbar`.
///
/// * [Design Guidelines](https://material.io/go/design-snackbar)
/// * [Component Reference](https://material.io/develop/web/components/snackbars/)
/// * [Demo](https://material-components.github.io/material-components-web-catalog/#/component/snackbar)
/// * [Source Code](https://github.com/material-components/material-components-web/blob/master/packages/mdc-snackbar/index.js)
///
/// 18:41 15.08.2020
@JS('MDCSnackbar')
abstract class SnackbarComponent extends Component {
  external static SnackbarComponent attachTo(Element root);
  external factory SnackbarComponent(Element root,
      [MDCFoundation foundation, args]);

  external bool get isOpen;
  external set timeoutMs(num value);
  external num get timeoutMs;
  external set closeOnEscape(bool value);
  external bool get closeOnEscape;
  external set labelText(String value);
  external String get labelText;
  external set actionButtonText(String value);
  external String get actionButtonText;

  external void open();
  external void close([String reason = '']);
}
