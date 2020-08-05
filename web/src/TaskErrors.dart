import 'dart:html';

import 'misc.dart';

class TaskErrorsDialog {
  final DialogElement eDialog = eGetById('task-errors-dialog');
  final SpanElement eCounter = eGetById('task-errors-counter');
  final DivElement eContent = eGetById('task-errors-content');

  final ButtonElement eClose = eGetById('task-errors-close');
  final ButtonElement eLoad = eGetById('task-errors-load');
  final DivElement eSpinner = eGetById('task-errors-spinner');
}
