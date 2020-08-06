import 'package:m4d_core/m4d_ioc.dart' as ioc;
import 'package:m4d_components/m4d_components.dart';

import 'src/PreInit.dart';

void main() {
  preInitApp();
  ioc.Container.bindModules([CoreComponentsModule()]);
  componentHandler().upgrade();
}
