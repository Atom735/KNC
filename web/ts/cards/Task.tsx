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

import { TaskState } from "./../redux";

interface CardTaskProps {
  task: TaskState;
}
const CardTask: React.FC<CardTaskProps> = (props) => {
  const { task } = props;
  const settings = props.task.settings;
  return (
    <Card>
      <CardActionArea component={RouterLink} to="/newtask">
        <CardMedia
          component="img"
          alt="Contemplative Reptile"
          height="140"
          image="https://material-ui.com/static/images/cards/contemplative-reptile.jpg"
          title="Contemplative Reptile"
        />
        <CardContent>
          <Typography gutterBottom variant="h5" component="h2">
            {settings ? settings.name : 'Загружаю данные'}
          </Typography>
          <Typography variant="body2" color="textSecondary" component="p">
            Просто текст
          </Typography>
        </CardContent>
      </CardActionArea>
    </Card>
  );
};

export default CardTask;
