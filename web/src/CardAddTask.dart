import 'dart:html';

import 'DialogAddTask.dart';
import 'misc.dart';

class CardAddTask {
  final eCard = eGetById('my-add-task-card');

  static Future<void> init() async {
    document.body.querySelector('main div.mdc-layout-grid__inner').appendHtml(
        await HttpRequest.getString('/src/CardAddTask.html'),
        validator: nodeValidator);
    CardAddTask();
  }

  CardAddTask._init() {
    print('$runtimeType created: $hashCode');
    eCard.onClick.listen((_) => DialogAddTask().open());

    eCard.querySelector('.mdc-card__media-content > i')?.style?.transform =
        'scale(${eCard.offsetWidth / 48})';
    window.onResize.listen((_) => eCard
        .querySelector('.mdc-card__media-content > i')
        ?.style
        ?.transform = 'scale(${eCard.offsetWidth / 48})');
  }

  static CardAddTask _instance;
  factory CardAddTask() => (_instance) ?? (_instance = CardAddTask._init());
}
