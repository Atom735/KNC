import { createMuiTheme } from '@material-ui/core/styles';
import { ruRU } from '@material-ui/core/locale';
import { blue, pink } from '@material-ui/core/colors';

// A custom theme for this app
const theme = createMuiTheme({
  palette: {
    primary: {
      main: blue[700],
    },
    secondary: {
      main: pink.A700,
    },
  },
}, ruRU);

export default theme;
