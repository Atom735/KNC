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
import clsx from 'clsx';
import { createStyles, Theme, withStyles, WithStyles } from '@material-ui/core/styles';
import TableCell from '@material-ui/core/TableCell';
import Paper from '@material-ui/core/Paper';
import { AutoSizer, Column, Table, TableCellRenderer, TableHeaderProps } from 'react-virtualized';
import { JOneFileData, NOneFileDataType } from "../dart/OneFileData";


declare module '@material-ui/core/styles/withStyles' {
  // Augment the BaseCSSProperties so that we can control jss-rtl
  interface BaseCSSProperties {
    /*
     * Used to control if the rule-set should be affected by rtl transformation
     */
    flip?: boolean;
  }
}

const styles = (theme: Theme) =>
  createStyles({
    flexContainer: {
      display: 'flex',
      alignItems: 'center',
      boxSizing: 'border-box',
    },
    table: {
      // temporary right-to-left patch, waiting for
      // https://github.com/bvaughn/react-virtualized/issues/454
      '& .ReactVirtualized__Table__headerRow': {
        flip: false,
        paddingRight: theme.direction === 'rtl' ? '0 !important' : undefined,
      },
    },
    tableRow: {
      cursor: 'pointer',
    },
    tableRowHover: {
      '&:hover': {
        backgroundColor: theme.palette.grey[200],
      },
    },
    tableCell: {
      flex: 1,
    },
    noClick: {
      cursor: 'initial',
    },
  });

interface ColumnData {
  dataKey: string;
  label: string;
  numeric?: boolean;
  typeOfFile?: boolean;
  width: number;
}

interface Row {
  index: number;
}

interface MuiVirtualizedTableProps extends WithStyles<typeof styles> {
  columns: ColumnData[];
  headerHeight?: number;
  onRowClick?: () => void;
  rowCount: number;
  rowGetter: (row: Row) => JOneFileData;
  rowHeight?: number;
}

class MuiVirtualizedTable extends React.PureComponent<MuiVirtualizedTableProps> {
  static defaultProps = {
    headerHeight: 48,
    rowHeight: 48,
  };

  getRowClassName = ({ index }: Row) => {
    const { classes, onRowClick } = this.props;

    return clsx(classes.tableRow, classes.flexContainer, {
      [classes.tableRowHover]: index !== -1 && onRowClick != null,
    });
  };

  cellRenderer: TableCellRenderer = ({ cellData, columnIndex }) => {
    const { columns, classes, rowHeight, onRowClick } = this.props;
    return (
      <TableCell
        component="div"
        className={clsx(classes.tableCell, classes.flexContainer, {
          [classes.noClick]: onRowClick == null,
        })}
        variant="body"
        style={{ height: rowHeight }}
        align={(columnIndex != null && columns[columnIndex].numeric) || false ? 'right' : 'left'}
      >
        {(columnIndex != null && columns[columnIndex].typeOfFile) || false ? NOneFileDataType[cellData] : cellData}
      </TableCell>
    );
  };

  headerRenderer = ({ label, columnIndex }: TableHeaderProps & { columnIndex: number }) => {
    const { headerHeight, columns, classes } = this.props;

    return (
      <TableCell
        component="div"
        className={clsx(classes.tableCell, classes.flexContainer, classes.noClick)}
        variant="head"
        style={{ height: headerHeight }}
        align={columns[columnIndex].numeric || false ? 'right' : 'left'}
      >
        <span>{label}</span>
      </TableCell>
    );
  };

  render() {
    const { classes, columns, rowHeight, headerHeight, ...tableProps } = this.props;
    return (
      <AutoSizer>
        {({ height, width }) => (
          <Table
            height={height}
            width={width}
            rowHeight={rowHeight!}
            gridStyle={{
              direction: 'inherit',
            }}
            headerHeight={headerHeight!}
            className={classes.table}
            {...tableProps}
            rowClassName={this.getRowClassName}
          >
            {columns.map(({ dataKey, ...other }, index) => {
              return (
                <Column
                  key={dataKey}
                  headerRenderer={(headerProps) =>
                    this.headerRenderer({
                      ...headerProps,
                      columnIndex: index,
                    })
                  }
                  className={classes.flexContainer}
                  cellRenderer={this.cellRenderer}
                  dataKey={dataKey}
                  {...other}
                />
              );
            })}
          </Table>
        )}
      </AutoSizer>
    );
  }
}

const VirtualizedTable = withStyles(styles)(MuiVirtualizedTable);



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

  const [files, setFiles] = useState(task?.filelist);


  useEffect(() => {
    props.fetchSetTitle('Список файлов задачи: ' + task?.id);
  }, [task]);

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
  }, [task?.files, task?.worked, task?.warnings, task?.errors]);

  useEffect(() => {
    setTask(props.tasks.find((value) => value.id == _taskId));
  }, [props.tasks]);

  useEffect(() => {
    setFiles(task?.filelist);
  }, [task]);

  const [height, setHeight] = useState(window.innerHeight - 100);

  useEffect(() => {
    const listner = () => {
      setHeight(window.innerHeight - 100);
    }
    window.addEventListener("resize", listner);
    return () => {
      window.removeEventListener("resize", listner);
    };
  }, []);

  return (
    <Container component="main">
      <CssBaseline />
      {!files ? null :
        <Paper style={{ height: height, width: '100%' }}>
          <VirtualizedTable
            rowCount={files.length}
            rowGetter={({ index }) => files[index]}
            columns={[
              {
                width: 200,
                label: 'Оригинал',
                dataKey: 'origin',
              },
              {
                width: 120,
                label: 'Копия',
                dataKey: 'path',
              },
              {
                width: 120,
                label: 'Тип',
                dataKey: 'type',
                typeOfFile: true,
              },
              {
                width: 120,
                label: 'Размер',
                dataKey: 'size',
                numeric: true,
              },
              {
                width: 120,
                label: 'Кодировка',
                dataKey: 'encode',
                numeric: true,
              },
              {
                width: 120,
                label: 'Предупреждений',
                dataKey: 'n-warn',
                numeric: true,
              },
              {
                width: 120,
                label: 'Ошибок',
                dataKey: 'n-errors',
                numeric: true,
              },
            ]}
          />

        </Paper>
      }
    </Container >
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
