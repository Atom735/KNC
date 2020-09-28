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
import { makeStyles } from "@material-ui/core/styles";
import Accordion from "@material-ui/core/Accordion";
import AccordionSummary from "@material-ui/core/AccordionSummary";
import AccordionDetails from "@material-ui/core/AccordionDetails";
import { connect } from "react-redux";
import { AppState } from "../redux";
import { JUser } from "../dart/Lib";
import Autocomplete from '@material-ui/lab/Autocomplete';

const useStyles = makeStyles((theme) => ({
  root: {
    width: '100%',
  }
}));


const PageNewTask: React.FC<RouterProps & PropsFromState & typeof mapDispatchToProps> = (props) => {
  const classesPage = useStylesPage();
  const classes = useStyles();

  const { user } = props;

  const [submit, setSubmit] = useState(false);
  const handleOnSubmit = (event: React.FormEvent<HTMLFormElement>) => {
    setSubmit(true);
    event.preventDefault();
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
          <div className={classes.root}>
            <Accordion>
              <AccordionSummary expandIcon={<ExpandMoreIcon />} >
                <Typography>Основный настройки</Typography>
              </AccordionSummary>
              <AccordionDetails>
                {/* //TODO */}
              </AccordionDetails>
            </Accordion>
            <Accordion>
              <AccordionSummary expandIcon={<ExpandMoreIcon />} >
                <Typography>Дополнительные настройки</Typography>
              </AccordionSummary>
              <AccordionDetails>
                {/* //TODO */}
              </AccordionDetails>
            </Accordion>
            <Accordion disabled={user == null}>
              <AccordionSummary expandIcon={<ExpandMoreIcon />} >
                <Typography>Настройки доступа</Typography>
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
    </Container>
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
