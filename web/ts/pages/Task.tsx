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
import { requestOnce, waitMsgAll } from "./../dart/SocketWrapper";
import { AppState, fetchSetTitle, fetchSignIn, TaskState } from "../redux";
import { connect } from "react-redux";
import { useSnackbar } from "notistack";
import { rTaskStateLinearProgress, rTaskStateString } from "../cards/Task";
import { useStylesApp } from "../App";



interface PageTaskProps {
};

const PageTask: React.FC<PageTaskProps & typeof mapDispatchToProps & RouteProps & PropsFromState> = (
  props
) => {
  const classes = useStyles();

  const classError = useStylesApp().error;

  const _path = props.location.pathname.substring('/task/'.length);

  const [task, setTask] = useState(props.tasks.find((value) => value.id == _path));

  useEffect(() => {
    props.fetchSetTitle('Задача: ' + task?.id);
  }, [task]);

  useEffect(() => {
    setTask(props.tasks.find((value) => value.id == _path));
  }, [props.tasks]);



  return (
    <Container component="main" maxWidth="lg">
      <CssBaseline />
      <div className={classes.paper}>
        <Avatar className={classes.avatar}>
          <AssignmentIcon />
        </Avatar>

        <Typography variant="h4">
          {task?.settings?.name}
        </Typography>
      </div>
      <Typography variant="h5">
        Основные данные задачи
      </Typography>

      <Typography>
        <b>Состояние: </b>
        {rTaskStateString(task)}
      </Typography>
      {rTaskStateLinearProgress(task)}

      <Typography>
        <b>Запущена пользователем: </b>
        {task?.settings?.user}
      </Typography>

      {task?.settings?.users && <Typography>
        <b>Доступна пользователям: </b>
        {task?.settings?.users.join(', ')}
      </Typography>}

      {task?.files && <Typography>
        <b>Количество файлов: </b>
        {task?.files}
      </Typography>}

      {task?.worked && <Typography>
        <b>Количество обработанных файлов: </b>
        {task?.worked}
      </Typography>}



      {task?.errors && <Typography>
        <b>Количество файлов с ошибками: </b>
        {task?.errors}
      </Typography>}

      {task?.warnings && <Typography>
        <b>Количество файлов с предупрежениями: </b>
        {task?.warnings}
      </Typography>}


      {task?.raport &&
        <Button variant="contained" href={"/raports/" + task?.id} color="primary">Файл отчёта</Button>}


      <Typography variant="h5">
        Управление задачей
      </Typography>

      <Button variant="outlined">Удалить</Button>




    </Container>
  );
};

interface PropsFromState {
  tasks: TaskState[];
}
const mapStateToProps = ({ tasks }: AppState): PropsFromState => ({ tasks: tasks })
const mapDispatchToProps = {
  fetchSetTitle: fetchSetTitle,
}
export default connect(mapStateToProps, mapDispatchToProps)(PageTask);
