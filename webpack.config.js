"use strict";

// import { path } from "path";
const path = require('path');

module.exports = {
    alias: {
        'react-virtualized/List': 'react-virtualized/dist/es/List',
    },
    entry: './web/ts/index.tsx',
    devtool: 'inline-source-map',
    module: {
        rules: [
            {
                test: /\.tsx?$/,
                use: 'ts-loader',
                exclude: /node_modules/,
            },
        ],
    },
    resolve: {
        extensions: ['.tsx', '.ts', '.js'],
    },
    output: {
        filename: 'app.bundle.js',
        path: path.resolve(__dirname, 'web'),
    },
    mode: 'development',
    watch: true,
    watchOptions: {
        aggregateTimeout: 500,
        poll: 1000 // порверяем измемения раз в секунду
    }

};
