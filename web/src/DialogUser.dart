import 'dart:html';

import 'package:mdc_web/mdc_web.dart' hide MDCSnackbar;

import 'User.dart';
import 'misc.dart';

class DialogUser extends MDCDialog {
  final ButtonElement eLogOut = eGetById('my-user-dialog-logout');

  static Future<void> init() async {
    document.body.appendHtml(
        await HttpRequest.getString('/src/DialogUser.html'),
        validator: nodeValidator);
    DialogUser();
  }

  DialogUser._init(Element root) : super(root) {
    print('$runtimeType created: $hashCode');
    close();
    eLogOut.onClick.listen((_) {
      User.logout();
      close();
    });
  }

  static DialogUser _instance;
  factory DialogUser() =>
      (_instance) ?? (_instance = DialogUser._init(eGetById('my-user-dialog')));
}
