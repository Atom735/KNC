declare function JsUser(str?: string): JsUser;

interface JsUser {
    name?: string;
    fname?: string;
    mname?: string;
    lname?: string;
    email?: string;
    phone?: string;
    pass?: string;
    access?: string;
    genJsonStringReg: () => string;
    genJsonStringPass: () => string;
}
