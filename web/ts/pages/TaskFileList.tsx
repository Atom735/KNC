import React, { useEffect, useState } from "react";
import { RouterProps } from "react-router";
import { Link as RouterLink, RouteProps } from "react-router-dom";
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

import LockOutlinedIcon from "@material-ui/icons/LockOutlined";
import AssignmentIcon from '@material-ui/icons/Assignment';

import useStyles from "./../styles";

import { funcs, JUser } from "./../dart/Lib";
import { requestOnce, send, waitMsgAll } from "./../dart/SocketWrapper";
import { AppState, fetchSetTitle, fetchSignIn, fetchTaskUpdateFileList, TaskState } from "../redux";
import { connect } from "react-redux";
import { useSnackbar } from "notistack";
import { rTaskStateLinearProgress, rTaskStateString } from "../cards/Task";
import { useStylesApp } from "../App";
import Tooltip from "@material-ui/core/Tooltip";



interface PageTaskFileListProps {
};

const PageTaskFileList: React.FC<PageTaskFileListProps & typeof mapDispatchToProps & RouterProps & PropsFromState> = (
  props
) => {
  const classes = useStyles();
  const { enqueueSnackbar } = useSnackbar();

  // const classError = useStylesApp().error;

  const _pathSegments = props.history.location.pathname.split('/');
  const _taskId = _pathSegments[2];

  const _filters = _pathSegments.length >= 5 && _pathSegments[4];

  const [task, setTask] = useState(props.tasks.find((value) => value.id == _taskId));

  useEffect(() => {
    props.fetchSetTitle('Список файлов задачи: ' + task?.id);
  }, [task]);

  useEffect(() => {
    if (task) {
      requestOnce(funcs.dartJMsgGetTaskFileList(task ? task.id : ""), msg => {
        console.dir(JSON.parse(msg));
        if (msg.startsWith('!!')) {
          enqueueSnackbar("Невозможно получить список файлов: " + msg, { variant: "error" });
        } else {
          fetchTaskUpdateFileList(msg, task?.id);
        }
      });
    }
  }, [task?.files, task?.worked, task?.warnings, task?.errors]);

  useEffect(() => {
    setTask(props.tasks.find((value) => value.id == _taskId));
  }, [props.tasks]);



  return (
    <Container component="main">
      <CssBaseline />
    </Container>
  );
};

interface PropsFromState {
  tasks: TaskState[];
}
const mapStateToProps = ({ tasks }: AppState): PropsFromState => ({ tasks: tasks })
const mapDispatchToProps = {
  fetchSetTitle: fetchSetTitle,
  fetchTaskUpdateFileList: fetchTaskUpdateFileList,
}
export default connect(mapStateToProps, mapDispatchToProps)(PageTaskFileList);
