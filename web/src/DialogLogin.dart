import 'dart:html';

import 'package:mdc_web/mdc_web.dart';

import 'misc.dart';

class DialogLogin extends MDCDialog {
  DialogLogin._init(Element root) : super(root);
  static DialogLogin _instance;
  factory DialogLogin() =>
      (_instance) ??
      (_instance = DialogLogin._init(eGetById('my-login-dialog')));
}
