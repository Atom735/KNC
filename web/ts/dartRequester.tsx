/// Вход на сервер возможен с помощью отправки почты и шифрованного пароля
/// с помощью метода `POST`, тогда вебклиенту возвращается строка прав доступа
/// и другие данные пользователя...
///
/// - `mail` и `pass` храним в `Cookie` браузера для послебующих запросов
/// - `WebSocket` соединение считается постоянным и не требует идентификации
/// при каждом запросе

export const msgRecordSeparator = "\u001E";

/// Класс содержащий данные о пользователе
export interface JUser {
  /// Имя пользователя
  first_name: String;
  /// Фамилия пользователя
  second_name: String;
  /// Почта пользователя
  mail: String;
  /// Захешированная в `md5` строка пароля
  pass: String;
  /// Символы доступа пользователя
  access: String;
}

/// Вход пользователя в систему.
///
/// Клиент отправляет запрос серверу, в ответ приходят данные о пользователе
/// [JUser] в `Json` формате, в случае неудачи пустая строка.
export function JMsgUserSignin(mail: String, pass: String) {
  console.log("Сообщение сгененирорванно!");
  return "JMsgUserSignin:" + mail + msgRecordSeparator + pass;
}

/// Выход пользователя из системы.
///
/// Клиент отправляет запрос серверу, в ответ приходит пустая строка.
export function JMsgUserLogout(mail: String, pass: String) {
  return "JMsgUserLogout:";
}

/// Регистрация нового пользователя и вход.
///
/// Клиент отправляет запрос серверу с данными нового пользователя,
/// в ответ приходят данные о пользователе
/// [JUser] в `Json` формате, в случае неудачи пустая строка.
export function JMsgUserRegistration(user: JUser) {
  return "JMsgUserRegistration:" + user;
}

export function msgRequest(msg: String, callback: CallableFunction) {
  console.log("Сообщение отправляется: " + msg);
  if (msg.startsWith("JMsgUserSignin:")) {
    console.log("Сообщение перехвачено: " + msg);
    setTimeout(callback, 333, msg.split(msgRecordSeparator)[0].substring(15));
  }
}
