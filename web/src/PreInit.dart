import 'dart:html';

import 'App.dart';
import 'TaskCard.dart';
import 'TaskFiles.dart';
import 'TaskSets.dart';

Future<void> preInitApp() async {
  TaskCard.htmlTemplateSrc =
      await HttpRequest.getString('/templates/TaskCard.html');
  TaskSetsPath.htmlTemplateSrc =
      await HttpRequest.getString('/templates/TaskSetsPath.html');
  LasFileDetails.htmlTemplateSrc =
      await HttpRequest.getString('/templates/LasFileDetails.html');
  InkFileDetails.htmlTemplateSrc =
      await HttpRequest.getString('/templates/InkFileDetails.html');
  App();
}
