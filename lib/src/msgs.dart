import 'dart:convert';

import 'package:knc/knc.dart';

/// Вход пользователя в систему.
///
/// Клиент отправляет запрос серверу, в ответ приходят данные о пользователе
/// [JUser] в `Json` формате, в случае неудачи пустая строка.
class JMsgUserSignin {
  static const msgId = 'JMsgUserSignin:';

  final String mail;
  final String pass;

  factory JMsgUserSignin.fromString(final String str) {
    final s = str.split(msgRecordSeparator);
    return JMsgUserSignin(s[0], s[1]);
  }
  const JMsgUserSignin(this.mail, this.pass);

  @override
  String toString() => '$msgId$mail$msgRecordSeparator$pass';

  static String jsFunc(String mail, String pass) =>
      JMsgUserSignin(mail, pass).toString();
}

/// Выход пользователя из системы.
///
/// Клиент отправляет запрос серверу, в ответ приходит пустая строка.
class JMsgUserLogout {
  static const msgId = 'JMsgUserLogout:';

  const JMsgUserLogout();
  @override
  String toString() => '$msgId';

  static String jsFunc() => JMsgUserLogout().toString();
}

/// Регистрация нового пользователя и вход.
///
/// Клиент отправляет запрос серверу с данными нового пользователя,
/// в ответ приходят данные о пользователе
/// [JUser] в `Json` формате, в случае неудачи пустая строка.
class JMsgUserRegistration {
  static const msgId = 'JMsgUserRegistration:';
  final JUser user;

  factory JMsgUserRegistration.fromString(final String str) =>
      JMsgUserRegistration(JUser.fromJson(jsonDecode(str)));
  const JMsgUserRegistration(this.user);

  @override
  String toString() => msgId + jsonEncode(user);

  static String jsFunc(
      String mail, String pass, String firstName, String secondName) {
    return JMsgUserRegistration(JUser(
      mail,
      pass,
      'a',
      firstName: firstName,
      secondName: secondName,
    )).toString();
  }
}

/// Запрос на получение данных задачи
///
/// Клиент отправляет запрос серверу для получения списка задач и их
/// состояния, также передаются идентификаторы, разделяемые символом
/// `;` задач, которые уже имеются у клиента.
///
/// Первое сообщение [JMsgTasksAll] отправляется клиенту с массивом
/// идентификаторов задач разделённых символом `;`.
///
/// Пустое сообщение посылается самой задаче, которая возвращает состояния
/// в виде сообщений [JMsgTaskUpdate].
///
/// Пустое сообщение передаётся клиенту как завершающее
class JMsgGetTasks {
  static const msgId = 'JMsgGetTasks:';

  const JMsgGetTasks();

  @override
  String toString() => msgId;

  static String jsFunc() => JMsgGetTasks().toString();
}

/// Сообщение [JMsgTaskKill] отправляется клиентом серверу с
/// идентификатором задачи которую необходимо уничтожить.
///
/// Возврщается идентификатор убитой задачи.
///
/// Также это сообщение может придти просто так от сервера, как уведомление
/// что задача удалена и к ней больше нет доступа.
class JMsgTaskKill {
  static const msgId = 'JMsgTaskKill:';
  final String id;

  factory JMsgTaskKill.fromString(final String str) => JMsgTaskKill(str);
  const JMsgTaskKill(this.id);

  @override
  String toString() => msgId + id;

  static String jsFunc(String id) => JMsgTaskKill(id).toString();
}

/// Сообщение [JMsgTasksAll] отправляется клиенту с массивом
/// идентификаторов задач разделённых символом `;`.
///
/// Так же означает начало передачи последующих данных о задачах в виде
/// сообщений [JMsgTaskUpdate].
///
/// Пустое сообщение передаётся клиенту как завершающее.
class JMsgTasksAll {
  static const msgId = 'JMsgAllTasks:';
  final List<String> ids;

  factory JMsgTasksAll.fromString(final String str) =>
      JMsgTasksAll(str.split(';'));
  const JMsgTasksAll(this.ids);

  @override
  String toString() => msgId + ids.join(';');
}

/// Сообщение об обновлении состояния задачи.
///
/// Приходит как уведомление от сервера клиенту. Передаются только
/// обновлённые поля, после чего внтуренний [state] необходимо слить с
/// клиентским.
class JMsgTaskUpdate {
  static const msgId = 'JMsgTaskUpdate:';
  final JTaskState state;

  factory JMsgTaskUpdate.fromString(final String str) =>
      JMsgTaskUpdate(JTaskState.fromJson(jsonDecode(str)));
  const JMsgTaskUpdate(this.state);
  @override
  String toString() => msgId + jsonEncode(state.mapUpdates);
}

/// Сообщение о создании новой задачи.
///
/// Приходит как уведомление от сервера клиенту. Передаётся идентификатор
/// новой задачи.
class JMsgTaskNew {
  static const msgId = 'JMsgTaskNew:';
  final String id;

  factory JMsgTaskNew.fromString(final String str) => JMsgTaskNew(str);
  const JMsgTaskNew(this.id);
  @override
  String toString() => msgId + id;
}

/// Сообщение от задачи о состоянии отчёта.
///
/// Отправляется задачей серверу, в [path] передаётся относительный путь к
/// файлу таблице.
class JMsgTaskRaport {
  static const msgId = 'JMsgTaskRaport:';
  final String path;

  factory JMsgTaskRaport.fromString(final String str) => JMsgTaskRaport(str);
  const JMsgTaskRaport([this.path = '']);
  @override
  String toString() => msgId + path;
}

/// Запрос на преобразование старого `*.doc` файла по пути [doc] в современный
/// `*.docx` файл по пути [docx].
///
/// Обычно отправляется исполнителем задачи главному изоляту, который в ответ
/// возвращает число, которое верёнт программа `WordConv.exe`.
class JMsgDoc2X {
  static const msgId = 'JMsgDoc2X:';

  /// Путь к старому файлу
  final String doc;

  /// Путь к новому файлу
  final String docx;

  factory JMsgDoc2X.fromString(final String str) {
    final s = str.split(msgRecordSeparator);
    return JMsgDoc2X(s[0], s[1]);
  }
  const JMsgDoc2X(this.doc, this.docx);
  @override
  String toString() => '$msgId$doc$msgRecordSeparator$docx';

  static String jsFunc(String doc, String docx) =>
      JMsgDoc2X(doc, docx).toString();
}

/// Запрос на запаковку файлов находящихся в [dir], в файл [zip]
///
/// Обычно отправляется исполнителем задачи главному изоляту, который в ответ
/// возвращает данные о работе архиватор в формате [ArchiverOutput].
class JMsgZip {
  static const msgId = 'JMsgZip:';

  /// Путь к папке с файлами
  final String dir;

  /// Путь к сгенерированному архиву
  final String zip;

  factory JMsgZip.fromString(final String str) {
    final s = str.split(msgRecordSeparator);
    return JMsgZip(s[0], s[1]);
  }
  const JMsgZip(this.dir, this.zip);
  @override
  String toString() => '$msgId$dir$msgRecordSeparator$zip';

  static String jsFunc(String dir, String zip) => JMsgZip(dir, zip).toString();
}

/// Запрос на распаковку файлов находящихся в [zip], в папку [dir], который
/// может быть пустой строкой, тогда архив распакуется во временную папку.
///
/// Обычно отправляется исполнителем задачи главному изоляту, который в ответ
/// возвращает данные о работе архиватор в формате [ArchiverOutput].
class JMsgUnzip {
  static const msgId = 'JMsgUnzip:';

  /// Путь к архиву
  final String zip;

  /// Путь к папке в которую будут распакованны файлы, может быть пустой
  /// строкой, тогда архив распакуется во временную папку.
  final String dir;

  factory JMsgUnzip.fromString(final String str) {
    final s = str.split(msgRecordSeparator);
    return JMsgUnzip(s[0], s.length > 1 ? s[1] : '');
  }
  const JMsgUnzip(this.zip, [this.dir = '']);
  @override
  String toString() => '$msgId$zip$msgRecordSeparator$dir';

  static String jsFunc(String zip, String dir) =>
      JMsgUnzip(zip, dir).toString();
}

/// Запрос на создание новой задачи... Настройки задачи передаются параметром.
///
/// Клиент отправляет запрос серверу с настройками новой задачи,
/// в ответ приходит идентификатор новой задачи, в случае неудачи пустая строка.
class JMsgNewTask {
  static const msgId = 'JMsgNewTask:';

  /// Путь к архиву
  final JTaskSettings settings;

  factory JMsgNewTask.fromString(final String str) =>
      JMsgNewTask(JTaskSettings.fromJson(jsonDecode(str)));
  const JMsgNewTask(this.settings);
  @override
  String toString() => msgId + jsonEncode(settings);

  static String jsFunc(String settings) =>
      JMsgNewTask.fromString(settings).toString();
}
