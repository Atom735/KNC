import React, { FunctionComponent, useState } from "react";
import { Link as RouterLink } from "react-router-dom";
import CssBaseline from "@material-ui/core/CssBaseline";

import Avatar from "@material-ui/core/Avatar";
import Button from "@material-ui/core/Button";
import TextField from "@material-ui/core/TextField";
import FormControlLabel from "@material-ui/core/FormControlLabel";
import Checkbox from "@material-ui/core/Checkbox";
import Link from "@material-ui/core/Link";
import Grid from "@material-ui/core/Grid";
import Typography from "@material-ui/core/Typography";
import Container from "@material-ui/core/Container";
import CircularProgress from "@material-ui/core/CircularProgress";
import Backdrop from "@material-ui/core/Backdrop";

import PostAddIcon from "@material-ui/icons/PostAdd";

import useStyles from "./../styles";

const PageNewTask: FunctionComponent = () => {
  const classes = useStyles();

  const [email, setEmail] = useState("");
  const handleChangeEmail = (event: React.ChangeEvent<HTMLInputElement>) => {
    setEmail(event.target.value);
  };
  const [pass, setPasss] = useState("");
  const handleChangePass = (event: React.ChangeEvent<HTMLInputElement>) => {
    setPasss(event.target.value);
  };
  const [remem, setRemem] = useState(true);
  const handleChangeRemem = (event: React.ChangeEvent<HTMLInputElement>) => {
    setRemem(event.target.checked);
  };

  const [submit, setSubmit] = useState(false);
  const handleOnSubmit = (event: React.FormEvent<HTMLFormElement>) => {
    setSubmit(true);
    event.preventDefault();
  };

  return (
    <Container component="main" maxWidth="xs">
      <CssBaseline />
      <div className={classes.paper}>
        <Avatar className={classes.avatar}>
          <PostAddIcon />
        </Avatar>
        <Typography component="h1" variant="h5">
          Добавление задачи
        </Typography>
        <form className={classes.form} noValidate onSubmit={handleOnSubmit}>
          <TextField
            variant="outlined"
            margin="normal"
            required
            fullWidth
            id="email"
            label="Телефон или Email"
            name="email"
            autoComplete="username"
            autoFocus
            value={email}
            onChange={handleChangeEmail}
            disabled={submit}
          />
          <TextField
            variant="outlined"
            margin="normal"
            required
            fullWidth
            name="password"
            label="Пароль"
            type="password"
            id="password"
            autoComplete="current-password"
            value={pass}
            onChange={handleChangePass}
            disabled={submit}
          />
          <FormControlLabel
            control={
              <Checkbox
                value="remember"
                color="primary"
                checked={remem}
                onChange={handleChangeRemem}
                disabled={submit}
              />
            }
            label="Запомнить меня"
            disabled={submit}
          />
          <Button
            type="submit"
            fullWidth
            variant="contained"
            color="primary"
            className={classes.submit}
            disabled={submit}
          >
            Войти
          </Button>
          <Grid container>
            <Grid item xs>
              <Link component={RouterLink} to="/" variant="body2">
                Забыли пароль?
              </Link>
            </Grid>
            <Grid item>
              <Link component={RouterLink} to="/signup" variant="body2">
                {"Нет аккаунта? Зрегестрируйтесь"}
              </Link>
            </Grid>
          </Grid>
        </form>
      </div>
      <Backdrop className={classes.backdrop} open={submit}>
        <CircularProgress color="secondary" />
      </Backdrop>
    </Container>
  );
};

export default PageNewTask;
// export useStyles;
