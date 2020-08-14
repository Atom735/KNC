import 'dart:html';

import 'package:knc/www.dart';
import 'package:mdc_web/mdc_web.dart';

import 'App.dart';
import 'DialogLogin.dart';
import 'misc.dart';

class DialogRegistration extends MDCDialog {
  final ButtonElement eSignIn = eGetById('my-registration-dialog-sign-in');
  final ButtonElement eRegistration =
      eGetById('my-registration-dialog-registration');
  final eLinearProgress =
      MDCLinearProgress(eGetById('my-registration-dialog-linear-progress'));
  final eInMail = MDCTextField(eGetById('my-registration-dialog-mail'));
  final eInPass = MDCTextField(eGetById('my-registration-dialog-pass'));

  DialogRegistration._init(Element root) : super(root) {
    print('DialogRegistration created: $hashCode');

    eLinearProgress.close();
    eInMail.disabled = false;
    eInPass.disabled = false;
    eSignIn.disabled = false;
    eRegistration.disabled = false;

    eRegistration.onClick.listen((_) {
      eLinearProgress.open();
      eInMail.disabled = true;
      eInPass.disabled = true;
      eSignIn.disabled = true;
      eRegistration.disabled = true;
      print('$wwwSignIn${eInMail.value}:${passwordEncode(eInPass.value)}');
      App()
          .requestOnce(
              '$wwwSignIn${eInMail.value}:${passwordEncode(eInPass.value)}')
          .then((msg) {
        _instance = null;
      });
    });

    eSignIn.onClick.listen((_) {
      close();
      DialogLogin().open();
    });
  }
  static DialogRegistration _instance;
  factory DialogRegistration() =>
      (_instance) ??
      (_instance =
          DialogRegistration._init(eGetById('my-registration-dialog')));
}
