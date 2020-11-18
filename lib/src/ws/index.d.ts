declare function JsSocketWrapper
    (token: string,
        callback: () => void):
    Object;
declare function JsSocketWrapperAddOnOpenCallback
    (socketWrapper: Object,
        callback: () => void):
    void;
declare function JsSocketWrapperSend
    (socketWrapper: Object, id: number, msg: string):
    void;
declare function JsSocketWrapperRecv
    (socketWrapper: Object, msg: string, id: number):
    boolean;
declare function JsSocketWrapperWaitMsg
    (socketWrapper: Object, msg: string, sync: boolean,
        callback: (id: number, msg: string) => void):
    void;
declare function JsSocketWrapperWaitMsgAll
    (socketWrapper: Object, msg: string, sync: boolean,
        callback: (id: number, msg: string) => void):
    () => void;
declare function JsSocketWrapperRequestOnce
    (socketWrapper: Object, msg: string, sync: boolean,
        callback: (msg: string) => void):
    void;


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
