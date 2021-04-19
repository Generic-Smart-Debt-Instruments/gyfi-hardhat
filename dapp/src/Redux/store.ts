// #region Global Imports
import { configureStore, getDefaultMiddleware } from "@reduxjs/toolkit";
// #endregion Global Imports

// #region Local Imports
import Reducers from "./Reducers";
// #endregion Local Imports

const store = configureStore({
    reducer: Reducers,
    middleware: [
        ...getDefaultMiddleware({ thunk: true, serializableCheck: false }),
    ],
    devTools: process.env.NODE_ENV !== "production",
});

export const makeStore = () => {
    return store;
};

export type AppState = ReturnType<typeof store.getState>;
export type AppDispatch = typeof store.dispatch;
