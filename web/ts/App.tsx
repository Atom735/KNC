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

import { dartSetSocketOnClose, dartSetSocketOnError, dartSetSocketOnOpen } from "./dartWrapper";


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
  const [anchorEl, setAnchorEl] = useState<null | HTMLElement>(null);

  const [username, setUsername] = useState("");
  dartSetSocketOnOpen(() => {
    enqueueSnackbar("Соединение установлено", { variant: "info" });
  });

  dartSetSocketOnClose((reason) => {
    enqueueSnackbar("Соединение было закрыто: " + reason, { variant: "warning" });
  });

  dartSetSocketOnError((error) => {
    enqueueSnackbar("Ошибка в соединении: " + error, { variant: "error" });
  });


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

  const callbackSignIn = (username: string) => {
    if (username) {
      console.log("Успешный вход!: " + username);
      setUsername(username.toString());
      props.history.push('/');
    }
  };


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
                open={anchorEl && true}
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
            <PageSignIn {...props} callback={callbackSignIn} />
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
