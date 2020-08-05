import 'dart:convert' as c;

import 'errors.dart';

/// Клиент отправляет серверу запрос на обновление данных всех задач
const wwwTaskViewUpdate = 'taskview;';

/// Клиент отправляет серверу запрос на новую задачу
const wwwTaskNew = 'tasknew;';

/// Подписка на обновления состояния задачи, далее идёт айди задачи
const wwwTaskUpdates = 'taskupdates;';

/// Запрос на получение ошибок
const wwwTaskGetErrors = 'taskgeterros;';

/// Закрыть подписку на обновления
const wwwStreamClose = 'streamclose;';

class CLasFileSub {
  final bool added;
  final String mnem;
  final double strt;
  final double stop;

  CLasFileSub(this.added, this.mnem, this.strt, this.stop);
  CLasFileSub.fromJson(final dynamic json)
      : added = json['added'],
        mnem = json['mnem'],
        strt = json['strt'],
        stop = json['stop'];
  dynamic toJson() =>
      {'added': added, 'mnem': mnem, 'strt': strt, 'stop': stop};
}

abstract class C_File {}

class CLasFile extends C_File {
  final String origin;
  final String path;
  final String well;
  final List<CLasFileSub> subs;

  CLasFile(this.origin, this.path, this.well, this.subs);
  CLasFile.fromJson(final dynamic json)
      : origin = json['origin'],
        path = json['path'],
        well = json['well'],
        subs = List(json['subc']) {
    for (var i = 0; i < subs.length; i++) {
      subs[i] = CLasFileSub.fromJson(json['subs'][i]);
    }
  }
  dynamic toJson() => {
        'origin': origin,
        'path': path,
        'well': well,
        'subc': subs.length,
        'subs': subs.map((e) => e.toJson()).toList()
      };
}

class CInkFile extends C_File {
  final String origin;
  final String path;
  final String well;
  final double strt;
  final double stop;
  final bool added;

  CInkFile(this.origin, this.path, this.well, this.strt, this.stop, this.added);

  CInkFile.fromJson(final dynamic json)
      : origin = json['origin'],
        path = json['path'],
        well = json['well'],
        strt = json['strt'],
        stop = json['stop'],
        added = json['added'];
  dynamic toJson() => {
        'origin': origin,
        'path': path,
        'well': well,
        'strt': strt,
        'stop': stop,
        'added': added
      };
}

class CErrorOnLine {
  final String origin;
  final String path;
  final List<ErrorOnLine> errors;

  CErrorOnLine(this.origin, this.path, this.errors);
  CErrorOnLine.fromJson(final dynamic json)
      : origin = json['origin'],
        path = json['path'],
        errors = List(json['errorc']) {
    for (var i = 0; i < errors.length; i++) {
      errors[i] = ErrorOnLine.fromJson(json['errors'][i]);
    }
  }
  dynamic toJson() => {
        'origin': origin,
        'path': path,
        'errorc': errors.length,
        'errors': errors.map((e) => e.toJson()).toList()
      };

  static List<CErrorOnLine> getByJsonString(String str) {
    final v = c.json.decode(str);
    if (v is Map) {
      return [CErrorOnLine.fromJson(v)];
    } else if (v is List) {
      return v
          .map<CErrorOnLine>((e) => CErrorOnLine.fromJson(e))
          .toList(growable: false);
    } else {
      return [];
    }
  }

  String get html {
    final s = StringBuffer();
    s.write('<details><summary>$origin</summary><p>$path</p>');
    for (final err in errors) {
      s.write('<p>${err.line}: ${kncErrorStrings[err.err]}<hr>${err.txt}</p>');
    }
    s.write('</details>');
    return s.toString();
  }
}
