import { createStore, Reducer } from "redux";
import { JUser } from "../dart/Lib";
import { action } from 'typesafe-actions'

export enum AppActionTypes {
    SIGN_IN = 'SIGN_IN',
    SIGN_OUT = 'SIGN_OUT',
}

export interface AppState {
    readonly user: JUser | null;
}
const initialState: AppState = {
    user: null,
};

const reducer: Reducer<AppState> = (state = initialState, action) => {
    switch (action.type) {
        case AppActionTypes.SIGN_IN: {
            return { ...state, userWaitingSignIn: false, user: action.payload }
        }
        case AppActionTypes.SIGN_OUT: {
            return { ...state, userWaitingSignOut: false, user: null }
        }
        default: {
            return state
        }
    }
}

const store = createStore(reducer);

export const fetchSignIn = (user: JUser) => action(AppActionTypes.SIGN_IN, user);
export const fetchSignOut = () => action(AppActionTypes.SIGN_OUT);


export default store;
