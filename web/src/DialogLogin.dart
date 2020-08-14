import 'dart:html';

import 'package:knc/www.dart';
import 'package:mdc_web/mdc_web.dart';

import 'App.dart';
import 'misc.dart';

class DialogLogin extends MDCDialog {
  final ButtonElement eSignIn = eGetById('my-login-dialog-sign-in');
  final ButtonElement eRegistration = eGetById('my-login-dialog-registration');
  final eLinearProgress =
      MDCLinearProgress(eGetById('my-login-dialog-linear-progress'));
  final eInMail = MDCTextField(eGetById('my-login-dialog-mail'));
  final eInPass = MDCTextField(eGetById('my-login-dialog-pass'));

  DialogLogin._init(Element root) : super(root) {
    eLinearProgress.close();
    eInMail.disabled = false;
    eInPass.disabled = false;
    eSignIn.disabled = false;
    eRegistration.disabled = false;

    eSignIn.onClick.listen((_) {
      eLinearProgress.open();
      eInMail.disabled = true;
      eInPass.disabled = true;
      eSignIn.disabled = true;
      eRegistration.disabled = true;
      print('$wwwLogin${eInMail.value};${passwordEncode(eInPass.value)}');
      App()
          .requestOnce(
              '$wwwLogin${eInMail.value};${passwordEncode(eInPass.value)}')
          .then((msg) {
        _instance = null;
      });
    });
  }
  static DialogLogin _instance;
  factory DialogLogin() =>
      (_instance) ??
      (_instance = DialogLogin._init(eGetById('my-login-dialog')));
}
