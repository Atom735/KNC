
/// Первое сообщение от сервера с уникальным айди для клиента
const wwwClientId = '@';

/// Клиент отправляет серверу запрос на обновление данных всех задач
const wwwTaskViewUpdate = 'taskview;';

/// Клиент отправляет серверу запрос на новую задачу
const wwwTaskNew = 'tasknew;';

/// Подписка на обновления состояния задачи, далее идёт айди задачи
const wwwTaskUpdates = 'taskupdates;';

/// Закрыть подписку на обновления
const wwwStreamClose = 'streamclose;';
