import React, { useEffect, useState } from "react";
import { RouterProps } from "react-router";
import {
  Switch as RouteSwitch,
  Route,
  Link as RouterLink,
} from "react-router-dom";
import { connect } from 'react-redux';
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
import PageTask from "./pages/Task";
import PageTaskFileList from "./pages/TaskFileList";

import { dartSetSocketOnClose, dartSetSocketOnError, dartSetSocketOnOpen, requestOnce, send } from "./dart/SocketWrapper";
import { funcs, JUser } from "./dart/Lib";
import { AppState, fetchSignIn, fetchSignOut } from "./redux";


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

export const useStylesApp = makeStyles((theme) =>
  createStyles({
    root: {
      flexGrow: 1
    },
    homeButton: {
      marginRight: theme.spacing(2)
    },
    title: {
      flexGrow: 1
    },
    error: {
      color: theme.palette.error.contrastText,
      backgroundColor: theme.palette.error.main
    }
  })
);



const App: React.FC<RouterProps & PropsFromState & typeof mapDispatchToProps> = (props) => {
  const classes = useStylesApp();
  const { enqueueSnackbar } = useSnackbar();
  const [anchorEl, setAnchorEl] = useState<null | HTMLElement>(null);
  const [connected, setConnected] = useState(false);

  const handleSignIn = (email: string, pass: string, remem: boolean, callback: () => any) => {
    requestOnce(funcs.dartJMsgUserSignin(email, pass), (msg) => {
      if (callback) {
        callback();
      }
      if (msg) {
        console.log("Успешный вход: " + msg);
        const _user = JSON.parse(msg) as JUser;
        console.dir(_user);
        props.fetchSignIn(_user, remem);
        enqueueSnackbar("Вы вошли как: " + _user.first_name, { variant: "info" });
        if (callback) {
          props.history.push('/');
        }
      } else {
        enqueueSnackbar("Неверные логин и/или пароль", { variant: "error" });
      }
    });
  };

  useEffect(() => {
    dartSetSocketOnOpen(() => {
      enqueueSnackbar("Соединение установлено", { variant: "info" });
      setConnected(true);
    });

    dartSetSocketOnClose((reason) => {
      enqueueSnackbar("Соединение было закрыто: " + reason, { variant: "warning" });
      setConnected(false);
    });

    dartSetSocketOnError(() => {
      enqueueSnackbar("Ошибка в соединении", { variant: "error" });
    });

    const _userData = window.localStorage.getItem('user');
    if (_userData) {
      const _user = JSON.parse(_userData) as JUser;
      handleSignIn(_user.mail, _user.pass, true, null);
    } else {
      send(0, funcs.dartJMsgGetTasks());
    }

    return () => {
      dartSetSocketOnOpen(null);
      dartSetSocketOnClose(null);
      dartSetSocketOnError(null);
    };
  }, []);

  // const [user, setUser] = useState<JUser | null>(null);



  const handleUserMenuOpen = (event: React.MouseEvent<HTMLElement>) => {
    setAnchorEl(event.currentTarget);
  };
  const handleUserMenuClose = () => {
    setAnchorEl(null);
  };




  const [submitLogOut, setSubmitLogOut] = useState(false);
  const handleSignOut = () => {
    handleUserMenuClose();
    setSubmitLogOut(true);
    requestOnce(funcs.dartJMsgUserLogout(), (msg) => {
      setSubmitLogOut(false);
      console.log("Вы вышли из системы");
      enqueueSnackbar("Вы вышли из системы", { variant: "info" });
      props.fetchSignOut();
    });
  };
  const handleSettings = () => {
    handleUserMenuClose();
  };





  const { user } = props;


  return (
    <>
      <AppBar className={connected ? null : classes.error}>
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
            {props.title}
          </Typography>
          {user ? (
            <>
              <Typography variant="h6">{user.mail}</Typography>
              <IconButton
                onClick={handleUserMenuOpen}
                color="inherit"
              // aria-controls="simple-menu" aria-haspopup="true"
              >
                <AccountCircle />
              </IconButton>
              <Menu
                // id="simple-menu"
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
                open={Boolean(anchorEl)}
                onClose={handleUserMenuClose}
              >
                <MenuItem onClick={handleSettings} disabled>Настройки</MenuItem>
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
        <Route path="/signin" component={() => <PageSignIn handleSignIn={handleSignIn} />} />
        <Route path="/signup" component={PageSignUp} />
        <Route path="/test" component={PageTest} />
        <Route path="/newtask" component={PageNewTask} />
        <Route path="/task/*/filelist" component={PageTaskFileList} />
        <Route path="/task" component={PageTask} />
        <Route path="/" component={PageHome} />
      </RouteSwitch>
      <Box mt={8}>
        <Copyright />
      </Box>
      <ScrollTop />
    </>
  );
};
interface PropsFromState {
  user: JUser,
  title: string,
}
const mapStateToProps = ({ user, title }: AppState): PropsFromState => ({ user: user, title: title })
const mapDispatchToProps = {
  fetchSignOut: fetchSignOut,
  fetchSignIn: fetchSignIn
}

export default connect(mapStateToProps, mapDispatchToProps)(App);
