import 'dart:html';

import 'package:m4d_core/m4d_ioc.dart' as ioc;
import 'package:m4d_components/m4d_components.dart';
import 'package:mdc_web/mdc_web.dart';

import 'src/PreInit.dart';

void main() {
  autoInit();
  document.querySelectorAll('.mdc-icon-button').forEach((element) {
    MDCRipple(element).unbounded = true;
  });

  final ButtonElement myLoginDialogOpen =
      document.querySelector('#my-login-dialog-open');

  preInitApp();
  ioc.Container.bindModules([CoreComponentsModule()]);
  componentHandler().upgrade();
}
