import 'package:mdc_web/src/base.dart';
import 'mdc_web/snackbar.dart';

/// Snackbars provide brief messages about app processes at the bottom of the
/// screen.
///
/// Javascript: `mdc.snackbar.MDCSnackbar`.
///
/// * [Design Guidelines](https://material.io/go/design-snackbar)
/// * [Component Reference](https://material.io/develop/web/components/snackbars/)
/// * [Demo](https://material-components.github.io/material-components-web-catalog/#/component/snackbar)
/// * [Source Code](https://github.com/material-components/material-components-web/blob/master/packages/mdc-snackbar/index.js)
class MDCSnackbar extends MDCComponent {
  static MDCSnackbar attachTo(Element root) => MDCSnackbar._attach(root);
  MDCSnackbar._attach(Element root) : _js = SnackbarComponent.attachTo(root);

  MDCSnackbar(Element root, [MDCFoundation foundation, args])
      : _js = _preserveUndefined(root, foundation, args);

  @override
  SnackbarComponent get js => _js;
  final SnackbarComponent _js;

  bool get isOpen => js.isOpen;
  set timeoutMs(num value) => js.timeoutMs = value;
  num get timeoutMs => js.timeoutMs;
  set closeOnEscape(bool value) => js.closeOnEscape = value;
  bool get closeOnEscape => js.closeOnEscape;
  set labelText(String value) => js.labelText = value;
  String get labelText => js.labelText;
  set actionButtonText(String value) => js.actionButtonText = value;
  String get actionButtonText => js.actionButtonText;

  void open() => js.open();
  void close([String reason = '']) => js.close(reason);

  static const openingEvent = 'MDCDialog:opening';
  static const openedEvent = 'MDCDialog:opened';

  /// `event.detail`: {action: string?}
  static const closingEvent = 'MDCDialog:closing';

  /// `event.detail`: {action: string?}
  static const closedEvent = 'MDCDialog:closed';
}

SnackbarComponent _preserveUndefined(
        Element root, MDCFoundation foundation, args) =>
    foundation == null
        ? SnackbarComponent(root)
        : args == null
            ? SnackbarComponent(root, foundation)
            : SnackbarComponent(root, foundation, args);
