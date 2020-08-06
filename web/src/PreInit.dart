import 'dart:html';

import 'App.dart';
import 'TaskCard.dart';

Future<void> preInitApp() async {
  TaskCard.htmlTemplateSrc =
      await HttpRequest.getString('/templates/TaskCard.html');

  App();
}
