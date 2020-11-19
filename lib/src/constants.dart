/// [WebSocket] подключение производится по адрессу
/// `ws://{host}:{port}/ws/{UserSessionToken}`

/// Отправляется сервером как самое первое сообщение пользователю установившим
/// [WebSocket] соединение. Содержит JSON данные пользователя, которые можно
/// разобрать с помощью [JsUser]
const msgUserConnected = 'UserConnected:';

/// Отправляется клиентом, как регистрация нового пользователя. Генерируется с
/// помощью [JsUser.genJsonStringReg]. Возвращается [UserSessionToken] нового
/// пользователя для подключения.
const msgUserReg = 'UserReg:';

/// Отправляется клиентом, как вход через нового пользователя. Генерируется с
/// помощью [JsUser.genJsonStringPass]. Возвращается [UserSessionToken]
/// для подключения через пользователя.
const msgUserPass = 'UserPass:';
