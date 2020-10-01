


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
export function recv(msgRaw: string, id: number = -1): boolean {
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
  if (!b) {
    console.warn("Неизвестное сообщение: " + id.toString());
  }
  return b;
}

/// Подписаться на получение единождого ответа
export function waitMsg(msgBegin: string, callback: (msg: SocketWrapperResponse) => any): void {
  const _ar = _listOfResponses.get(msgBegin);
  if (_ar) {
    const _callback = (msg: SocketWrapperResponse) => {
      callback(msg);
      const index = _ar.indexOf(_callback);
      if (index > -1) {
        _ar.splice(index, 1);
      }
    }
    _ar.push(_callback);
  } else {
    _listOfResponses.set(msgBegin, [callback]);
  }
}

/// Подписаться на получение всех ответов
export function waitMsgAll(msgBegin: string, callback: (msg: SocketWrapperResponse) => any): () => void {
  const _ar = _listOfRespSubers.get(msgBegin);
  if (_ar) {
    _ar.push(callback);
  } else {
    _listOfRespSubers.set(msgBegin, [callback]);
  }
  return () => {
    const _ar = _listOfRespSubers.get(msgBegin);
    const index = _ar.indexOf(callback);
    if (index > -1) {
      _ar.splice(index, 1);
    }
  };
}

/// Отправить запрос и получить на него ответ
export function requestOnce(msg: string, callback: (msg: string) => any): void {
  _requestID += 1;
  const id = _requestID;
  const _ar = _listOfRequest.get(id);
  if (_ar) {
    _ar.push(callback);
  } else {
    _listOfRequest.set(id, [callback]);
  }
  send(id, msg);
}

/// Отправить запрос на подписку к событиям
export function requestSubscribe(msg: string, callback: (msg: string) => any): () => void {
  _subscribersID += 1;
  let id = _subscribersID;
  let _ar = _listOfSubscribers.get(id);
  if (_ar) {
    _ar.push(callback);
  } else {
    _listOfSubscribers.set(id, [callback]);
  }
  send(id, msg);
  return () => {
    const _ar = _listOfSubscribers.get(id);
    const index = _ar.indexOf(callback);
    if (index > -1) {
      _ar.splice(index, 1);
    }
  };
}


const senderQuie = new Array<string>();
const senderWaiter = (msg: string) => {
  senderQuie.push(msg);
}
sender = senderWaiter;
export var dartSocket: WebSocket;

export function dartSetSocketOnOpen(callback: typeof dartSocketOnOpen) {
  dartSocketOnOpen = callback;
}
export function dartSetSocketOnClose(callback: typeof dartSocketOnClose) {
  dartSocketOnClose = callback;
}
export function dartSetSocketOnError(callback: typeof dartSocketOnError) {
  dartSocketOnError = callback;
}
export function dartSetSocketOnMessage(callback: typeof dartSocketOnMessage) {
  dartSocketOnMessage = callback;
}

var dartSocketOnOpen: null | (() => void);
var dartSocketOnClose: null | ((reason: string) => void);
var dartSocketOnError: null | (() => void);
var dartSocketOnMessage: null | ((data: any) => void);

const handleSocketOnOpen = () => {
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
const handleSocketOnError = () => {
  console.error("Ошибка в Сокете: ");
  if (dartSocketOnError) {
    dartSocketOnError();
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
    dartSocket.onopen = null;
    dartSocket.onclose = null;
    dartSocket.onerror = null;
    dartSocket.onmessage = null;
    _requestID = 0;
    _listOfRequest.clear();
    _subscribersID = 0;
    _listOfSubscribers.clear();
    // _listOfResponses.clear();
    // _listOfRespSubers.clear();
  }
  dartSocket = new WebSocket("ws://" + document.location.host + "/ws");
  dartSocket.onopen = handleSocketOnOpen;
  dartSocket.onclose = handleSocketOnClose;
  dartSocket.onerror = handleSocketOnError;
  dartSocket.onmessage = handleSocketOnMessage;


}
