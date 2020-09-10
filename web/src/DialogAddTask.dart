import 'dart:convert';
import 'dart:html';

import 'package:knc/knc.dart';
import 'package:mdc_web/mdc_web.dart';

import 'App.dart';
import 'User.dart';
import 'misc.dart';

class DialogAddTask extends MDCDialog {
  final ButtonElement eSend = eGetById('my-add-task-dialog-send');
  final eLinearProgress =
      MDCLinearProgress(eGetById('my-add-task-dialog-linear-progress'));
  final eTabBar = MDCTabBar(eGetById('my-add-task-dialog-tab-bar'));
  final ButtonElement ePublicSwitch = eGetById('my-atd-public-switch-1');
  final ButtonElement ePublicSwitch2 = eGetById('my-atd-public-switch-2');

  final Set<MDCTab> eTabs = {};

  final eSSName = MDCTextField(eGetById('my-add-task-dialog-task-name'));
  final ButtonElement eSSPathAdd = eGetById('my-add-task-dialog-task-path-add');
  final Set<DialogAddTaskPath> eSSPathSet = {};

  final ButtonElement eSSUsersAdd =
      eGetById('my-add-task-dialog-task-users-add');
  final Set<DialogAddTaskUsers> eSSUsersSet = {};

  final eSSExtAr = MDCTextField(eGetById('my-atd-settings-ext-ar'));
  final eSSExtFiles = MDCTextField(eGetById('my-atd-settings-ext-files'));
  final eSSMaxSizeAr = MDCTextField(eGetById('my-atd-settings-maxsize-ar'));
  final eSSMaxDepthAr = MDCTextField(eGetById('my-atd-settings-maxdepth-ar'));
  final eSSUpdateDuration =
      MDCTextField(eGetById('my-atd-settings-update-duration'));

  bool _public;
  set public(final bool _i) {
    if (_i == null || _i == _public) {
      return;
    }
    _public = _i;
    if (_public) {
      ePublicSwitch.classes
        ..add('mdc-button--raised')
        ..remove('mdc-button--outlined');
      ePublicSwitch.querySelector('.mdc-button__label').innerText =
          'Видима всем';
      ePublicSwitch2.classes
        ..add('mdc-button--raised')
        ..remove('mdc-button--outlined');
      ePublicSwitch2.querySelector('.mdc-button__label').innerText =
          'Видима всем';
    } else {
      ePublicSwitch.classes
        ..remove('mdc-button--raised')
        ..add('mdc-button--outlined');
      ePublicSwitch.querySelector('.mdc-button__label').innerText =
          'Видима только мне и назначенным пользователям';
      ePublicSwitch2.classes
        ..remove('mdc-button--raised')
        ..add('mdc-button--outlined');
      ePublicSwitch2.querySelector('.mdc-button__label').innerText =
          'Видима только мне и назначенным пользователям';
    }
  }

  void addPath() {
    eSSPathSet.add(DialogAddTaskPath());
  }

  void addUsers() {
    eSSUsersSet.add(DialogAddTaskUsers());
  }

  @override
  void open() {
    reset();
    super.open();
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
    public = true;
    ePublicSwitch.disabled = User() == null;
    ePublicSwitch2.disabled = User() == null;
    addPath();
    addUsers();
    tabActive = 1;
  }

  void send() {
    eLinearProgress.open();

    final path =
        eSSPathSet.map((e) => e.value).where((e) => e.isNotEmpty).toList();
    final users =
        eSSUsersSet.map((e) => e.value).where((e) => e.isNotEmpty).toList();

    final v = TaskSettings(
            name: eSSName.value.isNotEmpty
                ? eSSName.value
                : TaskSettings.def_name,
            path: path.isNotEmpty ? path : TaskSettings.def_path,
            users: _public ? TaskSettings.def_users : users,
            ext_ar: eSSExtAr.value.isEmpty
                ? TaskSettings.def_ext_ar
                : eSSExtAr.value.split(';'),
            ext_files: eSSExtFiles.value.isEmpty
                ? TaskSettings.def_ext_files
                : eSSExtFiles.value.split(';'),
            maxsize_ar: eSSMaxSizeAr.value.isEmpty
                ? TaskSettings.def_maxsize_ar
                : int.tryParse(eSSMaxSizeAr.value) ??
                    TaskSettings.def_maxsize_ar,
            maxdepth_ar: eSSMaxDepthAr.value.isEmpty
                ? TaskSettings.def_maxdepth_ar
                : int.tryParse(eSSMaxDepthAr.value) ??
                    TaskSettings.def_maxdepth_ar,
            update_duration: eSSUpdateDuration.value.isEmpty
                ? TaskSettings.def_update_duration
                : int.tryParse(eSSUpdateDuration.value) ??
                    TaskSettings.def_update_duration)
        .toJson();

    App().requestOnce('$wwwTaskNew${jsonEncode(v)}').then((msg) => reset());
  }

  static Future<void> init() async {
    document.body.appendHtml(
        await HttpRequest.getString('/src/DialogAddTask.html'),
        validator: nodeValidator);
    DialogAddTask();
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
    eSSUsersAdd.onClick.listen((_) => addUsers());
    eSend.onClick.listen((_) => send());

    ePublicSwitch.onClick.listen((e) => public = !_public);
    ePublicSwitch2.onClick.listen((e) => public = !_public);
    reset();
  }
  static DialogAddTask _instance;
  factory DialogAddTask() => (_instance) ?? (_instance = DialogAddTask._init());
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

class DialogAddTaskUsers extends MDCTextField {
  final ButtonElement btnClose;
  final DivElement container;
  DialogAddTaskUsers._init(Element root, this.btnClose, this.container)
      : super(root) {
    btnClose.onClick.listen((_) => _close());
  }
  void _close() {
    DialogAddTask().eSSUsersSet.remove(this);
    container.remove();
  }

  static int ident = 0;

  factory DialogAddTaskUsers() {
    final div = DivElement();
    div.classes.add('my-add-task-dialog-task-path');
    final _id = 'my-add-task-dialog-task-users-$ident';
    div.innerHtml = '''
              <label id="$_id"
                class="mdc-text-field mdc-text-field--filled mdc-text-field--fullwidth">
                <span class="mdc-text-field__ripple"></span>
                <input class="mdc-text-field__input" type="text" name="path"
                  placeholder="Почта пользователя которому предоставится доступ">
                <span class="mdc-line-ripple"></span>
              </label>
              <button id="$_id-btn" type="button"
                class="mdc-icon-button material-icons">close</button>
    ''';
    DialogAddTask()
        .eSSUsersAdd
        .parent
        .insertBefore(div, DialogAddTask().eSSUsersAdd);
    ident++;
    return DialogAddTaskUsers._init(eGetById(_id), eGetById(_id + '-btn'), div);
  }
}
