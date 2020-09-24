import React, { FunctionComponent, useState, useEffect } from "react";
import { RouterProps } from "react-router";
import {
  Switch as RouteSwitch,
  Route,
  Link as RouterLink,
} from "react-router-dom";
import { makeStyles, createStyles } from "@material-ui/core/styles";
import useScrollTrigger from "@material-ui/core/useScrollTrigger";
import { useSnackbar } from "notistack";

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

import PageHome from "./pages/Home";
import PageSignIn from "./pages/Signin";
import PageSignUp from "./pages/Signup";
import PageTest from "./pages/Test";
import PageNewTask from "./pages/NewTask";

const useStylesScrollTop = makeStyles((theme) =>
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

const useStylesApp = makeStyles((theme) =>
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


interface AppProps extends RouterProps {
  props?: React.ReactNode;
}

const App: FunctionComponent<AppProps> = (props: AppProps) => {
  const classes = useStylesApp();
  const { enqueueSnackbar } = useSnackbar();

  const [username, setUsername] = useState("");
  const [soketMsgRequsters, setSoketMsgRequsters] = useState(new Map<string, any>());
  const [soketMsgId, setSoketMsgId] = useState(1);
  const [anchorEl, setAnchorEl] = useState<null | HTMLElement>(null);
  const [socket, setSocket] = useState(
    new WebSocket("ws://" + document.location.host + "/ws")
  );
  const open = Boolean(anchorEl);

  const handleSocketOnOpen = (event: Event) => {
    enqueueSnackbar("Соединение установлено", { variant: "info" });
    console.log("Соединение установлено");
  };
  const handleSocketOnClose = (event: CloseEvent) => {
    enqueueSnackbar("Сокет был закрыт", { variant: "warning" });
    console.log("Сокет был закрыт");
  };
  const handleSocketOnError = (event: ErrorEvent) => {
    enqueueSnackbar("Ошибка в Сокете", { variant: "error" });
    console.log("Ошибка в Сокете: " + event.error);
  };
  const handleSocketOnMessage = (event: MessageEvent) => {
    enqueueSnackbar("Сообщения от сокета", { variant: "success" });
    console.log("Сообщения от сокета: " + event.data);
    console.dir(event.data);
    const msg = event.data as String;
    if (msg.startsWith("\u0001")) {
      const i0 = msg.indexOf("\u0002");
      const callback =
        soketMsgRequsters.get(msg.substring(1, i0));
      if (callback) {
        callback(msg.substring(i0 + 1));
      }
    }
  };

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

  const soketRequest = (msg: String, callback: any) => {
    const msgIdString = soketMsgId.toString();
    setSoketMsgRequsters(prevData => prevData.set(msgIdString, callback));
    socket.send("\u0001" + msgIdString + "\u0002" + msg.toString());
  };

  const callbackSignIn = (msg: String) => {
    console.log("Успешный вход!: " + msg);
    setUsername(msg.toString());
    props.history.push('/');
  };

  const handleOnSignIn = (msg: String) => {
    soketRequest(msg, callbackSignIn);
  };


  useEffect(() => {
    socket.onopen = handleSocketOnOpen;
    socket.onclose = handleSocketOnClose;
    socket.onerror = handleSocketOnError;
    socket.onmessage = handleSocketOnMessage;
    return () => {
      socket.onopen = null;
      socket.onclose = null;
      socket.onerror = null;
      socket.onmessage = null;
    };

  }, [socket]);


  return (
    <>
      <AppBar>
        <Toolbar>
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
          <Typography variant="h6" className={classes.title}>
            Пункт приёма стеклотары
          </Typography>
          {username ? (
            <>
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
            </>
          ) : (
              <Button color="inherit" component={RouterLink} to="/signin">
                Вход
              </Button>
            )}
        </Toolbar>
      </AppBar>
      <Toolbar id="back-to-top-anchor" />
      <RouteSwitch>
        <Route
          path="/signin"
          render={(props) => (
            <PageSignIn {...props} dartRequest={handleOnSignIn} />
          )}
        />
        <Route path="/signup" component={PageSignUp} />
        <Route path="/test" component={PageTest} />
        <Route path="/newtask" component={PageNewTask} />
        <Route path="/" component={PageHome} />
      </RouteSwitch>
      <Box mt={8}>
        <Copyright />
      </Box>
      <ScrollTop />
    </>
  );
};
export default App;
