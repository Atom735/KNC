import 'dart:html';

import 'package:knc/knc.dart';
import 'package:mdc_web/mdc_web.dart' hide MDCSnackbar;
import 'MDC/snackbar.dart';

import 'App.dart';
import 'DialogRegistration.dart';
import 'misc.dart';

class DialogLogin extends MDCDialog {
  final ButtonElement eSignIn = eGetById('my-login-dialog-sign-in');
  final ButtonElement eRegistration = eGetById('my-login-dialog-registration');
  final eLinearProgress =
      MDCLinearProgress(eGetById('my-login-dialog-linear-progress'));
  final eInMail = MDCTextField(eGetById('my-login-dialog-mail'));
  final eInPass = MDCTextField(eGetById('my-login-dialog-pass'));
  final eSnackBarOfError =
      MDCSnackbar(eGetById('my-login-dialog-sackbar-error'));

  static Future<void> init() async {
    document.body.appendHtml(
        await HttpRequest.getString('/src/DialogLogin.html'),
        validator: nodeValidator);
    DialogLogin();
  }

  DialogLogin._init(Element root) : super(root) {
    print('$runtimeType created: $hashCode');
    _clear();

    eSignIn.onClick.listen((_) {
      eLinearProgress.open();
      eInMail.disabled = true;
      eInPass.disabled = true;
      eSignIn.disabled = true;
      eRegistration.disabled = true;
      App()
          .requestOnce(
              '$wwwUserSignin${eInMail.value}$msgRecordSeparator${passwordEncode(eInPass.value)}')
          .then((msg) {
        if (msg.isNotEmpty) {
          _clear();
          window.localStorage['signin'] =
              '${eInMail.value}$msgRecordSeparator${passwordEncode(eInPass.value)}';
          App().signin(eInMail.value, msg);
        } else {
          _clear();
          open();
          eSnackBarOfError.open();
        }
      });
    });

    eRegistration.onClick.listen((_) {
      _clear();
      DialogRegistration().open();
    });
  }
  void _clear() {
    close();
    eLinearProgress.close();
    eInMail.disabled = false;
    eInPass.disabled = false;
    eSignIn.disabled = false;
    eRegistration.disabled = false;
  }

  static DialogLogin _instance;
  factory DialogLogin() =>
      (_instance) ??
      (_instance = DialogLogin._init(eGetById('my-login-dialog')));
}
