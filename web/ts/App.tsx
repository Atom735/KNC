import React, { FunctionComponent, useState } from "react";
import theme from "./theme";
import {
  makeStyles,
  Theme,
  createStyles,
  ThemeProvider
} from "@material-ui/core/styles";
import useScrollTrigger from "@material-ui/core/useScrollTrigger";
import CssBaseline from "@material-ui/core/CssBaseline";

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

import Home from "./Home";
import SignIn from "./Signin";
import SignUp from "./Signup";
import Test from "./Test";

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

const App: FunctionComponent = () => {
  const classes = useStylesApp();

  const [location, setLocation] = useState(window.location);
  const [username, setUsername] = useState("");
  const [anchorEl, setAnchorEl] = useState<null | HTMLElement>(null);
  const open = Boolean(anchorEl);

  let page;
  let pageHome;
  let userAction;
  if (location.pathname.startsWith("/signin")) {
    page = <SignIn />;
  } else if (location.pathname.startsWith("/signup")) {
    page = <SignUp />;
  } else if (location.pathname.startsWith("/test")) {
    page = <Test />;
  } else {
    page = <Home />;
    pageHome = true;
  }

  const handleUserMenuOpen = (event: React.MouseEvent<HTMLElement>) => {
    setAnchorEl(event.currentTarget);
  };
  const handleUserMenuClose = () => {
    setAnchorEl(null);
  };
  const handleSignIn = () => {};
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
      <Button color="inherit" onClick={handleSignIn}>
        Вход
      </Button>
    );
  }
  return (
    <ThemeProvider theme={theme}>
      <CssBaseline />
      <AppBar>
        <Toolbar>
          {pageHome && (
            <IconButton
              edge="start"
              className={classes.homeButton}
              color="inherit"
              aria-label="home"
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
      {page}
      <Box mt={8}>
        <Copyright />
      </Box>
      <ScrollTop />
    </ThemeProvider>
  );
};
export default App;
