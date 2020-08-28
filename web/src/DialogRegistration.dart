import 'dart:html';

import 'package:knc/knc.dart';
import 'package:mdc_web/mdc_web.dart' hide MDCSnackbar;
import 'MDC/snackbar.dart';

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
  final eSnackBarOfError =
      MDCSnackbar(eGetById('my-registration-dialog-sackbar-error'));

  static Future<void> init() async {
    document.body.appendHtml(
        await HttpRequest.getString('/src/DialogRegistration.html'));
    DialogRegistration();
  }

  DialogRegistration._init(Element root) : super(root) {
    print('$runtimeType created: $hashCode');
    _clear();

    eRegistration.onClick.listen((_) {
      eLinearProgress.open();
      eInMail.disabled = true;
      eInPass.disabled = true;
      eSignIn.disabled = true;
      eRegistration.disabled = true;
      App()
          .requestOnce(
              '$wwwRegistration${eInMail.value}:${passwordEncode(eInPass.value)}')
          .then((msg) {
        if (msg != 'null') {
          _clear();
          window.localStorage['signin'] =
              '${eInMail.value}:${passwordEncode(eInPass.value)}';
          App().signin(eInMail.value, msg);
        } else {
          _clear();
          open();
          eSnackBarOfError.open();
        }
      });
    });

    eSignIn.onClick.listen((_) {
      close();
      DialogLogin().open();
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

  static DialogRegistration _instance;
  factory DialogRegistration() =>
      (_instance) ??
      (_instance =
          DialogRegistration._init(eGetById('my-registration-dialog')));
}
