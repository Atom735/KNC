import React from "react";
import { Link as RouterLink } from "react-router-dom";

import Link from "@material-ui/core/Link";
import Card from "@material-ui/core/Card";
import CardActionArea from "@material-ui/core/CardActionArea";
import CardActions from "@material-ui/core/CardActions";
import CardContent from "@material-ui/core/CardContent";
import CardMedia from "@material-ui/core/CardMedia";
import Button from "@material-ui/core/Button";
import Typography from "@material-ui/core/Typography";

import { NTaskState, TaskState } from "./../redux";
import LinearProgress from "@material-ui/core/LinearProgress";

export function rTaskStateString(task: TaskState) {
  return !task ? "NULL" : !task.state ? "Инициализация" :
    (task.state == NTaskState.searchFiles) ? "Поиск файлов: " + task.files :
      (task.state == NTaskState.workFiles) ? "Обработка файлов: " + task.worked + "/" + task.files :
        (task.state == NTaskState.generateTable) ? "Генерация отчётной таблицы" :
          (task.state == NTaskState.completed) ? "Конец задачи" :
            "Неизвестное состояние";
}

export function rTaskStateLinearProgress(task: TaskState) {
  return !task ? null : !task.state ? <LinearProgress /> :
    (task.state == NTaskState.searchFiles) ? <LinearProgress /> :
      (task.state == NTaskState.workFiles && task.worked) ? <LinearProgress variant="determinate" value={task.worked * 100 / task.files} /> :
        (task.state == NTaskState.generateTable) ? <LinearProgress /> :
          null;
}

interface CardTaskProps {
  task: TaskState;
}
const CardTask: React.FC<CardTaskProps> = (props) => {
  const { task } = props;
  const settings = props.task.settings;
  return (
    <Card>
      <CardActionArea component={RouterLink} to={"/task/" + task.id}>
        <CardContent>
          <Typography gutterBottom variant="h5" component="h2">
            {!settings ? 'Загружаю данные задачи' : settings.name}
          </Typography>
          <Typography variant="body2" color="textSecondary" component="p">
            {rTaskStateString(task)}

          </Typography>
          {rTaskStateLinearProgress(task)}

        </CardContent>
      </CardActionArea>
      {   task.raport ? <CardActions>
        <Button href={"/raports/" + task.id + '.xlsx'} color="primary" download>Отчёт</Button>
        <Button href={"/lases/" + task.id + '.zip'} color="primary" download>LAS файлы</Button>
        <Button href={"/inks/" + task.id + '.zip'} color="primary" download>Файлы инклинометрии</Button>
      </CardActions> : null}
    </Card>
  );
};

export default CardTask;
