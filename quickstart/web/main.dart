import 'dart:html';

import 'package:m4d_core/m4d_ioc.dart' as ioc;
import 'package:m4d_components/m4d_components.dart';

/// webdev serve --auto refresh --debug --launch-in-chrome --log-requests

class TaskState {
  int id;
  String name;
  int state;
  // TODO: details
}

Element eGetById(final String id) => document.getElementById(id);

class TaskSetsPath {
  String value = '';
  final int id;
  final TableRowElement eRow;
  final InputElement eInput;
  final Element eRemove;
  TaskSetsPath(this.id, final List<TaskSetsPath> list)
      : eRow = eGetById('task-sets-path-${id}-row'),
        eInput = eGetById('task-sets-path-${id}-input'),
        eRemove = eGetById('task-sets-path-${id}-remove') {
    eRemove.onClick.listen((_) {
      eRow.remove();
      list[id] = null;
    });
    componentHandler().upgradeElement(eRow);
    eInput.focus();
  }

  static String html(final int id) => '''
    <tr id="task-sets-path-${id}-row">
      <td>
        <div class="mdl-textfield">
          <input id="task-sets-path-${id}-input" class=" mdl-textfield__input"
            type="text">
          <label for="task-sets-path-${id}-input" class="mdl-textfield__label">
            Путь к папке или файлу для обработки...
          </label>
        </div>
      </td>
      <td><button id="task-sets-path-${id}-remove"
          class="mdl-button mdl-button--icon">
          <i class="material-icons">remove</i>
        </button></td>
    </tr>
  ''';
}

class TaskSetsDialog {
  final DialogElement eDialog;
  final ButtonElement eClose;
  final ButtonElement eStart;
  final InputElement eName;
  final TableElement eTable;
  final ButtonElement eOpen;
  final ButtonElement ePath;

  final pathList = <TaskSetsPath>[];

  Future start() async {
    // TODO: отправка данных
  }

  void pathAdd() {
    var i = pathList.indexOf(null);
    if (i == -1) {
      i = pathList.length;
      pathList.add(null);
    }
    eTable.appendHtml(TaskSetsPath.html(i));
    pathList[i] = TaskSetsPath(i, pathList);
  }

  TaskSetsDialog()
      : eDialog = eGetById('task-sets-dialog'),
        eClose = eGetById('task-sets-close'),
        eStart = eGetById('task-sets-start'),
        eName = eGetById('task-sets-name'),
        eTable = eGetById('task-sets-table'),
        eOpen = eGetById('task-sets-open'),
        ePath = eGetById('task-sets-path') {
    eClose.onClick.listen((_) => eDialog.close());
    eStart.onClick.listen((_) => start());
    eOpen.onClick.listen((_) => eDialog.showModal());
    ePath.onClick.listen((_) => pathAdd());
    pathAdd();
  }
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
  final ButtonElement btnStartNewTask =
      document.getElementById('new-task-sets-btn-start');
  btnStartNewTask.onClick.listen((_) {
    dialogNewTaskSets.close();
  });

  final newTaskPathList = <TaskSetsPath>[];

  final InputElement newTaskName = document.getElementById('new-task-name');

  final TableElement tableNewTaskPaths =
      document.getElementById('new-task-path-table');
  void tableNewTaskPathsAddNew() {
    var i = newTaskPathList.indexOf(null);
    final taskPath = TaskSetsPath();
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
