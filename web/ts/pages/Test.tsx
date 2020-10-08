import React, { FunctionComponent, useEffect, useState } from "react";
import CssBaseline from "@material-ui/core/CssBaseline";
aimport { createStyles, makeStyles, Theme, withStyles, WithStyles } from "@material-ui/core/styles";

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

function VirtualizedTableFactory() {
  return withStyles(styles)(MuiVirtualizedTable);
}


const VirtualizedTable = VirtualizedTableFactory();

// ---

interface Data {
  calories: number;
  carbs: number;
  dessert: string;
  fat: number;
  id: number;
  protein: number;
}
type Sample = [string, number, number, number, number];

const sample: Sample[] = [
  ['Frozen yoghurt', 159, 6.0, 24, 4.0],
  ['Ice cream sandwich', 237, 9.0, 37, 4.3],
  ['Eclair', 262, 16.0, 24, 6.0],
  ['Cupcake', 305, 3.7, 67, 4.3],
  ['Gingerbread', 356, 16.0, 49, 3.9],
];

function createData(
  id: number,
  dessert: string,
  calories: number,
  fat: number,
  carbs: number,
  protein: number,
): Data {
  return { id, dessert, calories, fat, carbs, protein };
}

const rows: Data[] = [];

for (let i = 0; i < 20000; i += 1) {
  const randomSelection = sample[Math.floor(Math.random() * sample.length)];
  rows.push(createData(i, ...randomSelection));
}

const PageTest: React.FC<typeof mapDispatchToProps> = (props) => {



  useEffect(() => {
    props.fetchSetTitle('Тестовая комната');
  }, []);

  return (
    <Container component="main">
      <CssBaseline />
      <VirtualizedTable
        rowCount={rows.length}
        rowGetter={({ index }) => rows[index]}
        columns={[
          {
            width: 200,
            label: 'Dessert',
            dataKey: 'dessert',
          },
          {
            width: 120,
            label: 'Calories\u00A0(g)',
            dataKey: 'calories',
            numeric: true,
          },
          {
            width: 120,
            label: 'Fat\u00A0(g)',
            dataKey: 'fat',
            numeric: true,
          },
          {
            width: 120,
            label: 'Carbs\u00A0(g)',
            dataKey: 'carbs',
            numeric: true,
          },
          {
            width: 120,
            label: 'Protein\u00A0(g)',
            dataKey: 'protein',
            numeric: true,
          },
        ]}
      />
    </Container>
  );
};

const mapDispatchToProps = {
  fetchSetTitle: fetchSetTitle
}
export default connect(null, mapDispatchToProps)(PageTest);
