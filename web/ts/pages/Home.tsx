import React, { useEffect } from "react";
import CssBaseline from "@material-ui/core/CssBaseline";
import { makeStyles, createStyles } from "@material-ui/core/styles";

import Container from "@material-ui/core/Container";
import Grid from "@material-ui/core/Grid";

import CardNewTask from "./../cards/NewTask";
import { AppState, fetchSetTitle, fetchTaskUpdate, TaskState } from "../redux";
import { connect } from "react-redux";
import CardTask from "../cards/Task";

const useStyles = makeStyles((theme) =>
  createStyles({
    root: {
      marginTop: theme.spacing(3)
    }
  })
);

const PageHome: React.FC<PropsFromState & typeof mapDispatchToProps> = (props) => {
  const classes = useStyles();

  useEffect(() => {
    props.fetchSetTitle('Пункт приёма стеклотары');
  }, []);

  return (
    <Container component="main">
      <CssBaseline />
      <Grid container spacing={3} className={classes.root}>
        <Grid item xs={12} sm={6} xl={4}>
          <CardNewTask />
        </Grid>
      </Grid>
      <Grid container spacing={3} className={classes.root}>
        {
          props.tasks.map((value) => <Grid item xs={12} sm={6} xl={4} key={value.id}>
            <CardTask task={value} />
          </Grid>)
        }
      </Grid>
    </Container>
  );
};


interface PropsFromState {
  tasks: TaskState[];
}
const mapStateToProps = ({ tasks }: AppState): PropsFromState => ({ tasks: tasks })
const mapDispatchToProps = {
  fetchTaskUpdate: fetchTaskUpdate,
  fetchSetTitle: fetchSetTitle,
}

export default connect(mapStateToProps, mapDispatchToProps)(PageHome);
// export useStyles;
