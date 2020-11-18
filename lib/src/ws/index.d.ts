declare function JsSocketWrapper(token: string,
    callback: (t: JsSocketWrapper) => void): JsSocketWrapper;

interface JsSocketWrapper {
    send(msg: string, id: number): void;
    recv(msg: String, id?: number): boolean;
    waitMsg(msg: string, callaback?: (msg: string, id: number) => void, _sync?: boolean): void;
    /** Возвращает функцию отписки от вызова CallBack */
    waitMsgAll(msg: string, callaback?: (msg: string, id: number) => void, _sync?: boolean): () => void;
    requestOnce(msg: string, callaback?: (msg: string, id: number) => void, _sync?: boolean): void;
}
