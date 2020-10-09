import { createStore, Reducer } from "redux";
import { funcs, JTaskSettings, JUser } from "../dart/Lib";
import { action } from 'typesafe-actions'
import { send, waitMsgAll } from "../dart/SocketWrapper";
import { JOneFileData } from "../dart/OneFileData";

export enum AppActionTypes {
    SIGN_IN = 'SIGN_IN',
    SIGN_OUT = 'SIGN_OUT',
    TASK_NEW = 'TASK_NEW',
    TASK_UPDATE = 'TASK_UPDATE',
    TASK_UPDATE_FILELIST = 'TASK_UPDATE_FILELIST',
    TASK_UPDATE_FILE = 'TASK_UPDATE_FILE',
    TASK_KILL = 'TASK_KILL',
    TASKS_ALL = 'TASKS_ALL',
    SET_TITLE = 'SET_TITLE',
}
export enum NTaskState {
    initialization = 0,
    searchFiles = 1,
    workFiles = 2,
    generateTable = 3,
    waitForCorrectErrors = 4,
    reworkErrors = 5,
    completed = 6,
}

export interface TaskState {
    readonly id: string;
    readonly state?: NTaskState;
    readonly errors?: number;
    readonly files?: number;
    readonly warnings?: number;
    readonly worked?: number;
    readonly raport?: boolean;
    readonly settings?: JTaskSettings;
    readonly filelist?: Array<JOneFileData>;
}

export interface AppState {
    readonly user: JUser | null;
    readonly tasks: TaskState[];
    readonly title: string;
}




const initialState: AppState = {
    user: null,
    tasks: [],
    title: '',
};

const reducer: Reducer<AppState> = (state = initialState, action) => {
    // console.dir(state);
    switch (action.type) {
        case AppActionTypes.SIGN_IN: {
            if (action.meta) {
                window.localStorage.setItem("user", JSON.stringify(action.payload));
            } else {
                window.sessionStorage.setItem("user", JSON.stringify(action.payload));
            }
            send(0, funcs.dartJMsgGetTasks());
            return { ...state, user: action.payload }
        }
        case AppActionTypes.SIGN_OUT: {
            window.localStorage.removeItem("user");
            window.sessionStorage.removeItem("user");
            send(0, funcs.dartJMsgGetTasks());
            return { ...state, user: null, tasks: [] }
        }
        case AppActionTypes.TASK_NEW: {
            return {
                ...state, tasks: [...state.tasks, {
                    id: action.payload,
                    state: NTaskState.initialization,
                } as TaskState]
            }
        }
        case AppActionTypes.TASK_UPDATE: {
            const _data = JSON.parse(action.payload) as TaskState;
            const _id = state.tasks.findIndex(value => value.id == _data.id);
            return {
                ...state, tasks: state.tasks.map((value, index) => _id != index ? value :
                    { ...value, ..._data })
            }
        }
        case AppActionTypes.TASK_UPDATE_FILELIST: {
            const _data = JSON.parse(action.payload) as Array<JOneFileData>;
            const _id = state.tasks.findIndex(value => value.id == action.meta);
            const _dataPrev = state.tasks[_id]?.filelist;
            return {
                ...state, tasks: state.tasks.map((value, index) => _id != index ? value :
                    {
                        ...value, filelist: _data.map((value, index) => {
                            return (_dataPrev?.length > index) ?
                                {
                                    ..._dataPrev[index], ...value,
                                    notes: value.notes ? value.notes : _dataPrev[index].notes,
                                    curves: value.curves ? value.curves : _dataPrev[index].curves,
                                }
                                : value;
                        })
                    })

            }
        }
        case AppActionTypes.TASK_UPDATE_FILE: {
            const _data = JSON.parse(action.payload) as JOneFileData;
            const _id = state.tasks.findIndex(value => value.id == action.meta[0]);
            const _path = action.meta[1] as string;
            const _dataPrevIndex = state.tasks[_id]?.filelist?.findIndex((e) => e.path.endsWith(_path));
            return {
                ...state, tasks: state.tasks.map((value, index) => _id != index ? value :
                    {
                        ...value, filelist: value?.filelist?.map((value, index) => index != _dataPrevIndex ? value :
                            _data)
                    })

            }
        }
        case AppActionTypes.TASK_KILL: {
            return {
                ...state, tasks: state.tasks.filter(value => value.id != action.payload)
            }
        }
        case AppActionTypes.TASKS_ALL: {
            const _data = (action.payload as string).trim();
            const _tasks = [...state.tasks];
            if (_data) {
                _data.split(';').forEach((value) => { if (_tasks.length == 0 || !_tasks.some((task) => task.id == value)) { _tasks.push({ id: value, state: NTaskState.initialization }) } });
            }
            return {
                ...state, tasks: _tasks
            }
        }
        case AppActionTypes.SET_TITLE: {
            console.log("new title: " + action.payload);
            return {
                ...state, title: action.payload
            }
        }
        default: {
            return state
        }
    }
}

const store = createStore(reducer);

export const fetchSignIn = (user: JUser, remem: boolean) => action(AppActionTypes.SIGN_IN, user, remem);
export const fetchSignOut = () => action(AppActionTypes.SIGN_OUT);
export const fetchTaskNew = (id: string) => action(AppActionTypes.TASK_NEW, id);
export const fetchTaskUpdate = (data: string) => action(AppActionTypes.TASK_UPDATE, data);
export const fetchTaskKill = (data: string) => action(AppActionTypes.TASK_KILL, data);
export const fetchTasksAll = (data: string) => action(AppActionTypes.TASKS_ALL, data);
export const fetchSetTitle = (data: string) => action(AppActionTypes.SET_TITLE, data);
export const fetchTaskUpdateFileList = (data: string, id: string) => action(AppActionTypes.TASK_UPDATE_FILELIST, data, id);
export const fetchTaskUpdateFile = (data: string, id: string, path: string) => action(AppActionTypes.TASK_UPDATE_FILE, data, [id, path]);


waitMsgAll(funcs.dartIdJMsgTaskNew(), (msg) => { store.dispatch(fetchTaskNew(msg.s)) });
waitMsgAll(funcs.dartIdJMsgTaskUpdate(), (msg) => { store.dispatch(fetchTaskUpdate(msg.s)) });
waitMsgAll(funcs.dartIdJMsgTasksAll(), (msg) => { store.dispatch(fetchTasksAll(msg.s)) });
waitMsgAll(funcs.dartIdJMsgTaskKill(), (msg) => { store.dispatch(fetchTaskKill(msg.s)) });

export default store;
