import 'dart:convert';
import 'dart:html';
import 'dart:math';

import 'package:knc/www.dart';
import 'package:mdc_web/mdc_web.dart';

import 'App.dart';
import 'misc.dart';

class CardAddTask {
  final eCard = eGetById('my-add-task-card');
  CardAddTask._init() {
    print('$runtimeType created: $hashCode');
    eCard.onClick.listen((_) => DialogAddTask().open());
  }

  static CardAddTask _instance;
  factory CardAddTask() => (_instance) ?? (_instance = CardAddTask._init());
}

class DialogAddTaskPath extends MDCTextField {
  final ButtonElement btnClose;
  final DivElement container;
  DialogAddTaskPath._init(Element root, this.btnClose, this.container)
      : super(root) {
    btnClose.onClick.listen((_) => _close());
  }
  void _close() {
    DialogAddTask().eSSPathSet.remove(this);
    container.remove();
  }

  static int ident = 0;

  factory DialogAddTaskPath() {
    final div = DivElement();
    div.classes.add('my-add-task-dialog-task-path');
    final _id = 'my-add-task-dialog-task-path-$ident';
    div.innerHtml = '''
              <label id="$_id"
                class="mdc-text-field mdc-text-field--filled mdc-text-field--fullwidth">
                <span class="mdc-text-field__ripple"></span>
                <input class="mdc-text-field__input" type="text" name="path"
                  placeholder="Сканируемый путь">
                <span class="mdc-line-ripple"></span>
              </label>
              <button id="$_id-btn" type="button"
                class="mdc-icon-button material-icons">close</button>
    ''';
    DialogAddTask()
        .eSSPathAdd
        .parent
        .insertBefore(div, DialogAddTask().eSSPathAdd);
    ident++;
    return DialogAddTaskPath._init(eGetById(_id), eGetById(_id + '-btn'), div);
  }
}

class DialogAddTask extends MDCDialog {
  final ButtonElement eSend = eGetById('my-add-task-dialog-send');
  final eLinearProgress =
      MDCLinearProgress(eGetById('my-add-task-dialog-linear-progress'));
  final eTabBar = MDCTabBar(eGetById('my-add-task-dialog-tab-bar'));
  final Set<MDCTab> eTabs = {};

  final eSSName = MDCTextField(eGetById('my-add-task-dialog-task-name'));
  final ButtonElement eSSPathAdd = eGetById('my-add-task-dialog-task-path-add');
  final Set<DialogAddTaskPath> eSSPathSet = {};

  void addPath() {
    eSSPathSet.add(DialogAddTaskPath());
  }

  final tabCon = eGetById('my-add-task-dialog-tab-content-container');
  ElementList<Element> tabCons;
  int _tabActive;
  set tabActive(final int i) {
    if (_tabActive == i) {
      return;
    }
    _tabActive = i;
    tabCon.style.marginLeft = '-${_tabActive - 1}00%';
  }

  void reset() {
    close();
    while (eSSPathSet.isNotEmpty) {
      eSSPathSet.last._close();
    }
    eLinearProgress.close();
    addPath();
    tabActive = 1;
  }

  void send() {
    eLinearProgress.open();

    final path =
        eSSPathSet.map((e) => e.value).where((e) => e.isNotEmpty).toList();

    final v = WWW_TaskSettings(
            name: eSSName.value.isNotEmpty
                ? eSSName.value
                : WWW_TaskSettings.def_name,
            path: path.isNotEmpty ? path : WWW_TaskSettings.def_path)
        .json;

    App().requestOnce('$wwwTaskNew${jsonEncode(v)}').then((msg) => reset());
  }

  DialogAddTask._init() : super(eGetById('my-add-task-dialog')) {
    _instance = this;
    print('$runtimeType created: $hashCode');
    eTabs.addAll(eGetById('my-add-task-dialog-tab-bar')
        .querySelectorAll('.mdc-tab')
        .map((e) => MDCTab(e)));
    tabCon.style.width = '${eTabs.length}00%';
    tabCon.style.display = 'grid';
    tabCon.style.gridTemplateRows = '1fr';
    tabCon.style.gridTemplateColumns =
        ''.padRight(eTabs.length, '*').replaceAll('*', ' 1fr');
    tabCons = tabCon.querySelectorAll('.my-add-task-dialog-tab-content');
    eTabs.forEach((e) {
      e.listen('MDCTab:interacted', (e) {
        final i = int.parse(
            (e as CustomEvent).detail['tabId'].toString().substring(8));
        tabActive = i;
      });
    });
    eSSPathAdd.onClick.listen((_) => addPath());
    eSend.onClick.listen((_) => send());

    addPath();
  }
  static DialogAddTask _instance;
  factory DialogAddTask() => (_instance) ?? (_instance = DialogAddTask._init());
}
