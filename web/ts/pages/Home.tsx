import React, { FunctionComponent } from "react";
import CssBaseline from "@material-ui/core/CssBaseline";
import { makeStyles, createStyles } from "@material-ui/core/styles";

import Container from "@material-ui/core/Container";
import Grid from "@material-ui/core/Grid";

import CardNewTask from "./../cards/NewTask";

const useStyles = makeStyles((theme) =>
  createStyles({
    root: {
      marginTop: theme.spacing(3)
    }
  })
);

const PageHome: FunctionComponent = () => {
  const classes = useStyles();
  return (
    <Container component="main">
      <CssBaseline />
      <Grid container spacing={3} className={classes.root}>
        <Grid item xs={12} sm={6} xl={4}>
          <CardNewTask />
        </Grid>
      </Grid>
    </Container>
  );
};

export default PageHome;
// export useStyles;
