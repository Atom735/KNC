System.register("ProTip", ["react", "@material-ui/core/styles", "@material-ui/core/Link", "@material-ui/core/SvgIcon", "@material-ui/core/Typography"], function (exports_1, context_1) {
    "use strict";
    var react_1, styles_1, Link_1, SvgIcon_1, Typography_1, useStyles;
    var __moduleName = context_1 && context_1.id;
    function LightBulbIcon(props) {
        return (react_1.default.createElement(SvgIcon_1.default, Object.assign({}, props),
            react_1.default.createElement("path", { d: "M9 21c0 .55.45 1 1 1h4c.55 0 1-.45 1-1v-1H9v1zm3-19C8.14 2 5 5.14 5 9c0 2.38 1.19 4.47 3 5.74V17c0 .55.45 1 1 1h6c.55 0 1-.45 1-1v-2.26c1.81-1.27 3-3.36 3-5.74 0-3.86-3.14-7-7-7zm2.85 11.1l-.85.6V16h-4v-2.3l-.85-.6C7.8 12.16 7 10.63 7 9c0-2.76 2.24-5 5-5s5 2.24 5 5c0 1.63-.8 3.16-2.15 4.1z" })));
    }
    function ProTip() {
        const classes = useStyles();
        return (react_1.default.createElement(Typography_1.default, { className: classes.root, color: "textSecondary" },
            react_1.default.createElement(LightBulbIcon, { className: classes.lightBulb }),
            "Pro tip: See more",
            ' ',
            react_1.default.createElement(Link_1.default, { href: "https://material-ui.com/getting-started/templates/" }, "templates"),
            " on the Material-UI documentation."));
    }
    exports_1("default", ProTip);
    return {
        setters: [
            function (react_1_1) {
                react_1 = react_1_1;
            },
            function (styles_1_1) {
                styles_1 = styles_1_1;
            },
            function (Link_1_1) {
                Link_1 = Link_1_1;
            },
            function (SvgIcon_1_1) {
                SvgIcon_1 = SvgIcon_1_1;
            },
            function (Typography_1_1) {
                Typography_1 = Typography_1_1;
            }
        ],
        execute: function () {
            useStyles = styles_1.makeStyles((theme) => styles_1.createStyles({
                root: {
                    margin: theme.spacing(6, 0, 3),
                },
                lightBulb: {
                    verticalAlign: 'middle',
                    marginRight: theme.spacing(1),
                },
            }));
        }
    };
});
System.register("App", ["react", "@material-ui/core/Container", "@material-ui/core/Typography", "@material-ui/core/Box", "@material-ui/core/Link", "ProTip"], function (exports_2, context_2) {
    "use strict";
    var react_2, Container_1, Typography_2, Box_1, Link_2, ProTip_1;
    var __moduleName = context_2 && context_2.id;
    function Copyright() {
        return (react_2.default.createElement(Typography_2.default, { variant: "body2", color: "textSecondary", align: "center" },
            'Copyright © ',
            react_2.default.createElement(Link_2.default, { color: "inherit", href: "https://material-ui.com/" }, "Your Website"),
            ' ',
            new Date().getFullYear(),
            '.'));
    }
    function App() {
        return (react_2.default.createElement(Container_1.default, { maxWidth: "sm" },
            react_2.default.createElement(Box_1.default, { my: 4 },
                react_2.default.createElement(Typography_2.default, { variant: "h4", component: "h1", gutterBottom: true }, "Create React App v4-beta example with TypeScript"),
                react_2.default.createElement(ProTip_1.default, null),
                react_2.default.createElement(Copyright, null))));
    }
    exports_2("default", App);
    return {
        setters: [
            function (react_2_1) {
                react_2 = react_2_1;
            },
            function (Container_1_1) {
                Container_1 = Container_1_1;
            },
            function (Typography_2_1) {
                Typography_2 = Typography_2_1;
            },
            function (Box_1_1) {
                Box_1 = Box_1_1;
            },
            function (Link_2_1) {
                Link_2 = Link_2_1;
            },
            function (ProTip_1_1) {
                ProTip_1 = ProTip_1_1;
            }
        ],
        execute: function () {
        }
    };
});
System.register("theme", ["@material-ui/core/colors/red", "@material-ui/core/styles"], function (exports_3, context_3) {
    "use strict";
    var red_1, styles_2, theme;
    var __moduleName = context_3 && context_3.id;
    return {
        setters: [
            function (red_1_1) {
                red_1 = red_1_1;
            },
            function (styles_2_1) {
                styles_2 = styles_2_1;
            }
        ],
        execute: function () {
            theme = styles_2.createMuiTheme({
                palette: {
                    primary: {
                        main: '#556cd6',
                    },
                    secondary: {
                        main: '#19857b',
                    },
                    error: {
                        main: red_1.default.A400,
                    },
                    background: {
                        default: '#fff',
                    },
                },
            });
            exports_3("default", theme);
        }
    };
});
System.register("index", ["react", "react-dom", "@material-ui/core/CssBaseline", "@material-ui/core/styles", "App", "theme"], function (exports_4, context_4) {
    "use strict";
    var react_3, react_dom_1, CssBaseline_1, styles_3, App_1, theme_1;
    var __moduleName = context_4 && context_4.id;
    return {
        setters: [
            function (react_3_1) {
                react_3 = react_3_1;
            },
            function (react_dom_1_1) {
                react_dom_1 = react_dom_1_1;
            },
            function (CssBaseline_1_1) {
                CssBaseline_1 = CssBaseline_1_1;
            },
            function (styles_3_1) {
                styles_3 = styles_3_1;
            },
            function (App_1_1) {
                App_1 = App_1_1;
            },
            function (theme_1_1) {
                theme_1 = theme_1_1;
            }
        ],
        execute: function () {
            react_dom_1.default.render(react_3.default.createElement(styles_3.ThemeProvider, { theme: theme_1.default },
                react_3.default.createElement(CssBaseline_1.default, null),
                react_3.default.createElement(App_1.default, null)), document.querySelector('#root'));
        }
    };
});
//# sourceMappingURL=tsc.js.map