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
import { AppState, fetchSetTitle, fetchSignIn, TaskState } from "../redux";
import { connect } from "react-redux";
import { useSnackbar } from "notistack";
import { rTaskStateLinearProgress, rTaskStateString } from "../cards/Task";
import { useStylesApp } from "../App";
import Tooltip from "@material-ui/core/Tooltip";



interface PageTaskProps {
};

const PageTask: React.FC<PageTaskProps & typeof mapDispatchToProps & RouterProps & PropsFromState> = (
  props
) => {
  const classes = useStyles();
  const { enqueueSnackbar } = useSnackbar();

  // const classError = useStylesApp().error;

  const _taskId = props.history.location.pathname.split('/')[2];

  const [task, setTask] = useState(props.tasks.find((value) => value.id == _taskId));

  useEffect(() => {
    props.fetchSetTitle('Задача: ' + task?.id);
  }, [task]);

  useEffect(() => {
    setTask(props.tasks.find((value) => value.id == _taskId));
  }, [props.tasks]);


  const handleTaskDelete = (event: React.MouseEvent<HTMLButtonElement>) => {
    requestOnce(funcs.dartJMsgTaskKill(_taskId), (msg) => {
      console.warn(msg);
      const _msgId = funcs.dartIdJMsgTaskKill();
      if (msg.length <= _msgId.length || msg.substring(_msgId.length) != _taskId) {
        enqueueSnackbar("Невозможно удалить задачу", { variant: "error" });
      } else {
        props.history.push('/');
      }
    });
  };

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

      <Grid
        container
        direction="row"
        spacing={1}
      >
        <Grid item >
          <Tooltip title="Открывает страницу изменения параметров задачи, после чего необходимо будет принудительно повторить поиск, либо обработку, либо же генерацию таблицы">
            <Button variant="outlined">Изменить параметры</Button>
          </Tooltip>
        </Grid>
        <Grid item >
          <Tooltip title="Запускает процесс поиска файлов, а также их обработку и генерацию отчёта">
            <Button variant="outlined">Поиск файлов</Button>
          </Tooltip>
        </Grid>
        <Grid item >
          <Tooltip title="Запускает повторную обработку всех найденных файлов, после чего будет повторно сгененрирован отчёт">
            <Button variant="outlined">Обработать файлы</Button>
          </Tooltip>
        </Grid>
        <Grid item >
          <Tooltip title="Запускает повторную генерацию отчётной таблицы">
            <Button variant="outlined">Сгенерировать отчёт</Button>
          </Tooltip>
        </Grid>
        <Grid item xs={12}>
          <Tooltip title="Удаляет задачу и все её данные">
            <Button variant="outlined" onClick={handleTaskDelete}>Удалить</Button>
          </Tooltip>
        </Grid>
      </Grid>




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
