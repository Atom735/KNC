import { createStore, Reducer } from "redux";
import { JUser } from "../dart/Lib";
import { action } from 'typesafe-actions'

export enum AppActionTypes {
    ACTION_SIGN_IN_BEGIN = 'SIGN_IN_BEGIN',
    ACTION_SIGN_OUT_BEGIN = 'SIGN_OUT_BEGIN',
    ACTION_SIGN_UP_BEGIN = 'SIGN_UP_BEGIN',
    ACTION_SIGN_IN = 'SIGN_IN',
    ACTION_SIGN_OUT = 'SIGN_OUT',
    ACTION_SIGN_UP = 'SIGN_UP',
}

export interface AppState {
    readonly userWaitingSignIn: boolean;
    readonly userWaitingSignOut: boolean;
    readonly userWaitingSignUp: boolean;
    readonly user: JUser | null;
}
const initialState: AppState = {
    userWaitingSignIn: false,
    userWaitingSignOut: false,
    userWaitingSignUp: false,
    user: null,
};

const reducer: Reducer<AppState> = (state = initialState, action) => {
    switch (action.type) {
        case AppActionTypes.ACTION_SIGN_IN_BEGIN: {
            return { ...state, userWaitingSignIn: true }
        }
        case AppActionTypes.ACTION_SIGN_OUT_BEGIN: {
            return { ...state, userWaitingSignOut: true }
        }
        case AppActionTypes.ACTION_SIGN_UP_BEGIN: {
            return { ...state, userWaitingSignUp: true }
        }
        case AppActionTypes.ACTION_SIGN_IN: {
            return { ...state, userWaitingSignIn: false, user: action.payload }
        }
        case AppActionTypes.ACTION_SIGN_OUT: {
            return { ...state, userWaitingSignOut: false, user: null }
        }
        case AppActionTypes.ACTION_SIGN_UP: {
            return { ...state, userWaitingSignUp: false, user: action.payload }
        }
        default: {
            return state
        }
    }
}


const store = createStore(reducer);


export const fetchSignInBegin = () => action(AppActionTypes.ACTION_SIGN_IN_BEGIN);
export const fetchSignOutBegin = () => action(AppActionTypes.ACTION_SIGN_OUT_BEGIN);
export const fetchSignUpBegin = () => action(AppActionTypes.ACTION_SIGN_UP_BEGIN);
export const fetchSignIn = (user: JUser) => action(AppActionTypes.ACTION_SIGN_IN, user);
export const fetchSignOut = (user: JUser) => action(AppActionTypes.ACTION_SIGN_OUT, user);
export const fetchSignUp = (user: JUser) => action(AppActionTypes.ACTION_SIGN_UP, user);


export default store;
