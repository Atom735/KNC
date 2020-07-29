import 'dart:html';

import 'package:m4d_core/m4d_ioc.dart' as ioc;
import 'package:m4d_components/m4d_components.dart';

/// webdev serve --auto refresh --debug --launch-in-chrome --log-requests

class TaskPath {
  int i;
  String value = '';
  TableRowElement eTr;
  InputElement eInput;
  Element eButton;
}

Future main() async {
  ioc.Container.bindModules([CoreComponentsModule()]);
  await componentHandler().upgrade();

  final DialogElement dialogTaskDetails =
      document.getElementById('task-details');
  final ButtonElement btnCloseTaskDetails =
      document.getElementById('task-details-btn-close');
  btnCloseTaskDetails.onClick.listen((_) {
    dialogTaskDetails.close();
  });

  final DialogElement dialogNewTaskSets =
      document.getElementById('new-task-sets');
  final ButtonElement btnCloseNewTaskSets =
      document.getElementById('new-task-sets-btn-close');
  btnCloseNewTaskSets.onClick.listen((_) {
    dialogNewTaskSets.close();
  });

  final newTaskPathList = <TaskPath>[];

  final InputElement newTaskName = document.getElementById('new-task-name');

  final TableElement tableNewTaskPaths =
      document.getElementById('new-task-path-table');
  void tableNewTaskPathsAddNew() {
    var i = newTaskPathList.indexOf(null);
    final taskPath = TaskPath();
    if (i == -1) {
      i = newTaskPathList.length;
      newTaskPathList.add(taskPath);
    } else {
      newTaskPathList[i] = taskPath;
    }

    taskPath.i = i;
    tableNewTaskPaths.appendHtml('''
            <tr id="new-task-path${i}-div">
              <td>
                <div class="mdl-textfield">
                  <input class="mdl-textfield__input" type="text"
                    id="new-task-path${i}">
                  <label class="mdl-textfield__label" for="new-task-path${i}">
                    Путь к папке или файлу для обработки...</label>
                </div>
              </td>
              <td><button class="mdl-button mdl-button--icon"
                  id="new-task-path${i}-remove">
                  <i class="material-icons">remove</i>
                </button></td>
            </tr>
  ''');
    taskPath.eTr = document.getElementById('new-task-path${i}-div');
    taskPath.eInput = document.getElementById('new-task-path${i}');
    taskPath.eButton = document.getElementById('new-task-path${i}-remove');
    taskPath.eButton.onClick.listen((_) {
      taskPath.eTr.remove();
      newTaskPathList[i] = null;
    });

    componentHandler().upgradeElement(tableNewTaskPaths);

    taskPath.eInput.focus();
  }

  tableNewTaskPathsAddNew();

  final btnNewTaskPathAdd = document.getElementById('new-task-path-add');
  btnNewTaskPathAdd.onClick.listen((_) => tableNewTaskPathsAddNew());

  final AnchorElement btnAddNewTask = document.getElementById('add-task-btn');
  btnAddNewTask.onClick.listen((_) {
    dialogNewTaskSets.showModal();
    newTaskName.focus();
  });

  final List<ButtonElement> btnsTaskDetails =
      document.querySelectorAll<ButtonElement>('.task-btn-details');
  for (var btn in btnsTaskDetails) {
    btn.onClick.listen((_) {
      dialogTaskDetails.showModal();
    });
  }
}
