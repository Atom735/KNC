import React, { FunctionComponent, useState } from "react";
import { Link as RouterLink } from "react-router-dom";
import CssBaseline from "@material-ui/core/CssBaseline";
import { RouterProps } from "react-router";

import Avatar from "@material-ui/core/Avatar";
import Button from "@material-ui/core/Button";
import TextField, { TextFieldProps } from "@material-ui/core/TextField";
import FormControlLabel from "@material-ui/core/FormControlLabel";
import Checkbox from "@material-ui/core/Checkbox";
import Link from "@material-ui/core/Link";
import Grid from "@material-ui/core/Grid";
import { GridProps } from "@material-ui/core/Grid";

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
import { JTaskSettings, JTaskSettings_defs, JUser } from "../dart/Lib";
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
import HelpOutlineIcon from '@material-ui/icons/HelpOutline';

const useStyles = makeStyles((theme) =>
  createStyles({
    input: {
      display: 'none',
    }
  }),
);

interface TaskSets {
  public: boolean;
  settings: JTaskSettings;
};


interface NewTaskSetsChldProps {
  sets: TaskSets,
  setSets: React.Dispatch<React.SetStateAction<TaskSets>>,
};

const NewTaskArchiveExt: React.FC<NewTaskSetsChldProps> = (props) => {

  const {
    sets: sets,
    setSets: setSets,
  } = props;

  const [indexesNew, setIndexesNew] = useState<number>(sets.settings["ar-e"].length + 1);
  const [indexes, setIndexes] = useState<number[]>(sets.settings["ar-e"].map((value, index) => index));

  const handleChangeValue = (id: number) => (event: React.ChangeEvent<HTMLInputElement>) => {
    setSets({
      ...sets, settings: {
        ...sets.settings, "ar-e": sets.settings["ar-e"].map(
          (value, index) => id == index ? event.target.value : value)
      }
    });
  };

  const handlePreventEvent = (event: React.MouseEvent<HTMLButtonElement>) => {
    event.preventDefault();
  };

  const handleClickRemove = (id: number) => (event: React.MouseEvent<HTMLButtonElement>) => {
    setSets({
      ...sets, settings: {
        ...sets.settings, "ar-e": sets.settings["ar-e"].filter((value, index) => index != id)
      }
    });
    setIndexes(indexes.filter((value, index) => index != id));
  };

  const handleClickAddNewPath = () => {
    setSets({
      ...sets, settings: {
        ...sets.settings, "ar-e": [...sets.settings["ar-e"], '']
      }
    });
    setIndexes([...indexes, indexesNew]);
    setIndexesNew(indexesNew + 1);
  };

  const handleSetDefault = () => {

    setSets({
      ...sets, settings: {
        ...sets.settings, "ar-e": JTaskSettings_defs["ar-e"].map((value) => value)
      }
    });
    setIndexes(JTaskSettings_defs["ar-e"].map((value, index) => indexesNew + index));
    setIndexesNew(indexesNew + JTaskSettings_defs["ar-e"].length);
  };

  return (<>
    {
      sets.settings["ar-e"].map((value, index) =>
        <Grid item xs={6} sm={3} lg={2} key={indexes[index]} >
          <FormControl fullWidth>
            <Input
              id={"ar-e-" + indexes[index]}
              onChange={handleChangeValue(index)}
              value={value}
              endAdornment={
                <InputAdornment position="end">
                  <Tooltip title="Удалить поле">
                    <IconButton
                      onClick={handleClickRemove(index)}
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
    <Grid item xs={12}>
      <Tooltip title="Добавить новое поле">
        <IconButton
          onClick={handleClickAddNewPath}
        >
          <AddCircleOutlineIcon />
        </IconButton>
      </Tooltip>

      <Tooltip title={<>
        Указывает файлы с каким расширением будут вскрываться архиватором.<br />
        <br />
        Чтобы настройки остались по умолчанию, оставте поля пустыми или удалите все поля или
        Нажмите чтобы заменить настройками по умолчанию.</>}>
        <IconButton onClick={handleSetDefault}>
          <HelpOutlineIcon />
        </IconButton>
      </Tooltip>

    </Grid>
  </>);
};


const NewTaskPaths: React.FC<NewTaskSetsChldProps> = (props) => {

  const {
    sets: sets,
    setSets: setSets,
  } = props;

  const [indexesNew, setIndexesNew] = useState<number>(sets.settings.path.length + 1);
  const [indexes, setIndexes] = useState<number[]>(sets.settings.path.map((value, index) => index));

  const handleChangeValue = (id: number) => (event: React.ChangeEvent<HTMLInputElement>) => {
    setSets({
      ...sets, settings: {
        ...sets.settings, path: sets.settings.path.map(
          (value, index) => id == index ? event.target.value : value)
      }
    });
  };

  const handlePreventEvent = (event: React.MouseEvent<HTMLButtonElement>) => {
    event.preventDefault();
  };

  const handleClickRemove = (id: number) => (event: React.MouseEvent<HTMLButtonElement>) => {
    setSets({
      ...sets, settings: {
        ...sets.settings, path: sets.settings.path.filter((value, index) => index != id)
      }
    });
    setIndexes(indexes.filter((value, index) => index != id));
  };

  const handleClickAddNewPath = () => {
    setSets({
      ...sets, settings: {
        ...sets.settings, path: [...sets.settings.path, '']
      }
    });
    setIndexes([...indexes, indexesNew]);
    setIndexesNew(indexesNew + 1);
  };

  return (<>{
    sets.settings.path.map((value, index) =>
      <Grid item xs={12} key={indexes[index]} >
        <FormControl fullWidth>
          <InputLabel htmlFor={"path-" + indexes[index]}>Сканируемый путь</InputLabel>
          <Input
            id={"path-" + indexes[index]}
            onChange={handleChangeValue(index)}
            value={value}
            endAdornment={
              <InputAdornment position="end">
                <Tooltip title="Удалить поле">
                  <IconButton
                    onClick={handleClickRemove(index)}
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
  </>);
};

interface NumberTextFieldProps {
  value?: number;
  setValue: (value: number) => any;
  default?: number;
  textFieldProps?: TextFieldProps;
};

const NumberTextField: React.FC<NumberTextFieldProps> = (props) => {

  const [state, setState] = useState<string>(props.value ? props.value.toString() : '');

  const handlePreventEvent = (event: React.MouseEvent<HTMLButtonElement>) => {
    event.preventDefault();
  };
  const handleChange = (event: React.ChangeEvent<HTMLInputElement>) => {
    const _valS = event.target.value.trim();
    setState(_valS);
    if (_valS.endsWith('k') || _valS.endsWith('K') || _valS.endsWith('к') || _valS.endsWith('К')) {
      props.setValue(parseInt(_valS.substring(0, _valS.length - 1)) * 1024);
    } else if (_valS.endsWith('m') || _valS.endsWith('M') || _valS.endsWith('м') || _valS.endsWith('М')) {
      props.setValue(parseInt(_valS.substring(0, _valS.length - 1)) * 1024 * 1024);
    } else if (_valS.endsWith('g') || _valS.endsWith('G') || _valS.endsWith('г') || _valS.endsWith('Г')) {
      props.setValue(parseInt(_valS.substring(0, _valS.length - 1)) * 1024 * 1024 * 1024);
    } else {
      props.setValue(parseInt(_valS));
    }
  };

  const handleSetDefault = () => {
    if (props.default) {
      setState(props.default.toString());
      props.setValue(props.default);
    } else {
      setState('');
      props.setValue(0);
    }
  }

  return (<TextField {...props.textFieldProps}
    value={state}
    onChange={handleChange}
    InputProps={{
      endAdornment: <InputAdornment position="end">
        <Tooltip title={<>{props.children}<br /><br />
Если в конце написать букву 'K' - то значение будет умножено на 2^10, 'М' - на 2^20, 'Г' - на 2^30.
        <br /><br />
            Чтобы настройки остались по умолчанию, оставте поле пустым или
нажмите чтобы заменить настройками по умолчанию.</>}>
          <IconButton
            onClick={handleSetDefault}
            onMouseDown={handlePreventEvent}
          >
            <HelpOutlineIcon />
          </IconButton>
        </Tooltip>
      </InputAdornment>,
    }}
  />);
}


interface ArrayOfTextFieldsProps {
  value?: string[];
  setValue: (value: string[]) => any;
  default?: string[];
  itemProps?: GridProps;
  textFieldProps?: TextFieldProps;
  lastItemChilds?: React.ReactNode;
};
const ArrayOfTextFields: React.FC<ArrayOfTextFieldsProps> = (props) => {

  const [state, setState] = useState<string[]>(props.value ? props.value.map((value) => value) : []);
  const [indexesNew, setIndexesNew] = useState<number>(state.length + 1);
  const [indexes, setIndexes] = useState<number[]>(state.map((value, index) => index + 1));

  const handleChange = (id: number) => (event: React.ChangeEvent<HTMLInputElement>) => {
    setState(state.map(
      (value, index) => id == index ? event.target.value : value));
    props.setValue(state.map(
      (value, index) => id == index ? event.target.value : value));
  };

  const handlePreventEvent = (event: React.MouseEvent<HTMLButtonElement>) => {
    event.preventDefault();
  };

  const handleRemove = (id: number) => (event: React.MouseEvent<HTMLButtonElement>) => {
    setState(state.filter((value, index) => index != id));
    setIndexes(indexes.filter((value, index) => index != id));
    props.setValue(state.filter((value, index) => index != id));
  };

  const handleAddNew = () => {
    setState([...state, '']);
    setIndexes([...indexes, indexesNew]);
    setIndexesNew(indexesNew + 1);
    props.setValue([...state, '']);
  };

  const handleSetDefault = () => {
    if (props.default) {
      setState([...props.default]);
      setIndexes(props.default.map((value, index) => index + 1));
      setIndexesNew(indexesNew + props.default.length);
      props.setValue([...props.default]);
    } else {
      setState([]);
      setIndexes([]);
      props.setValue([]);
    }
  }

  return (<>{
    state.map((value, index) =>
      <Grid item {...props.itemProps} key={indexes[index]} >
        <TextField {...props.textFieldProps}
          value={value}
          onChange={handleChange(index)}
          InputProps={{
            endAdornment: <InputAdornment position="end">
              <Tooltip title="Удалить поле">
                <IconButton
                  onClick={handleRemove(index)}
                  onMouseDown={handlePreventEvent}
                >
                  <RemoveCircleOutlineIcon />
                </IconButton>
              </Tooltip>
            </InputAdornment>,
          }}
        />
      </Grid>
    )
  }
    <Grid item xs={12}>
      <Tooltip title="Добавить новое поле">
        <IconButton
          onClick={handleAddNew}
        >
          <AddCircleOutlineIcon />
        </IconButton>
      </Tooltip>
      <Tooltip title={<>{props.children}
        <br /><br />
          Чтобы настройки остались по умолчанию, оставте поля пустымы или удалите все поля или
нажмите чтобы заменить настройками по умолчанию.</>}>
        <IconButton
          onClick={handleSetDefault}
          onMouseDown={handlePreventEvent}
        >
          <HelpOutlineIcon />
        </IconButton>
      </Tooltip>
      {props.lastItemChilds}
    </Grid>
  </>);
};



const PageNewTask: React.FC<RouterProps & PropsFromState & typeof mapDispatchToProps> = (props) => {
  const classesPage = useStylesPage();
  const classes = useStyles();
  const { user } = props;

  const [sets, setSets] = useState<TaskSets>({
    public: user == null, settings: {
      user: user != null ? user.mail : "Гость", path: [''],
      "ar-e": [], "ar-s": null, "ar-d": null
    }
  });


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

  const handleChangeArSize = (value: number) => {
    setSets({ ...sets, settings: { ...sets.settings, "ar-s": value } });
  }
  const handleChangeArDepth = (value: number) => {
    setSets({ ...sets, settings: { ...sets.settings, "ar-d": value } });
  }
  const handleChangeUpdateDuration = (value: number) => {
    setSets({ ...sets, settings: { ...sets.settings, ud: value } });
  }
  const handleChangePaths = (value: string[]) => {
    setSets({ ...sets, settings: { ...sets.settings, path: [...value] } });
  }
  const handleChangeArExt = (value: string[]) => {
    setSets({ ...sets, settings: { ...sets.settings, "ar-e": [...value] } });
  }
  const handleChangeFileExt = (value: string[]) => {
    setSets({ ...sets, settings: { ...sets.settings, "f-e": [...value] } });
  }

  return (
    <Container component="main" maxWidth="lg">
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


                  <Grid item xs={12}>
                    <Typography variant="h6">Сканируемые пути к папкам и файлам</Typography>
                  </Grid>
                  <ArrayOfTextFields setValue={handleChangePaths} default={JTaskSettings_defs.path} itemProps={{ xs: 12 }}
                    textFieldProps={{ fullWidth: true, label: "Сканируемый путь" }} lastItemChilds={<>
                      <input
                        accept="*"
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

                      </label></>}>
                    Указывает пути к файлам и папкам, которые просканируем.<br />
                      Сейчас введено: {sets.settings.path && !sets.settings.path.every((value) => !value) ?
                      sets.settings.path.map((value, index) => <span key={index}><br />[{index}] {value}</span>)
                      : JTaskSettings_defs.path.map((value, index) => <span key={index}><br />[{index}] {value}</span>)}
                  </ArrayOfTextFields>
                </Grid>
              </AccordionDetails>
            </Accordion>
            <Accordion>
              <AccordionSummary expandIcon={<ExpandMoreIcon />} >
                <Typography variant="h5">Дополнительные настройки</Typography>
              </AccordionSummary>
              <AccordionDetails>
                <Grid container spacing={2}>
                  <Grid item xs={12}>
                    <Typography variant="h6">Расширения обрабатываемых файлов</Typography>
                  </Grid>
                  <ArrayOfTextFields setValue={handleChangeFileExt} default={JTaskSettings_defs["f-e"]} itemProps={{ xs: 6, sm: 3, lg: 2 }}
                    textFieldProps={{ fullWidth: true }}>
                    Указывает файлы с каким расширением будут обработаны программой.<br />
                      Сейчас введено: {sets.settings["f-e"] && !sets.settings["f-e"].every((value) => !value) ?
                      sets.settings["f-e"].map((value, index) => <span key={index}><br />[{index}] {value}</span>)
                      : JTaskSettings_defs["f-e"].map((value, index) => <span key={index}><br />[{index}] {value}</span>)}
                  </ArrayOfTextFields>
                  <Grid item xs={12} sm={4}>
                    <NumberTextField setValue={handleChangeUpdateDuration} default={JTaskSettings_defs.ud}
                      textFieldProps={{ fullWidth: true, label: "Интервал обновления" }}>
                      Указывает время в миллисекундах между отправками обновлённых данных задачи.<br />
                      Сейчас введено {sets.settings.ud ? sets.settings.ud.toString() : JTaskSettings_defs.ud} мс.
                      </NumberTextField>
                  </Grid>
                  <Grid item xs={12} sm={4}>
                    <NumberTextField setValue={handleChangeArDepth} default={JTaskSettings_defs["ar-d"]}
                      textFieldProps={{ fullWidth: true, label: "Вложенность архивов" }}>
                      Указывает глубину раскрытия архивов. Если `1` то архивы внутри архивов не будут вскрываться.<br />
                      `-1` - для бесконечной вложенности<br />
                      `0` - для отбрасывания всех архивов<br />
                      `1` - для входа на один уровень архива<br />
                      Сейчас введено {sets.settings["ar-d"] ? sets.settings["ar-d"].toString() : JTaskSettings_defs["ar-d"]}.
                      </NumberTextField>
                  </Grid>
                  <Grid item xs={12} sm={4}>
                    <NumberTextField setValue={handleChangeArSize} default={JTaskSettings_defs["ar-s"]}
                      textFieldProps={{ fullWidth: true, label: "Размер архива" }}>
                      Указывает файлы какого максимального размера будут вскрыты архиватором.<br />
                      Размер задаётся в байтах.<br />
                      Сейчас введено {sets.settings["ar-s"] ? sets.settings["ar-s"].toString() : JTaskSettings_defs["ar-s"]} байт.
                      </NumberTextField>
                  </Grid>
                  <Grid item xs={12}>
                    <Typography variant="h6">Расширения архивных файлов</Typography>
                  </Grid>
                  <ArrayOfTextFields setValue={handleChangeArExt} default={JTaskSettings_defs["ar-e"]} itemProps={{ xs: 6, sm: 3, lg: 2 }}
                    textFieldProps={{ fullWidth: true }}>
                    Указывает файлы с каким расширением будут вскрываться архиватором.<br />
                      Сейчас введено: {sets.settings["ar-e"] && !sets.settings["ar-e"].every((value) => !value) ?
                      sets.settings["ar-e"].map((value, index) => <span key={index}><br />[{index}] {value}</span>)
                      : JTaskSettings_defs["ar-e"].map((value, index) => <span key={index}><br />[{index}] {value}</span>)}
                  </ArrayOfTextFields>
                </Grid>
              </AccordionDetails>
            </Accordion>
            <Accordion disabled={user == null}>
              <AccordionSummary expandIcon={<ExpandMoreIcon />} >
                <Typography variant="h5">Настройки доступа</Typography>

              </AccordionSummary>
              <AccordionDetails>
                <Grid container spacing={2}>
                  <Grid item>
                  </Grid>
                </Grid>
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
