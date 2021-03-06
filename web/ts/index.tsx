import React from "react";
import ReactDOM from "react-dom";
import theme from "./theme";
import CssBaseline from "@material-ui/core/CssBaseline";

import { ThemeProvider } from "@material-ui/core/styles";
import { SnackbarProvider } from "notistack";
import { BrowserRouter, Route } from "react-router-dom";

import App from "./App";
import { dartConnect } from "./dart/SocketWrapper";
import { Provider } from 'react-redux'
import store from "./redux";

/*SECURE*navigator.serviceWorker
  .register("./sw.bundle.js", { scope: "./" })
  .then((reg) => {
    // регистрация сработала
    console.info("Registration succeeded. Scope is " + reg.scope);
  })
  .catch((error) => {
    // регистрация прошла неудачно
    console.error("Registration failed with " + error);
  });*/


ReactDOM.render(
  <Provider store={store}>
    <ThemeProvider theme={theme}>
      <SnackbarProvider maxSnack={4}>
        <CssBaseline />
        <BrowserRouter>
          <Route path="/" component={App} />
        </BrowserRouter>
      </SnackbarProvider>
    </ThemeProvider>
  </Provider>,
  document.querySelector("#root")
);

dartConnect();
