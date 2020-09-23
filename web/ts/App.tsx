import React, { FunctionComponent, useState, useEffect } from "react";
import { Switch, Route, Link as RouterLink } from "react-router-dom";

import { makeStyles, Theme, createStyles } from "@material-ui/core/styles";
import useScrollTrigger from "@material-ui/core/useScrollTrigger";

import AppBar from "@material-ui/core/AppBar";
import Toolbar from "@material-ui/core/Toolbar";
import Typography from "@material-ui/core/Typography";
import Button from "@material-ui/core/Button";
import IconButton from "@material-ui/core/IconButton";
import Box from "@material-ui/core/Box";
import Fab from "@material-ui/core/Fab";
import Zoom from "@material-ui/core/Zoom";
import Link from "@material-ui/core/Link";
import MenuItem from "@material-ui/core/MenuItem";
import Menu from "@material-ui/core/Menu";

import KeyboardArrowUpIcon from "@material-ui/icons/KeyboardArrowUp";
import HomeIcon from "@material-ui/icons/Home";
import AccountCircle from "@material-ui/icons/AccountCircle";

import { useSnackbar } from "notistack";

import Home from "./Home";
import SignIn from "./Signin";
import SignUp from "./Signup";
import Test from "./Test";
import NewTask from "./NewTask";

const useStylesScrollTop = makeStyles((theme: Theme) =>
  createStyles({
    root: {
      position: "fixed",
      bottom: theme.spacing(2),
      right: theme.spacing(2)
    }
  })
);

function ScrollTop() {
  const classes = useStylesScrollTop();
  // Note that you normally won't need to set the window ref as useScrollTrigger
  // will default to window.
  // This is only being set here because the demo is in an iframe.
  const trigger = useScrollTrigger({
    disableHysteresis: true,
    threshold: 100
  });

  const handleClick = (event: React.MouseEvent<HTMLDivElement>) => {
    const anchor = (
      (event.target as HTMLDivElement).ownerDocument || document
    ).querySelector("#back-to-top-anchor");

    if (anchor) {
      anchor.scrollIntoView({ behavior: "smooth", block: "center" });
    }
  };

  return (
    <Zoom in={trigger}>
      <div onClick={handleClick} role="presentation" className={classes.root}>
        <Fab color="secondary" size="small" aria-label="scroll back to top">
          <KeyboardArrowUpIcon />
        </Fab>
      </div>
    </Zoom>
  );
}

function Copyright() {
  return (
    <Typography variant="body2" color="textSecondary" align="center">
      {"Copyright © "}
      <Link color="inherit" href="https://github.com/Atom735/KNC/projects/3">
        Atom735
      </Link>{" "}
      {new Date().getFullYear()}
      {"."}
    </Typography>
  );
}

const useStylesApp = makeStyles((theme: Theme) =>
  createStyles({
    root: {
      flexGrow: 1
    },
    homeButton: {
      marginRight: theme.spacing(2)
    },
    title: {
      flexGrow: 1
    }
  })
);

function Example() {
  const [count, setCount] = useState(0);

  return (
    <div>
      <p>Вы кликнули {count} раз(а)</p>
      <button onClick={() => setCount(count + 1)}>Нажми на меня</button>
    </div>
  );
}

const App: FunctionComponent = () => {
  const classes = useStylesApp();
  const { enqueueSnackbar } = useSnackbar();

  const [username, setUsername] = useState("");
  const [anchorEl, setAnchorEl] = useState<null | HTMLElement>(null);
  const [socket, setSocket] = useState(
    new WebSocket("wss://" + document.location.host + "/wss")
  );
  const open = Boolean(anchorEl);

  useEffect(() => {
    socket.addEventListener("onopen", handleSocketOnOpen);
    socket.addEventListener("onclose", handleSocketOnClose);
    socket.addEventListener("onerror", handleSocketOnError);
    socket.addEventListener("onmessage", handleSocketOnMessage);
    return () => {
      socket.removeEventListener("onopen", handleSocketOnOpen);
      socket.removeEventListener("onclose", handleSocketOnClose);
      socket.removeEventListener("onerror", handleSocketOnError);
      socket.removeEventListener("onmessage", handleSocketOnMessage);
    };

    // onclose	EventListener	Обработчик событий, вызываемый, когда readyState WebSocket соединения изменяется на CLOSED. Наблюдатель получает CloseEvent с именем "close".
    // onerror	EventListener
    // Обработчик событий, вызываемый, когда происходит ошибка. Это простое событие, называемое "error".

    // onmessage	EventListener
    // Обработчик событий , вызываемый, когда получается сообщение с сервера. Наблюдатель получает MessageEvent,  называемое "message".

    // onopen	EventListener
    // Наблюдатель событий, вызываемый, когда readyState WebSocket - соединения изменяется на OPEN; это показывает, что соединение готово отсылать и принимать данные. Это простое событие, называемое "open".
  }, [socket]);

  const handleSocketOnOpen = (event: Event) => {
    enqueueSnackbar("Соединение установлено", { variant: "info" });
  };
  const handleSocketOnClose = (event: CloseEvent) => {
    enqueueSnackbar("Сокет был закрыт", { variant: "warning" });
  };
  const handleSocketOnError = (event: ErrorEvent) => {
    enqueueSnackbar("Ошибка в Сокете", { variant: "error" });
  };
  const handleSocketOnMessage = (event: MessageEvent) => {};

  let pageHome;
  let userAction;

  const handleUserMenuOpen = (event: React.MouseEvent<HTMLElement>) => {
    setAnchorEl(event.currentTarget);
  };
  const handleUserMenuClose = () => {
    setAnchorEl(null);
  };
  const handleSignOut = () => {
    handleUserMenuClose();
    setUsername("");
  };
  const handleSettings = () => {
    handleUserMenuClose();
  };

  if (username) {
    userAction = (
      <div>
        <Typography variant="h6">{username}</Typography>
        <IconButton
          aria-label="account of current user"
          aria-controls="menu-appbar"
          aria-haspopup="true"
          onClick={handleUserMenuOpen}
          color="inherit"
        >
          <AccountCircle />
        </IconButton>
        <Menu
          id="menu-appbar"
          anchorEl={anchorEl}
          anchorOrigin={{
            vertical: "top",
            horizontal: "right"
          }}
          keepMounted
          transformOrigin={{
            vertical: "top",
            horizontal: "right"
          }}
          open={open}
          onClose={handleUserMenuClose}
        >
          <MenuItem onClick={handleSettings}>Настройки</MenuItem>
          <MenuItem onClick={handleSignOut}>Выход</MenuItem>
        </Menu>
      </div>
    );
  } else {
    userAction = (
      <Button color="inherit" component={RouterLink} to="/signin">
        Вход
      </Button>
    );
  }
  return (
    <>
      <AppBar>
        <Toolbar>
          {pageHome || (
            <IconButton
              edge="start"
              className={classes.homeButton}
              color="inherit"
              aria-label="home"
              component={RouterLink}
              to="/"
            >
              <HomeIcon />
            </IconButton>
          )}
          <Typography variant="h6" className={classes.title}>
            Пункт приёма стеклотары
          </Typography>
          {userAction}
        </Toolbar>
      </AppBar>
      <Toolbar id="back-to-top-anchor" />
      <Switch>
        <Route path="/signin" component={SignIn} />
        <Route path="/signup" component={SignUp} />
        <Route path="/test" component={Test} />
        <Route path="/newtask" component={NewTask} />
        <Route path="/" component={Home} />
      </Switch>
      <Box mt={8}>
        <Copyright />
      </Box>
      <Example />
      <ScrollTop />
    </>
  );
};
export default App;