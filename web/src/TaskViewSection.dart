import 'dart:convert';
import 'dart:html';

import 'package:knc/www.dart';

import 'App.dart';
import 'TaskCard.dart';
import 'misc.dart';

class TaskViewSection {
  final Element eSection = eGetById('task-view-section');
  final Element eLoader = eGetById('task-view-loader');

  final list = <int, TaskCard>{};

  bool _loading = true;
  set loading(final bool b) {
    if (_loading == b) {
      return;
    }
    _loading = b;
    eLoader.hidden = !_loading;
  }

  TaskCard add(final int id) {
    eSection.appendHtml(TaskCard.html(id), validator: htmlValidator);
    return list[id] = TaskCard(id);
  }

  void update() {
    list.forEach((k, v) => v.hidden = false);
    loading = false;
  }

  TaskViewSection._init() {
    Future(() {
      App().requestOnce(wwwTaskViewUpdate).then((msg) {
        final items = json.decode(msg);
        for (final item in items) {
          final t = add(item['id']);
          t.eName.innerText = item['name'];
          t.iState = item['state'];
          t.iErrors = item['errors'];
          t.iFiles = item['files'];
        }
        update();
      });
      App().waitMsgAll(wwwTaskUpdates).listen((msg) {
        final items = json.decode(msg.s);
        for (final item in items) {
          final t = list[item['id']];
          if (t != null) {
            t.iState = item['state'];
            t.iErrors = item['errors'];
            t.iFiles = item['files'];
          }
        }
      });
      App().waitMsgAll(wwwTaskNew).listen((msg) {
        final v = json.decode(msg.s);
        final t = add(v['id']);
        t.eName.innerText = v['name'];
        t.iState = v['state'];
        t.iErrors = v['errors'];
        t.iFiles = v['files'];
        update();
      });
    });
  }

  static TaskViewSection _instance;
  factory TaskViewSection() =>
      (_instance) ?? (_instance = TaskViewSection._init());
}
