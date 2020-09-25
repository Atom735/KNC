


const msgRecordSeparator = '\u001E';

class SocketWrapperResponse {
  s: string;
  i: number;
  constructor(s: string, i: number) {
    this.s = s;
    this.i = i;
  }
}

/// Оболочка для взаимодействия передочи потоковых данных
///
/// * [sender] - функция отправки сообщения - должна быть задана
/// * [recv] - функция вызываемаемая при получении сообщения


var sender: (msgRaw: string) => void;
const msgIdBegin = '\u0001';
const msgIdEnd = '\u0002';
var _requestID = 0;
const _listOfRequest = new Map<number, Array<(msg: string) => any>>();
var _subscribersID = 0;
const _listOfSubscribers = new Map<number, Array<(msg: string) => any>>();
const _listOfResponses = new Map<string, Array<(msg: SocketWrapperResponse) => any>>();
const _listOfRespSubers = new Map<string, Array<(msg: SocketWrapperResponse) => any>>();

/// Функция отправки сообщений с уникальным айди
export function send(id: number, msg: string): void {
  sender.call(dartSocket, msgIdBegin + id + msgIdEnd + msg);
}

/// Возвращает `false` если на сообщение не вызвано реакции
export function recv(msgRaw: string, id: number = 0): boolean {
  if (id == undefined) {
    id = 0;
  }
  var b = false;

  /// Если сообщение содержит идетнификатор, то разбираем его
  if (msgRaw.startsWith(msgIdBegin)) {
    let i0 = msgRaw.indexOf(msgIdEnd, msgIdBegin.length);
    if (i0 != -1) {
      let id = parseInt(msgRaw.substring(msgIdBegin.length, i0));
      let msg = msgRaw.substring(i0 + msgIdEnd.length);
      let _req = _listOfRequest.get(id);
      if (_req) {
        b = true;
        for (let value of _req) {
          value(msg);
        }
        _listOfRequest.delete(id);
      }
      let _sub = _listOfSubscribers.get(id);
      if (_sub) {
        b = true;
        for (let value of _sub) {
          value(msg);
        }
      }
      if (!b) {
        /// Если сообщение не обработанно, то значит это не ответ на запрос
        /// а уведомитенльное, или сообщение команды...
        return recv(msg, id);
      }
    } else {
      throw new Error('Сообщение без идентификатора:\n$msgRaw');
    }
  } else {
    _listOfResponses.forEach((value, key) => {
      if (msgRaw.startsWith(key)) {
        b = true;
        for (let f of value) {
          f(new SocketWrapperResponse(msgRaw.substring(key.length), id));
        }
      }
    });
    _listOfRespSubers.forEach((value, key) => {
      if (msgRaw.startsWith(key)) {
        b = true;
        for (let f of value) {
          f(new SocketWrapperResponse(msgRaw.substring(key.length), id));
        }
      }
    });
  }
  return b;
}

/// Подписаться на получение единождого ответа
export function waitMsg(msgBegin: string, callback: (msg: SocketWrapperResponse) => any): void {
  let _ar = _listOfResponses.get(msgBegin);
  if (_ar) {
    _ar.push(callback);
  } else {
    _listOfResponses.set(msgBegin, [callback]);
  }
}

/// Подписаться на получение всех ответов
export function waitMsgAll(msgBegin: string, callback: (msg: SocketWrapperResponse) => any): void {
  let _ar = _listOfRespSubers.get(msgBegin);
  if (_ar) {
    _ar.push(callback);
  } else {
    _listOfRespSubers.set(msgBegin, [callback]);
  }
}

/// Отправить запрос и получить на него ответ
export function requestOnce(msg: string, callback: (msg: string) => any): void {
  _requestID += 1;
  let id = _requestID;
  let _ar = _listOfRequest.get(id);
  if (_ar) {
    _ar.push(callback);
  } else {
    _listOfRequest.set(id, [callback]);
  }
  send(id, msg);
}

/// Отправить запрос на подписку к событиям
export function requestSubscribe(msg: string, callback: (msg: string) => any): void {
  _subscribersID += 1;
  let id = _subscribersID;
  let _ar = _listOfSubscribers.get(id);
  if (_ar) {
    _ar.push(callback);
  } else {
    _listOfSubscribers.set(id, [callback]);
  }
  send(id, msg);
}
interface DartFuncs {
  dartJMsgUserSignin: (mail: string, pass: string) => string;
  dartJMsgUserLogout: () => string;
  dartJMsgUserRegistration: () => string;
  dartJMsgDoc2X: () => string;
  dartJMsgZip: () => string;
  dartJMsgUnzip: () => string;
}
export const funcs = (window as undefined as DartFuncs);


const senderQuie = new Array<string>();
const senderWaiter = (msg: string) => {
  senderQuie.push(msg);
}
sender = senderWaiter;
export var dartSocket: WebSocket;

export function dartSetSocketOnOpen(callback: () => void) {
  dartSocketOnOpen = callback;
}
export function dartSetSocketOnClose(callback: (reason: string) => void) {
  dartSocketOnClose = callback;
}
export function dartSetSocketOnError(callback: (error: any) => void) {
  dartSocketOnError = callback;
}
export function dartSetSocketOnMessage(callback: (data: any) => void) {
  dartSocketOnMessage = callback;
}

var dartSocketOnOpen: () => void;
var dartSocketOnClose: (reason: string) => void;
var dartSocketOnError: (error: any) => void;
var dartSocketOnMessage: (data: any) => void;

const handleSocketOnOpen = (event: Event) => {
  console.log("Соединение установлено");
  for (const msg of senderQuie) {
    dartSocket.send(msg);
  }
  senderQuie.length = 0;
  sender = dartSocket.send;
  if (dartSocketOnOpen) {
    dartSocketOnOpen();
  }
};
const handleSocketOnClose = (event: CloseEvent) => {
  console.warn("Сокет был закрыт");
  sender = senderWaiter;
  if (dartSocketOnClose) {
    dartSocketOnClose(event.reason);
  }
};
const handleSocketOnError = (event: ErrorEvent) => {
  console.error("Ошибка в Сокете: " + event.error);
  if (dartSocketOnError) {
    dartSocketOnError(event.error);
  }
};
const handleSocketOnMessage = (event: MessageEvent) => {
  console.log("Сообщения от сокета: " + event.data);
  console.dir(event.data);
  recv(event.data as string);
  if (dartSocketOnMessage) {
    dartSocketOnMessage(event.data);
  }

};

export function dartConnect() {
  if (dartSocket) {
    dartSocket.onopen = undefined;
    dartSocket.onclose = undefined;
    dartSocket.onerror = undefined;
    dartSocket.onmessage = undefined;
  }
  dartSocket = new WebSocket("ws://" + document.location.host + "/ws");
  dartSocket.onopen = handleSocketOnOpen;
  dartSocket.onclose = handleSocketOnClose;
  dartSocket.onerror = handleSocketOnError;
  dartSocket.onmessage = handleSocketOnMessage;
}
