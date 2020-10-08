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
import { createStyles, makeStyles, Theme, withStyles, WithStyles } from '@material-ui/core/styles';
import TableCell from '@material-ui/core/TableCell';
import Paper from '@material-ui/core/Paper';
import { AutoSizer, Column, ColumnProps, Index, Table, TableCellRenderer, TableHeaderProps, WindowScroller } from 'react-virtualized';
import { JOneFileData, NOneFileDataType } from "../dart/OneFileData";
import TableSortLabel from "@material-ui/core/TableSortLabel";


const styles = makeStyles((theme: Theme) =>
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
    visuallyHidden: {
      border: 0,
      clip: 'rect(0 0 0 0)',
      height: 1,
      margin: -1,
      overflow: 'hidden',
      padding: 0,
      position: 'absolute',
      top: 20,
      width: 1,
    },
  }));

enum ColumnType {
  text = 0,
  number,
  fileType,
}

interface ColumnData extends ColumnProps {
  dataKey: keyof JOneFileData;
  label: string;
  width: number;
  columnType?: ColumnType;
}

interface PageTaskFileListProps {
};

const PageTaskFileList: React.FC<PageTaskFileListProps & typeof mapDispatchToProps & RouterProps & PropsFromState> = (
  props
) => {
  const classes = useStyles();
  const classesTable = styles();
  const { enqueueSnackbar } = useSnackbar();

  // const classError = useStylesApp().error;

  const _pathSegments = props.history.location.pathname.split('/');
  const _taskId = _pathSegments[2];

  const _filters = _pathSegments.length >= 5 && _pathSegments[4];

  const [task, setTask] = useState(props.tasks.find((value) => value.id == _taskId));

  const [files, setFiles] = useState<JOneFileData[]>(task?.filelist);


  const [columns, setColumns] = useState<ColumnData[]>([{
    dataKey: 'path',
    label: 'Копия',
    width: 120,
    flexShrink: 0,
  }, {
    dataKey: 'origin',
    label: 'Оригинал',
    width: 200,
    flexShrink: 0,
    flexGrow: 1,
  }, {
    dataKey: 'type',
    label: 'Тип',
    width: 80,
    flexShrink: 0,
    columnType: ColumnType.fileType,
  }, {
    dataKey: 'size',
    label: 'Размер',
    width: 100,
    flexShrink: 0,
    columnType: ColumnType.number,
  }]);


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


  const getRowClassName = ({ index }: Index) => {
    return clsx(classesTable.tableRow, classesTable.flexContainer, {
      [classesTable.tableRowHover]: index !== -1,
    });
  };

  const headerHeight = 48;
  const rowHeight = 48;

  return (
    <Container component="main" maxWidth={false}>
      <CssBaseline />
      <WindowScroller
        scrollElement={window}>
        {({ height, isScrolling, registerChild, onChildScroll, scrollTop }) => (
          <div style={{ flex: "1 1 auto" }}>
            <AutoSizer disableHeight>
              {({ width }) => (
                <div ref={registerChild}>
                  <Table
                    autoHeight
                    height={height}
                    width={width}


                    headerHeight={headerHeight}

                    rowHeight={rowHeight}
                    rowCount={files ? files.length : 0}
                    rowGetter={(row) => files[row.index]}
                    rowClassName={getRowClassName}

                    className={classesTable.table}

                    isScrolling={isScrolling}
                    onScroll={onChildScroll}
                    scrollTop={scrollTop}
                    overscanRowCount={16}
                  >
                    {columns.map((columnData) => {
                      const { dataKey, ...other } = columnData;
                      return (
                        <Column
                          key={dataKey}
                          dataKey={dataKey}
                          columnData={columnData}
                          {...other}
                          headerRenderer={(propsHeader) => {
                            const columnData = propsHeader.columnData as ColumnData;
                            const { columnType } = columnData;
                            return (
                              <TableCell
                                component="div"
                                className={
                                  clsx(classesTable.tableCell,
                                    classesTable.flexContainer,
                                    classesTable.noClick)}
                                variant="head"
                                style={{ height: headerHeight }}
                                align={
                                  columnType == ColumnType.number || columnType == ColumnType.fileType ?
                                    'right' : 'left'}
                              >
                                {/* <TableSortLabel
                                  active={orderBy === columns[columnIndex].dataKey}
                                  direction={orderBy === columns[columnIndex].dataKey && order ? order : 'asc'}
                                  onClick={createSortHandler(columns[columnIndex].dataKey)}
                                >
                                  {label}
                                  {orderBy === columns[columnIndex].dataKey ? (
                                    <span className={classes.visuallyHidden}>
                                      {order === 'desc' ? 'sorted descending' : 'sorted ascending'}
                                    </span>
                                  ) : null}
                                </TableSortLabel> */
                                  propsHeader.label
                                }
                              </TableCell>);
                          }}
                          cellRenderer={({ columnIndex, cellData, ...propsCell }) => {
                            return (
                              <TableCell
                                component="div"
                                className={clsx(classesTable.tableCell, classesTable.flexContainer)}
                                variant="body"
                                style={{ height: rowHeight }}
                                align={(columnIndex != null &&
                                  (columns[columnIndex].columnType == ColumnType.number) ||
                                  (columns[columnIndex].columnType == ColumnType.fileType)) ?
                                  'right' : 'left'}
                              >
                                {columns[columnIndex].columnType == ColumnType.fileType ?
                                  NOneFileDataType[cellData] :
                                  cellData}
                              </TableCell>
                            );
                          }}
                        />
                      );
                    })}
                  </Table>
                </div>
              )}
            </AutoSizer>
          </div>
        )}
      </WindowScroller>
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
