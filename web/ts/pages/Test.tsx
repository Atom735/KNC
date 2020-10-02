import React, { FunctionComponent, useEffect, useState } from "react";
import CssBaseline from "@material-ui/core/CssBaseline";
import { makeStyles } from "@material-ui/core/styles";

import Avatar from "@material-ui/core/Avatar";
import Button from "@material-ui/core/Button";
import TextField from "@material-ui/core/TextField";
import FormControlLabel from "@material-ui/core/FormControlLabel";
import Checkbox from "@material-ui/core/Checkbox";
import Link from "@material-ui/core/Link";
import Grid from "@material-ui/core/Grid";
import Box from "@material-ui/core/Box";
import Typography from "@material-ui/core/Typography";
import Container from "@material-ui/core/Container";

import LockOutlinedIcon from "@material-ui/icons/LockOutlined";

import useStyles from "./../styles";
import { connect } from "react-redux";
import { fetchSetTitle } from "../redux";

const PageTest: React.FC<typeof mapDispatchToProps> = (props) => {



  useEffect(() => {
    props.fetchSetTitle('Тестовая комната');
  }, []);

  return (
    <Container component="main" maxWidth="xs">
      <CssBaseline />
    </Container>
  );
};

const mapDispatchToProps = {
  fetchSetTitle: fetchSetTitle
}
export default connect(null, mapDispatchToProps)(PageTest);
