/// Клиент отправляет серверу запрос на обновление данных всех задач
const wwwTaskViewUpdate = 'taskview;';

/// Клиент отправляет серверу запрос на новую задачу
const wwwTaskNew = 'tasknew;';

/// Первое сообщение от сервера с уникальным айди для клиента
const wwwClientId = '@';

/// Подписка на обновления состояния задачи, далее идёт айди задачи
const wwwTaskUpdates = 'taskupdates;';

/// Закрыть подписку на обновления
const wwwStreamClose = 'streamclose;';
