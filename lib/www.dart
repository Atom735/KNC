import 'dart:convert' as converter;

String _enc(final String str) => str != null
    ? str
        .replaceAll(r'\', r'\\')
        .replaceAll(r'"', r'\"')
        .replaceAll('\'', '\\\'')
    : str;

/// Начало сообщения о начале выполнения KncTask
const wwwKncTaskAdd = '#SS.A:';

/// Начало сообщения о последнем сообщении
const wwwKncTaskLastMsg = '#LastMsg';

/// Начало сообщения о обновлении состояния задачи {uID}:{iState}
const wwwKncTaskUpdateState = '#SS.US:';

/// Начало сообщения о обновлении ссылки на документ XML {uID}:{path}
const wwwKncTaskUpdateXlsTable = '#XLS:';

/// Путь к задачам
const wwwPathToTasks = '/task/';

/// Путь к подключению WebSocket
const wwwPathToWs = '/ws';

/// Начало сообщения об исключении
const wwwMsgException = '#Exception:';

/// Начало сообщения об ошибке
const wwwMsgError = '#Error:';

/// Начало сообщения о начале секции LAS
const wwwMsgLasBegin = '#Las:+';

/// Начало сообщения о секции LAS
const wwwMsgLas = '#Las:\t';

/// Начало сообщения о конце секции LAS
const wwwMsgLasEnd = '#Las:\$';

/// Начало сообщения о начале секции INK
const wwwMsgInkBegin = '#Ink:+';

/// Начало сообщения о секции INK
const wwwMsgInk = '#Ink:\t';

/// Начало сообщения о конце секции INK
const wwwMsgInkEnd = '#Ink:\$';

enum KncTaskState { initializing, work, generateTable, end }

class KncSettingsInternal {
  String get wsUpdateState => '$wwwKncTaskUpdateState${uID}:${iState.index}';

  /// Состояние задачи
  KncTaskState iState = KncTaskState.initializing;

  /// Последнее сообщение от сокета
  String lastWsMsg;

  /// Уникальный идентификатор
  int uID;

  /// Наименование задачи
  String ssTaskName = 'name';

  /// Путь к конечным данным
  String ssPathOut = '';

  /// Путь к XSL таблице
  String pathToTable;

  /// Настройки расширения для архивных файлов
  List<String> ssFileExtAr = ['.zip', '.rar'];

  /// Настройки расширения для файлов LAS
  List<String> ssFileExtLas = ['.las'];

  /// Настройки расширения для файлов с инклинометрией
  List<String> ssFileExtInk = ['.doc', '.docx', '.txt', '.dbf'];

  /// Путь для поиска файлов
  /// получается из полей `[path0, path1, path2, path3, ...]`
  List<String> pathInList = [];

  /// Максимальный размер вскрываемого архива в байтах
  ///
  /// Для задания значения можно использовать постфиксы:
  /// * `k` = КилоБайты
  /// * `m` = МегаБайты = `kk`
  /// * `g` = ГигаБайты = `kkk`
  ///
  /// `0` - для всех архивов
  ///
  /// По умолчанию 1Gb
  int ssArMaxSize = 1024 * 1024 * 1024;

  /// Максимальный глубина прохода по архивам
  /// * `-1` - для бесконечной вложенности (По умолчанию)
  /// * `0` - для отбрасывания всех архивов
  /// * `1` - для входа на один уровень архива
  int ssArMaxDepth = -1;

  /// Преобразует данные настроек в строку JSON
  String get json {
    final s = StringBuffer();
    s.write('{');
    s.write('"uID":"$uID"');
    s.write(',"lastWsMsg":"${_enc(lastWsMsg)}"');
    s.write(',"ssTaskName":"${_enc(ssTaskName)}"');
    s.write(',"ssPathOut":"${_enc(ssPathOut)}"');
    s.write(',"ssFileExtAr":[');
    if (ssFileExtAr.isNotEmpty) {
      s.write('"${_enc(ssFileExtAr[0])}"');
      for (var i = 1; i < ssFileExtAr.length; i++) {
        s.write(',"${_enc(ssFileExtAr[i])}"');
      }
    }
    s.write('],"ssFileExtLas":[');
    if (ssFileExtLas.isNotEmpty) {
      s.write('"${_enc(ssFileExtLas[0])}"');
      for (var i = 1; i < ssFileExtLas.length; i++) {
        s.write(',"${_enc(ssFileExtLas[i])}"');
      }
    }
    s.write('],"ssFileExtInk":[');
    if (ssFileExtInk.isNotEmpty) {
      s.write('"${_enc(ssFileExtInk[0])}"');
      for (var i = 1; i < ssFileExtInk.length; i++) {
        s.write(',"${_enc(ssFileExtInk[i])}"');
      }
    }
    s.write('],"pathInList":[');
    if (pathInList.isNotEmpty) {
      s.write('"${_enc(pathInList[0])}"');
      for (var i = 1; i < pathInList.length; i++) {
        s.write(',"${_enc(pathInList[i])}"');
      }
    }
    s.write('],"ssArMaxSize":$ssArMaxSize');
    s.write(',"ssArMaxDepth":$ssArMaxDepth');
    s.write('}');
    return s.toString();
  }

  /// Преобразует строку JSON в данные настроек
  set json(final String str) {
    print(str);
    final map = converter.json.decode(str);
    print(map);
    if (map['uID'] != null) {
      if (map['uID'] is num) {
        uID = (map['uID'] as num).toInt();
      } else if (map['uID'] is String) {
        uID = int.tryParse(map['uID'] as String);
      }
    }
    if (map['lastWsMsg'] != null && map['lastWsMsg'] is String) {
      lastWsMsg = map['lastWsMsg'];
    }
    if (map['ssTaskName'] != null && map['ssTaskName'] is String) {
      ssTaskName = map['ssTaskName'];
    }
    if (map['ssPathOut'] != null && map['ssPathOut'] is String) {
      ssPathOut = map['ssPathOut'];
    }
    if (map['ssFileExtAr'] != null) {
      if (ssFileExtAr == null) {
        ssFileExtAr = [];
      } else {
        ssFileExtAr.clear();
      }
      for (var item in map['ssFileExtAr']) {
        ssFileExtAr.add(item);
      }
    }
    if (map['ssFileExtLas'] != null) {
      if (ssFileExtLas == null) {
        ssFileExtLas = [];
      } else {
        ssFileExtLas.clear();
      }
      for (var item in map['ssFileExtLas']) {
        ssFileExtLas.add(item);
      }
    }
    if (map['ssFileExtInk'] != null) {
      if (ssFileExtInk == null) {
        ssFileExtInk = [];
      } else {
        ssFileExtInk.clear();
      }
      for (var item in map['ssFileExtInk']) {
        ssFileExtInk.add(item);
      }
    }
    if (map['pathInList'] != null) {
      if (pathInList == null) {
        pathInList = [];
      } else {
        pathInList.clear();
      }
      for (var item in map['pathInList']) {
        pathInList.add(item);
      }
    }
    if (map['ssArMaxSize'] != null) {
      if (map['ssArMaxSize'] is num) {
        ssArMaxSize = (map['ssArMaxSize'] as num).toInt();
      } else if (map['ssArMaxSize'] is String) {
        ssArMaxSize = int.tryParse(map['ssArMaxSize'] as String);
      }
    }
    if (map['ssArMaxDepth'] != null) {
      if (map['ssArMaxDepth'] is num) {
        ssArMaxDepth = (map['ssArMaxDepth'] as num).toInt();
      } else if (map['ssArMaxDepth'] is String) {
        ssArMaxDepth = int.tryParse(map['ssArMaxDepth'] as String);
      }
    }
  }

  /// Заменяет теги ${{tag}} на значение настройки
  String updateBufferByThis(final String data) {
    final out = StringBuffer();
    var i0 = 0;
    var i1 = data.indexOf(r'${{');
    while (i1 != -1) {
      out.write(data.substring(i0, i1));
      i0 = data.indexOf(r'}}', i1);
      var name = data.substring(i1 + 3, i0);
      switch (name) {
        case 'uID':
          out.write(uID);
          break;
        case 'lastWsMsg':
          out.write(lastWsMsg);
          break;
        case 'ssTaskName':
          out.write(ssTaskName);
          break;
        case 'ssPathOut':
          out.write(ssPathOut);
          break;
        case 'ssFileExtAr':
          if (ssFileExtAr.isNotEmpty) {
            out.write(ssFileExtAr[0]);
            for (var i = 1; i < ssFileExtAr.length; i++) {
              out.write(';');
              out.write(ssFileExtAr[i]);
            }
          }
          break;
        case 'ssFileExtLas':
          if (ssFileExtLas.isNotEmpty) {
            out.write(ssFileExtLas[0]);
            for (var i = 1; i < ssFileExtLas.length; i++) {
              out.write(';');
              out.write(ssFileExtLas[i]);
            }
          }
          break;
        case 'ssFileExtInk':
          if (ssFileExtInk.isNotEmpty) {
            out.write(ssFileExtInk[0]);
            for (var i = 1; i < ssFileExtInk.length; i++) {
              out.write(';');
              out.write(ssFileExtInk[i]);
            }
          }
          break;
        case 'ssArMaxSize':
          if (ssArMaxSize % (1024 * 1024 * 1024) == 0) {
            out.write('${ssArMaxSize ~/ (1024 * 1024 * 1024)}G');
          } else if (ssArMaxSize % (1024 * 1024) == 0) {
            out.write('${ssArMaxSize ~/ (1024 * 1024)}M');
          } else if (ssArMaxSize % (1024) == 0) {
            out.write('${ssArMaxSize ~/ (1024)}K');
          } else {
            out.write('${ssArMaxSize}');
          }
          break;
        case 'ssArMaxDepth':
          out.write('${ssArMaxDepth}');
          break;
        default:
          out.write('\${{$name}}');
      }
      i0 += 2;
      i1 = data.indexOf(r'${{', i0);
    }
    out.write(data.substring(i0));
    return out.toString();
  }

  /// Обновляет данные через полученные данные HTML формы
  void updateByMultiPartFormData(final Map<String, String> map) {
    if (map['ssTaskName'] != null) {
      ssTaskName = map['ssTaskName'];
    }
    if (map['ssPathOut'] != null) {
      ssPathOut = map['ssPathOut'];
    }
    if (map['ssFileExtAr'] != null) {
      ssFileExtAr.clear();
      ssFileExtAr = map['ssFileExtAr'].toLowerCase().split(';');
      ssFileExtAr.removeWhere((element) => element.isEmpty);
    }
    if (map['ssFileExtLas'] != null) {
      ssFileExtLas.clear();
      ssFileExtLas = map['ssFileExtLas'].toLowerCase().split(';');
      ssFileExtLas.removeWhere((element) => element.isEmpty);
    }
    if (map['ssFileExtInk'] != null) {
      ssFileExtInk.clear();
      ssFileExtInk = map['ssFileExtInk'].toLowerCase().split(';');
      ssFileExtInk.removeWhere((element) => element.isEmpty);
    }
    if (map['ssArMaxSize'] != null) {
      final str = map['ssArMaxSize'].toLowerCase();
      ssArMaxSize = int.tryParse(
          str.replaceAll('k', '').replaceAll('m', '').replaceAll('g', ''));
      if (ssArMaxSize != null) {
        if (str.endsWith('kkk') ||
            str.endsWith('g') ||
            str.endsWith('km') ||
            str.endsWith('mk')) {
          ssArMaxSize *= 1024 * 1024 * 1024;
        } else if (str.endsWith('kk') || str.endsWith('m')) {
          ssArMaxSize *= 1024 * 1024;
        } else if (str.endsWith('k')) {
          ssArMaxSize *= 1024;
        }
      } else {
        ssArMaxSize = 0;
      }
    }
    if (map['ssArMaxDepth'] != null) {
      ssArMaxDepth = int.tryParse(map['ssArMaxDepth']);
      ssArMaxDepth ??= -1;
    }
    pathInList.clear();
    for (var i = 0; map['path$i'] != null; i++) {
      pathInList.add(map['path$i'].replaceAll('"', ''));
    }
  }
}

/// Клиент отправляет серверу запрос на обновление данных всех задач
const wwwTaskViewUpdate = 'taskview;';

/// Клиент отправляет серверу запрос на новую задачу
const wwwTaskNew = 'tasknew;';

/// Подписка на обновления состояния задачи, далее идёт айди задачи
const wwwTaskUpdates = 'taskupdates;';

/// Закрыть подписку на обновления
const wwwStreamClose = 'streamclose;';
