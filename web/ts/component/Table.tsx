import React, { FunctionComponent, useEffect, useState } from "react";
import CssBaseline from "@material-ui/core/CssBaseline";
import { createStyles, makeStyles, Theme, withStyles, WithStyles } from "@material-ui/core/styles";

import Avatar from "@material-ui/core/Avatar";
import Button from "@material-ui/core/Button";
import TextField from "@material-ui/core/TextField";
import FormControlLabel from "@material-ui/core/FormControlLabel";
import Checkbox from "@material-ui/core/Checkbox";
import Link from "@material-ui/core/Link";
import Grid from "@material-ui/core/Grid";
import Box from "@material-ui/core/Box";
import Typography from "@material-ui/core/Typography";
import Container from "@material-ui/core/Container";

import LockOutlinedIcon from "@material-ui/icons/LockOutlined";

import useStyles from "./../styles";
import { connect } from "react-redux";
import { fetchSetTitle } from "../redux";
import { AutoSizer, Column, List, Table, TableCellRenderer, TableHeaderProps, WindowScroller } from "react-virtualized";
import TableCell from "@material-ui/core/TableCell";
import clsx from "clsx";
import PropTypes from 'prop-types';
import Immutable from 'immutable';
import TableSortLabel from "@material-ui/core/TableSortLabel";


function descendingComparator<T>(a: T, b: T, orderBy: keyof T) {
  if (b[orderBy] < a[orderBy]) {
    return -1;
  }
  if (b[orderBy] > a[orderBy]) {
    return 1;
  }
  return 0;
}

export type Order = 'asc' | 'desc';

function getComparator<Key extends keyof any>(
  order: Order,
  orderBy: Key,
): (a: { [key in Key]: number | string }, b: { [key in Key]: number | string }) => number {
  return order === 'desc'
    ? (a, b) => descendingComparator(a, b, orderBy)
    : (a, b) => -descendingComparator(a, b, orderBy);
}
function stableSort<T>(array: T[], comparator: (a: T, b: T) => number) {
  const stabilizedThis = array.map((el, index) => [el, index] as [T, number]);
  stabilizedThis.sort((a, b) => {
    const order = comparator(a[0], b[0]);
    if (order !== 0) return order;
    return a[1] - b[1];
  });
  return stabilizedThis.map((el) => el[0]);
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
  });


interface ColumnData {
  dataKey: string;
  label: string;
  numeric?: boolean;
  width: number;
}

interface Row {
  index: number;
}

interface MuiVirtualizedTableProps<T> extends WithStyles<typeof styles> {
  columns: ColumnData[];
  headerHeight?: number;
  onRowClick?: () => void;
  rowCount: number;
  rowGetter: (row: Row) => T;
  rowHeight?: number;
  orderBy: string;
  order: Order;
  numSelected: number;
  onRequestSort: (event: React.MouseEvent<unknown>, property: string) => void;
  onSelectAllClick: (event: React.ChangeEvent<HTMLInputElement>) => void;
}

class MuiVirtualizedTable<T> extends React.PureComponent<MuiVirtualizedTableProps<T>> {
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
        {cellData}
      </TableCell>
    );
  };

  headerRenderer = ({ label, columnIndex }: TableHeaderProps & { columnIndex: number }) => {
    const { headerHeight, columns, classes, order, orderBy, onRequestSort } = this.props;
    const createSortHandler = (property: string) => (event: React.MouseEvent<unknown>) => {
      onRequestSort(event, property);
    };

    return (
      <TableCell
        component="div"
        className={clsx(classes.tableCell, classes.flexContainer, classes.noClick)}
        variant="head"
        style={{ height: headerHeight }}
        align={columns[columnIndex].numeric || false ? 'right' : 'left'}
      >
        <TableSortLabel
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
        </TableSortLabel>
      </TableCell>
    );
  };

  render() {
    const { classes, columns, rowHeight, headerHeight, ...tableProps } = this.props;
    return (
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
                    rowHeight={rowHeight!}
                    gridStyle={{
                      direction: 'inherit',
                    }}
                    headerHeight={headerHeight!}
                    className={classes.table}
                    {...tableProps}
                    rowClassName={this.getRowClassName}
                    isScrolling={isScrolling}
                    onScroll={onChildScroll}
                    scrollTop={scrollTop}
                    overscanRowCount={2}
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
                </div>
              )}
            </AutoSizer>
          </div>
        )}
      </WindowScroller>
    );
  }
}

export default function VirtualizedTableFactory() {
  return withStyles(styles)(MuiVirtualizedTable);
}
