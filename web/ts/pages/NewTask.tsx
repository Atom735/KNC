import React, { FunctionComponent, useState } from "react";
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

import PostAddIcon from "@material-ui/icons/PostAdd";
import ExpandMoreIcon from '@material-ui/icons/ExpandMore';

import useStylesPage from "./../styles";
import { createStyles, makeStyles } from "@material-ui/core/styles";
import Accordion from "@material-ui/core/Accordion";
import AccordionSummary from "@material-ui/core/AccordionSummary";
import AccordionDetails from "@material-ui/core/AccordionDetails";
import { connect } from "react-redux";
import { AppState } from "../redux";
import { JTaskSettings, JUser } from "../dart/Lib";
import Autocomplete from '@material-ui/lab/Autocomplete';
import Switch from "@material-ui/core/Switch";
import { dartSetSocketOnClose } from "../dart/SocketWrapper";

import RemoveCircleOutlineIcon from '@material-ui/icons/RemoveCircleOutline';
import IconButton from "@material-ui/core/IconButton";
import AttachFileIcon from '@material-ui/icons/AttachFile';
import InputAdornment from "@material-ui/core/InputAdornment";
import FormControl from "@material-ui/core/FormControl";
import InputLabel from "@material-ui/core/InputLabel";
import Input from "@material-ui/core/Input";
import Tooltip from "@material-ui/core/Tooltip";
import AddCircleOutlineIcon from '@material-ui/icons/AddCircleOutline';

const useStyles = makeStyles((theme) =>
  createStyles({
    input: {
      display: 'none',
    },
  }),
);

interface TaskSets {
  public: boolean;
  settings: JTaskSettings;
};



const PageNewTask: React.FC<RouterProps & PropsFromState & typeof mapDispatchToProps> = (props) => {
  const classesPage = useStylesPage();
  const classes = useStyles();
  const { user } = props;

  const [sets, setSets] = useState<TaskSets>({ public: user == null, settings: { user: user != null ? user.mail : "Гость", path: [''] } });

  const [pathsIndexNew, setPathsIndexNew] = useState<number>(2);
  const [pathsIndex, setPathsIndex] = useState<number[]>([1]);

  const [submit, setSubmit] = useState<boolean>(false);
  const handleOnSubmit = (event: React.FormEvent<HTMLFormElement>) => {
    setSubmit(true);
    event.preventDefault();
  };


  const handleSwitchPublic = (event: React.ChangeEvent<HTMLInputElement>) => {
    setSets({ ...sets, [event.target.name]: event.target.checked });
  };

  const handleChangeName = (event: React.ChangeEvent<HTMLInputElement>) => {
    setSets({ ...sets, settings: { ...sets.settings, [event.target.name]: event.target.value } });
  };

  const handlePathEdit = (id: number) => (event: React.ChangeEvent<HTMLInputElement>) => {
    const _id = pathsIndex.indexOf(id);
    setSets({
      ...sets, settings: {
        ...sets.settings, path: sets.settings.path.map(
          (value, index) => _id == index ? event.target.value : value)
      }
    });
  };

  const handlePreventEvent = (event: React.MouseEvent<HTMLButtonElement>) => {
    event.preventDefault();
  };

  const handleClickRemove = (id: number) => (event: React.MouseEvent<HTMLButtonElement>) => {
    const _id = pathsIndex.indexOf(id);
    setSets({
      ...sets, settings: {
        ...sets.settings, path: sets.settings.path.filter((value, index) => index != _id)
      }
    });
    setPathsIndex(pathsIndex.filter((value, index) => index != _id));
    // setPathsIndexNew(pathsIndexNew + 1);
  };

  const handleClickAddNewPath = () => {
    setSets({
      ...sets, settings: {
        ...sets.settings, path: [...sets.settings.path, '']
      }
    });
    setPathsIndex([...pathsIndex, pathsIndexNew]);
    setPathsIndexNew(pathsIndexNew + 1);
  };

  return (
    <Container component="main" maxWidth="xs">
      <CssBaseline />
      <div className={classesPage.paper}>
        <Avatar className={classesPage.avatar}>
          <PostAddIcon />
        </Avatar>
        <Typography component="h1" variant="h5">
          Добавление задачи
        </Typography>
        <form className={classesPage.form} noValidate onSubmit={handleOnSubmit}>
          <Button
            type="submit"
            fullWidth
            variant="contained"
            color="primary"
            className={classesPage.submit}
            disabled={submit}
          >
            Добавить задачу
          </Button>
          <div>
            <Accordion>
              <AccordionSummary expandIcon={<ExpandMoreIcon />} >
                <Typography variant="h5">Основный настройки</Typography>
              </AccordionSummary>
              <AccordionDetails>
                <Grid container spacing={2}>
                  <Grid item xs={12}>
                    <TextField fullWidth
                      label="Название задачи"
                      name="name"
                      onChange={handleChangeName}
                    />
                  </Grid>
                  <Grid item xs={12}>

                    <TextField fullWidth
                      disabled={user == null || !user.access.includes("x")}
                      label="Пользователь"
                      defaultValue={sets.settings.user}
                      helperText="Почта пользователя запустившего задачу"
                    />
                  </Grid>
                  <Grid item xs={12}>
                    <FormControlLabel disabled={user == null}
                      control={
                        <Switch
                          checked={sets.public}
                          name="public"
                          onChange={handleSwitchPublic} />}
                      label={sets.public ? "Публичная задача" : "Приватная задача"} />
                  </Grid>
                  {
                    sets.settings.path.map((path, index) =>
                      <Grid item xs={12} key={pathsIndex[index]} >
                        <FormControl fullWidth>
                          <InputLabel htmlFor={"path-" + pathsIndex[index]}>Сканируемый путь</InputLabel>
                          <Input
                            id={"path-" + pathsIndex[index]}
                            onChange={handlePathEdit(pathsIndex[index])}
                            endAdornment={
                              <InputAdornment position="end">
                                <Tooltip title="Удалить поле">
                                  <IconButton
                                    onClick={handleClickRemove(pathsIndex[index])}
                                    onMouseDown={handlePreventEvent}
                                  >
                                    <RemoveCircleOutlineIcon />
                                  </IconButton>
                                </Tooltip>
                              </InputAdornment>
                            }
                          />
                        </FormControl>
                      </Grid>
                    )
                  }


                  <Grid item>
                    <Tooltip title="Добавить новое поле">
                      <IconButton
                        onClick={handleClickAddNewPath}
                      >
                        <AddCircleOutlineIcon />
                      </IconButton>
                    </Tooltip>
                  </Grid>
                  <Grid item>
                    <input
                      accept="image/*"
                      className={classes.input}
                      id="contained-button-file"
                      multiple
                      type="file"
                    />
                    <label htmlFor="contained-button-file">

                      <Tooltip title="Прикрепить файл">
                        <IconButton component="span">
                          <AttachFileIcon />
                        </IconButton>
                      </Tooltip>

                    </label>
                  </Grid>



                </Grid>
              </AccordionDetails>
            </Accordion>
            <Accordion>
              <AccordionSummary expandIcon={<ExpandMoreIcon />} >
                <Typography variant="h5">Дополнительные настройки</Typography>
              </AccordionSummary>
              <AccordionDetails>
                {/* //TODO */}
              </AccordionDetails>
            </Accordion>
            <Accordion disabled={user == null}>
              <AccordionSummary expandIcon={<ExpandMoreIcon />} >
                <Typography variant="h5">Настройки доступа</Typography>
              </AccordionSummary>
              <AccordionDetails>
                {/* //TODO */}
              </AccordionDetails>
            </Accordion>
          </div>
        </form>
      </div>
      <Backdrop className={classesPage.backdrop} open={submit}>
        <CircularProgress color="secondary" />
      </Backdrop>
    </Container >
  );
};

interface PropsFromState {
  user: JUser
}
const mapStateToProps = ({ user }: AppState): PropsFromState => ({ user: user });
const mapDispatchToProps = {
  // fetchSignOut: fetchSignOut
}
export default connect(mapStateToProps)(PageNewTask);
// export useStyles;
