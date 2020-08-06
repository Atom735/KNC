import 'dart:html';

import 'App.dart';
import 'TaskCard.dart';
import 'TaskSets.dart';

Future<void> preInitApp() async {
  TaskCard.htmlTemplateSrc =
      await HttpRequest.getString('/templates/TaskCard.html');
  TaskSetsPath.htmlTemplateSrc =
      await HttpRequest.getString('/templates/TaskSetsPath.html');

  App();
}
