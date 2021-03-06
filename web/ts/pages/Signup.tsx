import React, { FunctionComponent, useEffect, useState } from "react";
import { Link as RouterLink } from "react-router-dom";
import CssBaseline from "@material-ui/core/CssBaseline";
import { RouterProps } from "react-router";

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

import LockOutlinedIcon from "@material-ui/icons/LockOutlined";

import useStyles from "./../styles";


import { funcs, JUser } from "./../dart/Lib";
import { requestOnce } from "./../dart/SocketWrapper";
import { fetchSetTitle, fetchSignIn } from "../redux";
import { connect } from "react-redux";
import { useSnackbar } from "notistack";


const PageSignUp: React.FC<typeof mapDispatchToProps & RouterProps> = (props) => {
  const classes = useStyles();

  const { enqueueSnackbar } = useSnackbar();

  const [fname, setFName] = useState("");
  const handleChangeFName = (event: React.ChangeEvent<HTMLInputElement>) => {
    setFName(event.target.value);
  };

  const [lname, setLName] = useState("");
  const handleChangeLName = (event: React.ChangeEvent<HTMLInputElement>) => {
    setLName(event.target.value);
  };

  const [email, setEmail] = useState("");
  const handleChangeEmail = (event: React.ChangeEvent<HTMLInputElement>) => {
    setEmail(event.target.value);
  };
  const [pass, setPasss] = useState("");
  const handleChangePass = (event: React.ChangeEvent<HTMLInputElement>) => {
    setPasss(event.target.value);
  };

  const [submit, setSubmit] = useState(false);
  const handleOnSubmit = (event: React.FormEvent<HTMLFormElement>) => {
    event.preventDefault();
    setSubmit(true);
    requestOnce(funcs.dartJMsgUserRegistration(email, pass, fname, lname), (msg) => {
      setSubmit(false);
      if (msg) {
        console.log("Успешная регистрация: " + msg);
        const _user = JSON.parse(msg) as JUser;
        console.dir(_user);
        props.fetchSignIn(_user, false);
        enqueueSnackbar("Вы вошли как: " + _user.first_name, { variant: "info" });
        props.history.push('/');
      } else {
        enqueueSnackbar("Эта почта уже зарегестрированна", { variant: "error" });
      }
    });
  };


  useEffect(() => {
    props.fetchSetTitle('Регистратура');
  }, []);

  return (
    <Container component="main" maxWidth="xs">
      <CssBaseline />
      <div className={classes.paper}>
        <Avatar className={classes.avatar}>
          <LockOutlinedIcon />
        </Avatar>
        <Typography component="h1" variant="h5">
          Регистрация
        </Typography>
        <form className={classes.form} noValidate onSubmit={handleOnSubmit}>
          <Grid container spacing={2}>
            <Grid item xs={12} sm={6}>
              <TextField
                autoComplete="given-name"
                name="firstName"
                variant="outlined"
                required
                fullWidth
                id="firstName"
                label="Имя"
                autoFocus
                value={fname}
                onChange={handleChangeFName}
                disabled={submit}
              />
            </Grid>
            <Grid item xs={12} sm={6}>
              <TextField
                variant="outlined"
                required
                fullWidth
                id="lastName"
                label="Фамилия"
                name="lastName"
                autoComplete="family-name"
                value={lname}
                onChange={handleChangeLName}
                disabled={submit}
              />
            </Grid>
            <Grid item xs={12}>
              <TextField
                variant="outlined"
                required
                fullWidth
                id="email"
                label="Телефон или Email"
                name="email"
                autoComplete="username"
                value={email}
                onChange={handleChangeEmail}
                disabled={submit}
              />
            </Grid>
            <Grid item xs={12}>
              <TextField
                variant="outlined"
                required
                fullWidth
                name="password"
                label="Пароль"
                type="password"
                id="password"
                autoComplete="new-password"
                value={pass}
                onChange={handleChangePass}
                disabled={submit}
              />
            </Grid>
            <Grid item xs={12}>
              <FormControlLabel
                control={
                  <Checkbox
                    value="allowExtraEmails"
                    color="primary"
                    disabled={submit}
                  />
                }
                disabled={submit}
                label="I want to receive inspiration, marketing promotions and updates via email."
              />
            </Grid>{" "}
          </Grid>
          <Button
            type="submit"
            fullWidth
            variant="contained"
            color="primary"
            className={classes.submit}
            disabled={submit}
          >
            Зарегистрироваться
          </Button>
          <Grid container justify="flex-end">
            <Grid item>
              <Link component={RouterLink} to="/signin" variant="body2">
                Уже есть аккаунт? Войдите
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

const mapDispatchToProps = {
  fetchSignIn: fetchSignIn,
  fetchSetTitle: fetchSetTitle
}
export default connect(null, mapDispatchToProps)(PageSignUp);
