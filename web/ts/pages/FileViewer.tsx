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
import { JOneFileData } from "../dart/OneFileData";



interface PageFileViewerProps {
};

const PageFileViewer: React.FC<PageFileViewerProps & typeof mapDispatchToProps & RouterProps & PropsFromState> = (
  props
) => {
  const classes = useStyles();
  const { enqueueSnackbar } = useSnackbar();

  // const classError = useStylesApp().error;
  const _pathSegments = props.history.location.pathname.split('/');
  const _taskId = _pathSegments[2];
  const _fileName = _pathSegments[4];

  const [task, setTask] = useState(props.tasks.find((value) => value.id == _taskId));
  const [files, setFiles] = useState(task?.filelist);
  const [file, setFile] = useState(task?.filelist?.find((value) => value.path.toLowerCase().endsWith(_fileName.toLowerCase())));

  useEffect(() => {
    props.fetchSetTitle('Файл: ' + task?.id + '/' + file?.path);
    console.log('[task, files]');
    console.dir(file);
  }, [task, file]);

  useEffect(() => {
    setTask(props.tasks.find((value) => value.id == _taskId));
    console.log('[props.tasks]');
  }, [props.tasks]);

  useEffect(() => {
    setFiles(task?.filelist);
    console.log('[task]');
    console.dir(task);
  }, [task]);

  useEffect(() => {
    setFile(files?.find((value) => value.path == _fileName));
    console.log('[files] ' + _fileName);
    console.dir(files);
  }, [files]);


  useEffect(() => {
    if (task) {
      requestOnce(funcs.dartJMsgGetTaskFileList(task ? task.id : ""), msg => {
        // console.dir(JSON.parse(msg));
        if (msg.startsWith('!!')) {
          enqueueSnackbar("Невозможно получить список файлов: " + msg, { variant: "error" });
        } else {
          fetchTaskUpdateFileList(msg, task?.id);
          const list = JSON.parse(msg) as Array<JOneFileData>;
          const _path = list[0].path;
          const _i = _path.indexOf('temp') + 5;
          setFiles(list.map<JOneFileData>((value) => { return { ...value, path: value.path.substring(_i) } }));
        }
      });
    }
  }, [task]);



  return (
    <Container component="main" maxWidth="lg">
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
export default connect(mapStateToProps, mapDispatchToProps)(PageFileViewer);
