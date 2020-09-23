const path = require('path');

module.exports = {
    entry: {
        app: './web/ts/index.tsx',
        sw: './web/sw/index.tsx',
    },
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
        filename: '[name].bundle.js',
        path: path.resolve(__dirname, 'web'),
    },
    mode: process.env.NODE_ENV === 'production' ? 'production' : 'development'
};