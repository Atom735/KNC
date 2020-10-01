import { createStore, Reducer } from "redux";
import { funcs, JUser } from "../dart/Lib";
import { action } from 'typesafe-actions'
import { waitMsgAll } from "../dart/SocketWrapper";

export enum AppActionTypes {
    SIGN_IN = 'SIGN_IN',
    SIGN_OUT = 'SIGN_OUT',
    TASK_NEW = 'TASK_NEW',
    TASK_UPDATE = 'TASK_UPDATE',
}
export enum NTaskState {
    initialization = 0,
    searchFiles,
    workFiles,
    generateTable,
    waitForCorrectErrors,
    reworkErrors,
    completed,
}

export interface TaskState {
    readonly id: string;
    readonly state?: NTaskState;
    readonly erros?: number;
    readonly files?: number;
    readonly warnings?: number;
    readonly worked?: number;
    readonly raport?: boolean;
}

export interface AppState {
    readonly user: JUser | null;
    readonly tasks: TaskState[];
}




const initialState: AppState = {
    user: null,
    tasks: [],
};

const reducer: Reducer<AppState> = (state = initialState, action) => {
    switch (action.type) {
        case AppActionTypes.SIGN_IN: {
            return { ...state, user: action.payload }
        }
        case AppActionTypes.SIGN_OUT: {
            return { ...state, user: null }
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
            const _id = state.tasks.findIndex((value) => value.id == _data.id);
            return {
                ...state, tasks: state.tasks.map((value, index) => _id != index ? value :
                    { ...value, _data })
            }
        }
        default: {
            return state
        }
    }
}

const store = createStore(reducer);

export const fetchSignIn = (user: JUser) => action(AppActionTypes.SIGN_IN, user);
export const fetchSignOut = () => action(AppActionTypes.SIGN_OUT);
export const fetchTaskNew = (id: string) => action(AppActionTypes.TASK_NEW, id);
export const fetchTaskUpdate = (data: string) => action(AppActionTypes.TASK_UPDATE, data);

waitMsgAll(funcs.dartIdJMsgNewTask(), (msg) => { fetchTaskNew(msg.s) });
waitMsgAll(funcs.dartIdJMsgTaskUpdate(), (msg) => { fetchTaskUpdate(msg.s) });

export default store;
